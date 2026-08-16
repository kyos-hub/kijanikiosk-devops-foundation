# KijaniKiosk Payments: How Code Becomes a Trusted Release

Prepared for Nia, for the board review.

## Why this matters

Every time a developer changes the payments code, that change needs to be checked before it becomes part of what we actually run. This week we built an automated process that does exactly that: it takes a developer's change, runs it through a series of checks, and only if every check passes does it produce a numbered, traceable release. No one has to remember to run the checks by hand, and no change reaches a trusted release without passing all of them.

## What happens, step by step

When a developer saves a change to our shared codebase, the process below starts automatically, with no one needing to trigger it manually.

| Stage | What it confirms |
|---|---|
| Style Check | The code follows our agreed formatting and coding conventions |
| Build | The code actually compiles into a working package |
| Test & Security Check (run together) | The code behaves correctly, and no component it depends on has a known security weakness |
| Package | A single, labeled file is produced containing exactly what was built, with a unique fingerprint |
| Publish | That labeled file is stored in our internal release library, permanently and traceably |

Each stage only runs if the one before it succeeded, except for Test and the Security Check, which run side by side since neither depends on the other's result — this cuts the total time roughly in half without skipping either check.

Every release that comes out the other end has a version label made of two parts: a human-readable number, and the exact code change it came from. That second part means we can always answer "what code is actually running in production right now" with certainty, not a guess.

## What happens when something goes wrong

If a change fails any check, the process stops at that point and nothing further happens. A change that fails the style check never gets built. A change that fails to build never gets tested. A change that fails testing or the security check never gets packaged or released. The failure is recorded with enough detail to show exactly what went wrong and at which step, and the person who made the change is the one notified — not the whole team, and not after a delay.

Just as important: a broken change never overwrites or replaces a working release. Whatever was last successfully released stays exactly as it was, available and trusted, until a fixed change comes through the same process and passes every check on its own. Nothing goes into our release library by accident, and nothing goes in half-checked.

Because Test and the Security Check run side by side, it's possible for one to fail while the other still finishes and reports a clean result. Even so, the release is still blocked — passing only one of the two checks is not enough. Both must pass.

## What this does not yet do

This process confirms that a change is well-formed, passes our tests, and has no known security weaknesses at the time it's built — it does not yet deploy that release anywhere. Turning a trusted release into something running and serving real traffic is a separate, later step, and today's process stops once the release is safely stored. It also does not yet watch the running application after release, so if a problem only shows up under real customer usage rather than in our tests, this process alone will not catch it. And right now, one person's set of access keys is used to publish releases; as the team grows, that will need to move to a more carefully scoped, per-person or per-service arrangement rather than a single shared credential.
