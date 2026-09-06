# 12 — PromQL / Dashboard Starter Cheatsheet

Metric names can vary with library/client choices. Use Prometheus's metric browser to verify the actual names in your build rather than assuming every example exists.

## Server 1 request rate

Typical Spring MVC timer series:

```promql
sum(rate(http_server_requests_seconds_count{job="server-1",uri="/home"}[1m]))
```

## Server 1 error rate

```promql
sum(rate(http_server_requests_seconds_count{job="server-1",uri="/home",status=~"5.."}[1m]))
/
sum(rate(http_server_requests_seconds_count{job="server-1",uri="/home"}[1m]))
```

Adjust the definition if expected 4xx statuses are relevant.

## Server 1 P99 from histogram

Requires histogram buckets to be enabled for the meter:

```promql
histogram_quantile(
  0.99,
  sum by (le) (
    rate(http_server_requests_seconds_bucket{job="server-1",uri="/home"}[1m])
  )
)
```

Multiply by 1000 in Grafana if you want milliseconds.

## P95

Use the same expression with `0.95`.

## JVM heap used

```promql
sum(jvm_memory_used_bytes{job="server-1",area="heap"})
```

## JVM live threads

```promql
jvm_threads_live_threads{job="server-1"}
```

## Process CPU

```promql
process_cpu_usage{job="server-1"}
```

Treat this as process/JVM evidence; use Docker stats as the quota/container view.

## GC pause rate/duration

Explore metrics beginning with:

```text
jvm_gc_pause_seconds_...
```

Useful panels include pause count rate and total pause seconds rate. For percentile-style views, enable/use histogram buckets if the exported metric supports them in your configuration.

## Tomcat threads

Look for metrics beginning with:

```text
tomcat_threads_...
```

Common useful concepts are current, busy, and configured maximum threads. Verify labels/names in your app.

## Hikari pool

Common Prometheus names include:

```text
hikaricp_connections_active
hikaricp_connections_idle
hikaricp_connections_pending
hikaricp_connections_max
hikaricp_connections_min
```

Filter to `job="server-3"` and pool label if present.

## HTTP client/downstream timers

Depending on the Spring HTTP client and observation instrumentation, look for a timer equivalent to:

```text
http_client_requests_seconds_...
```

Inspect labels for target/service URI templates. Avoid high-cardinality raw URLs.

You want separate panels for S1 -> S2, S1 -> S3, and S1 -> S4.

## Important dashboard warning

Do not calculate a meaningful P99 by averaging P99 values across instances/windows. Percentiles generally must be calculated from the underlying histogram distribution with correct aggregation.
