#!/usr/bin/env bash
set -euo pipefail

test_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$test_dir/wrapper-contract.sh"
bash "$test_dir/hermetic-install.sh"
if [[ "${CLAUDEX_INSTALLED_TEST:-0}" != 1 ]]; then
  bash "$test_dir/installed-control.sh"
fi

if [[ "${CLAUDEX_RUN_LIVE:-0}" == 1 ]]; then
  bash "$test_dir/live-model.sh"
  bash "$test_dir/live-claude-md.sh"
  bash "$test_dir/live-permissions.sh"
  bash "$test_dir/live-resume.sh"
  bash "$test_dir/live-subagent-commit.sh"
  bash "$test_dir/live-default-subagent-commit.sh"
else
  printf 'SKIP live tests (set CLAUDEX_RUN_LIVE=1)\n'
fi
