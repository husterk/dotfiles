# Coding Preferences

- Follow existing project code style and conventions. Do not impose new patterns.
- Prefer minimal, focused changes. Do not refactor beyond what is asked.
- A pre-existing bug, performance problem, or gap you find along the way is a
  follow-up to report, not something to fix in this change, unless the
  requested behavior cannot work without it.
- Commit tests only where the task asks for them or the repo already keeps
  tests for this kind of change, sized like the neighboring test files. Scratch
  checks you ran to verify the work do not become permanent tests.
- Edit files surgically. Rewrite a whole file only when it is short or most of
  it is changing.
- Preserve all existing behavior when refactoring unless explicitly told otherwise.
- Code reviews: prioritize correctness, security, then maintainability.
- When fixing bugs, explain the root cause before applying the fix.

# Shell Commands Handed To Me

- Use absolute paths. Never rely on `cd`, and never chain `cd X && ...`.
  My `cd` is shimmed by zoxide (`zoxide init zsh --cmd cd`), which can exit
  non-zero and silently short-circuit the rest of the chain.
- Do not assume a plain shell. zsh with starship, zoxide, fzf, syntax
  highlighting and autosuggestions is loaded.
- Prefer commands that work in a non-interactive shell. mise has not activated
  there, so its shims are not on `PATH`. Use `mise exec -- <tool>` or an
  absolute path when the pinned version matters.

# Code Comments

Default to no comment. Self-describing code is the goal, and a clear name beats
a comment explaining an unclear one. If a comment is longer than the code it
describes, something is wrong: cut the comment or restructure the code.

Write a comment only for:

- Public API documentation, where the project already does it. Whatever
  convention that language uses: TSDoc on exported TypeScript, docstrings on
  Python, LuaLS annotations on Lua, doc comments on Rust or Go. If the
  surrounding code does not document its public surface, do not start.
- A non-obvious "why" the code cannot express. A workaround for a specific
  defect, a protocol or spec requirement, an ordering constraint, a measured
  performance tradeoff, or a deliberate deviation from convention.

Never write:

- A comment that restates the next line. Rename the thing instead.
- Issue keys, PR numbers, file paths, line numbers, or dates inside a comment.
  They go stale silently and then mislead both humans and agents. The commit
  body and PR description are the durable record for that context.
- A reference to another method or class by name unless the code cannot express
  the dependency. Renames break these without any warning.
- A note explaining a change you just made. That belongs in the commit body.
- Section-divider banners, ASCII art, or decorative separators in code. The
  banner comments already present in this repo's shell scripts are an existing
  convention; match a file that has them, do not add them to one that does not.
- Emoji. Never in code comments, in any language. A compiler, linter, or
  source-encoding step can misread them. This is the one place emoji are
  banned outright; elsewhere I use them freely.
- Commented-out code. Delete it. Git has it.

Also:

- When you touch code whose existing comment is now wrong, fix or delete that
  comment in the same change.
- Match the comment density of the surrounding file. Do not add comments to a
  file that has none.
- These rules govern whether a comment exists. When one is warranted, the prose
  rules in `communication.md` govern how it reads.
