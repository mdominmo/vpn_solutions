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

echo "== Preflight host node =="

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: this setup is meant for Linux." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not available." >&2
  exit 1
fi

if [[ ! -c /dev/net/tun ]]; then
  echo "ERROR: /dev/net/tun does not exist or is not a valid device." >&2
  exit 1
fi

echo "OK: Linux detected"
echo "OK: Docker available"
echo "OK: /dev/net/tun available"

"${COMPOSE_CMD[@]}" -f "${ROOT_DIR}/node/docker-compose.yml" config >/dev/null
echo "OK: node docker-compose is valid"

if command -v ss >/dev/null 2>&1; then
  if ss -ltn '( sport = :22 )' | tail -n +2 | grep -q .; then
    echo "OK: a service is listening on TCP/22 on the host"
  else
    echo "WARN: nothing is listening on TCP/22"
    echo "WARN: to SSH into this host you need an sshd running on it"
  fi
else
  echo "WARN: cannot check port 22 because 'ss' is not available"
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
    echo "OK: servicio ssh/sshd activo"
  else
    echo "WARN: no active ssh/sshd service found via systemd"
  fi
fi

echo "Preflight completed"
