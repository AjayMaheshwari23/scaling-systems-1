# Source Notes

These were the current official references checked when this handoff was created on **2026-09-05**. Tool versions change; re-check before a future rerun, and freeze versions during an experiment series.

## Spring Boot

- Spring Boot project/current stable versions: https://spring.io/projects/spring-boot/
- Spring Boot 3.5 system requirements: https://docs.spring.io/spring-boot/3.5/system-requirements.html
- Spring Boot metrics/Actuator: https://docs.spring.io/spring-boot/reference/actuator/metrics.html
- Prometheus Actuator endpoint: https://docs.spring.io/spring-boot/api/rest/actuator/prometheus.html

At handoff creation, official docs listed Spring Boot 4.1.1 and 3.5.16 as stable. The handoff originally pinned 3.5.16; the project owner later overrode this to Spring Boot 4.1.1, which is now the experiment constant. Java 17 is preserved.

## Gatling

- Local installation / Java+Maven recommendation: https://docs.gatling.io/reference/deploy/install-local/
- Java/JDK installation guide: https://docs.gatling.io/tutorials/test-as-code/java-jvm/installation-guide/
- Maven plugin: https://docs.gatling.io/integrations/build-tools/maven-plugin/

## OpenTelemetry Java

- Java zero-code instrumentation: https://opentelemetry.io/docs/zero-code/java/
- Java agent getting started: https://opentelemetry.io/docs/zero-code/java/agent/getting-started/
- Spring Boot instrumentation options: https://opentelemetry.io/docs/zero-code/java/spring-boot-starter/
- Java SDK/configuration: https://opentelemetry.io/docs/languages/java/configuration/

The OpenTelemetry docs recommend the Java agent as the default Spring Boot zero-code option because it provides broad out-of-the-box instrumentation.

## Prometheus

- Getting started: https://prometheus.io/docs/introduction/first_steps/
- Configuration: https://prometheus.io/docs/prometheus/latest/configuration/configuration/

## Grafana Tempo

- Local deployment: https://grafana.com/docs/tempo/latest/set-up-for-tracing/setup-tempo/deploy/locally/
- Monolithic Linux/local configuration: https://grafana.com/docs/tempo/latest/set-up-for-tracing/setup-tempo/deploy/locally/linux/
- OpenTelemetry Collector -> Tempo: https://grafana.com/docs/tempo/latest/set-up-for-tracing/instrument-send/set-up-collector/otel-collector/

The included Tempo configuration uses a local single-node/monolithic development setup, not production architecture.

## Docker Compose

- Compose services, including `cpus` and `mem_limit`: https://docs.docker.com/reference/compose-file/services/
- Compose deploy resource specification: https://docs.docker.com/reference/compose-file/deploy/
- Compose build/platform behavior: https://docs.docker.com/reference/compose-file/build/

## cAdvisor/macOS caveat

cAdvisor can be useful for container metrics on Linux, but Docker Desktop/macOS compatibility/visibility has historically been uneven. One relevant upstream issue is:

- https://github.com/google/cadvisor/issues/2838

For this project, Docker Desktop plus `docker stats` is the mandatory resource-observation path; cAdvisor is optional.
