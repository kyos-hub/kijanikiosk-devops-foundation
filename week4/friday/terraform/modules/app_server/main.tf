/*
  modules/app_server (Docker path, v2)

  Fix over the first Docker attempt: Docker Desktop runs its actual daemon
  inside its own hidden WSL2 VM. Custom bridge-network container IPs
  (e.g. 172.19.0.4) only exist inside that hidden VM's network namespace —
  they are NOT reachable from the WSL distro or Windows host directly. Only
  explicitly published ports cross that boundary. So each container's SSH
  port is published to a distinct host port instead, and Ansible connects to
  127.0.0.1:<published port>.

  Also fixed: geerlingguy/docker-ubuntu2204-ansible does not ship
  openssh-server pre-installed (it's built for Molecule's docker_exec
  connection plugin, not SSH). The provisioner below installs and starts it
  explicitly rather than assuming it's present.
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
  privileged = true
  tty        = true # required: systemd as PID1 crashes silently without a TTY attached (found via diagnosis after a Docker Desktop crash)

  networks_advanced {
    name = var.network_name
  }

  ports {
    internal = 22
    external = var.ssh_host_port
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

  # memory_swap is computed by the Docker daemon and drifts against Terraform's
  # recorded state even when nothing meaningful changed — a known provider
  # quirk, not a real config difference. Ignored so the second-run idempotency
  # check (Requirement 1, criterion 6) reflects actual drift, not this noise.
  lifecycle {
    ignore_changes = [memory_swap]
  }
}

resource "null_resource" "provision_ssh" {
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

      docker exec ${var.server_name} bash -c "which sshd > /dev/null 2>&1 || (apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server)"
      docker exec ${var.server_name} bash -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config || true"
      docker exec ${var.server_name} mkdir -p /run/sshd
      docker exec ${var.server_name} mkdir -p /root/.ssh
      docker cp ${var.ssh_public_key_path} ${var.server_name}:/root/.ssh/authorized_keys
      docker exec ${var.server_name} chmod 700 /root/.ssh
      docker exec ${var.server_name} chmod 600 /root/.ssh/authorized_keys
      docker exec ${var.server_name} chown -R root:root /root/.ssh
      docker exec ${var.server_name} systemctl enable ssh
      docker exec ${var.server_name} systemctl restart ssh
    EOT
  }
}
