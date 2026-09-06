#!/usr/bin/env bash
set -euo pipefail

check() {
  local name="$1"
  local url="$2"
  printf '%-18s ' "$name"
  if curl -fsS --max-time 3 "$url" >/dev/null; then
    echo "OK"
  else
    echo "FAILED ($url)"
    return 1
  fi
}

FAILED=0
check "server-1 health" "http://localhost:8080/actuator/health" || FAILED=1
check "server-2 health" "http://localhost:8082/actuator/health" || FAILED=1
check "server-3 health" "http://localhost:8083/actuator/health" || FAILED=1
check "server-4 health" "http://localhost:8084/actuator/health" || FAILED=1
check "prometheus" "http://localhost:9090/-/healthy" || FAILED=1
check "grafana" "http://localhost:3000/api/health" || FAILED=1
check "tempo" "http://localhost:3200/ready" || FAILED=1

exit "$FAILED"
