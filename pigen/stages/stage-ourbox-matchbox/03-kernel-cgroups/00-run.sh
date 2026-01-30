#!/usr/bin/env bash
set -euo pipefail

: "${ROOTFS_DIR:?ROOTFS_DIR not set}"

CMDLINE="${ROOTFS_DIR}/boot/firmware/cmdline.txt"
[[ -f "${CMDLINE}" ]] || { echo "ERROR: missing ${CMDLINE}" >&2; exit 1; }

FLAGS="cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1"

if ! grep -qE '(^| )cgroup_enable=memory( |$)' "${CMDLINE}"; then
  echo "==> Patching cmdline.txt to enable memory cgroup controller"
  sed -i "1 s/\$/ ${FLAGS}/" "${CMDLINE}"
fi

echo "==> Final /boot/firmware/cmdline.txt:"
cat "${CMDLINE}"
