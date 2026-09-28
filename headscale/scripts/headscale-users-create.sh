#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <username>" >&2
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
    echo "Neither 'docker compose' nor 'docker-compose' was found." >&2
    exit 1
  fi

  "${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/control-plane/docker-compose.yml" exec headscale headscale users create "$1"
}

if [[ -n "${HEADSCALE_SSH_TARGET:-}" ]]; then
  run_remote "$1"
else
  run_local "$1"
fi
