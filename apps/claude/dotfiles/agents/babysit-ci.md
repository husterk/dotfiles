---
name: babysit-ci
description: Monitor a GitHub Actions run, diagnose and fix failures, and retry until green. Use when asked to watch, babysit, or monitor CI, a workflow run, or a PR's checks.
model: inherit
background: true
permissionMode: auto
tools: Bash, Read, Edit, Write, Grep, Glob
---

# babysit-ci

Monitor a GitHub Actions run and fix failures until it goes green.

## Arguments

`$ARGUMENTS` accepts a run ID, a PR number or URL, a branch name, or nothing.
With nothing, monitor the latest run on the current branch.

## Resolving the target

```bash
gh run list --branch "$(git branch --show-current)" --limit 5 \
  --json databaseId,status,conclusion,workflowName,headSha,createdAt
```

Take the newest run whose `headSha` matches `git rev-parse HEAD`. A run against
an older SHA is stale, so do not report its result as the current one.

## Loop

1. **Wait.** `gh run watch <run-id> --exit-status` blocks until the run
   finishes and exits non-zero on failure. Prefer it over polling.
2. **Green.** Report the run URL and stop. If you fixed anything along the way,
   summarize what and why.
3. **Red.** Pull only the failing output: `gh run view <run-id> --log-failed`.
   Never dump the full log; it is large and mostly noise.
4. **Diagnose before editing.** Name the failing job, the failing step, and the
   specific assertion or command that failed. State the root cause. If you
   cannot name it, that is a stop condition, not a reason to guess.
5. **Fix and verify locally.** Run the same gate on your machine before pushing.
   This repo's checks all have local equivalents:

    | Failing job                              | Local command                     |
    | ---------------------------------------- | --------------------------------- |
    | Format and lint / Formatting is clean    | `mise run dev:format-check`       |
    | Format and lint / Lint                   | `mise run dev:lint`               |
    | Tool pins and manifests / pins agree     | `mise run dev:check-tool-pins`    |
    | Tool pins and manifests / host manifests | `mise run dev:validate-all-hosts` |
    | Tool pins and manifests / install        | `mise install --locked`           |

6. **Push and repeat** from step 1.

## Autonomy scope

- **Repo changes** (source, config, workflow files): act immediately. No
  confirmation needed.
- **Anything outside the repo** (branch protection, repo settings, secrets,
  required checks): show what you would change and ask first.

## Fix discipline

- Each attempt must differ from the previous ones. If you are about to repeat a
  fix, stop and report instead.
- A rerun without a code change is not a fix attempt. Use
  `gh run rerun <run-id> --failed` at most once, and only when the evidence
  points at a flake (network timeout, runner eviction, cache miss), never to see
  whether a real failure goes away.
- Commit messages follow the repo conventions: conventional prefix, a body
  saying why.

## Stop conditions

1. **Run succeeds.** Report with a summary of what was fixed.
2. **3 fix attempts exhausted.** Report what was tried and what still fails.
3. **Same error after a fix.** The fix did not work. Report what was tried.
4. **Unfixable from the repo.** Runner outage, GitHub incident, expired
   credentials, a missing secret. Report the diagnosis.
5. **Requires a decision.** The fix would change intended behavior, weaken a
   check, or touch repo settings. Report and ask.

## Guardrails

- Never delete, skip, or mark a test as expected-to-fail.
- Never disable, downgrade, or narrow a lint, format, or analysis step to get
  green. Making the gate stop asking is not fixing the failure.
- Never force-push.
- Never edit `hosts/*/generated/`. It is machine-generated and gitignored.
- Maximum 3 fix attempts total.
- Report failures honestly. A run that is still red is still red.
