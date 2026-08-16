# Fault Injection Log

**Fill in the "Observed downstream behaviour" and "Verified" columns from
your own runs — the instructions column tells you exactly how to break each
stage and how to undo it.**

For each row: make the change, push (or trigger a build), capture the
Jenkins console output showing the failure, restore the file, and push again
to confirm the pipeline returns to green before moving to the next row.

| Stage | How to break it | Observed downstream behaviour (fill in from your run) | Why this is the correct design |
|---|---|---|---|
| **Lint** | In `src/index.js`, add a syntax error — e.g. remove a closing brace `}` from `calculateTotal`. Push. | Lint failed with `Parsing error: Unexpected token }` (1 error). Build, Verify (Test and Security Audit branches), Archive, and Publish all skipped — each logged "skipped due to earlier failure(s)". Pipeline FAILURE at build #7 in ~2m10s. | Lint fails first and every later stage is skipped — no time is spent building, testing, or publishing code that doesn't even parse cleanly. This is the fail-fast principle: cheap checks run before expensive ones. |
| **Build** | In `package.json`, change the `build` script to reference a directory that doesn't exist, e.g. `"build": "cp -r nonexistent/* dist/"`. Push. | Build failed with `cp: can't stat 'nonexistent/*': No such file or directory`. Verify (Test and Security Audit branches), Archive, and Publish all skipped — logged "skipped due to earlier failure(s)". Pipeline FAILURE at build #8, total time ~1m26s. | Build fails and Verify/Archive/Publish never run — there is no artifact to test, package, or publish if the build step itself didn't produce one. |
| **Verify → Test** | In `test/index.test.js`, change an expected value so a test fails, e.g. `expect(calculateTotal(items)).toBe(999)`. Push. | Test branch failed: `expect(received).toBe(expected) // Expected: 999, Received: 250` (1 of 5 tests failed). Security Audit branch still ran to completion in parallel (npm audit report generated normally) despite Test failing. Overall Verify stage failed, so Archive and Publish were both skipped — "skipped due to earlier failure(s)". Pipeline FAILURE at build #11. | The Test branch fails but Security Audit (the sibling parallel branch) still completes, since the two checks are independent — that's the point of running them in parallel rather than sequentially. The overall Verify stage still fails, so Archive/Publish are correctly skipped: an artifact that fails its tests should never reach the registry. |
| **Verify → Security Audit** | Temporarily add a devDependency with a known high-severity CVE (or pin an old vulnerable version of an existing dependency) in `package.json`, so `npm audit --audit-level=high` finds it. Push. | Security Audit branch failed: pinning lodash@4.17.4 surfaced a critical Prototype Pollution CVE (GHSA-fvqr-27wr-82fm, plus 9 other advisories), tripping `npm audit --audit-level=high`. Test branch still ran to completion in parallel and passed all 5 tests despite Security Audit failing. Overall Verify stage failed, so Archive and Publish were both skipped. Pipeline FAILURE at build #13. | Same logic as the Test branch failing: Security Audit failing independently still fails the overall parallel Verify stage and blocks Publish, without needing the Test branch to also fail — each branch is an independent gate on the same door. |
| **Publish** | Temporarily give the `nexus-credentials` Jenkins credential a wrong password (edit it in Jenkins, don't touch code). Push. | *(paste: did Lint/Build/Verify/Archive all succeed? did only Publish fail, and with what HTTP status from Nexus?)* | Everything up through Archive succeeds — the artifact was built, tested, and locally packaged correctly — and only the network/auth-dependent Publish step fails. This isolates infrastructure/credential problems from actual code-quality problems in the pipeline's reported failure point. |

## After completing all five rows

Confirm and note here: each fault was reverted and a subsequent run returned
the pipeline to green (paste the final green build number/timestamp for each).
