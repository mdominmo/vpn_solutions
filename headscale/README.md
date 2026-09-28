# Tail Scale VPN — Headscale on a Hetzner VPS
This directory makes it easy to create a VPN network using the [Tail Scale]() client and the open source VPN server [Head Scale](). The infrastructure consists of the following components:
- Remote Head Scale server: Provides a public IP without NAT. It is provisioned with [Terraform]() on the [Hetzner]() services platform.

> [!NOTE]
> To use Terraform and provision infrastructure on Hetzner, you need a Hetzner project API key.

- Client machines: These are the VPN users. For now, a Linux OS is required (tested on Ubuntu 22/24). The required tools run in containers under [Docker Compose]().

## Getting started

> [!NOTE]
> All commands below are run from the root of this repository.

### On the infrastructure administrator machine

#### 1. Create the VPS and deploy `Headscale`

```bash
./headscale/scripts/bootstrap-hetzner-vps.sh
```

#### 2. Retrieve the `Headscale` URL

```bash
./headscale/scripts/iac.sh output
```

Take:

- `headscale_url`
- `vps_ipv4`

#### 3. Register client machines
In the following example we create the user `vpnops`. Since it is the first one in Head Scale, it will have user_id 1.

> [!NOTE]
> Several machines can use the same Head Scale user.

```bash
export HEADSCALE_SSH_TARGET=root@VPS_IP
./headscale/scripts/headscale-users-create.sh vpnops
```

#### 4. Generate a key for that client machine

```bash
export HEADSCALE_SSH_TARGET=root@VPS_IP
./headscale/scripts/headscale-preauthkey-create.sh 1
```

The output is the `TS_AUTHKEY` for that machine.

### On each client machine

### 1. Client machine setup
```bash
./headscale/scripts/node-host-preflight.sh
cp headscale/node/.env.example headscale/node/.env
```

Edit `headscale/node/.env`:

```env
TS_HOSTNAME=pc-remoto
TS_AUTHKEY=FILL_IN_WITH_PREAUTH_KEY
TS_EXTRA_ARGS=--login-server=http://VPS_IP:8080
```

- `TS_HOSTNAME`: name of that PC within Tailscale. You choose it, and it must be different on each machine.
- `TS_AUTHKEY`: key generated for that PC in the previous step.
- `TS_EXTRA_ARGS`: URL of your `Headscale`.

### 3. Connect the client machine to the VPN

```bash
docker compose -f headscale/node/docker-compose.yml up -d
./headscale/scripts/node-host-status.sh
```

## Testing SSH

Once `your local PC` and `the remote PC` have completed the `Each PC` steps:

1. Get the Tailscale IP of the remote machine:

```bash
docker compose -f headscale/node/docker-compose.yml exec tailscale tailscale ip -4
```

2. From the machine you want to connect from:

```bash
ssh user@100.x.y.z
```
## Key files

- [infra/terraform/main.tf](infra/terraform/main.tf)
- [node/docker-compose.yml](node/docker-compose.yml)
- [node/.env.example](node/.env.example)
