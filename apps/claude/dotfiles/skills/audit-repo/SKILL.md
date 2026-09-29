---
name: audit-repo
description: Audit one of husterk's GitHub repositories against the account baseline in husterk/.github, or set up a new repository to meet it. Use when asked to audit, harden or check a repo under husterk, to create a new husterk repo, or to compare a repo's settings, rulesets, Actions policy, Renovate config or templates with the standard.
---

# Audit a husterk repository

The baseline lives in the public repository `husterk/.github`, cloned at
`~/git-repos/.github`:

| Path                                                                                       | Use                                                                                |
| ------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| `~/git-repos/.github/docs/public-repos.md` and `~/git-repos/.github/docs/private-repos.md` | The rules, with the command that sets and verifies each one                        |
| `~/git-repos/.github/scripts/audit-repo.sh`                                                | Read-only check of one repository, run through `mise run audit`                    |
| `~/git-repos/.github/templates/`                                                           | Rulesets, Renovate config, the PR policy workflow and a CLAUDE.md skeleton to copy |
| `~/git-repos/.github/renovate/` and `~/git-repos/.github/actions/linked-issue/`            | Shared presets and the linked-issue action, consumed by release tag                |

## Steps

1. Update the local clone, or make one:

    ```bash
    git -C ~/git-repos/.github pull --ff-only || git clone git@github.com:husterk/.github.git ~/git-repos/.github
    ```

2. Run the audit. It only reads, and exits 1 on any FAIL:

    ```bash
    mise -C ~/git-repos/.github run audit -- husterk/<repo>
    ```

3. For every FAIL and WARN, read the matching section of the guide for the
   repository's visibility. A WARN the repository skips on purpose needs a
   line in its `CLAUDE.md` with the reason, not a fix.
4. Open issues **in the audited repository**, grouped by fix, each with
   checkable acceptance criteria and the recommended fix. Follow that
   repository's own issue conventions (milestones, label scheme).
5. When fixing, copy from `~/git-repos/.github/templates/` and pin to the latest
   release:

    ```bash
    tag=$(gh release view --repo husterk/.github --json tagName -q .tagName)
    git ls-remote https://github.com/husterk/.github "refs/tags/$tag^{}"   # SHA for the action
    ```

    Presets pin the tag (`github>husterk/.github//renovate/default#<tag>`).
    The action pins the SHA with the tag in a comment.

6. Re-run the audit after the fixes merge and post the output on the issue.

## Rules

- `husterk/.github` is public. Never write audit findings, private
  repository names, vault paths or other private detail into it, in files,
  issues or commit messages.
- Settings, rulesets and Actions policy change through the API only after
  the audited repository has an issue for them.
- On a private repository, the Actions allowlist and SHA-pinning rules are
  still unproven. Test one change at a time and roll back if CI stops.
