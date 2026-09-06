# Java Tail-Latency Lab — Handoff Pack

This repository is a **learning project**, not a prebuilt application. You will write the Java application code yourself. The pack gives you the architecture, implementation contracts, infrastructure scaffolding, observability plan, load-test methodology, experiment sequence, result templates, and guardrails for your local coding agent.

## Start here

Read these in order:

1. `AGENT_HANDOFF.md` — rules for your local agent.
2. `PROJECT_SPEC.md` — fixed architecture, resources, goals, and non-goals.
3. `docs/01-architecture-and-theory.md` — why this system behaves the way it does.
4. `docs/02-local-setup.md` — macOS/M4, Docker Desktop, Java, Maven, Gatling.
5. `docs/03-implementation-contracts.md` — exactly what each service must do, without giving you the finished application code.
6. `docs/04-observability.md` — JVM metrics, request metrics, DB pool metrics, traces, and container utilization.
7. `docs/05-load-testing.md` — how to generate and validate 1,000 RPS with Gatling.
8. `docs/06-experiment-plan.md` — the ordered optimization experiments.
9. `docs/07-benchmark-protocol.md` — rules for reproducible measurements.
10. `docs/08-troubleshooting.md` — common failures and how to reason about them.
11. `docs/09-final-analysis.md` — how to write the project conclusion.
12. `LEARNING_CHECKLIST.md` — concepts you should be able to explain at the end.

## Fixed system

```text
                         Gatling on macOS
                         target: 1,000 RPS
                               |
                               v
                    +---------------------+
                    |      Server 1       |
                    |      GET /home      |
                    | 1 vCPU / 512 MiB    |
                    +----------+----------+
                               |
                +--------------+---------------+
                |              |               |
                v              v               v
       +----------------+ +----------------+ +----------------+
       |    Server 2    | |    Server 3    | |    Server 4    |
       | CPU-bound work | | DB-backed read | | normal/static  |
       | .5 CPU/256 MiB | | .5 CPU/256 MiB | | .5 CPU/256 MiB |
       +----------------+ +-------+--------+ +----------------+
                                  |
                                  v
                         +------------------+
                         |    PostgreSQL    |
                         | .25 CPU / 1 GiB  |
                         +------------------+
```

All four services use **Java 17 + Spring Boot 4.1.1 + Maven**.

All application services and PostgreSQL run in **separate Docker containers** controlled by Docker Compose. The observability services are separate containers as well. Gatling runs directly on the Mac host so the load generator is easier to observe independently.

## Primary objective

Sustain a steady-state offered load of **1,000 `/home` requests/second** with:

- less than **0.1% failed requests**,
- no OOM/restart,
- no continuously growing queue/backlog,
- no load-generator saturation,
- and the **lowest reproducible end-to-end P99 latency** achievable under the fixed application and database resource limits.

P50 and P95 are also recorded. P99 from Gatling is the primary user-facing latency measure; Prometheus/Grafana metrics and Tempo traces are diagnostic evidence.

## Core rule

Change **one performance variable at a time**.

For every experiment:

```text
clean/reset -> start -> verify health -> warm up -> measure -> capture -> compare -> explain
```

Never claim an optimization worked from a single request, one graph, or one benchmark run.

## Important feasibility rule

1,000 RPS is a target to test, not a guarantee that the fixed resources can sustain it. If Server 2's CPU demand or PostgreSQL's CPU demand makes 1,000 RPS physically impossible, the correct result is to **prove the bottleneck quantitatively**, not to hide it by weakening the workload mid-experiment.

The project includes a calibration phase so the CPU workload and DB query are fixed before optimization begins.

## What is already scaffolded

`infra/docker-compose.yml` provides the container topology and resource limits, but it expects you to create the application projects and Dockerfiles.

The pack also includes configuration for:

- Prometheus
- Grafana data sources
- Grafana Tempo
- OpenTelemetry Collector
- a script to download the OpenTelemetry Java agent
- repeatable benchmark/result-capture shell helpers

No Java service implementation, controller, service class, repository, DTO, or Gatling simulation is provided. Those are intentionally yours to implement.

## Finish condition

When the final optimized benchmark and written conclusion are complete, instruct your local agent to invoke your existing **learning-capture / save-what-I-learned skill**. That skill exists in your local environment and cannot be invoked from this handoff itself.
