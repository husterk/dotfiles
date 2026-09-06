# Workflow Conventions

- Use conventional commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Include a commit body explaining the "why" behind changes.
- Keep commit bodies and PR descriptions brief. Include only what a human
  or AI reviewer needs to understand the change. No marketing prose, no
  exhaustive bullet list of what is already visible in the diff, no
  test-plan padding when the change is trivial.
- Prefer small, focused commits over large omnibus commits.
- Run the relevant test suite after making changes.
- Preserve existing code style when editing files.
- Do NOT add `Co-Authored-By: Claude <...>` trailers to commit messages.
- Do NOT add `🤖 Generated with [Claude Code]` footers to PR descriptions.
- Both of the above are also enforced by `attribution` in
  `~/.claude/settings.json` (`commit: ""`, `pr: ""`, `sessionUrl: false`).
  The two rules above state the intent; the setting is what actually holds when
  context is full. Do not delete that setting to "clean up" a duplicate.

# Branches and Pull Requests

- `git fetch origin` and confirm local `main` matches `origin/main` **before**
  creating a branch, rebasing onto main, or reasoning about what is already
  fixed. Local `main` goes stale between sessions, and building on a stale base
  silently reverts whatever landed in between.
- Re-fetch between consecutive merges, not just once at the start of a task.
- Some of my repositories protect `main` and reject direct pushes, including
  for admins. Branch and open a PR by default; do not reach for a direct push
  and then discover it is blocked.
- When a protected branch requires the PR to be up to date, a moved base means
  the branch needs updating before the merge unlocks. Update it rather than
  reporting the merge as blocked.

# Git Signing (1Password)

Commits are SSH-signed through the 1Password agent. 1Password locks whenever I
step away: lunch, a break, end of day, or the screen locking. This is routine
and frequent, not an incident.

When it is locked, agent reads still succeed and only the signature fails.
Recognize it from either signal:

- `Couldn't sign message (signer): communication with agent failed?` followed by
  `fatal: failed to write commit object`
- `ssh-add -l` lists the keys, but `ssh-keygen -Y sign` fails with
  `communication with agent failed`

Do not re-diagnose it. Checking whether 1Password is running, whether
`SSH_AUTH_SOCK` is set, or whether the signing key exists is wasted effort,
because all three look healthy while it is locked.

What to do:

- Say in one line that 1Password needs my fingerprint, then stop and wait.
  Do not retry in a loop.
- Leave the work staged. A failed commit leaves the index intact.
- Never work around it with `--no-gpg-sign` or `-c commit.gpgsign=false`.
  Signing is deliberate. Ask if you think an exception is warranted.
- When I say it is unlocked, retry the same commit unchanged.
- A `git push` can report success while the commit never happened, leaving the
  remote branch at the old tip. Confirm with `git log` before reporting a push.
