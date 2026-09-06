# 10 — Java/Spring Syntax Learning Map

This is a map of APIs/concepts you are expected to learn while writing the code. It intentionally does not contain the finished implementations.

## Create a REST endpoint

Learn:

- `@RestController`
- `@GetMapping`
- `@RequestParam`
- constructor injection
- Java `record` for small immutable response DTOs

Agent prompt:

> Explain how `@RestController`, `@GetMapping`, and `@RequestParam` work in Spring Boot. Show only one tiny syntax example, not my project endpoint.

## Configuration from environment

Learn:

- `application.yml` / `application.properties`
- Spring relaxed binding from environment variables
- `@ConfigurationProperties` versus `@Value`

Prefer configuration objects when several related settings exist.

Agent prompt:

> I need three downstream base URLs from environment variables. Explain the clean Spring Boot configuration options without writing Server 1 for me.

## Reusable HTTP client

Learn:

- a Spring-supported synchronous HTTP client suitable for Java 17/Spring Boot 3.5
- constructing it once through Spring configuration/injection
- request URI + query parameters
- response DTO mapping
- timeout configuration
- connection reuse

Rule: never create a new HTTP client per `/home` request.

Agent prompt:

> Compare RestClient, RestTemplate, and WebClient for this lab. I want the simplest blocking baseline first. Tell me which one you recommend and teach me only the relevant syntax pieces.

## Sequential fan-out

Learn normal method calls and handling three HTTP responses one after another.

Before coding, predict low-load latency as a sum-like value and verify that prediction with traces.

## Parallel fan-out

Learn:

- `ExecutorService`
- fixed/bounded thread pools
- `CompletableFuture.supplyAsync`
- `CompletableFuture.allOf`
- retrieving results
- exception handling
- executor shutdown lifecycle

Do not use an unbounded executor. Do not blindly rely on the common fork-join pool.

Agent prompt:

> Teach me `CompletableFuture` fan-out/fan-in using generic functions A/B/C. Do not use my server classes or write my implementation.

## CPU workload

Learn:

- primitive arithmetic/bit operations
- loops
- configuration-driven work factor
- returning a checksum/result
- avoiding `Thread.sleep` for a CPU-bound workload

Agent prompt:

> Help me design a deterministic low-allocation CPU workload whose work factor is tunable. Explain how to prevent the computation from being meaningless, but let me write it.

## JDBC

Learn one of Spring's lightweight JDBC APIs:

- `JdbcClient` or `JdbcTemplate`
- parameterized query
- row mapping
- DataSource managed by Spring Boot
- HikariCP as the connection pool

Agent prompt:

> Explain a parameterized single-row lookup using Spring's lightweight JDBC APIs. Show generic syntax with a fictional table, not my final repository.

## Schema/index

Learn:

- primary key
- `CREATE TABLE`
- deterministic seed data
- `EXPLAIN` / `EXPLAIN ANALYZE`
- why selecting only required columns matters

You write the lab schema/seed SQL yourself.

## Actuator and Prometheus

Learn Maven dependency categories and properties for:

- Spring Boot Actuator
- Micrometer Prometheus registry
- exposing `/actuator/health`
- exposing `/actuator/prometheus`
- enabling HTTP latency histograms

Agent prompt:

> Explain what dependencies/properties are required for Prometheus metrics in Spring Boot 3.5, but let me edit my pom and application config.

## Custom executor metrics

Once the parallel executor exists, learn how to expose:

- active thread count
- pool size
- queue depth

Micrometer can bind executor metrics; ask the agent to explain the appropriate binder for the executor type you selected.

## Cache

Only in E09, learn:

- bounded Caffeine cache
- max size
- expiration
- hit/miss metrics
- cache-aside read flow

Do not add it earlier.

## JVM flags

Learn what these mean before changing them:

- `-XX:MaxRAMPercentage`
- `-Xmx`
- `-XX:+UseG1GC`
- `-XX:+UseSerialGC`
- Java unified GC logging (`-Xlog:...`)

Never cargo-cult JVM flags from internet tuning guides.

## Dockerfile

Learn:

- `FROM`
- `WORKDIR`
- `COPY`
- `EXPOSE`
- `ENTRYPOINT` or `CMD`
- difference between build image and runtime image
- why ARM64-compatible base images matter on M4

Start with a simple runtime Dockerfile. A multi-stage build can be a later Docker exercise.

## Maven Wrapper

Learn:

- `./mvnw clean test`
- `./mvnw package`
- dependency scopes
- how Spring Boot's Maven plugin creates a runnable JAR

## Gatling Java DSL

Learn:

- `Simulation`
- HTTP protocol configuration
- `scenario`
- `exec`
- checks/assertions
- feeders
- open workload injection (`rampUsersPerSec`, `constantUsersPerSec` concepts)

Write the complete simulation yourself.
