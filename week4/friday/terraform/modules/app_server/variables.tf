variable "server_name" {
  description = "Unique name for this server's container (e.g. kijanikiosk-api)."
  type        = string
}

variable "image" {
  description = "Container image standing in for the VM's base OS image. Must run systemd as PID 1."
  type        = string
  default     = "geerlingguy/docker-ubuntu2204-ansible:latest"
}

variable "network_name" {
  description = "Name of the Docker network all three servers attach to, so they can reach each other."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key installed into the container's authorized_keys."
  type        = string
}

variable "ssh_host_port" {
  description = "Host port (on 127.0.0.1) published to this container's SSH port 22. Required because Docker Desktop's daemon runs in its own hidden VM — container bridge-network IPs aren't reachable from the WSL host directly, only published ports are."
  type        = number
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
