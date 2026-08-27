#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <username>" >&2
  exit 1
fi

run_remote() {
  local remote_cmd=""
  local arg=""

  for arg in docker exec headscale headscale users create "$1"; do
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

  "${COMPOSE_CMD[@]}" -f control-plane/docker-compose.yml exec headscale headscale users create "$1"
}

if [[ -n "${HEADSCALE_SSH_TARGET:-}" ]]; then
  run_remote "$1"
else
  run_local "$1"
fi
