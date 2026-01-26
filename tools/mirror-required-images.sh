#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/tools/lib.sh"
# shellcheck disable=SC1091
source "${ROOT}/tools/registry.sh"

# Add anything you want to keep local
mirror_image "docker.io/library/debian:trixie" "$(imgref mirror/debian trixie)"
mirror_image "docker.io/moby/buildkit:v0.23.2" "$(imgref mirror/buildkit v0.23.2)"
