# 6. Every change starts from a GitHub issue

Status: accepted

## Context

Most changes here are made by Claude Code agents in Agent of Empires
sessions, several at once in separate worktrees. Without a shared record,
an agent's definition of done is whatever it decided, and nothing checks
the result against the request.

## Decision

- Before changing a tracked file, an agent finds or creates an issue with a
  goal and checkable acceptance criteria (`start-work` skill).
- One branch and one PR per issue; the PR body says `Closes #<number>`.
- The `Linked issue` CI check fails any PR without an open linked issue.
  Renovate and other bot PRs are exempt.
- Before merging, the agent runs each acceptance criterion and posts the
  commands and results on the issue.
- There is no pre-commit hook. `mise run check` runs the CI gates locally,
  and CI enforces them.

## Consequences

- Every merged change has a written reason and recorded evidence.
- Small fixes carry the overhead of an issue.
