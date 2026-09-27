---
name: start-work
description: Start any change to this repo the issue-first way. Use before editing tracked files, when the user asks to fix, add, change, or refactor something, or when picking up an issue. Finds or creates the GitHub issue, creates the branch, opens the PR with Closes, and verifies the acceptance criteria before merge.
allowed-tools: Read, Bash, AskUserQuestion
---

# start-work

Every change to tracked files starts from a GitHub issue. The issue holds the
acceptance criteria that prove the work is done, and the `Linked issue` CI
check fails any PR that does not close one.

## 1. Find or create the issue

```bash
gh issue list --state open --search "<keywords>"
```

Reuse an open issue that already covers the work. Otherwise create one from
the task template, with a goal and checkable acceptance criteria:

```bash
gh issue create --title "<imperative summary>" --label task --body "$(cat <<'BODY'
## Goal
<what should be true, and why>

## Acceptance criteria
- [ ] <checkable statement naming the command or observation that proves it>
BODY
)"
```

Ask the user when the goal or the criteria are unclear. Do not guess them.

## 2. Branch

Fetch first, then branch from `origin/main`. Name the branch
`<type>/<issue-number>-<slug>`, where type is the conventional commit type:

```bash
git fetch origin
git switch -c fix/<number>-<slug> origin/main
```

## 3. Commit

Run `mise run check` before every commit. Use conventional commits with a
body that explains why. Never put `#<number>` in a commit message: the PR body
carries the link.

## 4. Open the PR

```bash
gh pr create --title "<conventional title>" --body "$(cat <<'BODY'
Closes #<number>

## What and why

## Verification
BODY
)"
```

## 5. Verify before merging

Run every acceptance criterion from the issue, then post the commands and
their results as a comment on the issue:

```bash
gh issue comment <number> --body "<evidence>"
```

Merge only when CI is green and every criterion has evidence. Merging the PR
closes the issue.
