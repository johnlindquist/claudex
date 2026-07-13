#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

tmp="$(new_tmp)"
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$tmp/config"
export CLAUDEX_TEST_MODE=1
export CLAUDEX_TEST_BREW_PREFIX="$tmp/brew"
export CLAUDEX_TEST_FORMULA_PREFIX="$tmp/formula"
mkdir -p "$HOME" "$CLAUDEX_TEST_FORMULA_PREFIX/bin"

bash "$project_root/install.sh" --from-checkout --no-login
bash "$project_root/install.sh" --from-checkout --no-login

[[ -x "$XDG_CONFIG_HOME/claudex/bin/claudex" ]] || fail 'wrapper was not installed'
[[ -L "$CLAUDEX_TEST_BREW_PREFIX/bin/claudex" ]] || fail 'wrapper link was not installed'
jq -e '.permissions.defaultMode == "bypassPermissions" and .effortLevel == "medium"' \
  "$XDG_CONFIG_HOME/claudex/settings.json" >/dev/null
jq -e '.formulaPreexisting == false and .configPreexisting == false' \
  "$XDG_CONFIG_HOME/claudex/install-state.json" >/dev/null \
  || fail 'reinstall lost original proxy ownership state'

bash "$XDG_CONFIG_HOME/claudex/uninstall.sh"
[[ ! -e "$XDG_CONFIG_HOME/claudex" ]] || fail 'install root remains after uninstall'
[[ ! -e "$CLAUDEX_TEST_BREW_PREFIX/bin/claudex" ]] || fail 'wrapper link remains after uninstall'

printf 'PASS hermetic install, reinstall, and uninstall\n'
