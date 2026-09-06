# 09 — Final Project Analysis Template

Complete this only after the final benchmark.

## Executive summary

- Did the system sustain 1,000 RPS under the success criteria?
- Initial sequential P99:
- Final optimized P99:
- Absolute improvement:
- Percentage improvement:
- Final error rate:
- Final identified bottleneck:

## Architecture tested

Document the final architecture and confirm resource limits remained:

- S1: 1 CPU / 512 MiB
- S2: 0.5 CPU / 256 MiB
- S3: 0.5 CPU / 256 MiB
- S4: 0.5 CPU / 256 MiB
- PostgreSQL: 0.25 CPU / 1 GiB

## Baseline

Describe E01:

- sequential calls,
- workload factor,
- DB access pattern,
- pool settings,
- JVM settings,
- trace sampling,
- P50/P95/P99,
- bottleneck evidence.

## Optimization table

| Experiment | Single change | P99 before | P99 after | Errors | Accepted? | Explanation |
|---|---|---:|---:|---:|---|---|
| E02 | parallel fan-out | | | | | |
| E03 | HTTP client/pool | | | | | |
| E04 | concurrency tuning | | | | | |
| E05 | timeouts | | | | | |
| E06 | S2 implementation | | | | | |
| E07 | Hikari pool | | | | | |
| E08 | query/index | | | | | |
| E09 | cache | | | | | |
| E10 | JVM/GC | | | | | |
| E11 | runtime threads | | | | | |
| E12 | serialization | | | | | |
| E13 | trace overhead | | | | | |

## Fan-out learning

Explain:

- sequential sum-like latency,
- parallel max-like latency,
- why P99 is not simply `max(P99_s2, P99_s3, P99_s4)`,
- internal traffic amplification from 1K external RPS.

## CPU capacity learning

Use the service-demand equation to explain Server 2 and PostgreSQL limits.

What CPU time/request was approximately supportable at the target rate?

Where did the saturation knee appear?

## Queueing/concurrency learning

Use Little's Law to estimate expected concurrency from measured average latency and throughput.

What happened to:

- Tomcat threads,
- parallel executor queue,
- Hikari pending connections?

## JVM learning

Which collector/heap setting performed best under the tiny memory limits?

What trade-offs appeared between:

- heap size,
- native headroom,
- GC frequency,
- GC pause duration,
- P99?

## Database and cache learning

Document:

- best Hikari pool size and why,
- query/index result,
- cache hit ratio,
- DB CPU reduction,
- memory/GC cost of caching.

## Observability learning

Describe how a specific slow trace corresponded to population-level metrics.

Quantify tracing overhead from E13.

## Null/negative results

List optimizations that:

- did nothing,
- made performance worse,
- only moved the bottleneck.

These are important results.

## Final 1K RPS evidence

Include the three final runs:

| Run | Successful RPS | Error % | P50 | P95 | P99 | S1 CPU | S2 CPU | S3 CPU | DB CPU |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | | | | | | | | | |
| 2 | | | | | | | | | |
| 3 | | | | | | | | | |

Median P99:

P99 range:

## What would scale next?

Without implementing it, explain what you would scale horizontally first and why.

Then predict the next bottleneck.

## Interview/SWE-II explanation

Write a two-minute explanation of the project without naming tools first. Focus on:

- hypothesis,
- constraints,
- measurement,
- bottleneck,
- change,
- measured result,
- trade-off.

Then be able to dive into Prometheus/Grafana/Gatling/Docker/Java details when asked.

## Project closeout

When this document is complete, ask the local agent to invoke your existing **learning-capture / save-what-I-learned skill** and store the durable lessons from the project.
