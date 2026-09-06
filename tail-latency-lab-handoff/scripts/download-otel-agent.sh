#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT_DIR/infra/otel-agent/opentelemetry-javaagent.jar"
URL="https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar"

mkdir -p "$(dirname "$DEST")"
echo "Downloading OpenTelemetry Java agent..."
curl -fL "$URL" -o "$DEST"
echo "Saved: $DEST"
ls -lh "$DEST"

echo
echo "For benchmark reproducibility, record the agent version before your first formal run."
