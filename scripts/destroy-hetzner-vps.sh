#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

read -r -p "Escribe DESTRUIR para eliminar el VPS y los recursos de Hetzner: " CONFIRM_DESTROY
if [[ "${CONFIRM_DESTROY}" != "DESTRUIR" ]]; then
  echo "Destruccion cancelada."
  exit 0
fi

"${ROOT_DIR}/scripts/iac.sh" init
"${ROOT_DIR}/scripts/iac.sh" destroy -auto-approve
