#!/usr/bin/env bash

claudex_die() {
  printf 'claudex: %s\n' "$*" >&2
  exit 1
}

claudex_note() {
  printf 'claudex: %s\n' "$*"
}

claudex_config_home() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

claudex_install_root() {
  printf '%s/claudex\n' "$(claudex_config_home)"
}

claudex_brew_prefix() {
  if [[ -n "${CLAUDEX_TEST_BREW_PREFIX:-}" ]]; then
    printf '%s\n' "$CLAUDEX_TEST_BREW_PREFIX"
  else
    brew --prefix
  fi
}

claudex_proxy_formula_prefix() {
  if [[ -n "${CLAUDEX_TEST_FORMULA_PREFIX:-}" ]]; then
    printf '%s\n' "$CLAUDEX_TEST_FORMULA_PREFIX"
  else
    brew --prefix cliproxyapi
  fi
}

claudex_proxy_config() {
  printf '%s/etc/cliproxyapi.conf\n' "$(claudex_brew_prefix)"
}

claudex_proxy_bin() {
  printf '%s/bin/cliproxyapi\n' "$(claudex_proxy_formula_prefix)"
}

claudex_proxy_models_ok() {
  command -v curl >/dev/null 2>&1 || return 1
  curl --silent --show-error --fail --max-time 4 \
    -H 'Authorization: Bearer claudex-local' \
    'http://127.0.0.1:8317/v1/models' 2>/dev/null \
    | grep -q 'gpt-5.6-sol'
}

claudex_validate_settings() {
  local file="$1"
  jq -e '
    .permissions.defaultMode == "bypassPermissions"
    and .effortLevel == "medium"
    and .skipDangerousModePermissionPrompt == true
  ' "$file" >/dev/null
}
