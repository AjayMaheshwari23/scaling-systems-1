# 03 — Application Implementation Contracts

This file tells you **what to build**, not the finished Java implementation.

## Common requirements for all four services

Each application must:

- use Java 17,
- use Spring Boot 4.1.1 (owner override; experiment constant),
- use Maven Wrapper,
- listen on container port 8080,
- expose health information,
- expose Prometheus metrics at `/actuator/prometheus`,
- return small JSON responses,
- avoid verbose per-request logs during benchmarks,
- propagate trace headers automatically through the instrumented HTTP client where supported,
- have a Dockerfile written by you.

Expose only the actuator endpoints needed for this local lab. Do not expose every actuator endpoint without understanding it.

## Request correlation

A request should have an identifier available in logs/traces when debugging. Prefer trace IDs from OpenTelemetry over inventing a custom distributed tracing scheme.

Do not add high-cardinality IDs as Prometheus metric labels.

## Server 1 contract

### Endpoint

`GET /home?itemId=<id>`

For controlled Gatling tests, `itemId` should be provided by the load generator. Server 1 forwards it to Server 3.

### Baseline behavior

Call in this exact order:

1. Server 2
2. Server 3
3. Server 4

Wait for each call before issuing the next one.

Then return one combined response containing small fields from all three downstream results.

### Configuration

Downstream base URLs must come from configuration/environment variables, not hard-coded host ports.

Inside Docker Compose they should resolve by service DNS name.

### Parallel experiment

Later, issue all three calls concurrently and wait until all required results are available.

Recommended first learning approach: understand `CompletableFuture` plus a **bounded, explicitly sized executor**. Do not use the common fork-join pool accidentally for benchmark-critical work without understanding its size and contention.

Optional later comparison: non-blocking HTTP using WebClient/Reactor. That is not required for the primary lab.

### Failure semantics

Initially, if a required downstream fails, `/home` may fail. Keep semantics simple and observable. Do not add retries early; retries can multiply load during saturation.

## Server 2 contract — CPU-bound service

### Endpoint

Use one small endpoint such as `GET /compute`.

### Workload properties

The computation must be:

- deterministic,
- mostly CPU rather than sleep/wait,
- low-allocation where practical,
- tunable by a configuration value such as a work factor,
- impossible to optimize away conceptually because its result contributes to the response.

A good shape is repeated integer mixing/rotation/arithmetic over primitive values with a returned checksum. Cryptographic hashing is also possible, but be aware it may create different allocation/library behavior.

### Calibration

Before Experiment 1, find a work factor that produces visible CPU pressure but does not trivially make 1,000 RPS impossible—unless you intentionally choose an impossible stress profile as a separate learning run.

Record:

- work factor,
- low-load request latency,
- approximate CPU utilization at 100/250/500 RPS.

Then **freeze the work factor** for all primary comparisons.

Never lower the work factor to make a later optimization look successful.

## Server 3 contract — PostgreSQL-backed service

### Endpoint

Use an endpoint such as:

`GET /data?itemId=<id>`

### DB behavior

Uncached baseline:

- exactly one logical read query per request,
- parameterized SQL,
- indexed lookup,
- small result set (normally one row),
- no artificial sleep.

Suggested table concept:

```text
home_item
- id: primary key
- title/text field
- numeric field
- another small text/category field
```

Seed around 10,000 deterministic rows so Gatling can cycle through IDs.

### Data access technology

Prefer plain JDBC/JdbcClient/JdbcTemplate for this lab rather than a heavy ORM. The objective is connection pools/query behavior, not ORM features.

Use HikariCP through Spring Boot's normal DataSource setup.

### Pool metrics to observe

Expect to investigate metrics corresponding to:

- active connections,
- idle connections,
- pending/waiting requests,
- max/min pool size,
- connection acquisition time if available.

Do not change pool size until the pool experiment.

### Caching experiment

The primary cache experiment belongs here, in front of the DB read.

Use a bounded in-process cache such as Caffeine only when that experiment begins. Record cache size and hit ratio.

Do **not** cache the entire Server 1 `/home` response in the primary sequence, because that bypasses all downstream behavior and trivializes the fan-out problem.

## Server 4 contract — control downstream

### Endpoint

Use an endpoint such as `GET /normal`.

Return a small in-memory JSON payload with minimal computation.

No DB, no file I/O, no deliberate delay, no cache experiment.

Server 4 helps show the latency/resource profile of a cheap downstream under the same fan-out traffic.

## HTTP client rules

Whichever client you use in Server 1:

- instantiate/configure it once and reuse it,
- do not construct a new client per request,
- use connection reuse/keep-alive,
- expose/observe client request timers if supported,
- add explicit connection/response timeouts in the timeout experiment,
- do not enable automatic retries without measuring their effect.

For the sequential baseline, keep the client configuration fixed. Connection-pool/client changes are separate experiments.

## Error response rule

Errors should be machine-detectable by Gatling via non-2xx status or explicit assertion. Do not return HTTP 200 with a hidden error message and then count it as success.

## Benchmark logging rule

During normal development, logs are useful. During performance runs:

- avoid INFO logs per request,
- avoid printing request/response bodies,
- keep warnings/errors,
- use traces/metrics for hot-path timing.

Logging can easily become an accidental I/O and allocation bottleneck.
