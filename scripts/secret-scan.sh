#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if rg -n --hidden --glob '!.git/**' \
  '(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|Bearer[[:space:]]+[A-Za-z0-9._-]{20,}|BEGIN (RSA |OPENSSH )?PRIVATE KEY|access[_-]?token["'"']?[[:space:]]*[:=][[:space:]]*["'"'][^"'"']+)' \
  "$root"; then
  printf 'Potential secret detected.\n' >&2
  exit 1
fi
printf 'PASS public tree secret scan\n'
