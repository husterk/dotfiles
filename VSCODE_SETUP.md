# VSCode Setup Guide

Minimal setup for this dotfiles repository using a custom VSCode profile.

## Prerequisites

**⚠️ CRITICAL**: Always open this project from the terminal so VSCode inherits the mise environment:

```bash
cd ~/git-repos/dotfiles
code .
```

**Note**: mise should be activated automatically when you `cd` into this directory (configured in your shell rc file).

## Setup Steps

### 1. Create Custom Profile

1. **Cmd+Shift+P** → `Profiles: Create Profile`
2. Choose **"Create from Current Profile"** or **"Create Empty Profile"**
3. Name it: `Dotfiles`

### 2. Associate Profile with Workspace

1. **Cmd+Shift+P** → `Profiles: Use Profile for Current Workspace`
2. Select: **"Dotfiles"**

### 3. Install Extensions

When prompted "This workspace has extension recommendations", click **"Install All"**.

If no prompt: **Cmd+Shift+P** → `Extensions: Show Recommended Extensions` → **"Install All Workspace Recommendations"**

### 4. Decline LSP Installation (if prompted)

When **Nix IDE** or other extensions prompt to install language servers, click **"Don't show again"**.

_You already have language servers installed via mise. VSCode will find them automatically._

### 5. Reload Window

**Cmd+Shift+P** → `Developer: Reload Window`

### 6. Sign In to GitHub Copilot (Optional)

**Cmd+Shift+P** → `GitHub Copilot: Sign In`

## What's Included

**Extensions:**

- GitHub Copilot (AI assistance)
- Nix IDE (Nix language support)
- ShellCheck + Shell Format (shell scripts)
- YAML, Markdown, Task, EditorConfig, GitLens, Error Lens, 1Password, Todo Tree

**Formatting:**

Format-on-save is disabled. Use mise tasks instead:
**Note**: Formatting is also automatically applied by pre-commit hooks.

```bash
mise run dev:format     # Format all files
```

Or let the pre-commit hook auto-format when you commit.

**Pre-commit hooks:**

Automatically installed by mise and run on `git commit`:

- `mise run dev:format` (auto-fixes formatting)
- `mise run dev:lint` (checks code quality)

Skip with: `SKIP=1 git commit` or `git commit --no-verify`

## Troubleshooting

**Language servers not working?**

1. Close VSCode
2. Open terminal: `cd ~/git-repos/dotfiles`
3. Verify mise is activated: `mise doctor`
4. Launch VSCode: `code .`
5. Verify tools are available: `which shellcheck yq jq`

**Profile not switching?**
**Cmd+Shift+P** → `Profiles: Use Profile for Current Workspace` → Select "Dotfiles"

**Extensions not installing?**
Manually install via Extensions sidebar (**Cmd+Shift+X**) or see [extensions.json](.vscode/extensions.json) for the list.

**Note**: This installs extensions in your default profile. Using a custom profile is recommended to keep your default profile clean.

## Additional Resources

- [mise Documentation](https://mise.jdx.dev/)
- [VSCode Profiles Documentation](https://code.visualstudio.com/docs/editor/profiles)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [Nix IDE Extension](https://marketplace.visualstudio.com/items?itemName=jnoortheen.nix-ide)
