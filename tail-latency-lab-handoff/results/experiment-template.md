# Experiment Result — <RUN ID>

## Identity

- Date/time:
- Experiment ID:
- Run number:
- Git commit/state:
- Hypothesis:
- **Single changed variable:**

## Fixed workload/configuration

- Offered RPS:
- Warm-up duration/RPS:
- Measurement duration:
- Item-ID distribution:
- Server 2 work factor:
- Trace sampling ratio:
- S1 CPU/RAM: 1 / 512 MiB
- S2 CPU/RAM: 0.5 / 256 MiB
- S3 CPU/RAM: 0.5 / 256 MiB
- S4 CPU/RAM: 0.5 / 256 MiB
- PostgreSQL CPU/RAM: 0.25 / 1 GiB
- JVM flags:
- HTTP client/pool settings:
- S1 executor settings:
- Hikari settings:
- Cache settings:

## Gatling result

- Offered/attempted rate:
- Successful RPS:
- Total requests:
- Failed requests:
- Error %:
- P50:
- P95:
- P99:
- Max (informational):

## Resource snapshot

| Component | CPU | Memory | Request P99 | Notes |
|---|---:|---:|---:|---|
| Server 1 | | | | |
| Server 2 | | | | |
| Server 3 | | | | |
| Server 4 | | | | |
| PostgreSQL | | | n/a | |

## JVM/queue evidence

- S1 heap/GC:
- S1 threads/Tomcat:
- S1 executor active/queue:
- S2 heap/GC:
- S3 heap/GC:
- S3 Hikari active/idle/pending:
- S4 heap/GC:

## Downstream timing

- S1 -> S2 P95/P99:
- S1 -> S3 P95/P99:
- S1 -> S4 P95/P99:
- S3 -> PostgreSQL span/query timing:

## Trace evidence

Trace ID(s) inspected:

What did a representative slow trace show?

## Comparison to previous accepted configuration

- Previous P99:
- New P99:
- Absolute change:
- Percentage change:
- Throughput changed?
- Errors changed?
- Bottleneck moved?

## Conclusion

Did the hypothesis hold?

Accept/reject the change for the next baseline?

Why, using metrics/traces rather than intuition?

## Anomalies

Record outliers, host activity, container restarts, thermal issues, or anything that may invalidate this run.
