terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Shared network so all three "servers" can reach each other and be reached
# from the host machine running Ansible (WSL/localhost, same host as Docker).
resource "docker_network" "kijanikiosk" {
  name = "kijanikiosk-net"
}

# Requirement 1, criterion 1: app_server module called with for_each across
# the three server definitions. No resource declared three times by hand.
module "server" {
  source = "./modules/app_server"

  for_each = var.servers

  server_name          = "kijanikiosk-${each.key}"
  image                = var.server_image
  network_name          = docker_network.kijanikiosk.name
  ssh_public_key_path  = var.ssh_public_key_path
  memory_mb            = each.value.memory_mb
  cpu_shares           = each.value.cpu_shares
}
