#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

pattern='\b(?:SKU|CFG)-[A-Za-z0-9]'

if matches=$(rg -n --hidden --glob '!.git' "${pattern}" . || true); then
  if [[ -n "${matches}" ]]; then
    echo "Legacy identifier prefixes found (CFG/SKU prefixes are banned):"
    echo "${matches}"
    exit 1
  fi
fi

echo "OK: no legacy CFG/SKU identifier prefixes found."
