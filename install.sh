#!/usr/bin/env bash
set -euo pipefail

repo="johnlindquist/claudex"
ref="${CLAUDEX_REF:-v1.0.2}"

bootstrap() {
  [[ "$ref" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ ]] \
    || { printf 'claudex: invalid CLAUDEX_REF\n' >&2; exit 1; }
  local tmp archive source_dir candidate
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  archive="$tmp/claudex.tar.gz"
  printf 'claudex: downloading %s at %s\n' "$repo" "$ref"
  curl --fail --location --proto '=https' --tlsv1.2 \
    "https://codeload.github.com/$repo/tar.gz/refs/tags/$ref" \
    --output "$archive"
  tar -xzf "$archive" -C "$tmp"
  source_dir=''
  for candidate in "$tmp"/*/; do
    source_dir="${candidate%/}"
    break
  done
  [[ -n "$source_dir" && -x "$source_dir/bin/claudex" \
    && -f "$source_dir/config/claudex/settings.json" ]] \
    || { printf 'claudex: downloaded release is incomplete\n' >&2; exit 1; }
  bash -n "$source_dir/install.sh" "$source_dir/bin/claudex"
  local status=0
  bash "$source_dir/install.sh" --from-checkout "$@" || status=$?
  rm -rf "$tmp"
  trap - EXIT
  exit "$status"
}

if [[ "${1:-}" != "--from-checkout" ]]; then
  bootstrap "$@"
fi
shift

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$script_dir/lib/common.sh"

no_login=false
while (($#)); do
  case "$1" in
    --no-login) no_login=true ;;
    -h|--help)
      printf 'Usage: install.sh [--no-login]\n'
      exit 0
      ;;
    *) claudex_die "unknown option: $1" ;;
  esac
  shift
done

command -v jq >/dev/null 2>&1 || claudex_die 'jq is required'
claudex_validate_settings "$script_dir/config/claudex/settings.json" \
  || claudex_die 'bundled settings failed validation'

test_mode="${CLAUDEX_TEST_MODE:-0}"
formula_preexisting=false
config_preexisting=false
service_preexisting=false
existing_state="$(claudex_install_root)/install-state.json"

if [[ "$test_mode" != 1 ]]; then
  [[ "$(uname -s)" == Darwin ]] || claudex_die 'the v1 installer supports macOS only'
  command -v brew >/dev/null 2>&1 || claudex_die 'Homebrew is required: https://brew.sh'

  if ! command -v claude >/dev/null 2>&1; then
    claudex_note 'installing Claude Code'
    brew install --cask claude-code
  fi
  claude --help 2>&1 | grep -q -- '--dangerously-skip-permissions' \
    || claudex_die 'installed Claude Code lacks the required permission flag'
  claude --help 2>&1 | grep -q -- '--effort' \
    || claudex_die 'installed Claude Code lacks --effort support'

  brew list --formula cliproxyapi >/dev/null 2>&1 && formula_preexisting=true
  [[ -e "$(brew --prefix)/etc/cliproxyapi.conf" ]] && config_preexisting=true
  brew services list 2>/dev/null | grep -Eq '^cliproxyapi[[:space:]]+(started|scheduled)' \
    && service_preexisting=true
  if [[ "$formula_preexisting" == false ]]; then
    claudex_note 'installing CLIProxyAPI'
    brew install cliproxyapi
  fi
else
  mkdir -p "$(claudex_brew_prefix)/bin" "$(claudex_brew_prefix)/etc"
fi

# Preserve ownership facts across reinstalls so an explicit purge remains safe.
if [[ -r "$existing_state" ]] && jq -e '.version == 1' "$existing_state" >/dev/null 2>&1; then
  formula_preexisting="$(jq -r '.formulaPreexisting' "$existing_state")"
  config_preexisting="$(jq -r '.configPreexisting' "$existing_state")"
  service_preexisting="$(jq -r '.servicePreexisting' "$existing_state")"
fi

brew_prefix="$(claudex_brew_prefix)"
proxy_config="$(claudex_proxy_config)"
if [[ "$config_preexisting" == true ]]; then
  grep -Eq "^[[:space:]]*host:[[:space:]]*['\"]?(127\\.0\\.0\\.1|localhost)['\"]?[[:space:]]*$" "$proxy_config" \
    || claudex_die "existing $proxy_config is not loopback-only; refusing to modify it"
  grep -Eq '^[[:space:]]*port:[[:space:]]*8317[[:space:]]*$' "$proxy_config" \
    || claudex_die "existing $proxy_config does not use port 8317; refusing to modify it"
  grep -Eq "^[[:space:]]*-[[:space:]]*['\"]?claudex-local['\"]?[[:space:]]*$" "$proxy_config" \
    || claudex_die "existing $proxy_config does not accept claudex-local; refusing to modify it"
else
  mkdir -p "$(dirname "$proxy_config")"
  cp "$script_dir/config/cliproxyapi.conf" "$proxy_config"
fi

install_root="$(claudex_install_root)"
mkdir -p "$install_root/bin" "$install_root/lib"
cp "$script_dir/bin/claudex" "$script_dir/bin/claudexctl" "$install_root/bin/"
cp "$script_dir/lib/common.sh" "$install_root/lib/"
cp "$script_dir/install.sh" "$install_root/install.sh"
cp "$script_dir/config/claudex/settings.json" "$install_root/settings.json"
cp "$script_dir/uninstall.sh" "$install_root/uninstall.sh"
rm -rf "$install_root/config" "$install_root/tests" "$install_root/scripts"
cp -R "$script_dir/config" "$install_root/config"
cp -R "$script_dir/tests" "$install_root/tests"
cp -R "$script_dir/scripts" "$install_root/scripts"
chmod +x "$install_root/bin/claudex" "$install_root/bin/claudexctl" \
  "$install_root/install.sh" "$install_root/uninstall.sh"

ln -sfn "$install_root/bin/claudex" "$brew_prefix/bin/claudex"
ln -sfn "$install_root/bin/claudexctl" "$brew_prefix/bin/claudexctl"

jq -n \
  --arg brewPrefix "$brew_prefix" \
  --arg proxyConfig "$proxy_config" \
  --argjson formulaPreexisting "$formula_preexisting" \
  --argjson configPreexisting "$config_preexisting" \
  --argjson servicePreexisting "$service_preexisting" \
  '{version:1, $brewPrefix, $proxyConfig, $formulaPreexisting, $configPreexisting, $servicePreexisting}' \
  >"$install_root/install-state.json"

if [[ "$test_mode" != 1 ]]; then
  if ! claudex_proxy_models_ok; then
    brew services restart cliproxyapi >/dev/null
    for _ in 1 2 3 4 5; do
      claudex_proxy_models_ok && break
      sleep 1
    done
  fi
  if ! claudex_proxy_models_ok; then
    if [[ "$no_login" == true ]]; then
      claudex_note 'proxy is installed, but login is still required: claudexctl login'
    else
      claudex_note 'starting Codex OAuth login; rerun claudexctl login for another account'
      "$(claudex_proxy_bin)" --config "$proxy_config" --codex-login
      brew services restart cliproxyapi >/dev/null
    fi
  fi
fi

claudex_note "installed $brew_prefix/bin/claudex"
claudex_note 'run: claudexctl doctor'
