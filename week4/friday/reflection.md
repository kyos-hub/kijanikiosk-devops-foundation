# Reflection

**These answers are drafted from the design of this pipeline. Read them against your
own actual run — adjust anything that didn't match what you observed, especially the
first question, which asks about a moment you discovered something, not just a
plausible-sounding conflict.**

## 1. Where did two requirements conflict?

The clearest conflict is Challenge D. Requirement 2 calls for `ProtectSystem=strict`
on the payments service, carried over from Week 3's hardening. Requirement 3 calls for
the Ansible-deployed configuration to actually work end-to-end on a second run. Those
two pull against each other: `ProtectSystem=strict` makes most of the filesystem
read-only to the service, including the conventional place to put a service's
environment file. Deploy the environment file there and the service starts, reads
nothing, and fails — hardening and functionality directly contradict each other at that
one path. The fix wasn't to loosen the hardening; it was to recognize that
`ProtectSystem=strict` still leaves specific directories writable, and to point the
environment file at one of those instead. The lesson: a security control and a
functional requirement can both be individually correct and still break each other at
a specific integration point, and the fix is almost never to weaken the control — it's
to find where the control already made room for what you need.

## 2. Rewriting one sentence for Tendo instead of Nia

For Nia, the document says: *"The payments service cannot see or modify most of the
underlying operating system, even though it runs on it."*

For Tendo, that becomes: *"The payments unit runs under `ProtectSystem=strict`, mounting
`/usr`, `/boot`, and `/etc` read-only for the process while leaving an explicit writable
path under `/opt/kijanikiosk` for its environment file."*

What's lost in the technical version: the reason anyone should care. Tendo's version is
precise about mechanism but says nothing about consequence — you'd need to already know
what `ProtectSystem=strict` is for to understand why it matters. What's gained: it's
actionable. If something breaks, Tendo's version tells you exactly which directive to
check and which paths are involved; Nia's version couldn't debug anything, but it
doesn't need to — its job is to build trust that the decision was made deliberately.

## 3. The most fragile handoff

The most fragile point is the IP handoff between Terraform and Ansible — Challenge A.
It works cleanly in this environment because Multipass assigns IPs predictably on a
local network and `pipeline.sh` waits for SSH before handing off to Ansible. In a real
production environment, that handoff gets fragile fast: cloud instances can take longer
to pass health checks than a fixed retry loop assumes, IP addresses can be private and
only reachable through a bastion or VPN, and DNS might be the actual contract between
provisioning and configuration rather than a raw IP. To make this robust against a real
target environment, I'd need to know: whether addresses are stable or reassigned on
reboot, whether the machine running Ansible has a direct network path to the new hosts
or needs to jump through something else first, and what a reliable "the instance is
actually ready" signal looks like beyond "SSH accepted a connection" — a service can
accept SSH long before its own application is capable of correct behavior.
