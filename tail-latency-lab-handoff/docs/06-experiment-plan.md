# 06 — Ordered Experiment Plan

Do the experiments in order unless evidence gives a strong reason to insert a diagnostic experiment. Record every change.

## E00 — Correctness and instrumentation

Goal: prove the topology works before load testing.

Build:

- four endpoints,
- S1 fan-out,
- S3 database read,
- Actuator/Prometheus,
- OpenTelemetry traces,
- Docker images/Compose.

Verify one `/home` request produces:

- correct combined response,
- one S2 call,
- one S3 call,
- one S4 call,
- one DB query,
- one connected distributed trace.

No performance conclusion yet.

## E00B — Workload calibration

### Server 2

Sweep its CPU work factor at low load. Choose and freeze one value.

Record enough evidence to estimate whether 1K RPS is theoretically plausible.

### Server 3 / DB

Confirm the indexed query is small and deterministic. Verify schema/index with PostgreSQL explain tools if needed.

The objective is not to make the DB intentionally terrible; it is to create real DB work with measurable pool/query behavior.

## E01 — Sequential baseline

Server 1 calls S2 -> S3 -> S4 sequentially.

Keep:

- normal HTTP connection reuse,
- default/baseline pool sizes,
- no app cache,
- fixed JVM memory envelope,
- fixed 5% trace sampling.

Run staircase, then three 1K target runs if feasible.

Answer:

- Can the architecture sustain 1K?
- Which component saturates first?
- Does low-load S1 latency approximate the downstream sum?

## E02 — Parallel fan-out

Only change: downstream calls in Server 1 are launched concurrently.

Use a bounded executor and record its size/queue configuration.

Expected learning:

- S1 wall time should move from sum-like toward max-like behavior at low load,
- total downstream work does **not** decrease,
- thread/executor demand may increase,
- the bottleneck may migrate to S2 or S3.

Inspect traces to confirm overlap.

## E03 — HTTP client reuse / connection behavior

Only change HTTP client/pool settings.

Investigate:

- connection reuse,
- max connections,
- pending acquisition if the client exposes it,
- connect overhead,
- whether you accidentally created clients per request.

Do not assume bigger pools are better.

If your baseline client already has adequate reuse/pooling, E03 may be a "no change needed" result. That is valid.

## E04 — Server 1 concurrency/thread tuning

Only change bounded executor/Tomcat-related concurrency parameters relevant to the measured bottleneck.

Sweep small, explicit values. Examples might include executor parallelism and queue capacity.

Questions:

- Are homepage request threads blocked waiting for executor work?
- Is the executor queue growing?
- Does adding threads reduce queueing or just add context switching/native memory?

Never use an unbounded queue as a latency fix.

## E05 — Timeouts

Add explicit downstream connection and response/read timeouts based on observed healthy latency.

Primary target has no deliberate network faults, so timeouts may not improve healthy P99. The learning goal is operational correctness and preventing infinite/very long waits.

Do not add retries here.

Verify timeouts are high enough not to manufacture failures during normal target load.

## E06 — Server 2 CPU investigation

The work factor remains fixed.

Investigate implementation overhead without changing the amount of intended logical work:

- unnecessary allocations,
- avoidable synchronization/contention,
- algorithm implementation details,
- JIT warm-up behavior.

If the workload definition itself changes, that is a different benchmark and must be labeled accordingly.

Use the CPU budget math to explain maximum sustainable throughput.

## E07 — Hikari connection-pool sweep

Only change Server 3 pool size.

Suggested candidates: 2, 4, 8, 16 (adapt if evidence indicates a narrower range).

For each value record:

- S3 P99,
- `/home` P99,
- Hikari active/idle/pending,
- PostgreSQL CPU,
- DB span duration,
- errors/timeouts.

A small DB with 0.25 CPU may perform worse with excessive concurrency.

## E08 — Query/index optimization

Only after E07.

Use query plan evidence. Possible changes:

- correct index,
- select only needed columns,
- avoid unnecessary conversions,
- prepared/parameterized access.

Because the baseline is intended to use an indexed primary-key lookup, this experiment may show little improvement. Do not invent a bad query just to produce a win.

## E09 — Server 3 cache

Introduce a bounded local in-process cache for DB read results.

Record:

- max cache size,
- expiration policy if any,
- hit ratio,
- miss ratio,
- DB QPS/CPU effect,
- S3 and S1 latency effect.

Use the same 10,000-ID access distribution.

Perform at least two useful cache sizes so the relationship between hit rate and DB load is visible.

Do not cache S1's whole response in the primary experiment.

## E10 — JVM heap and garbage collection

Now vary JVM memory/GC parameters, one configuration at a time.

Candidates to learn about:

- container-aware max heap percentage,
- fixed heap versus percentage,
- Java 17 default collector behavior,
- G1GC,
- SerialGC for very small heaps.

Measure:

- heap occupancy,
- GC pause distribution,
- allocation pressure,
- CPU,
- container memory,
- P99.

Do not pick a collector by reputation. Pick from measured behavior under these small container limits.

## E11 — Servlet/runtime tuning

Investigate only parameters supported by evidence:

- Tomcat max threads,
- accept count/queue behavior,
- keep-alive settings,
- request handling concurrency.

The goal is not to turn every knob. Explain each changed parameter through Little's Law and observed thread utilization.

## E12 — Payload/serialization

Keep semantics identical while testing whether response object shape/JSON allocation is material.

This may be a null result because payloads are intentionally small. Null results are useful.

## E13 — Observability overhead

Compare the same fixed workload/configuration with:

1. tracing disabled,
2. 5% trace sampling,
3. optional short 100% sampling diagnostic.

Metrics stay enabled.

This quantifies the cost of the instrumentation used to study the system.

Do not use the tracing-disabled number as the main final result unless you clearly state that observability was disabled. The final optimized result should use the agreed standard benchmark observability configuration.

## E14 — Saturation search

Using the best valid configuration so far, run a staircase beyond 1,000 RPS until one of these occurs:

- error threshold violated,
- P99 rises sharply,
- throughput stops tracking arrivals,
- queueing grows,
- a resource remains saturated.

Identify the knee and current limiting component.

## E15 — Final 1,000 RPS result

Run at least three independent 1K benchmarks using the final configuration and standard observability settings.

Report:

- median P50/P95/P99,
- P99 range across runs,
- successful throughput,
- error rate,
- resource utilization,
- final bottleneck,
- percent/absolute improvement from E01,
- which optimizations were effective,
- which did nothing or hurt.

## Optional follow-up project — horizontal scaling

Only after E15:

- replicate Server 2,
- then Server 3 if appropriate,
- add a load balancer/service discovery mechanism,
- study whether PostgreSQL becomes the shared bottleneck.

Do not mix this with the fixed single-instance primary result.
