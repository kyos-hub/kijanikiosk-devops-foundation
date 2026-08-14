/*
  modules/app_server (Docker path)

  Provisions one systemd-and-sshd-capable container per server, standing in
  for a VM. This replaces the original Multipass-based module after Multipass
  proved incompatible with this machine's WSL2 kernel (snap's mount-namespace
  confinement fails under WSL2 — a documented, unresolved compatibility gap,
  not a config mistake). Documented as an explicit engineering decision in
  hardening-decisions.md and reflection.md rather than silently swapped in.

  Image: geerlingguy/docker-ubuntu2204-ansible — built specifically for
  testing Ansible against a systemd-enabled container (systemd as PID 1,
  sshd pre-configured for root login). This keeps every downstream Ansible
  task (systemd unit management, journald, etc.) working exactly as it
  would against a real VM.
*/

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

resource "docker_container" "vm" {
  name       = var.server_name
  image      = var.image
  hostname   = var.server_name
  privileged = true # required for systemd to manage cgroups inside the container

  networks_advanced {
    name = var.network_name
  }

  tmpfs = {
    "/run"      = ""
    "/run/lock" = ""
  }

  volumes {
    container_path = "/sys/fs/cgroup"
    host_path       = "/sys/fs/cgroup"
    read_only       = false
  }

  memory     = var.memory_mb
  cpu_shares = var.cpu_shares

  # geerlingguy's image entrypoint starts systemd as PID 1 and brings up sshd.
}

# SSH key injection — Docker has no cloud-init equivalent, so the public key
# is copied in and permissions fixed immediately after the container is up.
# Requirement 1 criterion 3's "capture IP dynamically" is satisfied more
# directly here than under Multipass: docker_container.network_data is
# populated synchronously by the provider, no external-data-source shim needed.
resource "null_resource" "inject_ssh_key" {
  depends_on = [docker_container.vm]

  triggers = {
    container_id = docker_container.vm.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      for i in $(seq 1 20); do
        docker exec ${var.server_name} test -d /root 2>/dev/null && break
        sleep 1
      done
      docker exec ${var.server_name} mkdir -p /root/.ssh
      docker cp ${var.ssh_public_key_path} ${var.server_name}:/root/.ssh/authorized_keys
      docker exec ${var.server_name} chmod 700 /root/.ssh
      docker exec ${var.server_name} chmod 600 /root/.ssh/authorized_keys
      docker exec ${var.server_name} chown -R root:root /root/.ssh
      docker exec ${var.server_name} bash -c "systemctl restart sshd || service ssh restart || true"
    EOT
  }
}
