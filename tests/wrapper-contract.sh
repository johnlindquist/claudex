#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

tmp="$(new_tmp)"
trap 'rm -rf "$tmp"' EXIT
receipt="$tmp/receipt"
CLAUDEX_TEST_RECEIPT="$receipt" \
CLAUDEX_CLAUDE_BIN="$project_root/tests/fixtures/fake-claude" \
XDG_CONFIG_HOME="$tmp/config" \
  "$project_root/bin/claudex" --print 'hello'

assert_file_contains "$receipt" 'ANTHROPIC_BASE_URL=http://127.0.0.1:8317'
assert_file_contains "$receipt" 'ANTHROPIC_AUTH_TOKEN=claudex-local'
assert_file_contains "$receipt" 'CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol'
assert_file_contains "$receipt" 'CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1'
assert_file_contains "$receipt" 'CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3'
assert_file_contains "$receipt" 'ENABLE_TOOL_SEARCH=false'
assert_file_contains "$receipt" "--settings> <$tmp/config/claudex/settings.json"
assert_file_contains "$receipt" '--model> <gpt-5.6-sol'
assert_file_contains "$receipt" '--effort> <medium'
assert_file_contains "$receipt" '--dangerously-skip-permissions'

jq -e '
  .permissions.defaultMode == "bypassPermissions"
  and .effortLevel == "medium"
  and .skipDangerousModePermissionPrompt == true
  and any(.hooks.PreToolUse[]?;
    .matcher == "Agent"
    and any(.hooks[]?;
      .type == "command"
      and .command == "claudexctl _hook-agent-bypass"
    )
  )
' "$project_root/config/claudex/settings.json" >/dev/null

hook_receipt="$tmp/hook-receipt.jsonl"
hook_output="$(
  CLAUDEX_HOOK_RECEIPT="$hook_receipt" \
    "$project_root/bin/claudexctl" _hook-agent-bypass <<'JSON'
{"hook_event_name":"PreToolUse","tool_name":"Agent","tool_input":{"description":"Commit proof","prompt":"Create and commit proof.txt","subagent_type":"general-purpose","mode":"acceptEdits","run_in_background":true}}
JSON
)"
jq -e '
  .hookSpecificOutput.hookEventName == "PreToolUse"
  and .hookSpecificOutput.permissionDecision == "allow"
  and .hookSpecificOutput.updatedInput.description == "Commit proof"
  and .hookSpecificOutput.updatedInput.prompt == "Create and commit proof.txt"
  and .hookSpecificOutput.updatedInput.subagent_type == "general-purpose"
  and .hookSpecificOutput.updatedInput.run_in_background == true
  and .hookSpecificOutput.updatedInput.mode == "bypassPermissions"
' <<<"$hook_output" >/dev/null
jq -e '
  .event == "PreToolUse"
  and .tool == "Agent"
  and .originalMode == "acceptEdits"
  and .forcedMode == "bypassPermissions"
  and .background == true
' "$hook_receipt" >/dev/null

printf 'PASS wrapper and Agent hook contracts\n'
