variable "server_name" {
  description = "Nombre del VPS en Hetzner."
  type        = string
  default     = "headscale-vps"
}

variable "server_type" {
  description = "Tipo de servidor Hetzner."
  type        = string
  default     = "cx23"
}

variable "server_location" {
  description = "Ubicacion Hetzner."
  type        = string
  default     = "fsn1"
}

variable "server_image" {
  description = "Imagen del servidor."
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_key_name" {
  description = "Nombre del SSH key en Hetzner."
  type        = string
  default     = "headscale-admin"
}

variable "ssh_public_key_path" {
  description = "Ruta del fichero .pub que Terraform subira a Hetzner."
  type        = string
  default     = "generated/admin_key.pub"
}

variable "headscale_domain" {
  description = "Dominio publico para Headscale. Vacio para usar IP y HTTP en 8080."
  type        = string
  default     = ""
}

variable "tailscale_base_domain" {
  description = "Dominio interno usado por MagicDNS."
  type        = string
  default     = "tailnet.local"
}

variable "admin_allowed_cidrs" {
  description = "CIDRs autorizados para SSH al VPS."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "headscale_image" {
  description = "Imagen de Headscale."
  type        = string
  default     = "ghcr.io/juanfont/headscale:0.29.3"
}

variable "caddy_image" {
  description = "Imagen de Caddy."
  type        = string
  default     = "caddy:2.10.2-alpine"
}
