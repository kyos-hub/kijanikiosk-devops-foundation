output "api_server_ip" {
  value = module.server["api"].ip_address
}
output "api_server_port" {
  value = module.server["api"].ssh_port
}

output "payments_server_ip" {
  value = module.server["payments"].ip_address
}
output "payments_server_port" {
  value = module.server["payments"].ssh_port
}

output "logs_server_ip" {
  value = module.server["logs"].ip_address
}
output "logs_server_port" {
  value = module.server["logs"].ssh_port
}

output "ssh_commands" {
  description = "Ready-to-copy SSH commands for all three servers, keyed by server name."
  value       = { for k, s in module.server : k => s.ssh_command }
}
