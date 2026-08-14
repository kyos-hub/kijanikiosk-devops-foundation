variable "server_image" {
  description = "Container image used for all three servers — the environment-specific 'base image' equivalent of a cloud AMI or Multipass Ubuntu version."
  type        = string
  default     = "geerlingguy/docker-ubuntu2204-ansible:latest"
}

variable "ssh_public_key_path" {
  description = "Local filesystem path to the SSH public key installed on every server."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "servers" {
  description = "Map of server definitions provisioned via for_each. Keys are logical server names; values are per-server sizing overrides (the Docker equivalent of instance type)."
  type = map(object({
    memory_mb  = number
    cpu_shares = number
  }))
  default = {
    api = {
      memory_mb  = 512
      cpu_shares = 512
    }
    payments = {
      memory_mb  = 512
      cpu_shares = 512
    }
    logs = {
      memory_mb  = 768
      cpu_shares = 512
    }
  }
}
