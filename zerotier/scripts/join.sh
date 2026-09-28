#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/node/docker-compose.yml"
ENV_FILE="${ROOT_DIR}/node/.env"

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [network_id]" >&2
  exit 1
fi

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

zt() {
  compose exec -T zerotier zerotier-cli "$@" 2>/dev/null
}

echo "== Joining the VPN (ZeroTier) =="

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: this setup is meant for Linux." >&2
  exit 1
fi

if [[ ! -c /dev/net/tun ]]; then
  echo "ERROR: /dev/net/tun does not exist or is not a valid device." >&2
  exit 1
fi

ZT_NETWORK_ID="${1:-}"
if [[ -z "${ZT_NETWORK_ID}" ]]; then
  if [[ -t 0 ]]; then
    read -r -p "ZeroTier Network ID (16 characters): " ZT_NETWORK_ID
  else
    echo "ERROR: pass the Network ID as an argument." >&2
    exit 1
  fi
fi

ZT_NETWORK_ID="$(echo "${ZT_NETWORK_ID}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
if [[ ! "${ZT_NETWORK_ID}" =~ ^[0-9a-f]{16}$ ]]; then
  echo "ERROR: '${ZT_NETWORK_ID}' is not a valid Network ID (16 hexadecimal characters)." >&2
  exit 1
fi

cat > "${ENV_FILE}" <<EOF
ZEROTIER_IMAGE=${ZEROTIER_IMAGE:-zerotier/zerotier:1.14.2}
ZT_NETWORK_ID=${ZT_NETWORK_ID}
EOF

compose up -d

node_address=""
for _ in $(seq 1 30); do
  node_address="$(zt info | awk '$1 == "200" && $2 == "info" {print $3}' || true)"
  [[ -n "${node_address}" ]] && break
  sleep 1
done

if [[ -z "${node_address}" ]]; then
  echo "ERROR: ZeroTier did not start within 30 seconds. Logs:" >&2
  compose logs --tail 30 zerotier >&2
  exit 1
fi

# The network only grants access once the admin authorizes the machine on the website.
status=""
for _ in $(seq 1 30); do
  status="$(zt get "${ZT_NETWORK_ID}" status | grep -Ex '[A-Z_]+' || true)"
  [[ "${status}" == "OK" || "${status}" == "ACCESS_DENIED" || "${status}" == "NOT_FOUND" ]] && break
  sleep 1
done

echo
echo "This machine's address: ${node_address}"
case "${status}" in
  OK)
    echo "OK: machine in the VPN. Assigned IP: $(zt get "${ZT_NETWORK_ID}" ip4 || echo 'pending')"
    ;;
  NOT_FOUND)
    echo "ERROR: network ${ZT_NETWORK_ID} does not exist. Check the Network ID." >&2
    exit 1
    ;;
  ACCESS_DENIED)
    echo "PENDING: ask your admin to authorize address ${node_address} on the ZeroTier website."
    echo "Then check the status with: ./zerotier/scripts/status.sh"
    ;;
  *)
    echo "PENDING: the network has not answered yet (status: ${status:-unknown})."
    echo "If your admin has not authorized address ${node_address} yet, ask them to."
    echo "Then check the status with: ./zerotier/scripts/status.sh"
    ;;
esac
