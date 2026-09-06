# Java Tail-Latency Lab — Motivation, Objective & Current State

Status: **live working document** — updated at each checkpoint.
Last updated: 2026-09-06 (pre-laptop-restart).

## 1. Why this project exists (motivation)

Performance engineering in production is usually reactive: something is slow, someone
fires a profiler, a band-aid is applied, and the "why" is never really learned. This lab
inverts that. It is a **hands-on, single-machine laboratory** built to *see* how a
distributed request behaves under load when every component has a different bottleneck,
a different resource limit, and a different failure mode — and to understand tail
latency from first principles rather than folklore.

The learner (Ajay) writes every line of application code. The agent teaches concepts,
reviews reasoning before syntax, and verifies evidence. The point is not "make it fast"
— it is **"be able to explain why it is slow, in terms of service demand, utilization,
queueing, concurrency, resource limits, GC, connection pools, and fan-out tail
amplification."** (`docs/09-final-analysis.md` is the eventual written proof.)

Deliberate constraints force this learning:
- fixed resource limits (small on purpose — 256 MiB services are genuinely tight),
- one experiment variable at a time (causal attribution, not vibes),
- mandatory metrics + traces (observe, don't guess),
- open arrival-rate load model (realistic, exposes coordinated-omission traps).

## 2. What we are building (objective)

A 1K-RPS fan-out service, on a Mac M4, with one instance each of four Spring Boot apps
and PostgreSQL, all under fixed Docker resource limits, fully instrumented with
Prometheus/Grafana/Tempo, load-tested with Gatling.

```
Gatling ──> Server 1 /home (aggregator, 1.0 CPU / 512 MiB)
              ├──> Server 2 /compute  (CPU-bound,     0.5 CPU / 256 MiB)
              ├──> Server 3 /data     (PostgreSQL,    0.5 CPU / 256 MiB)
              └──> Server 4 /user-details (control,   0.5 CPU / 256 MiB)
                     └──> PostgreSQL (0.25 CPU / 1 GiB)
```

At 1,000 homepage RPS the uncached system drives ~1,000 RPS into each service and
~1,000 DB ops/sec — **fan-out multiplies internal work**. That multiplication is the
first scaling lesson and the mechanical heart of the whole lab.

### Success criteria at 1,000 RPS (from PROJECT_SPEC.md)

All true during the measurement window: 1,000 offered RPS · Gatling not CPU-starved ·
failures < 0.1% · no container restarts/OOMs · no unbounded queue growth · throughput
plateaus at offered load · P99 reported from steady state. Primary score: **end-to-end
Gatling P99 for `/home`**.

### The planned experiment sequence (docs/06)

E00 correctness/instrumentation → E00B calibration → E01 sequential baseline → E02
parallel fan-out → E03 HTTP client reuse → E04 Server 1 concurrency → E05 timeouts →
E06 Server 2 CPU → E07 Hikari pool sweep → E08 query/index → E09 Server 3 cache →
E10 JVM heap/GC → E11 servlet tuning → E12 payload/serialization → E13 observability
overhead → E14 saturation search → E15 final 1,000 RPS result.

## 3. What exists right now (current state)

### Environment
- Rancher Desktop (moby/Docker) running; daemon on `~/.rd/docker.sock`
- Java 17 (Temurin 17.0.17) for the lab; org work uses Java 21 — see `ENV_BASELINE.md`
- Infra working copy lives at `~/tail-latency-lab` (space-free path; Rancher can't
  bind-mount the repo path under `Desktop/AJAY/AI/...`). `~/services` symlinks to the repo.

### Checkpoints
| Checkpoint | Status |
|---|---|
| 1 — Bootstrap (4 Spring Boot 4.1.1 / Java 17 Maven projects) | ✅ |
| 2 — Server 4 `/user-details` + metrics | ✅ |
| 3 — Server 2 `/compute` deterministic CPU work (factor 200) | ✅ |
| 4 — PostgreSQL + Server 3 `/data` JDBC read (JdbcClient) | ✅ |
| 6 — Docker pilot (server-2/3/4 containerized, limits verified) | ✅ (server-1 still host-run) |
| 5 — Server 1 `/home` sequential fan-out | ✅ code; diagnostics run |
| 7 — Metrics/traces verification | 🔶 metrics live (Prometheus/Grafana); traces (Tempo) not yet verified |
| E00B — Workload calibration | 🔶 **first scalability cliff found** |

### Key versions (frozen for the experiment series)
- Spring Boot **4.1.1** (owner override from 3.5.16 — mentor-confirmed; experiment constant)
- Java 17, Maven Wrapper, Tomcat 11.0.24
- OTel Java agent **2.31.1** (MD5 94263fea1e6884d9a989259b97f573d0)
- Postgres 17-alpine, prom/prometheus:latest, grafana/grafana:latest (pin before formal runs)

### Instrumentation baseline (all services)
```properties
management.endpoints.web.exposure.include=health,prometheus,metrics
server.tomcat.mbeanregistry.enabled=true
management.metrics.distribution.percentiles-histogram.http.server.requests=true
management.metrics.distribution.percentiles.http.server.requests=0.50,0.95,0.99
```

### Dashboards (Grafana :3000, admin/admin)
- **Tail Latency Lab — Overview**: RPS, P50/95/99, errors, Tomcat threads, per-server
  heap used + ceiling graphs, GC, CPU, top stat boxes for `/home` endpoints
- **Tail Latency Lab — Prometheus Scrapes**: observability-overhead view (E13 precursor)

## 4. First scalability cliff (E00B diagnostic — the headline finding)

Boundary sweep with `hey` against sequential `/home`:

| Offered | Successful RPS | Error % |
|---|---:|---:|
| 50 RPS | ~50 | 0% |
| 100 RPS | ~100 | 0% |
| 250 RPS | ~31 | ~87.5% |

**Root cause (evidenced, reproduced 3×):** Server 3 is killed by the kernel OOM killer
under its 256 MiB cap. `docker stats` at 2s interval:

```
MEM=252.9MiB / 256MiB
MEM=253.5MiB / 256MiB
MEM=255.3MiB / 256MiB
MEM=255.9MiB / 256MiB   <- hits cap
MEM=0B / 0B             <- kernel OOM SIGKILL (exit 137)
```

Every `/home` needing the DB read then returns 500 → error flood. Crucially, Prometheus
JVM metrics showed only ~150 MB (49 heap + 103 non-heap) while the container was at
~255 MiB: **JVM-attributed metrics under-report the cgroup memory the kernel counts**
(native OTel agent + JVM overhead are invisible to `jvm_memory_used_bytes`).

Full detail + artifacts: `results/E00B-findings.md` and
`results/docker-stats-E00B-250rps.log`.

## 5. Where we go next

1. Restart stack: `bash tail-latency-lab-handoff/scripts/start-lab.sh --apps`
2. **E10 (JVM heap/GC) first** — the cliff points at Server 3's memory envelope:
   try `MaxRAMPercentage=40` on server-3 (reserve native headroom), re-run 250 RPS.
3. Narrow boundary (125/150/175/200 RPS) with the docker-stats monitor to find the knee.
4. Containerize Server 1 (currently host-run = confound for formal runs).
5. Switch from `hey` (closed-loop) to **Gatling** (open arrival-rate) per protocol.
6. Formal E01 sequential baseline → onward through E02…E15.
7. Write `docs/09-final-analysis.md` at the end; capture learnings.

## 6. Guardrails that keep this a learning project (not a chase)

- One optimization variable at a time; record every change (`results/` sheets).
- Do not raise the fixed 256 MiB limits as a first fix — that changes the spec. The
  failure IS the data point.
- Server 2 work factor frozen after calibration; never lower it to fake a win.
- Lower P99 with more failures is not a win; fast 500s are not good latency.
- Instrumentation (5% trace sampling, metrics on) is part of the standard config;
  observability overhead is itself measured (E13).
- Every accepted improvement needs ≥3 comparable runs.

## 7. Restarting after a laptop reboot (quick start)

```bash
# 0. Docker: open Rancher Desktop, wait for ~/.rd/docker.sock
# 1. One-time (only if ~/tail-latency-lab missing):
bash tail-latency-lab-handoff/scripts/setup-lab.sh
# 2. Daily:
bash tail-latency-lab-handoff/scripts/start-lab.sh --apps
# 3. Server 1 is host-run (see script output for the env-var command) OR containerize it.
# 4. Grafana :3000 admin/admin · Prometheus :9090 · server-2 :8082 · server-3 :8083 · server-4 :8084
```

After finishing the lab, restore the org-work environment per `ENV_BASELINE.md`
(Java 21 Corretto, docker socket symlink, stop lab containers).