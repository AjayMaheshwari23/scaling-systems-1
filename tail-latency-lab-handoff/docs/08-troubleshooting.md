# 08 — Troubleshooting Guide

Use this guide as a reasoning tree. Do not change several parameters at once just to make an error disappear.

## App container exits immediately

Check:

```bash
cd infra
docker compose ps
docker compose logs server-1 --tail=200
```

Common causes:

- Dockerfile/JAR path wrong,
- Java process exceeds 256/512 MiB container memory,
- OpenTelemetry agent mount missing,
- bad environment variable,
- port/config mismatch.

If the container is OOM-killed, record that before increasing/change heap settings.

## OpenTelemetry agent missing

Run:

```bash
./scripts/download-otel-agent.sh
ls -lh infra/otel-agent/opentelemetry-javaagent.jar
```

Compose expects the file to exist.

## Prometheus target is DOWN

Check:

- service is reachable inside Compose network,
- `/actuator/prometheus` is exposed,
- Prometheus target name/port is correct,
- app health endpoint works,
- no actuator security config blocks it.

From the Prometheus container/network, DNS names are `server-1`, `server-2`, etc., not `localhost`.

## Grafana shows no metrics

First check Prometheus directly. If Prometheus has no samples, Grafana is not the root problem.

Then check Grafana data source configuration and time range.

## No traces in Tempo

Check in order:

1. Java agent actually attached.
2. `OTEL_SERVICE_NAME` is set.
3. app exports to `otel-collector:4317`.
4. Collector logs show incoming/export activity/errors.
5. Collector exporter points to `tempo:4317`.
6. Tempo OTLP receiver binds to `0.0.0.0`, not localhost only.
7. Grafana Tempo data source points to `http://tempo:3200`.

## Traces show only Server 1, not downstreams

Possible causes:

- HTTP client library not automatically instrumented,
- propagation headers not preserved,
- unsupported/custom HTTP client,
- creating work across threads without context propagation support.

Before manually adding spans, confirm the selected HTTP library is supported by the Java agent.

## JDBC query is not visible

Check:

- actual JDBC driver path is used,
- OpenTelemetry agent is attached to Server 3,
- query really executes,
- sampling retained that trace.

Use a 100% sampled low-RPS debug run before changing instrumentation code.

## Server 2 hits 100% of its quota and P99 explodes

This may be the correct result.

Use CPU service-demand math. If work requires more CPU than 0.5 vCPU can provide at 1K RPS, no thread setting fixes it.

Prove:

- throughput plateaus,
- CPU stays quota-bound,
- queueing/latency rises,
- errors eventually rise.

Do not lower the fixed work factor in the same experiment series.

## PostgreSQL CPU hits limit

Inspect:

- DB span duration,
- Hikari pending connections,
- pool size,
- query plan/index,
- cache hit experiment later.

A larger Hikari pool can increase pressure on a CPU-limited DB. Try a controlled pool sweep, not arbitrary enlargement.

## Hikari pending > 0 but DB CPU is not high

Possibilities:

- pool too small,
- connections held longer than expected,
- connection leak,
- transaction scope unnecessarily large,
- DB latency from another cause.

Inspect traces and code ownership of connections.

## Heap looks fine but container OOMs

Remember non-heap/native memory:

- metaspace,
- direct buffers,
- thread stacks,
- code cache,
- agents/native libraries.

Reduce thread count or heap envelope as evidence dictates. Do not equate Xmx with process RSS.

## GC pauses spike

Check:

- heap occupancy,
- allocation rate,
- request rate,
- object churn in recent code,
- collector and heap configuration.

A cache can reduce DB work but increase heap pressure. Optimization trade-offs should be visible here.

## Parallel version is slower than sequential

Possible reasons:

- executor too small, causing queue wait,
- executor too large, causing scheduling/CPU contention,
- downstream is already saturated,
- HTTP connection pool cannot support concurrency,
- extra allocations/context switches dominate because downstreams are extremely fast,
- accidental blocking/deadlock,
- common pool contention,
- measurement noise.

Use traces: do the three calls actually overlap?

## P99 is good but throughput is below 1K

Not a valid success.

Check:

- Gatling offered rate,
- failed requests,
- injection lag/load-generator health,
- server queue/rejection behavior.

## P99 differs between Gatling and Grafana

Expected within reason. They use different measurement points and percentile implementations.

Check:

- exact time window,
- warm-up inclusion,
- histogram bucket resolution,
- whether the Grafana panel aggregates across services/statuses incorrectly.

Use Gatling for the official external number.

## Docker stats collection is awkward on macOS

Use the provided sampler plus Docker Desktop UI. Do not block the project on cAdvisor.

## Benchmark results vary a lot run-to-run

Improve experimental control:

- longer warm-up,
- longer measurement,
- close background tasks,
- keep host powered,
- run repetitions,
- record host activity,
- confirm containers are not restarting,
- confirm trace sampling/version did not change.
