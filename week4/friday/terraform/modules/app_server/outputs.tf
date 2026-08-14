output "server_name" {
  description = "Name of the provisioned server's container."
  value       = var.server_name
}

output "ip_address" {
  description = "Container IP on the shared kijanikiosk network, populated synchronously by the docker provider — no polling or external script needed."
  value       = docker_container.vm.network_data[0].ip_address
  depends_on  = [null_resource.inject_ssh_key]
}

output "ssh_command" {
  description = "Ready-to-copy SSH command for this server."
  value       = "ssh -i ${replace(var.ssh_public_key_path, ".pub", "")} root@${docker_container.vm.network_data[0].ip_address}"
}
