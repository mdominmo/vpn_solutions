#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IAC_DIR="${ROOT_DIR}/infra/terraform"
GENERATED_DIR="${IAC_DIR}/generated"
ENV_FILE="${IAC_DIR}/.env"
TFVARS_FILE="${IAC_DIR}/terraform.tfvars"

mkdir -p "${GENERATED_DIR}"

prompt_value() {
  local var_name="$1"
  local prompt="$2"
  local default_value="$3"
  local value=""

  if [[ -n "${default_value}" ]]; then
    read -r -p "${prompt} [${default_value}]: " value
    value="${value:-${default_value}}"
  else
    while [[ -z "${value}" ]]; do
      read -r -p "${prompt}: " value
    done
  fi

  printf -v "${var_name}" '%s' "${value}"
}

prompt_optional_value() {
  local var_name="$1"
  local prompt="$2"
  local default_value="$3"
  local value=""

  if [[ -n "${default_value}" ]]; then
    read -r -p "${prompt} [${default_value}]: " value
    value="${value:-${default_value}}"
  else
    read -r -p "${prompt}: " value
  fi

  printf -v "${var_name}" '%s' "${value}"
}

prompt_secret() {
  local var_name="$1"
  local prompt="$2"
  local value=""

  while [[ -z "${value}" ]]; do
    read -r -s -p "${prompt}: " value
    echo
  done

  printf -v "${var_name}" '%s' "${value}"
}

prompt_secret "HCLOUD_TOKEN" "Hetzner API token"
prompt_value "SSH_PUBLIC_KEY_SOURCE" "Ruta a tu clave publica SSH" "${HOME}/.ssh/id_ed25519.pub"

if [[ ! -f "${SSH_PUBLIC_KEY_SOURCE}" ]]; then
  echo "ERROR: no existe ${SSH_PUBLIC_KEY_SOURCE}" >&2
  exit 1
fi

prompt_value "SERVER_NAME" "Nombre del VPS" "headscale-vps"
prompt_value "SERVER_LOCATION" "Location Hetzner" "fsn1"
prompt_value "SERVER_TYPE" "Tipo de servidor" "cx23"
prompt_value "SERVER_IMAGE" "Imagen del servidor" "ubuntu-24.04"
prompt_value "SSH_KEY_NAME" "Nombre del SSH key en Hetzner" "headscale-admin"
prompt_optional_value "HEADSCALE_DOMAIN" "Dominio publico para Headscale (deja vacio para usar IP:8080)" ""
prompt_value "TAILSCALE_BASE_DOMAIN" "Dominio interno para MagicDNS" "tailnet.local"
prompt_value "ADMIN_ALLOWED_CIDRS_RAW" "CIDRs permitidos para SSH al VPS, separados por coma" "0.0.0.0/0,::/0"

cp "${SSH_PUBLIC_KEY_SOURCE}" "${GENERATED_DIR}/admin_key.pub"
chmod 600 "${GENERATED_DIR}/admin_key.pub"

cat > "${ENV_FILE}" <<EOF
HCLOUD_TOKEN=${HCLOUD_TOKEN}
EOF
chmod 600 "${ENV_FILE}"

IFS=',' read -r -a ADMIN_ALLOWED_CIDRS <<< "${ADMIN_ALLOWED_CIDRS_RAW}"

CIDR_LINES=()
for cidr in "${ADMIN_ALLOWED_CIDRS[@]}"; do
  trimmed="$(echo "${cidr}" | sed 's/^ *//;s/ *$//')"
  if [[ -n "${trimmed}" ]]; then
    CIDR_LINES+=("  \"${trimmed}\",")
  fi
done

if [[ ${#CIDR_LINES[@]} -eq 0 ]]; then
  CIDR_LINES+=("  \"0.0.0.0/0\",")
  CIDR_LINES+=("  \"::/0\",")
fi

last_index=$((${#CIDR_LINES[@]} - 1))
CIDR_LINES[$last_index]="${CIDR_LINES[$last_index]%,}"

{
  echo "server_name           = \"${SERVER_NAME}\""
  echo "server_type           = \"${SERVER_TYPE}\""
  echo "server_location       = \"${SERVER_LOCATION}\""
  echo "server_image          = \"${SERVER_IMAGE}\""
  echo "ssh_key_name          = \"${SSH_KEY_NAME}\""
  echo "ssh_public_key_path   = \"generated/admin_key.pub\""
  echo "headscale_domain      = \"${HEADSCALE_DOMAIN}\""
  echo "tailscale_base_domain = \"${TAILSCALE_BASE_DOMAIN}\""
  echo "admin_allowed_cidrs = ["
  printf '%s\n' "${CIDR_LINES[@]}"
  echo "]"
} > "${TFVARS_FILE}"
chmod 600 "${TFVARS_FILE}"

echo
echo "Resumen:"
echo "  VPS: ${SERVER_NAME}"
echo "  Location: ${SERVER_LOCATION}"
echo "  Tipo: ${SERVER_TYPE}"
echo "  Imagen: ${SERVER_IMAGE}"
if [[ -n "${HEADSCALE_DOMAIN}" ]]; then
  echo "  Headscale: https://${HEADSCALE_DOMAIN}"
else
  echo "  Headscale: http://<IP_DEL_VPS>:8080"
fi
echo "  MagicDNS: ${TAILSCALE_BASE_DOMAIN}"
echo

read -r -p "Quieres ejecutar 'init' y 'plan' ahora? [y/N]: " RUN_PLAN
if [[ "${RUN_PLAN}" =~ ^[Yy]$ ]]; then
  "${ROOT_DIR}/scripts/iac.sh" init
  "${ROOT_DIR}/scripts/iac.sh" plan
fi

echo
read -r -p "Escribe PROVISIONAR para crear el VPS y desplegar Headscale: " CONFIRM_APPLY
if [[ "${CONFIRM_APPLY}" == "PROVISIONAR" ]]; then
  "${ROOT_DIR}/scripts/iac.sh" init
  "${ROOT_DIR}/scripts/iac.sh" apply -auto-approve
  echo
  "${ROOT_DIR}/scripts/iac.sh" output
else
  echo "Provisionamiento cancelado."
fi
