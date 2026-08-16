# Reflection

**Drafted from the design of this pipeline — read against your own actual
fault-injection runs and adjust anything that doesn't match what you
observed, especially question 1.**

## 1. Where two requirements were in tension

The tension surfaced in the Security Audit branch. Requirement 1 wants a
fast pipeline (under 10 minutes) and a parallel Verify stage so checks
don't serialize unnecessarily. But `npm audit` by default fails on *any*
severity finding, including low-severity advisories buried in transitive
dev dependencies that have nothing to do with the actual runtime code. A
strict audit would make the pipeline red constantly for reasons unrelated
to the code being shipped, which trains people to ignore red builds — the
opposite of what a CI gate is for. The choice was `--audit-level=high`:
strict enough to actually block a real vulnerability, loose enough not to
manufacture false urgency out of routine noise. The tension was really
between "check everything" and "only block on what matters enough to
justify blocking a release."

## 2. Rewriting a board sentence for a technical audience

For Nia: *"Every release that comes out the other end has a version label
made of two parts: a human-readable number, and the exact code change it
came from."*

For Osei, or as a Jenkinsfile comment: *"PACKAGE_VERSION is built from
package.json's semver plus the short git SHA (`${baseVersion}-${GIT_SHA_SHORT}`),
so every published artifact is traceable to the exact commit that produced
it."*

What's the same: the underlying fact — every artifact's version string
encodes both a human-readable number and a precise commit reference. What's
different: Nia's version explains *why it matters* (traceability, trust) and
never names the mechanism. Osei's version assumes the "why" is already
understood and gives the exact variable names and format string needed to
debug or modify it. Nia's version would be useless for fixing a bug in the
versioning logic; Osei's version would be tone-deaf in a board meeting.

## 3. What breaks first at 4 → 40 developers

The single shared Nexus credential used in the Publish stage. At four
developers, one shared `nexus-credentials` secret is a minor smell. At
forty, it becomes a real liability: no way to tell which team or service
published a given artifact, no way to revoke one team's publish access
without breaking everyone else's pipeline, and a much larger blast radius
if that one credential ever leaks. It would need to become per-service or
per-team scoped credentials in Nexus, provisioned through whatever secrets
manager the org standardizes on, with each Jenkinsfile referencing its own
narrowly-scoped credential ID rather than a single shared admin-level
account. The second thing likely to strain is the single Jenkins
controller itself running all builds on its built-in node — at forty
developers pushing regularly, that would need dedicated build agents
rather than everything running on the controller's own executors.
