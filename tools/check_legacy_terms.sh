#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if rg -n "\\b(?:SKU|CFG)-[A-Z0-9]" .; then
  echo "Legacy identifiers found. Use TOO- prefixed identifiers only." >&2
  exit 1
fi

echo "Legacy identifier check passed."
