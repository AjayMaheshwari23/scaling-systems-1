# 01 — Architecture and Performance Theory

## 1. Why this project is useful

The Java code is intentionally simple. The difficult part is understanding how a distributed request behaves under load when each component has a different bottleneck.

One `/home` request becomes:

- one request into Server 1,
- one request from Server 1 to Server 2,
- one request from Server 1 to Server 3,
- one request from Server 1 to Server 4,
- one DB operation from Server 3 to PostgreSQL.

At 1,000 homepage RPS, the uncached steady-state system therefore drives approximately:

- 1,000 RPS into Server 1,
- 1,000 RPS into each downstream,
- 3,000 downstream HTTP calls/sec in aggregate,
- roughly 1,000 DB operations/sec.

That is the first scaling lesson: **fan-out multiplies internal work**.

## 2. Sequential versus parallel fan-out

At low load, a rough model for sequential fan-out is:

`T_home ≈ T_s2 + T_s3 + T_s4 + aggregator_overhead`

If the calls are independent and execute in parallel:

`T_home ≈ max(T_s2, T_s3, T_s4) + fanout/aggregation_overhead`

This is only an intuition. Under load, queueing, thread scheduling, connection waiting, GC, CPU throttling, and DB contention can dominate.

Example low-load service times:

- Server 2: 8 ms
- Server 3: 27 ms
- Server 4: 4 ms

Sequential might be around 39 ms plus overhead. Parallel might be around 27 ms plus overhead.

## 3. P99 is not composable by simple arithmetic

Do not calculate homepage P99 by either summing the three downstream P99s or taking the maximum of the three P99 numbers. Percentiles are distribution properties.

With parallel fan-out, the homepage finishes only when all required dependencies finish. Even if downstream latency distributions were independent, tail probability compounds.

For illustration: if each of three dependencies has a 99% probability of completing under some threshold, the probability that **all three** complete under that threshold is:

`0.99 × 0.99 × 0.99 = 97.03%`

To make 99% of three-way fan-outs finish below a threshold under the simplifying independence assumption, each dependency would need to be below it about 99.665% of the time.

Real dependencies are often correlated because they share the host, CPU scheduler, network stack, garbage collector behavior, or load phase. Correlation can make the tail worse.

## 4. CPU service-demand feasibility

A powerful sanity check is:

`CPU utilization ≈ arrival_rate × CPU_time_per_request / available_CPU_capacity`

Server 2 has 0.5 vCPU. At 1,000 requests/sec, the absolute theoretical CPU budget is only:

`0.5 CPU-seconds/sec / 1000 requests/sec = 0.0005 sec/request = 0.5 ms CPU/request`

That is at 100% saturation, which leaves no useful headroom. If the deterministic Server 2 workload actually consumes 1 ms of CPU per request, then 1,000 RPS requires roughly one full CPU and cannot be sustained on a 0.5-vCPU quota. No HTTP-client optimization can fix that.

For PostgreSQL at 0.25 vCPU, the corresponding theoretical budget at 1,000 DB operations/sec is about 0.25 ms of CPU per DB operation at 100% saturation.

These are not guaranteed achievable budgets; they are upper-bound sanity checks. Scheduler overhead and other work consume CPU too.

## 5. Queueing and the saturation knee

Latency usually rises gently at low utilization and sharply as a bottleneck approaches saturation. This creates a knee in the latency-throughput curve.

A fictional example:

| Offered RPS | Successful RPS | P99 | Bottleneck |
|---:|---:|---:|---|
| 100 | 100 | 12 ms | none |
| 500 | 500 | 18 ms | none |
| 750 | 750 | 25 ms | S2 CPU rising |
| 900 | 899 | 40 ms | S2 CPU high |
| 1000 | 995 | 95 ms | S2 queueing |
| 1100 | 970 | 600 ms | saturated |

The exact numbers do not matter. The shape does.

## 6. Little's Law

For a stable system:

`L = λW`

where:

- `L` = average requests in flight,
- `λ` = throughput in requests/sec,
- `W` = average time in system in seconds.

At 1,000 RPS:

- 20 ms average latency implies roughly 20 requests in flight,
- 50 ms implies roughly 50,
- 100 ms implies roughly 100,
- 200 ms implies roughly 200.

This is why latency affects required concurrency. With a blocking servlet model, long latency can consume many request threads even if Server 1 itself performs little CPU work.

## 7. Why parallel blocking calls can still be expensive

Parallelizing three blocking downstream calls reduces wall-clock latency but does not make blocking disappear.

A naive design may consume:

- one Server 1 request thread,
- plus up to three executor tasks waiting on downstream responses,
- plus downstream server threads,
- plus a DB connection/thread path on Server 3.

At high concurrency, an unbounded executor or queue can convert overload into enormous P99 rather than obvious rejection. Use bounded resources and observe queueing.

## 8. Bottleneck migration

A successful optimization often moves the bottleneck:

1. sequential fan-out makes Server 1 wait on sums,
2. parallel fan-out removes that latency component,
3. Server 2 CPU becomes dominant,
4. CPU work is calibrated/tuned and Server 3 DB dominates,
5. DB caching lowers DB utilization,
6. Server 1 thread/HTTP pool or GC becomes visible.

This migration is a feature of the project. The goal is not to make every component 'fast'; it is to identify the current limiting resource from evidence.

## 9. Coordinated omission and workload model

A fixed-concurrency load test can accidentally send fewer requests when the server slows down, making latency look better than a real arrival stream. For a target of 1,000 RPS, use Gatling's open workload/arrival-rate model so new requests continue to be scheduled according to the target rate.

Also verify the load generator itself can maintain that schedule.

## 10. Client latency versus server latency

Use Gatling as the authoritative end-to-end measure because it sees the entire request from outside the system.

Use application metrics and traces to explain the result.

A trace might show:

```text
GET /home                        42 ms
|-- call server-2                18 ms
|-- call server-3                39 ms
|   `-- PostgreSQL SELECT        31 ms
`-- call server-4                 4 ms
```

That tells you why the external 42 ms occurred.

## 11. Percentiles from Prometheus are approximations

Prometheus commonly calculates percentiles from histogram buckets using `histogram_quantile`. The result depends on bucket boundaries and aggregation. Gatling's report and Prometheus-derived P99 need not match exactly.

Do not treat a disagreement of a few milliseconds as a bug until you understand the measurement methods and windows.

## 12. Observability changes the system

Tracing every request at 1,000 RPS can itself change CPU, memory, allocation, and network behavior. Therefore:

- use 100% trace sampling for low-RPS correctness or short diagnostics,
- use a fixed low ratio such as 5% for normal performance experiments,
- keep that ratio unchanged between comparable runs,
- run a dedicated tracing-on versus tracing-off experiment to quantify overhead.

Metrics also have overhead, but it is typically much smaller when label cardinality and scrape frequency are controlled.
