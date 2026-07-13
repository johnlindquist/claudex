#!/usr/bin/env bash
set -euo pipefail

install_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state="$install_root/install-state.json"
purge_proxy=false
[[ "${1:-}" == '--purge-proxy' ]] && purge_proxy=true

if [[ -r "$state" ]]; then
  brew_prefix="$(jq -r '.brewPrefix' "$state")"
  for name in claudex claudexctl; do
    link="$brew_prefix/bin/$name"
    if [[ -L "$link" && "$(readlink "$link")" == "$install_root/bin/$name" ]]; then
      rm "$link"
    fi
  done

  if [[ "$purge_proxy" == true ]]; then
    formula_preexisting="$(jq -r '.formulaPreexisting' "$state")"
    config_preexisting="$(jq -r '.configPreexisting' "$state")"
    service_preexisting="$(jq -r '.servicePreexisting' "$state")"
    proxy_config="$(jq -r '.proxyConfig' "$state")"
    if [[ "$service_preexisting" == false ]] && command -v brew >/dev/null 2>&1; then
      brew services stop cliproxyapi >/dev/null 2>&1 || true
    fi
    if [[ "$config_preexisting" == false && -f "$proxy_config" ]]; then
      rm "$proxy_config"
    fi
    if [[ "$formula_preexisting" == false ]] && command -v brew >/dev/null 2>&1; then
      brew uninstall cliproxyapi
    fi
  fi
fi

rm -rf "$install_root"
printf 'claudex: removed claudex-owned files\n'
printf 'claudex: OAuth credentials in ~/.cli-proxy-api were preserved\n'
