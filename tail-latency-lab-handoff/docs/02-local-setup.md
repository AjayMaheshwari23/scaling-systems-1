# 02 — Local Setup on macOS M4

## 1. Prerequisites

Install or verify:

- Docker Desktop for Mac / Apple Silicon
- Java 17 JDK
- Git
- a terminal
- an IDE/editor

Maven does not need to be installed globally if every Java project uses Maven Wrapper (`./mvnw`). The recommended Gatling Java starter also includes a Maven Wrapper.

Verify:

```bash
java -version
docker version
docker compose version
git --version
```

Ensure Java reports version 17.

## 2. Docker Desktop resources

Your Mac has 18 GB RAM. Docker Desktop runs a Linux VM, so the containers do not directly receive all host memory.

Allocate enough Docker Desktop resources for:

- four Spring Boot JVMs,
- PostgreSQL,
- Prometheus,
- Grafana,
- Tempo,
- OpenTelemetry Collector.

A practical starting point is to give Docker Desktop around 8–10 GB RAM and enough host CPUs that the configured per-container quotas can actually be scheduled. Do **not** change Docker Desktop resources between comparable benchmark runs.

The application resource limits themselves stay fixed in Compose.

## 3. Apple Silicon rule

Prefer images that publish `linux/arm64` variants. Do not force `linux/amd64` unless a required dependency lacks ARM64 support, because emulation can distort performance.

For your own application images, build for the host platform by default. Multi-platform image publishing is a later Docker-learning extension, not part of the P99 baseline.

## 4. Create the Java projects yourself

Create four separate Spring Boot projects under:

```text
services/server-1
services/server-2
services/server-3
services/server-4
```

Use:

- Java 17
- Spring Boot 4.1.1 (owner override; experiment constant)
- Maven
- packaging: jar

Expected dependency categories:

### All servers

- Spring Web
- Spring Boot Actuator
- Micrometer Prometheus registry

### Server 3 additionally

- JDBC support
- PostgreSQL JDBC driver

Do not add caching until the caching experiment. Do not add reactive WebFlux merely because it is available; keep the first implementation conceptually simple.

## 5. JVM/container memory reality

A 256 MiB container is intentionally tight for a Spring Boot JVM plus observability agent. The JVM heap is only part of process memory. Other consumers include:

- metaspace,
- code cache,
- thread stacks,
- direct buffers,
- native libraries,
- OpenTelemetry agent overhead.

Do not set `-Xmx256m` inside a 256 MiB container.

For the initial bootable baseline, use a conservative container-aware heap cap and keep it identical for comparable runs. A reasonable starting experiment setting is:

- 256 MiB services: `-XX:MaxRAMPercentage=50`
- 512 MiB Server 1: `-XX:MaxRAMPercentage=55`

These values are not declared optimal. They are a starting envelope to leave native-memory headroom. Record them in every run. Later, the JVM/GC experiment deliberately varies heap sizing and collector choice.

If the service cannot boot within 256 MiB, capture the failure evidence before changing anything. Memory pressure itself is a valid finding.

## 6. OpenTelemetry Java agent

Run:

```bash
./scripts/download-otel-agent.sh
```

This downloads the latest Java agent into `infra/otel-agent/opentelemetry-javaagent.jar`.

The Compose scaffold mounts that JAR into each app container and uses `JAVA_TOOL_OPTIONS` to attach it. This avoids writing tracing code just to obtain baseline traces.

For fully reproducible final results, record the downloaded agent version in the experiment sheet. If you later rerun the project months later, do not silently upgrade it mid-comparison.

## 7. Start observability support services first

Before app code exists, you can validate the support stack separately by commenting out/building only the infrastructure services or by using Compose service selection.

Once the applications exist:

```bash
cd infra
docker compose up -d postgres prometheus tempo otel-collector grafana
```

Then inspect:

```bash
docker compose ps
docker compose logs --tail=100 tempo
docker compose logs --tail=100 otel-collector
```

## 8. Build the application images

Each service should eventually produce a runnable JAR and have a Dockerfile you write yourself.

A conventional image-learning path is:

1. build JAR with Maven,
2. use a Java 17 runtime base image,
3. copy only the runnable JAR into the runtime image,
4. expose port 8080,
5. run `java -jar ...`.

Once all four Dockerfiles exist:

```bash
cd infra
docker compose build
```

Then:

```bash
docker compose up -d
```

## 9. Verify the resource limits

Run:

```bash
docker stats --no-stream
```

Also inspect a container if needed:

```bash
docker inspect tail-latency-server-1
```

Do not assume a YAML value is being honored just because it is present. Verify behavior.

## 10. Expected local ports

The scaffold uses:

- Server 1: `localhost:8080`
- Server 2: `localhost:8082`
- Server 3: `localhost:8083`
- Server 4: `localhost:8084`
- PostgreSQL: `localhost:5432`
- Grafana: `localhost:3000`
- Prometheus: `localhost:9090`
- Tempo HTTP/query: `localhost:3200`
- OTel Collector OTLP gRPC: `localhost:4317`
- OTel Collector OTLP HTTP: `localhost:4318`

Only Server 1 needs to be host-accessible for Gatling. The other app ports are published for learning/debug convenience; inter-service calls should use Docker DNS names such as `server-2:8080`.

## 11. Gatling setup

Use the official **Java + Maven** Gatling starter project rather than installing a large standalone tool bundle.

Create the project under `load-test/`. The official starter uses Maven Wrapper, so a global Maven installation is unnecessary.

Your local agent may guide you through creating the Gatling project and syntax, but it must not write the full simulation for you.

See `docs/05-load-testing.md` for the workload design.

## 12. cAdvisor note on macOS

Do not make cAdvisor a hard dependency for this project. Docker Desktop on macOS runs containers inside a Linux VM, and cAdvisor setups have had Docker Desktop/macOS compatibility and visibility issues.

Mandatory container-resource evidence will therefore use:

- Docker Desktop's container resource view, and/or
- `docker stats`, with the provided periodic sampler.

If cAdvisor works reliably on your exact Docker Desktop version, adding it to Prometheus is an optional extension. Do not burn project time debugging it before the core lab works.
