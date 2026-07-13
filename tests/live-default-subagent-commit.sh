#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

tmp="$(new_tmp)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
receipt="$tmp/agent-hook.jsonl"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.name 'Claudex Default Subagent Test'
git -C "$repo" config user.email 'claudex-default-subagent-test@example.invalid'

prompt='Use the Agent tool exactly once to delegate this entire task to a general-purpose subagent. The subagent must create default-subagent-proof.txt containing exactly default-subagent-bypass-ok, git add it, and git commit it with message test: default subagent bypass. Do not create or commit the file in the parent. After the subagent succeeds, return only DEFAULT_SUBAGENT_DONE.'
result="$(cd "$repo" && CLAUDEX_HOOK_RECEIPT="$receipt" \
  claudex --print --output-format json --max-turns 12 "$prompt")"

[[ "$(cat "$repo/default-subagent-proof.txt")" == 'default-subagent-bypass-ok' ]] \
  || fail 'ordinary subagent proof file missing'
[[ "$(git -C "$repo" log -1 --format=%s)" == 'test: default subagent bypass' ]] \
  || fail 'ordinary subagent commit missing'
jq -e '
  .event == "PreToolUse"
  and .tool == "Agent"
  and .forcedMode == "bypassPermissions"
' "$receipt" >/dev/null || fail 'Agent launch was not rewritten to bypassPermissions'
jq -e '.subtype == "success" and ((.permission_denials // []) | length == 0)' \
  <<<"$result" >/dev/null || fail 'ordinary subagent run had permission denials'
printf 'PASS ordinary Agent launch rewritten to bypassPermissions and committed\n'
