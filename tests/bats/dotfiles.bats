#!/usr/bin/env bats
# Round trip through the dotfile pipeline on a throwaway copy of the repo:
# host-vars.toml -> .env -> rendered dotfile -> edit -> capture -> template.

setup() {
  repo="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$repo"
  (cd "$BATS_TEST_DIRNAME/../.." && git ls-files -z | rsync -a --from0 --files-from=- ./ "$repo/")
  git -C "$repo" init -q

  host="$repo/hosts/test-host"
  mkdir -p "$host" "$repo/apps/test-app/dotfiles"
  cat > "$host/host-vars.toml" << 'TOML'
PATH_USERS = "/Users"
USER_EMAIL = "tester@example.com"
USER_FIRST_NAME = "Test"
USER_LAST_NAME = "User"
USER_USERNAME = "tester"
TOML
  cat > "$host/host-manifest.toml" << 'TOML'
[config]
bootstrap-target = "macos-arm64"
home-dir = "${PATH_USERS}/${USER_USERNAME}"

[system]
modules = []

[[apps]]
modules = []
name = "test-app"
[[apps.dotfiles]]
source = "/apps/test-app/dotfiles/**/*"
target = "~/.config/test-app/"
TOML
  printf 'email = ${USER_EMAIL}\nname = static\n' > "$repo/apps/test-app/dotfiles/config"
  git -C "$repo" add -A
  scripts="$repo/bootstrap-scripts/macos-arm64"
  rendered="$host/generated/dotfiles/.config/test-app/config"
}

generate() {
  bash "$scripts/generate-env.sh" test-host < /dev/null
  FORCE_OVERWRITE=true bash "$scripts/generate-dotfiles.sh" test-host < /dev/null
}

@test "generate-env renders host-vars.toml into a sourceable .env" {
  run bash "$scripts/generate-env.sh" test-host < /dev/null
  [ "$status" -eq 0 ]
  # shellcheck disable=SC1091
  (source "$host/generated/.env" && [ "$USER_EMAIL" = "tester@example.com" ])
}

@test "generate-dotfiles substitutes variables and maps the target path" {
  generate
  [ -f "$rendered" ]
  grep -qx 'email = tester@example.com' "$rendered"
  grep -qx 'name = static' "$rendered"
}

@test "capture turns an edited value back into its placeholder" {
  generate
  printf 'email = tester@example.com\nname = changed\n' > "$rendered"
  run bash "$scripts/capture-dotfiles.sh" test-host < /dev/null
  [ "$status" -eq 0 ]
  grep -qx 'email = ${USER_EMAIL}' "$repo/apps/test-app/dotfiles/config"
  grep -qx 'name = changed' "$repo/apps/test-app/dotfiles/config"
}

@test "capture leaves a value literal where the template never used its placeholder" {
  printf 'email = ${USER_EMAIL}\nhome = /Users/shared\n' > "$repo/apps/test-app/dotfiles/config"
  git -C "$repo" add -A
  generate
  printf 'email = tester@example.com\nhome = /Users/shared\nname = new\n' > "$rendered"
  run bash "$scripts/capture-dotfiles.sh" test-host < /dev/null
  [ "$status" -eq 0 ]
  grep -qx 'email = ${USER_EMAIL}' "$repo/apps/test-app/dotfiles/config"
  grep -qx 'home = /Users/shared' "$repo/apps/test-app/dotfiles/config"
}

@test "deploy links rendered files into HOME and prune removes a link whose source left" {
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME"
  printf 'x = 1\n' > "$repo/apps/test-app/dotfiles/extra"
  git -C "$repo" add -A
  generate
  run bash "$scripts/deploy-dotfiles.sh" test-host < /dev/null
  [ "$status" -eq 0 ]
  [ -L "$HOME/.config/test-app/config" ]
  [ -L "$HOME/.config/test-app/extra" ]
  grep -qx 'email = tester@example.com' "$HOME/.config/test-app/config"

  rm "$repo/apps/test-app/dotfiles/extra"
  git -C "$repo" add -A
  generate
  run bash "$scripts/deploy-dotfiles.sh" test-host < /dev/null
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.config/test-app/extra" ]
  [ ! -L "$HOME/.config/test-app/extra" ]
  [ -L "$HOME/.config/test-app/config" ]
}
