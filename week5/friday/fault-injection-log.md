# Fault Injection Log

**Fill in the "Observed downstream behaviour" and "Verified" columns from
your own runs — the instructions column tells you exactly how to break each
stage and how to undo it.**

For each row: make the change, push (or trigger a build), capture the
Jenkins console output showing the failure, restore the file, and push again
to confirm the pipeline returns to green before moving to the next row.

| Stage | How to break it | Observed downstream behaviour (fill in from your run) | Why this is the correct design |
|---|---|---|---|
| **Lint** | In `src/index.js`, add a syntax error — e.g. remove a closing brace `}` from `calculateTotal`. Push. | *(paste what stages ran/skipped, and the exact ESLint error line from the console log)* | Lint fails first and every later stage is skipped — no time is spent building, testing, or publishing code that doesn't even parse cleanly. This is the fail-fast principle: cheap checks run before expensive ones. |
| **Build** | In `package.json`, change the `build` script to reference a directory that doesn't exist, e.g. `"build": "cp -r nonexistent/* dist/"`. Push. | *(paste which stages ran/skipped, and the shell error)* | Build fails and Verify/Archive/Publish never run — there is no artifact to test, package, or publish if the build step itself didn't produce one. |
| **Verify → Test** | In `test/index.test.js`, change an expected value so a test fails, e.g. `expect(calculateTotal(items)).toBe(999)`. Push. | *(paste: did Security Audit still run in parallel? did Archive/Publish get skipped?)* | The Test branch fails but Security Audit (the sibling parallel branch) still completes, since the two checks are independent — that's the point of running them in parallel rather than sequentially. The overall Verify stage still fails, so Archive/Publish are correctly skipped: an artifact that fails its tests should never reach the registry. |
| **Verify → Security Audit** | Temporarily add a devDependency with a known high-severity CVE (or pin an old vulnerable version of an existing dependency) in `package.json`, so `npm audit --audit-level=high` finds it. Push. | *(paste: did Test still run and pass? did the overall Verify stage fail?)* | Same logic as the Test branch failing: Security Audit failing independently still fails the overall parallel Verify stage and blocks Publish, without needing the Test branch to also fail — each branch is an independent gate on the same door. |
| **Publish** | Temporarily give the `nexus-credentials` Jenkins credential a wrong password (edit it in Jenkins, don't touch code). Push. | *(paste: did Lint/Build/Verify/Archive all succeed? did only Publish fail, and with what HTTP status from Nexus?)* | Everything up through Archive succeeds — the artifact was built, tested, and locally packaged correctly — and only the network/auth-dependent Publish step fails. This isolates infrastructure/credential problems from actual code-quality problems in the pipeline's reported failure point. |

## After completing all five rows

Confirm and note here: each fault was reverted and a subsequent run returned
the pipeline to green (paste the final green build number/timestamp for each).
