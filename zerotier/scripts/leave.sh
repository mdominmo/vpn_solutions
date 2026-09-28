#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/node/.env"

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "ERROR: neither 'docker compose' nor 'docker-compose' was found." >&2
  exit 1
fi

read -r -p "Type LEAVE to remove this machine from the VPN: " CONFIRM_LEAVE
if [[ "${CONFIRM_LEAVE}" != "LEAVE" ]]; then
  echo "Cancelled."
  exit 0
fi

ZT_NETWORK_ID="$(grep -E '^ZT_NETWORK_ID=' "${ENV_FILE}" 2>/dev/null | cut -d= -f2 || true)"
if [[ -n "${ZT_NETWORK_ID}" ]]; then
  "${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" exec zerotier zerotier-cli leave "${ZT_NETWORK_ID}" || true
  # Otherwise the container would rejoin the network on its next start.
  sed -i 's/^ZT_NETWORK_ID=.*/ZT_NETWORK_ID=/' "${ENV_FILE}"
fi
"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" down

echo "Machine removed from the VPN. Your admin can also delete it from the members list on the website."
