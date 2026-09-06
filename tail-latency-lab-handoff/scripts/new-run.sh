#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <run-id>" >&2
  exit 1
fi

RUN_ID="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/results/runs/$RUN_ID"
mkdir -p "$OUT_DIR"

if [[ ! -f "$OUT_DIR/result.md" ]]; then
  cp "$ROOT_DIR/results/experiment-template.md" "$OUT_DIR/result.md"
  perl -0pi -e "s/<RUN ID>/$RUN_ID/g" "$OUT_DIR/result.md" 2>/dev/null || true
fi

{
  echo "run_id=$RUN_ID"
  echo "captured_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "== java =="
  java -version 2>&1 || true
  echo
  echo "== docker =="
  docker version 2>&1 || true
  echo
  echo "== docker compose =="
  docker compose version 2>&1 || true
  echo
  echo "== git =="
  git -C "$ROOT_DIR" rev-parse HEAD 2>&1 || true
  git -C "$ROOT_DIR" status --short 2>&1 || true
  echo
  echo "== compose ps =="
  docker compose -f "$ROOT_DIR/infra/docker-compose.yml" ps 2>&1 || true
  echo
  echo "== compose images =="
  docker compose -f "$ROOT_DIR/infra/docker-compose.yml" images 2>&1 || true
} > "$OUT_DIR/environment.txt"

echo "Created run directory: $OUT_DIR"
echo "Fill in: $OUT_DIR/result.md"
echo "Environment snapshot: $OUT_DIR/environment.txt"
