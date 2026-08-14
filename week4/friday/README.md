# Week 4 Friday — KijaniKiosk IaC Pipeline

## Why Docker instead of Multipass

The project brief's primary path assumes Multipass. On this machine (Windows +
WSL2), Multipass fails at launch with `cannot preserve mount namespace ... as
multipass.mnt: Invalid argument` — a documented incompatibility between
snap's confinement and the WSL2 kernel, not a configuration mistake (verified
after a clean Ubuntu reinstall, confirmed disk space, confirmed `/dev/kvm`
present and group membership correct — the error is structural, not
environmental).

**Substitution:** the `app_server` module provisions Docker containers
running `geerlingguy/docker-ubuntu2204-ansible` — an image built specifically
for testing Ansible against a systemd-enabled target (systemd as PID 1, sshd
pre-configured). Every downstream requirement — reusable module with
`for_each`, dynamic IP capture, real systemd unit management, idempotent
Ansible runs — works identically to a VM-based setup. This is called out
explicitly in `hardening-decisions.md` and `reflection.md` as a deliberate
engineering decision, not hidden.

## Prerequisites (already set up on this machine)

- Docker Desktop with WSL integration enabled for this distro
- Terraform (via HashiCorp's apt repo)
- Ansible (via apt)
- SSH key pair at `~/.ssh/id_rsa` / `~/.ssh/id_rsa.pub`
- MinIO running as a Docker container, state persisted to `~/minio-data`:

  ```bash
  docker run -d --name minio \
    -p 9000:9000 -p 9001:9001 \
    -e MINIO_ROOT_USER=minioadmin \
    -e MINIO_ROOT_PASSWORD=minioadmin \
    -v ~/minio-data:/data \
    minio/minio server /data --console-address :9001
  ```

  If the `minio` container isn't running when you start a session:
  `docker start minio` brings it back with state intact (the volume mount is
  what makes Challenge E — state surviving between pipeline runs — hold true).

- MinIO needs its state bucket created once before first use. Either via the
  console at `http://localhost:9001` (login `minioadmin` / `minioadmin`,
  create bucket `kijanikiosk-tfstate`), or via the `mc` CLI if installed.

## What to run, in order

```bash
# 1. first run — captures full Terraform apply + Ansible output
./pipeline.sh 2>&1 | tee pipeline-run1.log

# 2. second run — must show 0 changes / changed=0 throughout
./pipeline.sh 2>&1 | tee pipeline-run2.log

# 3. sanity check dynamic inventory really was regenerated
cat ansible/inventory.ini

# 4. teardown, captured for submission
cd terraform && terraform destroy -auto-approve | tee ../destroy-output.txt
```

Fill in `environment-setup.md`'s `<TODO>` fields with your actual tool
versions (`terraform version`, `docker version`, `ansible --version`) before
committing.

## Known things to double check

- UFW inside a Docker container (even `--privileged`) can behave
  inconsistently depending on the host's netfilter setup. If those tasks
  fail, that's worth a note in the reflection rather than something to force
  — it's a known limitation of simulating firewalls inside containers.
- `ansible_user` is `root` here (matching the container image), not `ubuntu`
  — this is the one detail that would need to change back if this ever runs
  against real cloud VMs.
- The payments hardening tier in `ansible/host_vars/kk-payments.yml` is a
  reasonable default aimed at a systemd-analyze security score below 2.5 —
  cross-check it against whatever you actually achieved in Week 3 and adjust
  if your directives differed.

## Before opening the PR

- Branch: `feature/week4-iac-pipeline` → PR into `develop`
- All files live under `week4/friday/`
- PR description, one paragraph for Tendo: what you built, the decision
  you're most confident about, one thing you'd improve with more time.
  Given the Docker substitution, this is a strong thing to lead with — it's
  a real engineering trade-off, not a workaround to gloss over.
