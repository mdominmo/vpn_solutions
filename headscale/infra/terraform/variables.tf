variable "server_name" {
  description = "Name of the VPS in Hetzner."
  type        = string
  default     = "headscale-vps"
}

variable "server_type" {
  description = "Hetzner server type."
  type        = string
  default     = "cx23"
}

variable "server_location" {
  description = "Hetzner location."
  type        = string
  default     = "fsn1"
}

variable "server_image" {
  description = "Server image."
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_key_name" {
  description = "Name of the SSH key in Hetzner."
  type        = string
  default     = "headscale-admin"
}

variable "ssh_public_key_path" {
  description = "Path to the .pub file that Terraform uploads to Hetzner."
  type        = string
  default     = "generated/admin_key.pub"
}

variable "headscale_domain" {
  description = "Public domain for Headscale. Empty to use the IP and HTTP on 8080."
  type        = string
  default     = ""
}

variable "tailscale_base_domain" {
  description = "Internal domain used by MagicDNS."
  type        = string
  default     = "tailnet.local"
}

variable "admin_allowed_cidrs" {
  description = "CIDRs allowed to SSH into the VPS."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "headscale_image" {
  description = "Headscale image."
  type        = string
  default     = "ghcr.io/juanfont/headscale:0.29.3"
}

variable "caddy_image" {
  description = "Caddy image."
  type        = string
  default     = "caddy:2.10.2-alpine"
}
