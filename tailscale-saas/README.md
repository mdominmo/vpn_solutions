# Tail Scale VPN — Tailscale SaaS
A VPN coordinated by Tailscale. There is no server to maintain: the admin sets things up once in the Tailscale website, and each machine joins with a single script.

## Admin guide
Everything here is done in the Tailscale admin console: https://login.tailscale.com/admin

### First-time setup

1. **Create the network.** Sign in at https://login.tailscale.com with your Google, Microsoft, GitHub or Apple account. Your network is created on first sign-in.
2. **Set the access rules.** Go to **Access controls**, replace the content with [policy/tailnet-policy.hujson](policy/tailnet-policy.hujson) and click **Save**.
3. **Create the enrollment secret.** Go to **Settings → OAuth clients → Generate OAuth client**:
   - Under **Keys**, tick **Auth Keys → Write**.
   - Under **Tags**, select `tag:server`.
   - Click **Generate client** and copy the **Client secret** (it starts with `tskey-client-`).

> [!WARNING]
> The secret is shown only once, and anyone who has it can add machines to the network. Store it in a password manager and never commit it to this repository.

### Adding a machine
Give the secret to whoever runs the [user guide](#user-guide) on that machine. The machine appears in **Machines** within a few seconds.

### Adding a person with a laptop or phone
Go to **Users → Invite users** and send the invitation by email. The person accepts it, installs the Tailscale app from https://tailscale.com/download and signs in with the same account.

### Removing access
- **A machine:** go to **Machines**, click **⋯** next to it and choose **Remove**.
- **A person:** go to **Users**, click **⋯** next to them and choose **Remove user**.
- **The secret was leaked:** go to **Settings → OAuth clients** and **Revoke** it, then create a new one. Machines already in the network keep working.

## User guide
Requirements: a Linux machine (Ubuntu 22/24) with Docker, and the secret from your admin.

All commands are run from the root of this repository.

### Join the VPN

```bash
./tailscale-saas/scripts/join.sh my-machine
```

- Paste the secret when asked. It is not displayed and not stored on the machine.
- `my-machine` is the name the machine will have in the VPN. Choose a unique one. If you leave it out, the computer's name is used.

When it finishes, it prints the machine's VPN IP (`100.x.y.z`).

### Check the status

```bash
./tailscale-saas/scripts/status.sh
```

### Leave the VPN

```bash
./tailscale-saas/scripts/leave.sh
```

### Connect to another machine

```bash
ssh user@100.x.y.z
```

Use the other machine's VPN IP, which is shown by `./tailscale-saas/scripts/status.sh` or in **Machines** in the admin console.
