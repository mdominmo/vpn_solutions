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

read -r -p "Type LEAVE to remove this machine from the VPN: " CONFIRM_LEAVE
if [[ "${CONFIRM_LEAVE}" != "LEAVE" ]]; then
  echo "Cancelled."
  exit 0
fi

# Logging out invalidates the session in Tailscale; stopping the container alone would not.
"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" exec tailscale tailscale logout || true
"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" down

echo "Machine removed from the VPN. Check in the admin console (Machines) that it is gone."
