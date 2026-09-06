# Project Specification

## Project name

**Java Tail-Latency Lab: 1K RPS Fan-Out Service**

## Machine

- Host: macOS
- Apple Silicon: M4
- Host RAM: 18 GB
- Container runtime: Docker Desktop
- Load generator: Gatling running on the host

## Language and framework

- Java 17
- Spring Boot 4.1.1
- Maven / Maven Wrapper
- REST/HTTP services

### Version-change note (owner override)

The original handoff documentation pinned Spring Boot 3.5.16. The project owner later
explicitly changed the baseline to Spring Boot 4.1.1 (mentor-confirmed). This decision
supersedes any conflicting statement in PROJECT_SPEC.md, README.md, AGENT_HANDOFF.md,
checkpoints, or any other generated handoff document.

- Spring Boot 4.1.1 is now the experiment constant.
- The framework version must NOT change between benchmark runs (baseline through final).
- Spring Boot 4.1.1 uses Boot 4 starter names (e.g. `spring-boot-starter-webmvc`).
- Java 17 is preserved.

## Service topology

### Server 1 — homepage aggregator

- Resource limit: **1.0 vCPU, 512 MiB RAM**
- Endpoint: `GET /home`
- No database access
- Calls Server 2, Server 3, and Server 4
- Initially calls them sequentially
- Later calls them in parallel
- Combines the three responses into one response
- Forwards a deterministic `itemId` to Server 3 so DB/cache experiments have a controllable access pattern

### Server 2 — CPU-bound downstream

- Resource limit: **0.5 vCPU, 256 MiB RAM**
- No DB
- Performs deterministic, low-allocation CPU work
- Work factor is configurable, but becomes **frozen after calibration**
- Returns a small response containing a checksum/result so the computation cannot be optimized away conceptually

### Server 3 — DB-backed downstream

- Resource limit: **0.5 vCPU, 256 MiB RAM**
- Calls PostgreSQL once per request in the uncached baseline
- Uses a JDBC connection pool (Spring Boot default HikariCP is expected)
- Reads a small row by indexed primary key or unique key
- Later experiments tune pool size/query/caching

### Server 4 — normal downstream

- Resource limit: **0.5 vCPU, 256 MiB RAM**
- No DB
- No intentional sleep
- Minimal in-memory response
- Serves as the low-cost downstream control

### PostgreSQL

- Resource limit: **0.25 vCPU, 1 GiB RAM**
- Seeded with a deterministic table of approximately 10,000 rows
- Server 3 uses a parameterized indexed lookup
- Database schema/data stay unchanged during the primary experiment sequence unless an experiment explicitly targets query/index design

## Infrastructure services

These are support services and are not subject to the application limits above:

- Prometheus — metrics store/scraper
- Grafana — dashboards
- Tempo — trace backend
- OpenTelemetry Collector — OTLP receiver/forwarder

Their CPU/RAM consumption can perturb a local benchmark. That is expected and must be recorded. The benchmark protocol therefore keeps their configuration stable between comparable runs.

## Traffic model

The homepage load is an **open arrival-rate workload**, because the target is RPS rather than a fixed number of virtual users.

Suggested staircase:

- 100 RPS
- 250 RPS
- 500 RPS
- 750 RPS
- 900 RPS
- 1,000 RPS
- 1,100 RPS
- 1,250 RPS
- continue only if the system is still healthy

The final target benchmark is 1,000 RPS after warm-up.

## Success criteria at 1,000 RPS

A run is considered technically valid only when all are true during the measurement window:

1. Offered arrival rate is 1,000 requests/sec.
2. Gatling itself is not CPU-starved or unable to schedule the requested rate.
3. Failed requests are below 0.1%.
4. No service or DB container restarts/OOMs.
5. No queue/backlog metric shows unbounded growth throughout the run.
6. Throughput reaches a stable plateau consistent with the offered load.
7. P99 is reported from the steady-state measurement window.

Primary score: **end-to-end Gatling P99 for `/home`**.

Secondary measures:

- P50, P95
- successful RPS
- errors/timeouts
- CPU and memory
- GC pauses
- thread utilization
- downstream client latency
- Hikari pool usage/waiting
- PostgreSQL query latency
- trace span duration

## Non-goals for the primary project

- Kubernetes
- cloud deployment
- service mesh
- autoscaling
- multiple replicas
- cross-machine network latency
- distributed cache
- production authentication/security
- resilience architecture such as circuit breakers/retries as a first-line performance fix

Those can become follow-up projects after the single-instance limits are understood.

## Learning outcome

At the end, you should be able to explain not just *which* change improved P99, but **why** in terms of service demand, utilization, queueing, concurrency, resource limits, GC, connection pools, and fan-out tail amplification.
