output "server_name" {
  description = "Name of the provisioned server's container."
  value       = var.server_name
}

output "ip_address" {
  description = "Reachable host address for Ansible/SSH — always 127.0.0.1 on the Docker Desktop path, since only published ports cross into the WSL host's network."
  value       = "127.0.0.1"
}

output "ssh_port" {
  description = "Host port publishing this container's SSH service."
  value       = var.ssh_host_port
  depends_on  = [null_resource.provision_ssh]
}

output "ssh_command" {
  description = "Ready-to-copy SSH command for this server."
  value       = "ssh -i ${replace(var.ssh_public_key_path, ".pub", "")} -p ${var.ssh_host_port} root@127.0.0.1"
}
