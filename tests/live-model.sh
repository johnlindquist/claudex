#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

result="$(claudex --print --output-format json --max-turns 1 \
  'Reply only MODEL_OK' --tools '')"
jq -e '
  .subtype == "success"
  and (.result | contains("MODEL_OK"))
  and ((.modelUsage // {}) | has("gpt-5.6-sol"))
' <<<"$result" >/dev/null || fail 'runtime receipt did not attribute usage to gpt-5.6-sol'
printf 'PASS live runtime model receipt: gpt-5.6-sol\n'
