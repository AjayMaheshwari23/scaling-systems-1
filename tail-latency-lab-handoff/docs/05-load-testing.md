# 05 — Gatling Load Testing Guide

## Why Gatling

Gatling can express an **open arrival-rate model**, which fits the requirement "send 1,000 requests per second" better than a closed test that merely keeps N virtual users active.

Use the Java DSL so the load-test language matches the project language.

## Setup

Use Gatling's official Java + Maven starter under `load-test/`.

The official starter includes Maven Wrapper. Typical workflow after setup:

```bash
cd load-test
./mvnw clean install
./mvnw gatling:test
```

Your local agent should help with syntax and explain the Gatling DSL, but you should write the simulation.

## The homepage request

The simulation should call only the externally relevant endpoint:

`GET http://localhost:8080/home?itemId=<id>`

Do not have Gatling directly benchmark Server 2/3/4 during the primary end-to-end experiment. You may create separate diagnostic microbenchmarks later.

## Deterministic item IDs

Use a deterministic feeder or repeatable sequence across approximately 10,000 IDs. This produces a controlled DB/cache access pattern.

Avoid a different random distribution for every experiment unless the distribution itself is the variable being tested.

## Open workload model

Learn the Gatling APIs for arrival-rate injection such as ramping users per second and constant users per second.

Model one virtual-user iteration as one `/home` request. Then an injection rate of 1,000 new users/iterations per second approximates 1,000 offered requests/sec for this simple scenario.

Do not confuse:

- 1,000 concurrent users,
- 1,000 total requests,
- 1,000 requests/second.

They are different tests.

## Recommended staircase test

Use this before the final target run:

| Stage | Offered load | Purpose |
|---|---:|---|
| A | 100 RPS | correctness + low-load latency |
| B | 250 RPS | early utilization |
| C | 500 RPS | mid-load |
| D | 750 RPS | approach bottleneck |
| E | 900 RPS | near target |
| F | 1,000 RPS | target |
| G | 1,100 RPS | find knee if healthy |
| H | 1,250 RPS | continue only if meaningful |

Do not run all stages in one giant test when comparing optimization experiments. A single long staircase is useful for capacity discovery; fixed-load runs are better for apples-to-apples P99 comparison.

## Standard comparison run

Recommended default:

1. 60 seconds warm-up at 250 RPS.
2. Optional short ramp to target.
3. 5 minutes steady state at 1,000 RPS.
4. Stop and capture artifacts.

At 1,000 RPS for five minutes you get roughly 300,000 homepage samples, enough for a meaningful P99 estimate while still being practical locally.

For final conclusions, run the same candidate configuration at least **three independent times**. Report the median P99 and the range/min-max across runs.

## Assertions

Your simulation should fail a benchmark when important conditions are violated. Learn Gatling assertions for:

- failed request percentage < 0.1%,
- response-time percentile threshold if/when you establish one,
- possibly successful request count/throughput checks.

Do not create a P99 target before you have a measured baseline; the goal is to discover the best achievable value.

## Load generator health

Gatling runs on the same Mac, so it shares physical CPU with Docker Desktop.

During high-load runs:

- watch macOS Activity Monitor or equivalent,
- ensure the Gatling JVM is not maxed out,
- ensure Docker Desktop still has resources,
- avoid IDE indexing/builds/browser-heavy activity.

If Gatling cannot schedule 1,000 arrivals/sec, the benchmark is invalid even if the server graphs look good.

## Connection behavior

Use normal HTTP keep-alive. Do not intentionally create a fresh TCP connection per request unless that is a separate experiment.

Do not add artificial think time to the 1K RPS target scenario.

## Response validation

At minimum validate:

- expected HTTP status,
- basic response body/field existence so a broken endpoint is not counted as fast success.

Keep validation lightweight and unchanged between experiments.

## Result naming

Every benchmark gets a run ID, for example:

`E02-parallel-1000rps-run1`

Use the same ID for:

- Gatling output/report,
- Docker stats CSV,
- experiment markdown sheet,
- screenshots/notes if any.

## Common testing mistakes

### Mistake: fixed users instead of fixed arrival rate

When latency rises, closed workloads naturally issue fewer requests. This can mask overload.

### Mistake: including warm-up in the final P99

JIT compilation, class loading, connection establishment, and cache warming distort startup latency.

### Mistake: changing request data

A new ID distribution changes DB/cache behavior and invalidates comparison.

### Mistake: one run only

A single local benchmark can be affected by host scheduling, thermal state, Docker activity, JIT, or GC timing.

### Mistake: testing from inside the same constrained app container

Keep Gatling on the host so it is not competing inside an application resource quota.
