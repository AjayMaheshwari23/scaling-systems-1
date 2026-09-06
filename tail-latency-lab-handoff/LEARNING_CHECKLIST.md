# Learning Checklist

Do not treat the project as finished until you can explain these without reading the implementation.

## Distributed request behavior

- [ ] Why 1K external RPS produces ~3K downstream HTTP calls/sec plus DB work.
- [ ] Sequential latency versus parallel fan-out latency.
- [ ] Why parallel fan-out P99 is not simply the maximum of downstream P99 numbers.
- [ ] Tail amplification across required dependencies.
- [ ] Why the slowest dependency tends to dominate a parallel aggregate request.

## Capacity and queueing

- [ ] CPU service demand and the 0.5-ms/request theoretical CPU budget of S2 at 1K RPS/0.5 CPU.
- [ ] The 0.25-ms/query theoretical DB CPU budget at 1K QPS/0.25 CPU.
- [ ] Difference between throughput, concurrency, and arrival rate.
- [ ] Little's Law and how latency changes in-flight concurrency.
- [ ] The saturation knee.
- [ ] Why increasing concurrency after saturation usually increases queueing/P99.

## Java/JVM

- [ ] Heap versus total process/container memory.
- [ ] Metaspace, thread stacks, direct/native memory.
- [ ] What GC pause metrics mean.
- [ ] How allocation pressure affects GC/P99.
- [ ] Why a small heap can GC frequently and an oversized heap can violate native headroom.
- [ ] Why collector choice must be benchmarked under the actual small-memory workload.

## Threads and HTTP

- [ ] Servlet request threads.
- [ ] Blocking I/O versus CPU time.
- [ ] `CompletableFuture` and executor ownership.
- [ ] Why an unbounded executor/queue is dangerous.
- [ ] HTTP keep-alive and connection reuse.
- [ ] Connection pool sizing versus downstream capacity.
- [ ] Timeout purpose.
- [ ] Why retries can amplify overload.

## Database

- [ ] Hikari active/idle/pending connections.
- [ ] Connection pool queueing versus DB queueing.
- [ ] Why a larger connection pool can make a CPU-bound DB worse.
- [ ] Indexed parameterized lookup.
- [ ] Cache hit ratio and its effect on DB QPS.
- [ ] Cache memory/GC trade-off.

## Observability

- [ ] Metric versus trace.
- [ ] Counter, gauge, timer/histogram.
- [ ] Prometheus scrape model.
- [ ] `histogram_quantile` approximation.
- [ ] Why trace examples do not replace population statistics.
- [ ] Trace context propagation.
- [ ] Why high-cardinality metric labels are dangerous.
- [ ] Why tracing changes the performance being measured.

## Load testing

- [ ] Open versus closed workload model.
- [ ] Offered RPS versus successful RPS.
- [ ] Coordinated-omission intuition.
- [ ] Warm-up/JIT effects.
- [ ] Why multiple benchmark repetitions matter.
- [ ] Why P99 with dropped requests is not an optimization.

## Docker

- [ ] Image versus container.
- [ ] Dockerfile versus Compose.
- [ ] Docker service DNS names.
- [ ] CPU quota and memory limit.
- [ ] Why host CPU can be low while a 0.5-vCPU container is saturated.
- [ ] Apple Silicon image/platform considerations.

## Final systems reasoning

- [ ] Identify the bottleneck from evidence.
- [ ] Predict how an optimization moves the bottleneck.
- [ ] Explain at least one optimization that made performance worse.
- [ ] Explain at least one optimization that produced no meaningful improvement.
- [ ] Explain what you would horizontally scale next and why.
