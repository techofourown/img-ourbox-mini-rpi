#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/tools/lib.sh"
# shellcheck disable=SC1091
source "${ROOT}/tools/registry.sh"

cli="$(pick_container_cli)"

pull_and_tag() {
  local src="$1" dst="$2"
  log ">> Pull: $src"
  # shellcheck disable=SC2086
  $cli pull "$src"
  log ">> Tag:  $src -> $dst"
  # shellcheck disable=SC2086
  $cli tag "$src" "$dst"
}

# pi-gen Dockerfile build arg uses "debian:trixie"
pull_and_tag "$(imgref mirror/debian trixie)" "debian:trixie"

# Optional convenience tag (not strictly needed for our buildkitd approach)
pull_and_tag "$(imgref mirror/buildkit v0.23.2)" "moby/buildkit:v0.23.2"
