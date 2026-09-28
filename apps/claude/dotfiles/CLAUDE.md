# Before Starting Work

- If the request is unambiguous, just do it. No preamble, no confirmation ritual.
- If it is ambiguous, spans multiple files or systems, or has more than one
  reasonable reading: state your understanding in 1-3 lines, ask only the
  questions whose answers would change what you build, then stop and wait.
- Ask about decisions that change the output. Do not ask about things you can
  verify yourself, or where a conventional default clearly applies.
- Loop if needed. If my answer is still ambiguous, ask again rather than guessing.
- `just do it` or `go` = skip clarification, use your best judgment.
- `spec it` = clarify fully, even if the request looks obvious.
- Naming your interpretation before you start is a correctness step, not
  narration. It outranks brevity rules. A few lines is enough.
- When you need a decision from me, state your recommended reading and ask me
  to correct it. Use a multiple-choice prompt only when the options are
  genuinely exhaustive.
- On a multi-part request, say which parts you are not doing and why. Do not
  quietly drop one.

# Claims and Evidence

Distinguish what you proved from what you assumed, whenever a claim is
load-bearing, untested, or something I might act on:

- `Verified:` you ran it, read it, or tested it. Say how.
- `Reported:` a person asserted it and you have not checked. Name who, or say
  the source is unidentified. Not `Inferred:`, which credits your reasoning for
  someone else's assertion, and not `Unknown:`, which says nothing was offered.
- `Inferred:` reasoning only. Say what you did not check.
- `Unknown:` you do not know. Say so instead of filling the gap.

Rules:

- Never state an inference in the grammar of a fact.
- "Should work", "this will fix it", "tests should pass" are inferences unless
  you actually ran them. Either run them or label them.
- If you did not run the tests, say you did not run the tests.
- Skip the labels on the obvious. They are for claims I might act on, not
  decoration.
- Evidence you did not gather yourself is not verified. Subagent reports, tool
  and MCP results, docs and web pages are `Inferred:` until you check the
  primary source. The built-in Explore and Plan agents never load this file, so
  their findings arrive with no labels at all.
- A tool result that summarizes is not the source. When exact content matters,
  fetch the raw file.
- If your evidence contradicts something I told you, check whether you verified
  the right artifact before concluding I am wrong.
- Match verification effort to what the claim costs if wrong. A detail already
  very likely correct does not need a deep dig. State it, label it, move on.
  Burning a long time proving something low-stakes is its own failure. Judgment
  plus an honest label beats exhaustive checking.
- When you delegate work that will produce prose or code, restate the relevant
  constraint inside the delegation prompt. Explore and Plan load none of this
  file, and no subagent inherits the output style.

# Environment

- macOS on Apple silicon. Declaratively managed: Nix-darwin for packages,
  mise for repo-local tooling and task running, GNU Stow for dotfile
  deployment, 1Password for secrets. The source of truth is
  `~/git-repos/dotfiles`, which has its own `CLAUDE.md` covering its rules.
- **zsh is the login shell**, with starship, zoxide, fzf, syntax highlighting
  and autosuggestions. nushell is installed but secondary. Do not assume a bare
  POSIX shell.
- WezTerm is the terminal, with tmux inside it (`TERM_PROGRAM=tmux`), which is
  what decides how OSC 8 hyperlinks and color actually render.
- Editors: Neovim and VS Code.
- Nix owns system-wide binaries under `/run/current-system/sw/bin`. mise owns
  repo-local pinned tools via shims in `~/.local/share/mise/shims`. A tool can
  exist in both at different versions. When a version matters, check which one
  is actually resolving before drawing a conclusion.
- Language runtimes come from mise, not from Homebrew or a system install.
  Prefer `mise exec -- <tool>` when you need the pinned version in a
  non-interactive shell, because mise has not activated there.
- `gh` is authenticated and is the way to touch GitHub: PRs, issues, checks,
  branch protection.
- `shellcheck` lints sh/bash/dash/ksh. It cannot parse zsh and exits `SC1071`,
  so validate zsh with `zsh -n` instead. `statix` lints Nix, `treefmt` drives
  every formatter.
- Git commits are SSH-signed through the 1Password agent. See
  `rules/workflows.md` for what a locked vault looks like and what to do.
- Every session runs inside an Agent of Empires (AoE) managed session. Always.
  Never assume a bare `claude` invocation. AoE already places each session in
  its own git worktree, so spawning a subagent with `isolation: "worktree"`
  nests a worktree inside a worktree. Prefer plain subagents unless parallel
  file mutation genuinely requires isolation.
- The hook blocks tagged `# aoe-hooks` in `~/.claude/settings.json` are owned
  and regenerated by aoe. Do not hand-edit them. Never set
  `disableAllHooks: true`; it would blind the AoE status view.
- `~/.claude/settings.json` is a regular file, not a Stow symlink. The
  dotfiles repo owns the keys in `apps/claude/settings.base.json` and merges
  them in on `mise run refresh`; every other key, including `hooks` and
  `modelSettings`, stays as Claude Code and aoe wrote it. Change a repo-owned
  setting in the base file, not in the live file.

# Rules

Three files load with every session and are authoritative:

| File                     | Governs                                                    |
| ------------------------ | ---------------------------------------------------------- |
| `rules/communication.md` | All prose you write: replies, commits, PRs, docs, comments |
| `rules/preferences.md`   | Code style, comments, and shell commands handed to me      |
| `rules/workflows.md`     | Commits, PRs, git signing, and test discipline             |
