#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/tools/lib.sh"
# shellcheck disable=SC1091
source "${ROOT}/tools/registry.sh"

need_cmd curl
need_cmd chmod

# Resolve K3S_VERSION if not provided
if [[ -z "${K3S_VERSION:-}" ]]; then
  log "K3S_VERSION not set; resolving latest from GitHub releases..."
  K3S_VERSION="$(
    curl -fsSLI https://github.com/k3s-io/k3s/releases/latest \
      | tr -d '\r' \
      | sed -n 's/^location: .*\/tag\/\(v[^ ]*\)$/\1/ip' \
      | tail -n1
  )"
fi

[[ -n "${K3S_VERSION}" ]] || die "K3S_VERSION resolution failed"
[[ "${K3S_VERSION}" != "vX.Y.Z+k3s1" ]] || die "K3S_VERSION is a placeholder; set it or let the script resolve latest"

log "Using K3S_VERSION=${K3S_VERSION}"

OUT="artifacts/airgap"
mkdir -p "$OUT/k3s" "$OUT/platform/images"

log "Fetch k3s binary (arm64) @ ${K3S_VERSION}"
curl -fsSL \
  -o "$OUT/k3s/k3s" \
  "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-arm64"
chmod +x "$OUT/k3s/k3s"

log "Fetch k3s airgap images (arm64) @ ${K3S_VERSION}"
curl -fsSL \
  -o "$OUT/k3s/k3s-airgap-images-arm64.tar" \
  "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-airgap-images-arm64.tar"

CLI="$(pick_container_cli)"
log "Using container CLI: ${CLI}"

log "Pull + save demo image (arm64): nginx:1.27-alpine"

case "$(cli_base "${CLI}")" in
  nerdctl|docker)
    # shellcheck disable=SC2086
    $CLI pull --platform=linux/arm64 nginx:1.27-alpine
    if [[ "$(cli_base "${CLI}")" = "nerdctl" ]]; then
      # shellcheck disable=SC2086
      $CLI save --platform=linux/arm64 -o "$OUT/platform/images/nginx_1.27-alpine.tar" nginx:1.27-alpine
    else
      # shellcheck disable=SC2086
      $CLI save -o "$OUT/platform/images/nginx_1.27-alpine.tar" nginx:1.27-alpine
    fi
    ;;
  podman)
    # shellcheck disable=SC2086
    $CLI pull --arch=arm64 --os=linux nginx:1.27-alpine
    # shellcheck disable=SC2086
    $CLI save -o "$OUT/platform/images/nginx_1.27-alpine.tar" nginx:1.27-alpine
    ;;
  *)
    die "Unsupported container CLI: ${CLI}"
    ;;
esac

log "Writing airgap manifest"
cat > "$OUT/manifest.env" <<EOF_MANIFEST
K3S_VERSION=${K3S_VERSION}
NGINX_IMAGE=nginx:1.27-alpine
EOF_MANIFEST

log "Artifacts created:"
ls -lah "$OUT/k3s" "$OUT/platform/images" "$OUT/manifest.env"
