# Server 3 — Implementation Area

You write this Spring Boot application yourself.

Do not copy a generated complete service into this folder. Use your local agent for concept explanations, minimal syntax help, code review, and debugging.

Read the Server 3 contract in `../../docs/03-implementation-contracts.md` before creating the project.

Required common stack:

- Java 17
- Spring Boot 4.1.1 (owner override; experiment constant)
- Maven Wrapper
- Spring Web
- Actuator
- Micrometer Prometheus registry
- runnable Docker image on port 8080

The Compose scaffold expects a Dockerfile in this directory after you create it.

Server 3 additionally needs JDBC and the PostgreSQL driver. Do not add the application cache until Experiment E09.
