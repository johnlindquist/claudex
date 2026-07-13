#!/usr/bin/env bash
set -euo pipefail
repo="${1:-johnlindquist/claudex}"
ref="${2:-v1.0.1}"

gh api "repos/$repo/git/ref/tags/$ref" >/dev/null
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 \
  "https://raw.githubusercontent.com/$repo/$ref/install.sh" \
  --output "$tmp/install.sh"
bash -n "$tmp/install.sh"
grep -Fq 'refs/tags/$ref' "$tmp/install.sh" \
  || { printf 'published installer is not tag-pinned\n' >&2; exit 1; }
printf 'PASS published tag and installer\n'
