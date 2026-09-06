# Gatling Project — You Implement This

Create the official Gatling Java + Maven starter project in this directory.

Do not ask the local agent to generate the complete simulation. Ask it to teach you the Java DSL for the specific piece you are implementing.

## Required simulation capabilities

Your simulation must eventually support:

- base URL `http://localhost:8080`,
- `GET /home?itemId=...`,
- deterministic item IDs from a controlled set (~10,000),
- open arrival-rate injection,
- 100/250/500/750/900/1000+ RPS profiles,
- 60-second warm-up profile,
- 5-minute 1K steady-state profile,
- response status/content validation,
- failed-request assertion <0.1%,
- selectable run/scenario through configuration if practical.

## Learning prompts for your agent

Ask questions such as:

- "Explain Gatling open workload injection and show me only the syntax shape for constant users per second."
- "How do feeders work in the Java DSL? Don't write my full simulation."
- "How can I separate warm-up from the steady-state measurement?"
- "How do Gatling percentile assertions work?"
- "Review this simulation for whether it really produces ~1,000 offered requests/sec."

See `docs/05-load-testing.md`.
