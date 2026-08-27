output "server_name" {
  value = hcloud_server.headscale.name
}

output "vps_ipv4" {
  value = hcloud_primary_ip.headscale_ipv4.ip_address
}

output "ssh_target" {
  value = "root@${hcloud_primary_ip.headscale_ipv4.ip_address}"
}

output "headscale_url" {
  value = local.headscale_url
}

output "node_login_server_arg" {
  value = "--login-server=${local.headscale_url}"
}
