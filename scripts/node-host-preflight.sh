#!/usr/bin/env bash

set -euo pipefail

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "ERROR: no se ha encontrado ni 'docker compose' ni 'docker-compose'." >&2
  exit 1
fi

echo "== Preflight host node =="

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: este despliegue esta pensado para Linux." >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker no esta disponible." >&2
  exit 1
fi

if [[ ! -c /dev/net/tun ]]; then
  echo "ERROR: /dev/net/tun no existe o no es un dispositivo valido." >&2
  exit 1
fi

echo "OK: Linux detectado"
echo "OK: Docker disponible"
echo "OK: /dev/net/tun disponible"

"${COMPOSE_CMD[@]}" -f node/docker-compose.yml config >/dev/null
echo "OK: docker-compose del nodo valido"

if command -v ss >/dev/null 2>&1; then
  if ss -ltn '( sport = :22 )' | tail -n +2 | grep -q .; then
    echo "OK: hay un servicio escuchando en TCP/22 en el host"
  else
    echo "WARN: no se detecta ningun listener en TCP/22"
    echo "WARN: para hacer SSH al host remoto necesitaras un sshd real en el anfitrion"
  fi
else
  echo "WARN: no se puede comprobar el puerto 22 porque 'ss' no esta disponible"
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
    echo "OK: servicio ssh/sshd activo"
  else
    echo "WARN: no se detecta servicio ssh/sshd activo via systemd"
  fi
fi

echo "Preflight completado"
