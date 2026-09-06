#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <run-id>" >&2
  exit 1
fi

RUN_ID="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/results/runs/$RUN_ID"
OUT="$OUT_DIR/docker-stats.csv"
mkdir -p "$OUT_DIR"

printf 'timestamp,name,cpu_percent,mem_usage,mem_percent,net_io,block_io,pids\n' > "$OUT"

echo "Sampling Docker stats every 1 second -> $OUT"
echo "Press Ctrl-C after the benchmark measurement is complete."

while true; do
  TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}},{{.PIDs}}' \
    | while IFS= read -r line; do
        printf '%s,%s\n' "$TS" "$line" >> "$OUT"
      done
  sleep 1
done
