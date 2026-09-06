#!/usr/bin/env bash
# Start the full tail-latency lab stack (observability + apps + DB) in one go.
# Usage: ./start-lab.sh  [options]
#   Options:
#     --build   rebuild app images before starting (after code changes)
#     --apps    also start the 4 app servers + postgres (default: infra only)
#
# Prereqs: Rancher Desktop running, docker.sock symlinked per ENV_BASELINE.md.

set -euo pipefail

export DOCKER_HOST="${DOCKER_HOST:-unix:///Users/ajaymaheshwari/.rd/docker.sock}"
export DOCKER_API_VERSION="${DOCKER_API_VERSION:-1.41}"

# Working copy of infra lives in a space-free path (Rancher can't mount paths with spaces)
INFRA_DIR="${TAIL_LATENCY_INFRA:-$HOME/tail-latency-lab}"

if [ ! -f "$INFRA_DIR/docker-compose.yml" ]; then
  echo "ERROR: infra not found at $INFRA_DIR"
  echo "Run: bash tail-latency-lab-handoff/scripts/setup-lab.sh first"
  exit 1
fi

BUILD_FLAG=""
APPS=""
for arg in "$@"; do
  case "$arg" in
    --build) BUILD_FLAG="--build" ;;
    --apps)  APPS="postgres server-1 server-2 server-3 server-4" ;;
  esac
done

cd "$INFRA_DIR"

echo "==> Ensuring OTel agent exists"
AGENT="$INFRA_DIR/otel-agent/opentelemetry-javaagent.jar"
if [ ! -f "$AGENT" ]; then
  echo "Downloading OTel Java agent (record version before formal runs)..."
  curl -fL "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar" -o "$AGENT"
fi
java -jar "$AGENT" 2>&1 | grep -m1 . >/dev/null || true
AGENT_VER="$(java -jar "$AGENT" 2>&1 | head -1 || echo 'unknown')"
echo "    OTel agent version: $AGENT_VER"

echo "==> Starting infra (prometheus grafana tempo otel-collector)"
docker compose up -d prometheus grafana tempo otel-collector

if [ -n "$APPS" ]; then
  echo "==> Starting apps + postgres ($APPS)"
  docker compose up -d $BUILD_FLAG $APPS
fi

echo "==> Waiting for health..."
wait_for() { # $1 = name, $2 = url
  for i in $(seq 1 30); do
    if curl -sf -o /dev/null "$2" 2>/dev/null; then echo "    $1 UP"; return 0; fi
    sleep 5
  done
  echo "    $1 NOT UP (timed out)"; return 1
}

if [ -n "$APPS" ]; then
  wait_for "server-1 (host-run expected; container only if built)" "http://localhost:8080/actuator/health" || true
  wait_for "server-2" "http://localhost:8082/compute" || true
  wait_for "server-3" "http://localhost:8083/actuator/health" || true
  wait_for "server-4" "http://localhost:8084/actuator/health" || true
fi

echo ""
echo "==> Stack ready"
echo "    Grafana   http://localhost:3000   (admin/admin)"
echo "    Prometheus http://localhost:9090"
echo "    server-1  http://localhost:8080/home?itemId=1"
echo "    server-2  http://localhost:8082/compute"
echo "    server-3  http://localhost:8083/data?itemId=1"
echo "    server-4  http://localhost:8084/user-details"
echo ""
echo "==> If server-1 is host-run, start it separately:"
echo "    cd services/server-1 && export SERVER2_BASE_URL=http://localhost:8082 SERVER3_BASE_URL=http://localhost:8083 SERVER4_BASE_URL=http://localhost:8084 && ./mvnw spring-boot:run"
echo ""
echo "==> Remember: server-3 has OOM-killed under 250 RPS (see results/E00B-findings.md)"