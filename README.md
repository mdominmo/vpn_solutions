# tail_scale_vpn

`SSH` al PC remoto con:

- `Headscale` en un VPS de Hetzner
- `Tailscale` en Docker con `network_mode: host`
- `sshd` del host remoto

## Flujo rapido

### 1. En tu PC local: crear el VPS y desplegar `Headscale`

```bash
./scripts/bootstrap-hetzner-vps.sh
```

El script:

- pide los datos uno a uno
- guarda la configuracion
- pide confirmacion antes de crear nada
- crea el VPS
- despliega `Headscale` en Docker dentro del VPS

### 2. En tu PC local: ver la URL de `Headscale`

```bash
./scripts/iac.sh output
```

Copia el valor de `headscale_url`.

### 3. En tu PC local: crear usuario y `preauth key`

Usa la IP del VPS que devuelve `./scripts/iac.sh output`:

```bash
export HEADSCALE_SSH_TARGET=root@IP_DEL_VPS
./scripts/headscale-users-create.sh vpnops
./scripts/headscale-preauthkey-create.sh 1
```

### 4. En cada PC que quieras unir a la red: preparar la carpeta `node/`

`node/` es la carpeta de este repositorio que contiene la configuracion del cliente `Tailscale` de cada PC.

```bash
./scripts/node-host-preflight.sh
```

Este comando comprueba si ese PC tiene lo necesario para arrancar `Tailscale` en Docker.

```bash
cp node/.env.example node/.env
```

Este comando crea `node/.env`, que es el archivo real de configuracion de ese PC, a partir de la plantilla [node/.env.example](/home/manuel/repositories/own/tail_scale_vpn/node/.env.example:1).

Despues edita `node/.env` y ajusta:

- `TS_HOSTNAME`: nombre que tendra ese PC dentro de la red Tailscale. Lo eliges tu. Usa uno distinto por equipo, por ejemplo `pc-casa` o `pc-remoto`
- `TS_AUTHKEY`: clave de alta que genera `Headscale` para registrar ese nodo
- `TS_EXTRA_ARGS=--login-server=URL_DE_HEADSCALE`: URL de tu servidor `Headscale`

Ejemplo:

```env
TS_HOSTNAME=pc-remoto
TS_AUTHKEY=RELLENAR_CON_PREAUTH_KEY
TS_EXTRA_ARGS=--login-server=https://vpn.midominio.com
```

Repite este paso en cada equipo. Si tambien quieres que tu PC local entre en la red Tailscale, crea ahi su propio `node/.env` con otro `TS_HOSTNAME`, por ejemplo `pc-casa`.

### 5. En cada PC: levantar el nodo

Este es el momento en que ese PC entra en la VPN.

```bash
docker compose -f node/docker-compose.yml up -d
./scripts/node-host-status.sh
```

Haz este paso:

- una vez en tu PC local
- y otra vez en el PC remoto

### 6. En tu PC local: probar `SSH`

Desde otro equipo unido a la misma tailnet:

```bash
ssh usuario@100.x.y.z
```

## Donde se ejecuta cada cosa

- Tu PC local:
  `./scripts/bootstrap-hetzner-vps.sh`
  `./scripts/iac.sh output`
  `export HEADSCALE_SSH_TARGET=root@IP_DEL_VPS`
  `./scripts/headscale-users-create.sh vpnops`
  `./scripts/headscale-preauthkey-create.sh 1`
  `cp node/.env.example node/.env`
  `docker compose -f node/docker-compose.yml up -d`
  `./scripts/node-host-status.sh`
  `ssh usuario@100.x.y.z`

- VPS de Hetzner:
  no ejecutas pasos manuales normales
  `bootstrap-hetzner-vps.sh` despliega ahi `Headscale` automaticamente en Docker

- PC remoto:
  `./scripts/node-host-preflight.sh`
  `cp node/.env.example node/.env`
  `docker compose -f node/docker-compose.yml up -d`
  `./scripts/node-host-status.sh`

## Ficheros clave

- [infra/terraform/main.tf](/home/manuel/repositories/own/tail_scale_vpn/infra/terraform/main.tf:1)
- [scripts/bootstrap-hetzner-vps.sh](/home/manuel/repositories/own/tail_scale_vpn/scripts/bootstrap-hetzner-vps.sh:1)
- [node/docker-compose.yml](/home/manuel/repositories/own/tail_scale_vpn/node/docker-compose.yml:1)
