#!/usr/bin/env bats
# Every host manifest must point at modules and dotfiles that exist, and every
# app directory must be used by some host; an orphan is dead code.

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

manifests() {
  git ls-files 'hosts/*/host-manifest.toml'
}

@test "at least one host manifest exists" {
  [ -n "$(manifests)" ]
}

@test "every module path in every manifest exists" {
  missing=()
  for manifest in $(manifests); do
    while IFS= read -r module; do
      [ -f ".${module}" ] || missing+=("$manifest: $module")
    done < <(yq -p toml -o yaml '(.system.modules // [])[], (.apps[].modules // [])[]' "$manifest")
  done
  printf '%s\n' "${missing[@]}"
  [ "${#missing[@]}" -eq 0 ]
}

@test "every dotfile source directory in every manifest exists" {
  missing=()
  for manifest in $(manifests); do
    while IFS= read -r source; do
      base="${source%%\**}"
      [ -e ".${base}" ] || missing+=("$manifest: $source")
    done < <(yq -p toml -o yaml '.apps[] | select(.dotfiles != null) | .dotfiles[].source' "$manifest")
  done
  printf '%s\n' "${missing[@]}"
  [ "${#missing[@]}" -eq 0 ]
}

@test "every app directory is referenced by some manifest" {
  referenced="$(for manifest in $(manifests); do
    yq -p toml -o yaml '(.apps[].modules // [])[]' "$manifest"
  done | awk -F/ '{print $3}' | sort -u)"
  orphans=()
  for dir in apps/*/; do
    name="$(basename "$dir")"
    grep -qx "$name" <<< "$referenced" || orphans+=("$name")
  done
  printf 'orphan: %s\n' "${orphans[@]}"
  [ "${#orphans[@]}" -eq 0 ]
}
