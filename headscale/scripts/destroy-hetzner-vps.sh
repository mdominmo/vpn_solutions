#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

read -r -p "Type DESTROY to delete the VPS and the Hetzner resources: " CONFIRM_DESTROY
if [[ "${CONFIRM_DESTROY}" != "DESTROY" ]]; then
  echo "Destruction cancelled."
  exit 0
fi

"${ROOT_DIR}/scripts/iac.sh" init
"${ROOT_DIR}/scripts/iac.sh" destroy -auto-approve
