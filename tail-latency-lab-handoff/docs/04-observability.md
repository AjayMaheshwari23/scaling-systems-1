# 04 — Observability: Metrics, Traces, JVM, DB Pool, Containers

## Goal

You should be able to answer, for any slow `/home` request:

1. Which downstream dominated?
2. Was that downstream waiting on CPU, a thread, a connection, or PostgreSQL?
3. Was the JVM pausing or allocating heavily?
4. Was the container near its CPU/memory limit?
5. Did the system remain healthy as offered load increased?

## Stack

```text
Spring Boot Actuator + Micrometer
           |
           v
      Prometheus  ---> Grafana dashboards

Java services + OpenTelemetry Java agent
           |
           v
OpenTelemetry Collector ---> Tempo ---> Grafana trace view
```

Spring Boot exposes Prometheus-formatted metrics at `/actuator/prometheus` when the Prometheus registry is present and the endpoint is exposed.

The OpenTelemetry Java agent is used for zero-code baseline tracing of inbound HTTP, supported outbound HTTP clients, and JDBC. If a chosen library is not automatically instrumented, diagnose that explicitly before adding manual spans.

## Mandatory application/JVM metrics

For every Java service, inspect at least:

### Traffic and latency

- request count/rate
- request duration histogram
- status/error rate
- active requests if available
- downstream client request duration/count for Server 1

### JVM memory

- heap used/committed/max
- non-heap/metaspace
- buffer/direct memory where available

### Garbage collection

- GC pause duration
- GC count
- allocation/promotion indicators available through Micrometer/JVM metrics

### Threads

- live thread count
- daemon thread count
- peak threads
- Tomcat worker busy/current/max metrics when exposed
- custom executor active threads, pool size, queue depth when you introduce a custom executor

### CPU

- process CPU utilization
- system CPU indicators exposed to the container/JVM

## Server 3 / Hikari metrics

Monitor:

- active connections
- idle connections
- pending/waiting acquisition
- total/max connections
- acquisition timing when exposed
- timeout count/errors

Questions to ask:

- Is the pool empty while PostgreSQL is idle? Then the pool may be too small.
- Is the pool large while PostgreSQL CPU is pegged? Making it larger may worsen queueing at the DB.
- Are callers waiting for a connection even though query latency is low?

## PostgreSQL evidence

At minimum capture:

- query span duration through JDBC tracing,
- DB container CPU/memory from Docker stats,
- connection count/pool behavior from Server 3.

Optional later extension: add a PostgreSQL Prometheus exporter for internal DB metrics. Do not block the primary project on this.

## Prometheus scrape configuration

The provided `infra/prometheus/prometheus.yml` scrapes all four app `/actuator/prometheus` endpoints every 5 seconds.

Five seconds is a compromise: enough resolution for multi-minute benchmarks without excessively aggressive scraping.

Do not use request IDs, item IDs, URLs with unbounded values, or trace IDs as metric labels. High-cardinality labels can damage the monitoring system and distort the lab.

## Histograms and percentiles

For service-side P95/P99, enable histogram publication for the HTTP meters you actually use. Ask the local agent to explain Spring Boot's `management.metrics.distribution.*` properties and then add the smallest necessary configuration yourself.

Do not configure dozens of percentiles and buckets blindly.

Remember:

- Gatling P99 = external benchmark truth for this project.
- Prometheus P99 = histogram-based diagnostic estimate.

## Distributed tracing setup

The Compose scaffold configures each app with environment variables conceptually equivalent to:

- a unique `OTEL_SERVICE_NAME`,
- OTLP exporter endpoint pointing at the Collector,
- OTLP gRPC protocol,
- parent-based trace-ID ratio sampling,
- 5% sampling for normal benchmarks.

For low-RPS debugging, temporarily set sampling to 100% and restore the benchmark value before comparable runs.

## What a useful trace should show

Sequential baseline:

```text
server-1 GET /home
  server-1 -> server-2 HTTP
  server-1 -> server-3 HTTP
    server-3 JDBC SELECT
  server-1 -> server-4 HTTP
```

Parallel version should show the three Server 1 client spans overlapping in time.

That visual overlap is one of the clearest proofs that you actually parallelized the downstream work.

## Trace checklist

Before doing performance tests, confirm:

- all services have distinct service names,
- trace context propagates Server 1 -> downstream,
- Server 3 JDBC span is a child of the Server 3 request,
- errors are marked on spans,
- span names do not contain high-cardinality values,
- 100% sampling is not accidentally left enabled for long 1K RPS runs.

## Container CPU and memory on macOS

Because cAdvisor can be awkward on Docker Desktop/macOS, the mandatory path is:

```bash
./scripts/collect-docker-stats.sh <run-id>
```

This samples `docker stats` periodically into `results/runs/<run-id>/docker-stats.csv`.

Also use Docker Desktop's container UI to visually inspect CPU/memory during a run.

Optional: if cAdvisor works correctly on your exact Docker Desktop version, add it later as a Prometheus target. Treat it as an observability extension, not a project prerequisite.

## CPU throttling interpretation

A container configured for 0.5 CPU may frequently hit its quota even though the physical M4 has many cores. That is intentional.

If Server 2 is quota-bound:

- latency increases,
- runnable work queues,
- P99 expands,
- physical host CPU can still look far from 100%.

This is why host-wide CPU alone is not enough.

## Memory interpretation

Watch for:

- heap steadily approaching max,
- frequent GC with low reclaimed memory,
- process/container memory near limit,
- container restart/OOM,
- direct/native memory growth,
- high thread counts increasing native stack memory.

Do not assume a low heap graph means the process has plenty of container memory.

## Suggested Grafana dashboard groups

Create dashboards yourself or import/build panels with local-agent help. Organize them as:

### Dashboard A — End-to-end

- S1 request rate
- S1 P50/P95/P99
- S1 errors
- Gatling result note/run ID

### Dashboard B — Fan-out

- S1 -> S2 request latency/rate/errors
- S1 -> S3 request latency/rate/errors
- S1 -> S4 request latency/rate/errors

### Dashboard C — JVM

Per service:

- CPU
- heap
- GC pauses
- live threads
- Tomcat busy threads

### Dashboard D — Server 3 / DB

- S3 request latency
- JDBC span/query timing
- Hikari active/idle/pending
- PostgreSQL container CPU/memory

## Correlating a bad run

When P99 jumps, inspect in this order:

1. Was target RPS actually maintained?
2. Did errors/timeouts increase?
3. Which downstream latency increased?
4. Which resource hit saturation at the same time?
5. Did GC or thread count change?
6. Did the DB pool begin waiting?
7. Inspect several slow traces.

A trace is an example, not a population statistic. Use it to explain patterns already visible in metrics.
