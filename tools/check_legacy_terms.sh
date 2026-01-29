#!/usr/bin/env bash
set -euo pipefail

prefix_sku="SKU"
prefix_cfg="CFG"
pattern="\\b${prefix_sku}-|\\b${prefix_cfg}-"

if rg -n "${pattern}"; then
  echo "Legacy identifiers found. Replace CFG or SKU prefixes with TOO-prefixed identifiers." >&2
  exit 1
fi
