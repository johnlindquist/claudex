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
CLAUDEX_INSTALLED_TEST=1 CLAUDEX_RUN_LIVE=0 \
  "$CLAUDEX_TEST_BREW_PREFIX/bin/claudexctl" test
"$CLAUDEX_TEST_BREW_PREFIX/bin/claudexctl" uninstall

printf 'PASS installed claudexctl test command\n'
