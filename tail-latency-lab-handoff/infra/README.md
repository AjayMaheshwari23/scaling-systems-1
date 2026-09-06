# Infrastructure Scaffold

This directory contains the support stack and fixed container resource limits.

## Before starting app containers

1. Create all four Spring Boot projects yourself.
2. Create a Dockerfile in each `services/server-*` directory.
3. Ensure each app listens on port 8080.
4. Ensure `/actuator/prometheus` is available.
5. Run `../scripts/download-otel-agent.sh`.

## Start

From repository root:

```bash
cp infra/.env.example infra/.env
cd infra
docker compose up -d --build
```

## Important

The observability images default to `latest` in this scaffold for setup convenience. Once your stack works, pin exact versions/digests before final benchmarking and record them. Do not upgrade infrastructure versions in the middle of an experiment series.

Application and DB resource limits are encoded using service-level `cpus` and `mem_limit`, which current Docker Compose supports.

The Postgres credentials are intentionally simple because this is a local-only lab. They are not production security guidance.
