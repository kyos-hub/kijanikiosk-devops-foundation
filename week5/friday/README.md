# Week 5 Friday — CI Pipeline

## What's here

- **`/Jenkinsfile`** (repo root, as required) — the full pipeline: Lint →
  Build → parallel Verify (Test + Security Audit) → Archive → Publish,
  with a complete `post` block.
- **`/package.json`, `/src`, `/test`, `/.eslintrc.json`** — a minimal
  Node.js app the pipeline actually builds, lints, tests, and publishes.
- **`week5/friday/ci-pipeline-board-document.md`** — the Nia document,
  648 words.
- **`week5/friday/fault-injection-log.md`** — table with exact steps to
  break each of the 5 fault points; fill in the "Observed" column from
  your real console output.
- **`week5/friday/reflection.md`** — drafted answers to all three
  reflection questions.

## What I could not produce here

Same situation as Week 4: `green-pipeline-run.txt`, the Nexus versions
screenshot, the filled-in fault injection log, and `credential-audit.txt`
all require a real Jenkins run against your actual Nexus instance. I have
no access to your Jenkins/Nexus containers from here.

## Environment already confirmed working

- Jenkins running at `localhost:8080` (admin / — reset via init script
  this session), Docker Pipeline plugin installed.
- Nexus running at `localhost:8081`, `npm-hosted` repository created.
- Jenkins container has Docker socket access — pipeline-spawned containers
  are siblings on the same Docker Desktop engine as Nexus, reachable via
  `host.docker.internal:8081` (see the networking note at the top of the
  Jenkinsfile for why this differs from the brief's Linux-bridge-IP
  suggestion).

## Setup steps before the first real run

1. **Create the Nexus credential in Jenkins:**
   Manage Jenkins → Credentials → System → Global credentials → Add
   Credentials → Kind: "Username with password", ID: `nexus-credentials`,
   Username: `admin`, Password: (your Nexus admin password).

2. **Create the Jenkins pipeline job:**
   New Item → Pipeline → name it `kijanikiosk-payments-ci` → under
   Pipeline, choose "Pipeline script from SCM" → SCM: Git → Repository
   URL: `https://github.com/kyos-hub/kijanikiosk-devops-foundation.git`
   → Branch: `*/feature/week5-ci-pipeline` → Script Path: `Jenkinsfile`.

3. **Run it.** First run installs npm dependencies fresh (no lockfile
   committed), so it'll be a little slower than subsequent runs — still
   should land well under the 10-minute budget for an app this small.

4. **Run it a second time** (a trivial commit works, or just re-run) to
   get the second distinct version in Nexus that Requirement 2 needs.

5. **Capture `green-pipeline-run.txt`** from the Console Output of the
   successful run (the "Full log" link, or copy from the console).

6. **Screenshot Nexus** at `localhost:8081` → Browse → `npm-hosted` →
   `kijanikiosk-payments`, showing both version tarballs.

7. **Work through `fault-injection-log.md`** — each row has exact
   instructions for what to break, how, and what to look for.

8. **Credential audit** — search the Jenkinsfile, `git log -p`, and a
   downloaded build console log for the literal Nexus password string;
   confirm zero matches in all three, save that as `credential-audit.txt`.

## Before opening the PR

- Branch: `feature/week5-ci-pipeline` → PR into `develop`
- All docs under `week5/friday/`, Jenkinsfile at repo root
- PR description: one paragraph for Tendo — what you built, one confident
  decision, one thing you'd add next.
