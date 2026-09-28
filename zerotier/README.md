# Tail Scale VPN — ZeroTier
A VPN coordinated by ZeroTier. There is no server to maintain: the admin creates the network once in the ZeroTier website and approves each machine that joins.

## Admin guide
Everything here is done in ZeroTier Central: https://my.zerotier.com

> [!NOTE]
> The free plan allows up to 10 devices.

### First-time setup

1. **Create the network.** Sign in and click **Create A Network**.
2. **Copy the Network ID.** It is the 16-character code shown on the network (for example `8056c2e21c000001`). Give it to the people who will join.
3. **Keep the network private.** Open the network and check that **Access Control** is set to **Private**, so that nobody can get in without your approval.

### Approving a machine
When someone joins, their machine appears in the **Members** section of the network, identified by its **Address** (10 characters, for example `5bbbd3f038`).

1. Check that the address matches the one the person gives you.
2. Tick the **Auth** checkbox.
3. Optionally, write a name for the machine so you can recognise it later.

The machine gets its VPN IP a few seconds later.

### Adding a person with a laptop or phone
They install the ZeroTier app from https://www.zerotier.com/download, choose **Join Network** and enter the Network ID. Then approve their machine as above.

### Removing access
In **Members**, untick **Auth** next to the machine, or delete it.

## User guide
Requirements: a Linux machine (Ubuntu 22/24) with Docker, and the Network ID from your admin.

All commands are run from the root of this repository.

### Join the VPN

```bash
./zerotier/scripts/join.sh <network_id>
```

It prints this machine's **address**. Send it to your admin so they can approve it.

### Check the status

```bash
./zerotier/scripts/status.sh
```

Once your admin has approved the machine, the network shows `OK` and your VPN IP.

### Leave the VPN

```bash
./zerotier/scripts/leave.sh
```

### Connect to another machine

```bash
ssh user@<vpn_ip>
```

Use the other machine's VPN IP, which is shown in **Members** in ZeroTier Central.
