#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IAC_DIR="${ROOT_DIR}/infra/terraform"
ENV_FILE="${IAC_DIR}/.env"
IAC_IMAGE="${IAC_IMAGE:-hashicorp/terraform:latest}"

if [[ $# -eq 0 ]]; then
  echo "Uso: $0 <init|plan|apply|output|destroy|fmt|validate> [args...]" >&2
  exit 1
fi

if [[ ! -d "${IAC_DIR}" ]]; then
  echo "ERROR: no existe ${IAC_DIR}" >&2
  exit 1
fi

TTY_ARGS=()
if [[ -t 0 && -t 1 ]]; then
  TTY_ARGS=(-it)
fi

ENV_ARGS=()
if [[ -f "${ENV_FILE}" ]]; then
  ENV_ARGS=(--env-file "${ENV_FILE}")
fi

docker run --rm "${TTY_ARGS[@]}" \
  -u "$(id -u):$(id -g)" \
  "${ENV_ARGS[@]}" \
  -v "${ROOT_DIR}:/workspace" \
  -w /workspace/infra/terraform \
  "${IAC_IMAGE}" "$@"
