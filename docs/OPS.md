# OurBox Mini OS -- Operator Runbook (Zero -> Boot)

**Last verified:** 2026-01-26  
**Verified on:** Pi 5 + dual NVMe (DATA label `OURBOX_DATA`, SYSTEM flashed to other NVMe)  
**Outcome:** k3s + hello workload running, nginx reachable on `127.0.0.1:30080`

This is the only step-by-step doc. If reality and this file disagree, update this file.

---

## Opinionated defaults (repeatable, no options)

We do **not** offer a menu of container runtimes or "latest" versions. This runbook assumes:

- **Container runtime:** Podman (rootful)  
- **BuildKit:** installed on the host (buildctl/buildkitd)  
- **Pinned versions:** `tools/versions.env` (K3s version is pinned here)

If you change pinned versions or tooling, update **Last verified** and re-run end-to-end.

---

## What you need

### Any Linux host (including the Raspberry Pi)

This runbook is designed to work on a fresh Linux machine -- including a Raspberry Pi booted from SD/USB that will flash its own NVMe.

You need:

- `sudo` access
- working Internet for the first run (fetch k3s + pull images)
- enough disk space for pi-gen output (**~60GB free recommended**)
- if building on **x86_64** for an **arm64** image, you need qemu/binfmt (our bootstrap script installs it on apt/dnf)

### Storage layout (Pi 5 + dual NVMe)

We assume two NVMe drives:

- **DATA**: ext4 labeled `OURBOX_DATA` (**must never be wiped**)
- **SYSTEM**: raw disk that will be overwritten (**will be wiped**)

---

## Happy path (single machine: build + flash on the same Pi)

If you are doing everything on the Pi (booted from SD/USB):

```bash
# 0) Clone
git clone --recurse-submodules <REPO_URL>
cd img-ourbox-mini-rpi

# 1) Install deps (Podman + BuildKit + basics)
./tools/bootstrap-host.sh

# 2) Use Podman for all repo scripts (rootful)
export DOCKER="sudo podman"

# 3) Load pinned versions into your environment (exports vars)
set -a
source ./tools/versions.env
set +a

# 4) Fetch airgap artifacts (uses pinned K3S_VERSION)
./tools/fetch-airgap-platform.sh

# 5) Build image
OURBOX_VARIANT=dev OURBOX_VERSION=dev ./tools/build-image.sh

# 6) Flash (DESTRUCTIVE) -- pick SYSTEM NVMe by-id
IMG="$(ls -1 deploy/img-*.img.xz | head -n1)"
sudo ./tools/flash-system-nvme.sh "${IMG}" /dev/disk/by-id/<YOUR_SYSTEM_NVME_BY_ID>

# 7) Pre-boot username/password
sudo ./tools/preboot-userconf.sh /dev/nvme1n1 <NEW_USER>

# 8) Power off, remove SD/USB (or fix boot order), boot NVMe
```

Then jump to **8) First boot verification**.

---

## 0) Clone correctly (submodules)

```bash
git clone --recurse-submodules <REPO_URL>
cd img-ourbox-mini-rpi

# If you already cloned:
git submodule update --init --recursive
```

---

## 1) Bootstrap this machine (Podman + BuildKit + basics)

This step makes a fresh Pi / Linux box usable (no "podman not found" surprises).

```bash
./tools/bootstrap-host.sh
```

Then in your current shell:

```bash
export DOCKER="sudo podman"

# Export pinned versions (K3S_VERSION, BUILDKIT_VERSION, etc)
set -a
source ./tools/versions.env
set +a
```

Verify:

```bash
podman version
buildctl --version || true
buildkitd --version || true
systemctl status buildkit --no-pager || true
```

---

## 2) Fetch airgap platform artifacts (k3s + images)

This repo builds an image that includes an airgapped k3s. We fetch these artifacts *before* building.

**K3s is pinned** in `tools/versions.env`. Do not use "latest".

```bash
./tools/fetch-airgap-platform.sh
```

Expected artifacts:

* `artifacts/airgap/k3s/k3s`
* `artifacts/airgap/k3s/k3s-airgap-images-arm64.tar`
* `artifacts/airgap/platform/images/nginx_1.27-alpine.tar`
* `artifacts/airgap/manifest.env`

---

## 3) Build the OS image

```bash
OURBOX_VARIANT=dev OURBOX_VERSION=dev ./tools/build-image.sh
```

Expected output: a `deploy/` directory with:

* `img-*.img.xz`
* `*.info`
* `build.log`

If the build finishes but you do not see `deploy/img-*.img.xz`, treat it as a build failure.

---

## 4) Publish the OS image as a registry artifact (optional)

If you have a registry workflow, publish the artifact:

```bash
xz -t deploy/img-*.img.xz
./tools/publish-os-artifact.sh deploy
```

Save the printed image reference, e.g. `registry.example.dev/ourbox/os:<tag>`.

---

## 5) Pull + extract the artifact (optional)

If you published to a registry, pull/extract anywhere (this host now has Podman):

```bash
rm -rf ./deploy-from-registry
./tools/pull-os-artifact.sh <registry-image-ref> ./deploy-from-registry
ls -lah ./deploy-from-registry
xz -t ./deploy-from-registry/os.img.xz
```

---

## 6) Flash the SYSTEM NVMe (DESTRUCTIVE -- protect DATA)

### 6.1 Verify current root is NOT the disk you will overwrite

```bash
findmnt /
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,LABEL,MOUNTPOINTS
```

If you are booted from SD/USB, `/` should be `mmcblk*` or `sd*`, NOT `nvme*`.

### 6.2 Identify DATA by label and SYSTEM by by-id

```bash
ls -l /dev/disk/by-label/OURBOX_DATA
ls -l /dev/disk/by-id/ | grep -i nvme || true
```

### 6.3 Flash using the safety-rails script

Pick ONE image source:

* from local build output: `deploy/img-*.img.xz`
* from registry extraction: `deploy-from-registry/os.img.xz`
* from SCP: `/home/<user>/os.img.xz`

Then flash:

```bash
sudo ./tools/flash-system-nvme.sh <path-to-os.img.xz> /dev/disk/by-id/<YOUR_SYSTEM_NVME_BY_ID>
```

---

## 7) Pre-boot config (set username/password without wizard)

Before booting the newly-flashed NVMe OS, create `userconf.txt` on the boot partition:

```bash
sudo ./tools/preboot-userconf.sh /dev/nvme1n1 <NEW_USER>
```

Notes:

* This script expects a real device path like `/dev/nvme1n1` (not a by-id path).
* It will prompt you for a password and write the hash to the boot partition.

Power down, remove SD/USB (or fix boot order), and boot the NVMe OS.

---

## 8) First boot verification (what "good" looks like)

### 8.1 Storage mounts

```bash
findmnt /
findmnt /var/lib/ourbox || true
```

Expected:

* `/` is `nvme...p2`
* `/var/lib/ourbox` is the DATA disk (`LABEL=OURBOX_DATA`)

### 8.2 Bootstrap + k3s

```bash
systemctl status ourbox-bootstrap --no-pager || true
systemctl status k3s --no-pager || true

sudo /usr/local/bin/k3s kubectl get nodes
sudo /usr/local/bin/k3s kubectl get pods -A
```

### 8.3 Demo service reachable

```bash
curl -sSf http://127.0.0.1:30080 | head
```

### 8.4 Bootstrap completion marker

```bash
sudo cat /var/lib/ourbox/state/bootstrap.done 2>/dev/null || true
```

---

## Troubleshooting

### Podman is missing / "podman: command not found"

You skipped bootstrap. Fix:

```bash
./tools/bootstrap-host.sh
export DOCKER="sudo podman"
```

### BuildKit is missing / build scripts complain about buildkitd/buildctl

Fix:

```bash
./tools/bootstrap-host.sh
buildctl --version
systemctl status buildkit --no-pager || true
```

### "Container pigen_work already exists"

```bash
sudo podman rm -v pigen_work || true
```

### k3s fails with: "failed to find memory cgroup (v2)"

If you are running an image built after the cgroup patch stage, this should already be baked in. If you are on an older image or you edited cmdline manually, use the steps below.

Symptom:

* `systemctl status k3s` shows crash loop
* journal shows: `fatal ... failed to find memory cgroup (v2)`

Fix (on the Pi):

```bash
sudo systemctl stop ourbox-bootstrap.service || true
sudo systemctl stop k3s.service || true
sudo systemctl disable k3s.service || true

sudo cp -a /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.bak
sudo sed -i '1 s/$/ cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/firmware/cmdline.txt
cat /boot/firmware/cmdline.txt

sudo reboot
```

Verify after reboot:

```bash
stat -fc %T /sys/fs/cgroup
cat /sys/fs/cgroup/cgroup.controllers
```

You should see `cgroup2fs` and `memory` present in controllers.

Then:

```bash
sudo systemctl start ourbox-bootstrap.service
sudo systemctl status k3s --no-pager
```

### Wi-Fi blocked by rfkill

```bash
sudo raspi-config
# Localisation Options -> WLAN Country
```

### Registry TLS / unknown CA

Use local flash (`deploy/img-*.img.xz`) or SCP as a fallback, or install your registry CA. Do not stall the workflow on this.

---

## One important meta-point (why pin K3S)
Because **airgap artifacts are part of the OS image**. If K3s changes under you, you will get "works yesterday, broken today" builds -- and it will be impossible to debug reproducibly.

With `tools/versions.env`, you have got:
- deterministic builds
- deliberate upgrades (edit the pin, rebuild, re-verify, update the runbook date)

---
