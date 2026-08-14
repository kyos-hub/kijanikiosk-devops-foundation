variable "server_name" {
  description = "Unique name for this server's container (e.g. kijanikiosk-api)."
  type        = string
}

variable "image" {
  description = "Container image standing in for the VM's base OS image. Must run systemd as PID 1 with sshd pre-configured."
  type        = string
  default     = "geerlingguy/docker-ubuntu2204-ansible:latest"
}

variable "network_name" {
  description = "Name of the Docker network all three servers attach to, so they can reach each other and be reached from the host running Ansible."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key installed into the container's authorized_keys."
  type        = string
}

variable "memory_mb" {
  description = "Memory limit in MB for this container, standing in for cloud instance sizing."
  type        = number
  default     = 512
}

variable "cpu_shares" {
  description = "Relative CPU share for this container, standing in for cloud instance type."
  type        = number
  default     = 512
}
