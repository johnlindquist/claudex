#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

tmp="$(new_tmp)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
probe="/tmp/claudex-bypass-$RANDOM-$RANDOM"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.name 'Claudex Test'
git -C "$repo" config user.email 'claudex-test@example.invalid'

prompt="Use Bash to write exactly claudex-bypass-ok to $probe. Then create proof.txt in the current repository containing exactly claudex-git-ok, git add it, and git commit it with message 'test: claudex bypass'. Do not ask questions. Return only DONE."
result="$(cd "$repo" && claudex --print --output-format json --max-turns 8 "$prompt")"

[[ "$(cat "$probe")" == 'claudex-bypass-ok' ]] || fail '/tmp write did not happen'
[[ "$(git -C "$repo" log -1 --format=%s)" == 'test: claudex bypass' ]] || fail 'git commit did not happen'
jq -e '.subtype == "success" and ((.permission_denials // []) | length == 0)' \
  <<<"$result" >/dev/null || fail 'live run had permission denials'
rm -f "$probe"
printf 'PASS live /tmp write and git commit without permission denials\n'
