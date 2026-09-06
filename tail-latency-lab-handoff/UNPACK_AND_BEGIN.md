# Unpack and Begin

Put this project wherever you keep local projects. For example:

```bash
cd ~/projects
unzip tail-latency-lab-handoff.zip
cd tail-latency-lab-handoff
```

Then tell your local coding agent:

> Read `AGENT_HANDOFF.md` and `PROJECT_SPEC.md` first. Follow the handoff strictly. I will write the Java application and Gatling code myself; teach me syntax/concepts and review my work instead of implementing the project for me. Start with Checkpoint 1 in `docs/11-agent-session-checkpoints.md`.

Your first human tasks are:

1. Verify Java 17 and Docker Desktop.
2. Create the four Spring Boot 4.1.1 Maven projects.
3. Implement Server 4 first as the simplest endpoint.
4. Continue through the checkpoints.

Do not start optimization experiments until E00 correctness, instrumentation, and E00B workload calibration are complete.
