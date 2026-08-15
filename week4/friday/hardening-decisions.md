# KijaniKiosk Staging Environment: Security Decisions

Prepared for Nia. This document explains, in plain language, the security choices built into the staging environment this week and what they protect against. It closes with an honest account of what is not yet covered.

## Why this matters

Every server we stand up for KijaniKiosk now goes through the same automated process, and every security-relevant choice in that process is written down rather than remembered. That matters for two reasons. First, if someone new joins the team, they can read this document and understand exactly what protections are in place without needing a walkthrough from whoever built it. Second, when we say the payments service is hardened, we can point to a specific, repeatable configuration rather than a claim about what someone did once and might have gotten right.

## What we built

Three servers are created automatically from a single specification: one that serves customer-facing API requests, one that handles payments, and one that collects logs from the other two. All three are built the same reliable way, and the process can be run again at any time to produce an identical result. That repeatability is itself a security property: it removes the chance that one server quietly drifts out of line with the others because someone made a manual change and forgot to document it.

The payments server receives the strictest protections of the three, because it is the one most directly tied to financial data and the one most attractive to anyone trying to cause harm.

## Control summary

| Control | What it does | Risk mitigated |
|---|---|---|
| Restricted network access | Only the connections each server actually needs are allowed in; everything else is blocked by default | Reduces the number of ways an outside party could reach a server that has no reason to be reached |
| Locked-down service accounts | Each service runs under its own dedicated account with no ability to log in interactively | Limits what an attacker can do even if they compromise the running service, since that account cannot open a shell or access other services' data |
| Process isolation from the operating system | The payments service cannot see or modify most of the underlying operating system, even though it runs on it | Contains the damage from a compromised payments process; it cannot tamper with system files or other software on the same machine |
| No new privileges | A running service can never gain more permissions than it started with, even if tricked into trying | Blocks a common technique attackers use to escalate from a minor foothold into full control of a machine |
| Restricted memory behavior | The service is not permitted to turn writable memory into executable code while running | Closes off a well-known method for smuggling and running malicious code inside a legitimate process |
| Locked-down system calls | The service can only make the narrow set of low-level requests it actually needs to function | Shrinks the attack surface available to malicious code, even if it somehow got loaded |
| Stored configuration, version-controlled infrastructure | The exact setup of every server is captured as a specification kept alongside our code, not held in one engineer's memory | Removes single points of failure in institutional knowledge and makes every change reviewable before it happens |
| Locked infrastructure records | The record of what currently exists in the environment is stored centrally rather than only on one person's laptop | Prevents the team from losing track of what is actually running, and reduces the chance of two people making conflicting changes at once |

## A gap we are choosing to name

The record described in the last row of that table — the one that tracks what currently exists in the environment — does not yet have a lock on it that would stop two people from changing it at the exact same moment. For a small team running this process one person at a time, that is a manageable risk today. It becomes a real one the moment more than one engineer might run this process concurrently, which is likely as the team grows. Larger, well-resourced cloud setups solve this with a shared locking mechanism; we have identified which one we would use and have not yet built it, because our current process guarantees only one person runs it at a time by design. We are naming this now rather than waiting for it to become a problem.

## What this does not protect against

This week's work hardens the servers themselves and the process that builds them. It does not protect against a valid set of credentials being stolen and used by someone who was never supposed to have them — password and key management is a separate piece of work. It does not inspect the actual application code running on these servers for bugs or vulnerabilities; it assumes the code deployed to them is sound. It does not yet cover what happens after these servers are live in a real production setting with real customer traffic, including monitoring for unusual behavior in real time. And it does not address physical or cloud-provider-level security, since today's environment runs on infrastructure we control directly rather than a third-party data center. Each of these is a reasonable next step, and none of them is quietly assumed to be solved by this week's work.
