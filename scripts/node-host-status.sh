#!/usr/bin/env bash

set -euo pipefail

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "ERROR: no se ha encontrado ni 'docker compose' ni 'docker-compose'." >&2
  exit 1
fi

echo "== Estado del nodo host =="
"${COMPOSE_CMD[@]}" -f node/docker-compose.yml ps
echo
"${COMPOSE_CMD[@]}" -f node/docker-compose.yml exec tailscale tailscale status || true
echo
"${COMPOSE_CMD[@]}" -f node/docker-compose.yml exec tailscale tailscale ip || true
echo
"${COMPOSE_CMD[@]}" -f node/docker-compose.yml exec tailscale tailscale netcheck || true
