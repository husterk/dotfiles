# VSCode Setup Guide

Minimal setup for this dotfiles repository using a custom VSCode profile.

## Prerequisites

**⚠️ CRITICAL**: Always open this project from the terminal so VSCode inherits the dev shell environment:

```bash
cd ~/git-repos/dotfiles
code .
```

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

### 4. Decline nil Installation

When **Nix IDE** prompts to install `nil`, click **"Don't show again"**.

_You already have nil in your dev shell. VSCode will find it automatically._

### 5. Reload Window

**Cmd+Shift+P** → `Developer: Reload Window`

### 6. Sign In to GitHub Copilot (Optional)

**Cmd+Shift+P** → `GitHub Copilot: Sign In`

## What's Included

**Extensions:**

-   GitHub Copilot (AI assistance)
-   Nix IDE (Nix language support)
-   ShellCheck + Shell Format (shell scripts)
-   YAML, Markdown, Task, EditorConfig, GitLens, Error Lens, 1Password, Todo Tree

**Auto-formatting on save:**

-   Nix files → nixpkgs-fmt
-   Shell scripts → shfmt

**Manual formatting via Task:**

```bash
task dev:format        # Format all files
task dev:format-yaml   # YAML with yq
task dev:format-json   # JSON with jq
```

## Troubleshooting

**Nix LSP not working?**

1. Close VSCode
2. Open terminal: `cd ~/git-repos/dotfiles`
3. Launch VSCode: `code .`
4. Verify: `which nil` (should show `/nix/store/.../bin/nil`)

**Profile not switching?**
**Cmd+Shift+P** → `Profiles: Use Profile for Current Workspace` → Select "Dotfiles"

**Extensions not installing?**
Manually install via Extensions sidebar (**Cmd+Shift+X**) or see [extensions.json](.vscode/extensions.json) for the list.

**Note**: This installs extensions in your default profile. Using a custom profile is recommended to keep your default profile clean.

## Additional Resources

-   [VSCode Profiles Documentation](https://code.visualstudio.com/docs/editor/profiles)
-   [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
-   [Nix IDE Extension](https://marketplace.visualstudio.com/items?itemName=jnoortheen.nix-ide)
-   [nil Language Server](https://github.com/oxalica/nil) (provided by your dev shell)
