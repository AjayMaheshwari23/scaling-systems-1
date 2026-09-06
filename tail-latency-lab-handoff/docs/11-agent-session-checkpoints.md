# 11 — Suggested Agent Session Checkpoints

Use these checkpoints to keep the local agent in teaching/review mode rather than implementation mode.

## Checkpoint 1 — Project bootstrap

You do:

- create four Spring Boot Maven projects,
- select dependencies,
- run each empty app locally.

Agent verifies:

- Java/Spring versions,
- dependency choices,
- directory layout.

Exit condition: all four apps boot independently.

## Checkpoint 2 — Server 4 first

Implement the simplest downstream yourself.

Agent reviews endpoint/DTO style.

Exit condition: curl gets a small valid response and Prometheus endpoint exists.

## Checkpoint 3 — Server 2

Implement configurable deterministic CPU work.

Agent reviews for accidental sleep/I/O, excessive allocations, and dead-code-like logic.

Exit condition: work factor visibly changes CPU/request time.

## Checkpoint 4 — PostgreSQL + Server 3

You create schema/seed and JDBC read.

Agent teaches parameterized JDBC and reviews pool usage.

Exit condition: one request produces one DB read and one JDBC span.

## Checkpoint 5 — Server 1 sequential

You implement three sequential downstream calls and aggregate output.

Agent reviews HTTP-client lifecycle and error behavior.

Exit condition: a trace shows S2 then S3 then S4 with no overlap.

## Checkpoint 6 — Docker

You write each Dockerfile.

Agent explains image/container concepts and reviews Dockerfiles.

Use the provided Compose stack.

Exit condition: all services communicate using Docker DNS, not localhost.

## Checkpoint 7 — Metrics/traces

Agent helps you find the exact metric names in Prometheus and verify Tempo trace topology.

Exit condition: you can point at a graph/trace for every mandatory measurement category.

## Checkpoint 8 — Gatling

You write a small 10–100 RPS simulation first.

Agent verifies that the injection is an open arrival-rate model.

Exit condition: Gatling RPS approximately matches Server 1 metrics.

## Checkpoint 9 — E01 baseline

Calibrate S2, freeze work factor, then run sequential staircase and baseline.

Do not optimize yet.

Exit condition: completed result sheets and identified bottleneck hypothesis.

## Checkpoint 10 onward — one experiment at a time

For each experiment:

1. state hypothesis,
2. name one changed variable,
3. predict which metric should move,
4. implement change,
5. benchmark,
6. compare,
7. accept/reject.

The agent should refuse to stack unrelated optimizations into one benchmark if the goal is causal learning.
