#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/node/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/node/.env"
CONTAINER_NAME="tailscale-saas-node"

if [[ $# -gt 1 ]]; then
  echo "Usage: TS_OAUTH_SECRET=tskey-client-... $0 [hostname]" >&2
  exit 1
fi

TS_HOSTNAME="${1:-$(hostname -s)}"
TS_TAGS="${TS_TAGS:-tag:server}"
TS_PREAUTHORIZED="${TS_PREAUTHORIZED:-true}"
TAILSCALE_IMAGE="${TAILSCALE_IMAGE:-tailscale/tailscale:v1.98.8}"

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "ERROR: neither 'docker compose' nor 'docker-compose' was found." >&2
  exit 1
fi

compose() {
  "${COMPOSE_CMD[@]}" -f "${COMPOSE_FILE}" "$@"
}

backend_state() {
  compose exec -T tailscale tailscale status --json 2>/dev/null \
    | grep -Eo '"BackendState": *"[A-Za-z]+"' \
    | grep -Eo '[A-Za-z]+"$' | tr -d '"' || true
}

# Waits until the machine is enrolled: connected (Running) or
# pending approval in the console (NeedsMachineAuth).
wait_for_login() {
  local state=""
  local _

  for _ in $(seq 1 60); do
    state="$(backend_state)"
    if [[ "${state}" == "Running" || "${state}" == "NeedsMachineAuth" ]]; then
      echo "${state}"
      return 0
    fi
    sleep 1
  done

  return 1
}

echo "== Joining the VPN (Tailscale SaaS) =="

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: this setup is meant for Linux." >&2
  exit 1
fi

if [[ ! -c /dev/net/tun ]]; then
  echo "ERROR: /dev/net/tun does not exist or is not a valid device." >&2
  exit 1
fi

if [[ "$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}" 2>/dev/null || true)" == "true" ]]; then
  if [[ "$(backend_state)" == "Running" ]]; then
    echo "This machine is already in the VPN. Nothing to do."
    exit 0
  fi
elif ip link show tailscale0 >/dev/null 2>&1; then
  echo "ERROR: another Tailscale is already running on this machine (tailscale0 interface)." >&2
  echo "ERROR: stop it first, for example the headscale/node node." >&2
  exit 1
fi

if [[ -z "${TS_OAUTH_SECRET:-}" ]]; then
  if [[ -t 0 ]]; then
    read -r -s -p "OAuth client secret (tskey-client-...): " TS_OAUTH_SECRET
    echo
  else
    echo "ERROR: set TS_OAUTH_SECRET to the OAuth client secret." >&2
    exit 1
  fi
fi

if [[ "${TS_OAUTH_SECRET}" != tskey-client-* ]]; then
  echo "ERROR: TS_OAUTH_SECRET does not look like an OAuth secret (it must start with tskey-client-)." >&2
  exit 1
fi

# .env only holds non-secret settings.
(
  umask 077
  cat > "${ENV_FILE}" <<EOF
TAILSCALE_IMAGE=${TAILSCALE_IMAGE}
TS_HOSTNAME=${TS_HOSTNAME}
TS_TAGS=${TS_TAGS}
TS_ACCEPT_DNS=${TS_ACCEPT_DNS:-false}
EOF
)

echo "Enrolling '${TS_HOSTNAME}' with ${TS_TAGS}..."
TS_AUTHKEY="${TS_OAUTH_SECRET}?ephemeral=false&preauthorized=${TS_PREAUTHORIZED}" \
  compose up -d --force-recreate

if ! wait_for_login >/dev/null; then
  echo "ERROR: the machine did not join the VPN within 60 seconds. Logs:" >&2
  compose logs --tail 30 tailscale >&2
  exit 1
fi

# Recreate the container without the secret: with TS_AUTH_ONCE=true the session
# already saved in node/state is enough, and the secret is not left in docker inspect.
env -u TS_AUTHKEY "${COMPOSE_CMD[@]}" -f "${COMPOSE_FILE}" up -d --force-recreate

if ! state="$(wait_for_login)"; then
  echo "ERROR: the machine did not reconnect after removing the secret. Logs:" >&2
  compose logs --tail 30 tailscale >&2
  exit 1
fi

echo
if [[ "${state}" == "NeedsMachineAuth" ]]; then
  echo "OK: '${TS_HOSTNAME}' enrolled, pending approval in the Tailscale admin console (Machines)."
else
  echo "OK: '${TS_HOSTNAME}' is in the VPN with IP $(compose exec -T tailscale tailscale ip -4)"
fi
