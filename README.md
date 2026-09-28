# VPN Solutions
Three ways to set up a private VPN, so that your machines can reach each other (for example over SSH) from anywhere, without opening ports on their networks. Pick one: each directory has its own guide for the admin and for users.

| | [Headscale](headscale/README.md) | [Tailscale SaaS](tailscale-saas/README.md) | [ZeroTier](zerotier/README.md) |
|---|---|---|---|
| Who runs the VPN | You, on your own server | Tailscale | ZeroTier |
| Server to maintain | A Hetzner VPS | None | None |
| Free plan limits | None (you pay for the VPS) | 6 users | 10 devices |
| How a machine joins | Admin creates a key per machine | One script with a shared secret | One script, then the admin approves it on the website |

## Headscale on a VPS
Directory: [`headscale/`](headscale/README.md)

You run your own VPN server ([Headscale](https://headscale.net)) on a VPS that is created automatically on Hetzner. Nothing depends on an outside VPN provider, and there are no user or device limits. The admin needs a Hetzner account and manages users and keys from the command line.

## Tailscale SaaS
Directory: [`tailscale-saas/`](tailscale-saas/README.md)

[Tailscale](https://tailscale.com) runs the VPN for you. The admin sets it up once on the Tailscale website, and each machine joins by running a single script.

> [!NOTE]
> Create the network with a personal account (Gmail, GitHub…). If you sign in with an organization email, such as a university one, you may be added to a network that someone in your organization already created.

## ZeroTier
Directory: [`zerotier/`](zerotier/README.md)

[ZeroTier](https://www.zerotier.com) runs the VPN for you. The admin creates the network on the ZeroTier website and shares its Network ID. Each machine joins by running a single script, and the admin approves it on the website.

## Requirements
- Linux machines (tested on Ubuntu 22/24) with Docker. Laptops and phones can also join using the official Tailscale or ZeroTier app.
- All commands in the guides are run from the root of this repository.
