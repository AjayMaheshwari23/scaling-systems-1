# Environment Baseline (org-work state) — restore these when lab is done

Captured: 2026-09-05. This laptop runs the org's Java 21 services; the lab pins Java 17.
DO NOT leave lab overrides in place after finishing.

## Java

| Setting | Lab value (while working) | Baseline (org work) |
|---|---|---|
| `JAVA_HOME` | `/Users/ajaymaheshwari/Library/Java/JavaVirtualMachines/temurin-17.0.17/Contents/Home` | `/Users/ajaymaheshwari/Library/Java/JavaVirtualMachines/corretto-21.0.9/Contents/Home` |
| default `java` on PATH | Temurin 17.0.17 | Corretto 25.0.1 (`/Users/ajaymaheshwari/Library/Java/JavaVirtualMachines/corretto-25.0.1/Contents/Home/bin`) |
| org services | n/a | Java 21 (via `JAVA_HOME` = Corretto 21) |

Note: the raw `java` on PATH resolves to Corretto 25. Org projects pick up 21 via `JAVA_HOME`.

## Docker

- Container runtime: **Rancher Desktop** (`/Applications/Rancher Desktop.app`), engine **moby** (Docker)
- Docker client: `/Users/ajaymaheshwari/.rd/bin/docker` (client 29.6.2-rd, server 29.5.3)
- Actual socket: `~/rd/docker.sock` (`/Users/ajaymaheshwari/.rd/docker.sock`)
- Documented host setup (user's own config):
  - `sudo ln -sf ~/.rd/docker.sock /var/run/docker.sock`
  - `export DOCKER_API_VERSION=1.41`
- Rancher Desktop VM settings: memory 5 GB, 2 CPUs, vz type, Rosetta enabled

## Reset checklist (after project ends)

1. Restore JAVA_HOME to Corretto 21 path above.
2. Re-export `DOCKER_API_VERSION=1.41` if unset in new shells.
3. Confirm `/var/run/docker.sock` symlink still points at `~/.rd/docker.sock` (re-run the `sudo ln -sf` if the lab replaced it — we did NOT replace it; we used `DOCKER_HOST` instead).
4. Stop lab-only containers/images/volumes (compose project `tail-latency-lab`).
5. Optional: revert Rancher Desktop VM RAM/CPU if changed for the lab.