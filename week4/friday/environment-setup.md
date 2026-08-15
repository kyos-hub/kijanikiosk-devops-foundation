# Environment Setup

Path used for this submission: **Docker path** (Multipass unavailable on this
machine due to a WSL2 + snap nested-virtualization incompatibility — see
README.md for details).

| Tool | Version | Command used to check |
|---|---|---|
| OS (host) | Ubuntu 26.04 LTS (resolute), running under WSL2 on Windows | `lsb_release -a` |
| Terraform | v1.15.8 | `terraform version` |
| Docker Desktop | 4.84.0, Engine 29.6.2, API 1.55 | `docker version` |
| Ansible | core 2.20.1 | `ansible --version` |
| Python (control node) | 3.14.4 | `ansible --version` |
| Container base image | geerlingguy/docker-ubuntu2204-ansible:latest (Ubuntu 22.04) | fixed in `terraform/variables.tf` |

## Notes on reproducibility

- MinIO runs as a Docker container with a mounted volume (`~/minio-data`) so
  the Terraform state bucket survives a MinIO restart between pipeline runs
  (Challenge E from the project brief).
- The SSH key referenced throughout (`~/.ssh/id_rsa` / `~/.ssh/id_rsa.pub`)
  must already exist on the machine running `pipeline.sh`.
- Each server's SSH is published to a distinct host port (2222/2223/2224)
  rather than reachable by container IP — required because Docker Desktop
  runs its daemon inside its own hidden WSL2 VM, so bridge-network container
  IPs aren't reachable from the host directly (see `terraform/modules/app_server`
  for the full explanation).
- `docker_container.vm` sets `tty = true` — systemd running as PID 1 inside
  the container crashes silently (exit 255, no logs) without a TTY attached.
  Found through direct diagnosis after a Docker Desktop backend crash forced
  a full container rebuild.
