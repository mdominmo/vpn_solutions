# tail_scale_vpn

`SSH` al PC remoto usando:

- `Headscale` en un VPS
- `Tailscale` en Docker en cada PC
- `sshd` del host remoto

## VPS

Estos pasos se hacen `una sola vez`, por el `administrador`.

### 1. Crear el VPS y desplegar `Headscale`

```bash
./scripts/bootstrap-hetzner-vps.sh
```

### 2. Ver la URL de `Headscale`

```bash
./scripts/iac.sh output
```

Coge:

- `headscale_url`
- `vps_ipv4`

### 3. Crear el usuario

```bash
export HEADSCALE_SSH_TARGET=root@IP_DEL_VPS
./scripts/headscale-users-create.sh vpnops
```

Esto normalmente se hace `una sola vez`.

## Cada PC

Estos pasos se repiten `en cada equipo` que quieras unir a la VPN, incluido tu `PC local` si tambien quieres meterlo en la red.

### 1. Generar una clave para ese PC

Este paso lo hace el `administrador`:

```bash
export HEADSCALE_SSH_TARGET=root@IP_DEL_VPS
./scripts/headscale-preauthkey-create.sh 1
```

La salida es la `TS_AUTHKEY` de ese PC.

`TS_AUTHKEY` la genera el `administrador`. El equipo remoto no la genera: solo la usa en su `node/.env`.

Ese `1` es el `user_id` de `Headscale`.

- Si todos los equipos cuelgan del mismo usuario, puede seguir siendo `1`.
- Si usas otro usuario, cambia ese numero por su `user_id`.
- La `TS_AUTHKEY` si debes generarla de nuevo para cada equipo.

### 2. Preparar ese PC

Este paso se hace `en ese PC`:

```bash
./scripts/node-host-preflight.sh
cp node/.env.example node/.env
```

Edita `node/.env`:

```env
TS_HOSTNAME=pc-remoto
TS_AUTHKEY=RELLENAR_CON_PREAUTH_KEY
TS_EXTRA_ARGS=--login-server=http://IP_DEL_VPS:8080
```

Que es cada variable:

- `TS_HOSTNAME`: nombre de ese PC dentro de Tailscale. Lo eliges tu y debe ser distinto en cada equipo.
- `TS_AUTHKEY`: clave generada para ese PC en el paso anterior.
- `TS_EXTRA_ARGS`: URL de tu `Headscale`.

### 3. Conectar ese PC a la VPN

Este es el paso en el que `ese PC entra en la VPN`:

```bash
docker compose -f node/docker-compose.yml up -d
./scripts/node-host-status.sh
```

## Probar SSH

Cuando `tu PC local` y `el PC remoto` ya hayan hecho los pasos de `Cada PC`:

1. Saca la IP Tailscale del remoto:

```bash
docker compose -f node/docker-compose.yml exec tailscale tailscale ip -4
```

2. Desde el equipo desde el que quieras conectarte:

```bash
ssh usuario@100.x.y.z
```

## Repetir pasos

- Puedes repetir `./scripts/node-host-preflight.sh` sin problema.
- Puedes repetir `docker compose -f node/docker-compose.yml up -d` sin problema.
- Debes repetir `./scripts/headscale-preauthkey-create.sh 1` por cada PC nuevo.
- No copies el mismo `node/.env` entre varios equipos.
- No uses el mismo `TS_HOSTNAME` en varios equipos.
- Si haces `cp node/.env.example node/.env` otra vez, puedes machacar tu configuracion actual.

## Ficheros clave

- [infra/terraform/main.tf](/home/manuel/repositories/own/tail_scale_vpn/infra/terraform/main.tf:1)
- [node/docker-compose.yml](/home/manuel/repositories/own/tail_scale_vpn/node/docker-compose.yml:1)
- [node/.env.example](/home/manuel/repositories/own/tail_scale_vpn/node/.env.example:1)
