#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "${ROOT}/tools/lib.sh"

if [ "${EUID}" -ne 0 ]; then
  log "Re-executing with sudo..."
  exec sudo -E -- "$0" "$@"
fi

IMG="${1:-}"
SYS_DISK="${2:-}"
DATA_PART="/dev/disk/by-label/OURBOX_DATA"

if [ -z "${IMG}" ] || [ -z "${SYS_DISK}" ]; then
  die "Usage: $0 <path-to-os.img.xz> <SYS_DISK-by-id>"
fi

case "${SYS_DISK}" in
  /dev/disk/by-id/*) ;;
  *) die "SYS_DISK must be a /dev/disk/by-id/... path (got: ${SYS_DISK})" ;;
esac

need_cmd xz
need_cmd xzcat
need_cmd dd
need_cmd lsblk
need_cmd readlink
need_cmd partprobe

if [ ! -e "${DATA_PART}" ]; then
  die "DATA disk not found: ${DATA_PART}"
fi

if [ ! -f "${IMG}" ]; then
  die "Image not found: ${IMG}"
fi

log "Verifying image integrity: ${IMG}"
xz -t "${IMG}"

DATA_DEV="$(readlink -f "${DATA_PART}")"
DATA_DISK="/dev/$(lsblk -no PKNAME "${DATA_DEV}")"
SYS_DEV="$(readlink -f "${SYS_DISK}")"

if [ "$(lsblk -no TYPE "${SYS_DEV}")" != "disk" ]; then
  die "SYS_DISK must resolve to a raw disk (got: ${SYS_DEV})"
fi

log "IMG=${IMG}"
log "DATA_PART=${DATA_PART} -> ${DATA_DEV} (disk ${DATA_DISK})"
log "SYS_DISK=${SYS_DISK} -> ${SYS_DEV}"

echo
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,LABEL,MOUNTPOINTS "${DATA_DISK}"
echo
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,LABEL,MOUNTPOINTS "${SYS_DEV}"
echo

if [ "${SYS_DEV}" = "${DATA_DISK}" ]; then
  die "SYS_DEV resolves to DATA disk (${DATA_DISK}). Refusing."
fi

read -r -p "Type FLASH (all caps) to erase and flash ${SYS_DEV}: " ans
[ "${ans}" = "FLASH" ]

log "Flashing ${IMG} -> ${SYS_DEV}"
xzcat "${IMG}" | dd of="${SYS_DEV}" bs=4M conv=fsync status=progress
sync

log "Refreshing partition table"
partprobe "${SYS_DEV}" || true
lsblk -f "${SYS_DEV}"
