#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1" expected="$2"
  grep -Fq -- "$expected" "$file" \
    || fail "$file does not contain: $expected"
}

new_tmp() {
  mktemp -d "${TMPDIR:-/tmp}/claudex-test.XXXXXX"
}
