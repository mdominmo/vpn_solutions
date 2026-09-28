#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "ERROR: neither 'docker compose' nor 'docker-compose' was found." >&2
  exit 1
fi

echo "== Node status (ZeroTier) =="
"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" ps
echo
"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" exec zerotier zerotier-cli info || true
echo
"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" exec zerotier zerotier-cli listnetworks || true
echo
"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" exec zerotier zerotier-cli peers || true
