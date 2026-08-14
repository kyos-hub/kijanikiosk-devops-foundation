# Requirement 1, criterion 4: outputs formatted for direct use in the
# Ansible inventory. pipeline.sh reads these via `terraform output -raw`.

output "api_server_ip" {
  description = "IP of the api server container."
  value       = module.server["api"].ip_address
}

output "payments_server_ip" {
  description = "IP of the payments server container."
  value       = module.server["payments"].ip_address
}

output "logs_server_ip" {
  description = "IP of the logs server container."
  value       = module.server["logs"].ip_address
}

output "ssh_commands" {
  description = "Ready-to-copy SSH commands for all three servers, keyed by server name."
  value       = { for k, s in module.server : k => s.ssh_command }
}
