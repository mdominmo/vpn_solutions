#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Uso: $0 <user_id> [expiration]" >&2
  echo "Ejemplo: $0 1 720h" >&2
  exit 1
fi

USER_ID="$1"
EXPIRATION="${2:-720h}"

run_remote() {
  local remote_cmd=""
  local arg=""

  for arg in docker exec headscale headscale preauthkeys create --user "${USER_ID}" --reusable --expiration "${EXPIRATION}"; do
    remote_cmd+=$(printf '%q ' "${arg}")
  done

  ssh "${HEADSCALE_SSH_TARGET}" "${remote_cmd% }"
}

run_local() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
  else
    echo "No se ha encontrado ni 'docker compose' ni 'docker-compose'." >&2
    exit 1
  fi

  "${COMPOSE_CMD[@]}" -f control-plane/docker-compose.yml exec headscale \
    headscale preauthkeys create --user "${USER_ID}" --reusable --expiration "${EXPIRATION}"
}

if [[ -n "${HEADSCALE_SSH_TARGET:-}" ]]; then
  run_remote
else
  run_local
fi
