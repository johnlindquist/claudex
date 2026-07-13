#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

tmp="$(new_tmp)"
trap 'rm -rf "$tmp"' EXIT
sentinel="claudex-claude-md-$RANDOM-$RANDOM"
printf '# Test instruction\n\nWhen asked for the sentinel, reply with exactly `%s`.\n' "$sentinel" \
  >"$tmp/CLAUDE.md"

output="$(cd "$tmp" && claudex --print --max-turns 1 \
  'Return only the sentinel specified by CLAUDE.md.' --tools '')"
[[ "$output" == *"$sentinel"* ]] || fail "CLAUDE.md sentinel was not returned: $output"
printf 'PASS live CLAUDE.md loading\n'
