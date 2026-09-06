# 07 — Reproducible Benchmark Protocol

## Why this exists

Local performance testing is noisy. The benchmark protocol is part of the project, not paperwork after the project.

## Before each comparable run

1. Close unrelated heavy applications if practical.
2. Keep the Mac on power.
3. Keep Docker Desktop CPU/RAM settings unchanged.
4. Record git commit or code state.
5. Record Java/Spring/OTel/Gatling/Docker versions if changed.
6. Ensure the same Compose resource limits are active.
7. Ensure the same DB seed and Gatling item-ID distribution.
8. Ensure the same trace sampling ratio.
9. Ensure no previous Gatling process is still running.
10. Verify all containers are healthy and stable.

## Reset rules

Choose whether each experiment is a **warm-state comparison** or a **cold-state comparison** and keep it consistent.

For the primary P99 optimization sequence, prefer warm steady state:

- restart app containers when the changed configuration requires it,
- ensure DB schema/data is unchanged,
- warm the JVM and common DB pages before measurement,
- do not drop OS/PostgreSQL caches between normal comparisons.

If you explicitly study cold-start/cold-cache behavior, label that as a separate experiment.

## Warm-up

Default warm-up:

- 60 seconds at 250 RPS,
- then transition to target.

If JIT/GC graphs show the system is still changing materially after one minute, extend the warm-up for all subsequent comparable tests.

## Measurement window

Default target window:

- 5 minutes at 1,000 offered requests/sec.

Keep warm-up samples separate from the primary comparison when possible.

## Repetitions

For exploratory changes: one run can tell you whether to investigate further, but not prove a result.

For any claimed improvement: at least three comparable runs.

Report:

- individual P99s,
- median P99,
- min/max range,
- error rate for each run.

If one run is an outlier, do not delete it silently. Investigate or report it.

## Run ID convention

Use:

`E<experiment>-<short-change>-<rps>rps-run<N>`

Examples:

- `E01-sequential-1000rps-run1`
- `E02-parallel-executor12-1000rps-run2`
- `E07-hikari4-1000rps-run1`

## What to capture

For every run:

### Gatling

- requested/offered load
- successful request count
- failed request count/percentage
- P50
- P95
- P99
- maximum latency (informational, not a primary target)

### Server 1

- RPS
- request latency
- error rate
- CPU
- heap
- GC pauses
- threads/Tomcat busy
- executor active/queue size once parallel
- downstream client latency per service

### Server 2

- CPU
- request latency
- heap/GC
- threads

### Server 3

- request latency
- CPU
- heap/GC
- Hikari active/idle/pending
- JDBC query spans

### Server 4

- request latency
- CPU
- heap/GC

### PostgreSQL

- container CPU/memory
- DB-related errors
- DB span/query latency

### Host/load generator

- note whether Gatling/host showed CPU pressure
- note thermal/background activity if obvious

## Comparing runs

An optimization is accepted only if:

- offered load is the same,
- success criteria remain valid,
- P99 improvement repeats,
- no hidden semantic/workload change occurred.

Always look at absolute and percentage change.

Example:

`improvement % = (old_p99 - new_p99) / old_p99 × 100`

## Beware false wins

### Dropping requests

Lower P99 with more failures is not a win.

### Lowering Server 2 work

That changes the problem.

### Cache distribution changed

A higher hit rate caused by changing IDs is not a valid implementation comparison.

### Trace sampling changed

Instrumentation overhead changed.

### JVM/container limit changed

Resource budget changed.

### Warm-up changed

JIT/cache state changed.

## P99 stability

P99 is sensitive to rare events. Use enough samples and multiple runs.

At 300,000 requests, P99 describes the boundary around the slowest ~3,000 requests, which is far more useful than calculating P99 from a few hundred requests.

## Finding the knee

When running the staircase, plot offered RPS versus:

- successful RPS,
- P99,
- error rate,
- CPU of each constrained component.

The knee is where more offered load causes disproportionate latency/errors or throughput stops increasing linearly.

## Final evidence standard

A strong final statement looks like:

> Parallel fan-out reduced median E01 P99 from X ms to Y ms at the same 1,000 RPS and <0.1% errors. Server 1 client spans overlapped after the change, while aggregate downstream RPS remained 3,000/sec. Afterward Server 2 reached approximately Z% of its 0.5-vCPU quota and became the dominant tail contributor.

A weak statement looks like:

> CompletableFuture is faster.

Always connect code/configuration change -> metric/trace evidence -> system explanation.
