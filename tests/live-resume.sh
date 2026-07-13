#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

tmp="$(new_tmp)"
trap 'rm -rf "$tmp"' EXIT
session_id="$(uuidgen | tr '[:upper:]' '[:lower:]')"
first="$(cd "$tmp" && claudex --print --output-format json --session-id "$session_id" \
  --max-turns 1 'Reply only FIRST_OK' --tools '')"
second="$(cd "$tmp" && claudex --print --output-format json --resume "$session_id" \
  --max-turns 1 'Reply only RESUME_OK' --tools '')"
jq -e '.subtype == "success" and (.result | contains("FIRST_OK"))' <<<"$first" >/dev/null
jq -e '.subtype == "success" and (.result | contains("RESUME_OK"))' <<<"$second" >/dev/null
printf 'PASS live resume reapplies wrapper contract\n'
