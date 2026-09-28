locals {
  use_caddy     = trimspace(var.headscale_domain) != ""
  public_domain = trimspace(var.headscale_domain)

  headscale_url  = local.use_caddy ? "https://${local.public_domain}" : "http://${hcloud_primary_ip.headscale_ipv4.ip_address}:8080"
  headscale_bind = local.use_caddy ? "127.0.0.1:8080:8080" : "0.0.0.0:8080:8080"

  common_labels = {
    managed_by = "terraform"
    project    = "tail_scale_vpn"
    role       = "headscale"
  }

  acl_content = templatefile("${path.module}/templates/acl.hujson.tftpl", {})

  config_content = templatefile("${path.module}/templates/config.yaml.tftpl", {
    server_url  = local.headscale_url
    base_domain = var.tailscale_base_domain
  })

  caddyfile_content = local.use_caddy ? templatefile("${path.module}/templates/Caddyfile.tftpl", {
    public_domain = local.public_domain
  }) : ""

  cloud_init = templatefile("${path.module}/templates/cloud-init.sh.tftpl", {
    headscale_bind    = local.headscale_bind
    headscale_image   = var.headscale_image
    caddy_image       = var.caddy_image
    headscale_config  = local.config_content
    acl_content       = local.acl_content
    caddyfile_content = local.caddyfile_content
    use_caddy         = local.use_caddy
  })
}

resource "hcloud_ssh_key" "admin" {
  name       = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
  labels     = local.common_labels
}

resource "hcloud_primary_ip" "headscale_ipv4" {
  name        = "${var.server_name}-ipv4"
  location    = var.server_location
  type        = "ipv4"
  auto_delete = false
  labels      = local.common_labels
}

resource "hcloud_firewall" "headscale" {
  name   = "${var.server_name}-fw"
  labels = local.common_labels

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.admin_allowed_cidrs
    description = "SSH"
  }

  dynamic "rule" {
    for_each = local.use_caddy ? toset(["80", "443"]) : toset([])

    content {
      direction   = "in"
      protocol    = "tcp"
      port        = rule.value
      source_ips  = ["0.0.0.0/0", "::/0"]
      description = "Headscale public"
    }
  }

  dynamic "rule" {
    for_each = local.use_caddy ? toset([]) : toset(["8080"])

    content {
      direction   = "in"
      protocol    = "tcp"
      port        = rule.value
      source_ips  = ["0.0.0.0/0", "::/0"]
      description = "Headscale HTTP"
    }
  }

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "ICMP"
  }
}

resource "hcloud_server" "headscale" {
  name         = var.server_name
  server_type  = var.server_type
  image        = var.server_image
  location     = var.server_location
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.headscale.id]
  labels       = local.common_labels
  user_data    = local.cloud_init

  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.headscale_ipv4.id
    ipv6_enabled = true
  }

  lifecycle {
    ignore_changes = [
      ssh_keys,
      user_data,
    ]
  }
}
