#!/usr/bin/env bash
# One-time setup: prepare the space-free infra working copy + services symlink.
# Run once after clone. Then use ./start-lab.sh for daily startup.
# Usage: bash setup-lab.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INFRA_DIR="${TAIL_LATENCY_INFRA:-$HOME/tail-latency-lab}"

echo "==> Creating working copy at $INFRA_DIR (Rancher can't mount the repo path with spaces)"
mkdir -p "$INFRA_DIR"
cp -R "$REPO_ROOT/tail-latency-lab-handoff/infra/." "$INFRA_DIR/"

echo "==> Symlinking services so compose build.context resolves"
# compose uses context: ../services/server-N ; from ~/tail-latency-lab that resolves to ~/services
if [ ! -e "$HOME/services" ]; then
  ln -s "$REPO_ROOT/services" "$HOME/services"
  echo "    created $HOME/services -> $REPO_ROOT/services"
else
  echo "    $HOME/services already exists (ok if it points at the repo)"
fi

echo "==> Downloading OTel Java agent"
AGENT="$INFRA_DIR/otel-agent/opentelemetry-javaagent.jar"
if [ ! -f "$AGENT" ]; then
  curl -fL "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar" -o "$AGENT"
fi
VER="$(java -jar "$AGENT" 2>&1 | head -1 || echo unknown)"
echo "    OTel agent version: $VER (record before formal runs)"

echo ""
echo "Done. Start the stack with:  bash tail-latency-lab-handoff/scripts/start-lab.sh --apps"