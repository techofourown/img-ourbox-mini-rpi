#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${ROOT}/tools/lib.sh"

log "Checking for legacy naming terms..."

FAILED=0

# Patterns to detect (these must NOT appear in the repo)
LEGACY_PATTERNS=(
  "OurBox Mini"
  "TOO-OBX-MINI-"
  "img-ourbox-mini-rpi"
  "stage-ourbox-mini"
  "CFG-"
  "SKU-"
)

# Files/paths to exclude from search
EXCLUDE_DIRS=(
  ".git"
  "vendor/pi-gen"
  "deploy"
  "deploy-from-registry"
  "artifacts"
)

EXCLUDE_FILES=(
  "CHANGELOG.md"  # Contains historical git URLs and references
  "tools/check_legacy_terms.sh"  # This file itself contains the patterns
)

# Build grep exclude args
EXCLUDE_ARGS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
  EXCLUDE_ARGS+=(--exclude-dir="${dir}")
done
for file in "${EXCLUDE_FILES[@]}"; do
  EXCLUDE_ARGS+=(--exclude="${file}")
done

cd "${ROOT}"

for pattern in "${LEGACY_PATTERNS[@]}"; do
  log "Searching for: ${pattern}"

  # Use grep to search, excluding specified directories and files
  # Redirect output to suppress grep's output; capture exit code
  if grep -r "${EXCLUDE_ARGS[@]}" -F "${pattern}" . 2>/dev/null | grep -v "^./tools/check_legacy_terms.sh:" | grep -q .; then
    echo "ERROR: Found legacy term: ${pattern}" >&2
    grep -r "${EXCLUDE_ARGS[@]}" -F "${pattern}" . 2>/dev/null | grep -v "^./tools/check_legacy_terms.sh:" >&2
    FAILED=1
  fi
done

if [[ "${FAILED}" -eq 1 ]]; then
  die "Legacy naming terms detected. See errors above."
fi

log "OK: No legacy naming terms found"
