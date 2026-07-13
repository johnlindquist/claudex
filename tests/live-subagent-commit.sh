#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

tmp="$(new_tmp)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.name 'Claudex Subagent Test'
git -C "$repo" config user.email 'claudex-subagent-test@example.invalid'

agents='{"committer":{"description":"Creates and commits the requested proof file","prompt":"You are the committer. Use Bash to create subagent-proof.txt containing exactly subagent-bypass-ok, git add it, and git commit it with message test: subagent bypass. Do not ask questions.","tools":["Bash","Write"],"model":"inherit","permissionMode":"bypassPermissions"}}'
prompt='Delegate this entire task to the committer subagent: create and commit its requested proof. Do not perform the file or git operations yourself. After it succeeds, return only SUBAGENT_DONE.'
result="$(cd "$repo" && claudex --print --output-format json --max-turns 10 --agents "$agents" "$prompt")"

[[ "$(cat "$repo/subagent-proof.txt")" == 'subagent-bypass-ok' ]] || fail 'subagent proof file missing'
[[ "$(git -C "$repo" log -1 --format=%s)" == 'test: subagent bypass' ]] || fail 'subagent commit missing'
jq -e '.subtype == "success" and ((.permission_denials // []) | length == 0)' \
  <<<"$result" >/dev/null || fail 'subagent run had permission denials'
printf 'PASS real subagent commit with bypassPermissions\n'
