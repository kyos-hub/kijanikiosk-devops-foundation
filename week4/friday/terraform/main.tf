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

resource "docker_network" "kijanikiosk" {
  name = "kijanikiosk-net"
}

module "server" {
  source = "./modules/app_server"

  for_each = var.servers

  server_name         = "kijanikiosk-${each.key}"
  image               = var.server_image
  network_name        = docker_network.kijanikiosk.name
  ssh_public_key_path = var.ssh_public_key_path
  ssh_host_port       = each.value.ssh_host_port
  memory_mb           = each.value.memory_mb
  cpu_shares          = each.value.cpu_shares
}
