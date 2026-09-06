#!/usr/bin/env bash
set -euo pipefail

# Check that tools provided by BOTH mise and Nix agree on a version
#
# A few tools are deliberately installed twice:
#   • mise  - pinned in mise.toml, on PATH inside this repo (via mise shims)
#   • Nix   - declared in apps/<name>/<name>.nix, on PATH everywhere else
#
# When the two drift you silently get a different binary depending on your
# working directory. Neovim hit exactly this: the mise pin held 0.11.6 inside
# the repo while Nix had already moved the system editor to 0.12.5.
#
# Renovate only sees the mise side, so nothing upstream catches the drift.

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

# Where nix-darwin puts system packages. Absent on CI and non-darwin machines.
NIX_BIN="${NIX_BIN:-/run/current-system/sw/bin}"

# Tools present in both managers.
#   <mise.toml key>|<binary name>|<apps/ module declaring the Nix side>
DUAL_MANAGED=(
  "aqua:neovim/neovim|nvim|apps/neovim/neovim.nix"
  "jq|jq|apps/claude/claude.nix"
  "op|op|apps/1password/1password.nix"
)

echo "🔍 Checking mise/Nix tool version sync..."
echo ""

if [ ! -d "$NIX_BIN" ]; then
  echo "⚠️  $NIX_BIN not found - skipping (not a nix-darwin machine)"
  gha_summary_heading "mise/Nix tool sync"
  gha_summary "⏭️ Skipped - \`$NIX_BIN\` is absent, so there is no Nix side to compare against. This gate only runs on a nix-darwin machine."
  exit 0
fi

if ! command -v mise &> /dev/null; then
  echo "❌ mise is required but not on PATH"
  exit 1
fi

# Extract the first dotted version number from a --version banner.
# Handles "NVIM v0.12.5", "jq-1.8.2", "2.39.0" alike.
extract_version() {
  grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1
}

mise_versions="$(mise ls --current --json | jq -r \
  'to_entries[] | "\(.key)\t\(.value[0].requested_version // .value[0].version)"')"

gha_summary_heading "mise/Nix tool sync"
gha_summary_table "" "Tool" "mise" "Nix" "Nix module"

drift=0
checked=0

for entry in "${DUAL_MANAGED[@]}"; do
  IFS='|' read -r mise_key binary nix_module <<< "$entry"

  nix_bin="$NIX_BIN/$binary"
  if [ ! -x "$nix_bin" ]; then
    echo "  ⏭️  $binary - not in the Nix profile, skipping"
    continue
  fi

  mise_version="$(printf '%s\n' "$mise_versions" | awk -F'\t' -v k="$mise_key" '$1 == k { print $2 }')"
  if [ -z "$mise_version" ]; then
    echo "  ⏭️  $binary - not pinned in mise.toml, skipping"
    continue
  fi

  nix_version="$("$nix_bin" --version 2>&1 | extract_version || true)"
  if [ -z "$nix_version" ]; then
    echo "  ⚠️  $binary - could not parse a version from '$nix_bin --version'"
    continue
  fi

  checked=$((checked + 1))

  if [ "$mise_version" = "$nix_version" ]; then
    printf '  ✅ %-8s mise=%-10s nix=%-10s\n' "$binary" "$mise_version" "$nix_version"
    gha_summary_row "✅" "\`$binary\`" "$mise_version" "$nix_version" "\`$nix_module\`"
  else
    gha_summary_row "❌" "\`$binary\`" "**$mise_version**" "**$nix_version**" "\`$nix_module\`"
    gha_error "$binary: mise pins $mise_version but Nix provides $nix_version" "mise.toml"
    printf '  ❌ %-8s mise=%-10s nix=%-10s  DRIFT\n' "$binary" "$mise_version" "$nix_version"
    echo "       mise pin: mise.toml ($mise_key)"
    echo "       nix side: $nix_module"
    drift=$((drift + 1))
  fi
done

echo ""

if [ "$drift" -eq 0 ]; then
  echo "✅ All $checked dual-managed tool(s) in sync!"
  gha_summary_result ok "All $checked dual-managed tool(s) in sync"
else
  gha_summary_result fail "$drift of $checked dual-managed tool(s) have drifted"
  echo "❌ $drift of $checked dual-managed tool(s) have drifted"
  echo ""
  echo "The Nix side follows nixpkgs and moves with 'mise run nix:update'."
  echo "Align the mise pin in mise.toml to match, then run 'mise lock'."
  exit 1
fi
