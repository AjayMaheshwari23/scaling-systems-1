# E00B — Workload Calibration Diagnostic: First Scalability Cliff

Status: **DIAGNOSTIC FINDING** (not a formal experiment — pre-Gatling, used `hey`).
Phase: E00B calibration boundary sweep on Server 1 sequential fan-out.

## Finding summary

Between 100 and 250 offered RPS, the system collapses. Server 3 (PostgreSQL-backed)
is killed by the kernel OOM killer under its 256 MiB container cap, and every
`/home` request that needs the DB read returns HTTP 500.

## Workload/configuration used

- Load tool: `hey` (closed-loop) on host, hitting `http://localhost:8080/home?itemId=42`
- Server 1: **host-run** via `mvnw spring-boot:run` (NOT containerized — 1 CPU/512 MiB limit NOT applied)
- Server 2: container, 0.5 CPU / 256 MiB, work factor 200
- Server 3: container, 0.5 CPU / 256 MiB, Hikari default (10), Postgres via Docker DNS
- Server 4: container, 0.5 CPU / 256 MiB
- PostgreSQL: 0.25 CPU / 1 GiB
- OTel Java agent 2.31.1 attached to all 4 apps
- JVM: `-XX:MaxRAMPercentage=50` (256 MiB services) / `55` (server-1 when containerized)

## Boundary results

| Offered | Successful RPS | Error % | Notes |
|---|---:|---:|---|
| 50 RPS | ~50 | 0% | healthy |
| 100 RPS | ~100 | 0% | healthy |
| 250 RPS | ~31 | ~87.5% | **collapse — server-3 OOM-killed** |

250 RPS detail (`hey -n 15000`): 200 responses 1,870 / 500 responses 13,130.
`hey` reported "Requests/sec: 249.85" but that counts error responses too — NOT successful throughput.
P99=83 ms was contaminated by fast-failing 500s; not a valid latency number.

## Root cause evidence (docker stats, 2s interval, server-3)

```
MEM=252.9MiB / 256MiB
MEM=253.5MiB / 256MiB
MEM=255.3MiB / 256MiB
MEM=255.9MiB / 256MiB   <- hits cap
MEM=0B / 0B             <- kernel OOM SIGKILL
```

- Exit code: 137 (SIGKILL), `OOMKilled=true` — reproduced on 3 separate runs.
- No Java exception logged before death (kernel kills the process silently).
- Prometheus `jvm_memory_used_bytes` showed only ~150 MB (49 heap + 103 non-heap)
  at the same time the container was at ~255 MiB. Gap ≈ native/untracked memory:
  OTel agent, thread stacks, JIT buffers, direct buffers, metaspace, malloc arenas.
  **JVM-attributed metrics under-report the real cgroup memory the kernel counts.**
- Prometheus scrape every 5s also misses the final spike → the last recorded
  data point can sit well below the death value.

## Causal chain

```
250 RPS /home -> S3 memory climbs 253 -> 255.9 MiB in seconds
  -> hits 256 MiB cgroup cap -> kernel OOM SIGKILL (exit 137)
  -> S3 gone -> /home DB reads fail -> 500s flood -> ~87.5% errors
```

## Who generated the 500?

Server 1 returned 500 because its downstream Server 3 was dead. Server 2 (CPU-bound)
and Server 4 (trivial) survived. Not CPU-bound, not Hikari pool exhaustion, not Server 1
thread exhaustion — **Server 3 memory envelope**.

## Actions / next steps

- Do NOT increase 256 MiB container limits yet — that changes the spec. This finding
  is the material for the **E10 (JVM heap/GC)** experiment.
- E10 candidate: lower `MaxRAMPercentage` on server-3 (e.g., 40) to reserve more
  native headroom for OTel agent + JVM overhead, then re-run 250 RPS.
- Narrow the boundary: 125 / 150 / 175 / 200 RPS with docker-stats monitor to find the knee.
- Before formal E01: containerize Server 1 (currently host-run = confound).
- Before formal runs: switch from `hey` (closed-loop) to Gatling (open arrival-rate).

## Anomalies / confounds to record

- Server 4 was OOM-killed once earlier under a heavier `hey -c 500` blast.
- Server 1 host-run has no 1 CPU/512 MiB cap — its own limits not yet measured.
- `hey` is closed-loop; a fixed-concurrency model can mask/alter latency vs open arrival-rate.
- Infra containers (prometheus/grafana/tempo/otel) consume host resources on the same Mac.

## Evidence artifacts

- `/tmp/docker-stats.log` (live 2s container stats during the 250 RPS kill)
- Grafana "Tail Latency Lab — Overview" dashboard (server-2/3/4 heap graphs with ceiling)