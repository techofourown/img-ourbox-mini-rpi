
````md
# RFC-0002: Field Note - Build, Publish, Retrieve, and Flash an OurBox Mini OS Image

**Status:** Draft (Non-normative field note)  
**Created:** 2026-01-19  
**Updated:** 2026-01-19

---

## What

This memo captures a pragmatic, “worked in the real world” workflow for:

1. Building an OurBox Mini Raspberry Pi OS image using `pi-gen` (via `vendor/pi-gen`)
2. Publishing the build output as a registry-hosted artifact (OCI image carrying `os.img.xz`)
3. Retrieving that artifact onto another machine
4. Flashing the OS image onto the **SYSTEM NVMe** (without touching the **DATA NVMe**)

This is intentionally **non-normative**. It documents the specific commands and gotchas that
occurred during bring-up, and provides a reusable pattern for future environments.

> This is not a production manufacturing procedure. It’s a dev / bring-up / recovery playbook.

---

## Why

Even with a clean repo layout, there are operational “glue steps” that matter:

- Build hosts differ (Docker vs nerdctl vs podman)
- Some environments require a **local registry mirror** (offline builds, pinned deps)
- `pi-gen`’s container workflow has quirks (e.g., persistent `pigen_work` container)
- Boot media safety matters (SYSTEM vs DATA NVMe) and enumeration is not stable

Capturing this as a field note reduces future “how did we do that again?” time.

---

## Repository Orientation (mental model)

- `vendor/pi-gen/`  
  Upstream pi-gen (submodule, `arm64` branch). Produces Raspberry Pi OS images based on Debian.

- `pigen/`  
  OurBox custom stages and overrides:
  - `pigen/stages/stage-ourbox-mini/` adds:
    - `/etc/ourbox/release` contract file (OURBOX_* metadata)
    - storage contract (`LABEL=OURBOX_DATA` → `/var/lib/ourbox`)
    - `fstrim.timer` enabled
  - `pigen/overrides/stage2/SKIP_IMAGES` suppresses upstream stage2 image export so we only ship the OurBox artifact.

- `tools/`  
  “Operational glue” scripts:
  - `registry.sh`: registry config, `ensure_buildkitd`, helper funcs
  - `mirror-required-images.sh`: optional mirroring of base dependencies
  - `pull-required-images.sh`: pulls from our registry and tags to the names vendor expects
  - `build-image.sh`: builds the OS image using pi-gen in a container
  - `publish-os-artifact.sh`: wraps the build output into a scratch OCI image and pushes it
  - `pull-os-artifact.sh`: pulls and extracts `/artifact/*` from the pushed OCI image

---

## Preconditions / Safety

- You must be very clear which NVMe is **SYSTEM** (gets flashed) and which is **DATA** (must not be touched).
- Do **not** trust `nvme0n1` vs `nvme1n1` ordering in general.
  - Prefer `by-id` (serial) and `by-label` (filesystem label).

Recommended verification patterns:

```bash
findmnt /
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,FSTYPE,LABEL,MOUNTPOINTS
ls -l /dev/disk/by-id/ | grep -i nvme || true
ls -l /dev/disk/by-label/ || true
````

If you already created the DATA filesystem as:

* `LABEL=OURBOX_DATA`

…then you should see it under `/dev/disk/by-label/OURBOX_DATA`.

---

## Procedure A: Build + Publish (build host)

### 1) Set your registry variables (optional, recommended)

The build tooling supports environment overrides and/or `tools/registry.env`.

* `REGISTRY` (example: `registry.benac.dev`)
* `REGISTRY_NAMESPACE` (example: `ourbox`)

File:

`tools/registry.env`

```bash
REGISTRY="registry.example.dev"
REGISTRY_NAMESPACE="ourbox"
# Optional CA path for hosts that need to trust the registry:
REGISTRY_CA_CERT="/etc/ssl/your-ca.crt"
```

> If you don’t want a registry involved at all, you can skip the publish/pull path and move the `.img.xz` via SCP/USB.

---

### 2) Mirror base images into your registry (optional)

If you want builds to be reproducible/offline-friendly, mirror upstream dependencies:

```bash
./tools/mirror-required-images.sh
```

This currently mirrors at least:

* `debian:trixie` (pi-gen base image)
* `moby/buildkit:v0.23.2` (for nerdctl buildkitd)

---

### 3) Build the image

Typical build:

```bash
OURBOX_VARIANT=dev OURBOX_VERSION=dev ./tools/build-image.sh
```

Notes:

* `tools/build-image.sh`:

  * ensures buildkitd if using `nerdctl`
  * pulls required images from the configured registry and tags them to the canonical names
  * binds the repo into the pi-gen container so `/ourbox/pigen/...` stages can run

#### Common pitfall: `pigen_work` already exists

If you see:

> `Container pigen_work already exists and you did not specify CONTINUE=1. Aborting.`

You have two valid options:

**Option 1: delete and rebuild clean**

```bash
nerdctl rm -v pigen_work
# (or docker rm -v pigen_work)
```

**Option 2: continue an interrupted build**

```bash
CONTINUE=1 ./tools/build-image.sh
```

---

### 4) Publish the OS artifact to the registry

After a successful build, publish from the deploy directory:

```bash
./tools/publish-os-artifact.sh deploy
```

This builds a `FROM scratch` OCI image that contains:

* `/artifact/os.img.xz`
* `/artifact/os.info` (if present)
* `/artifact/build.log` (if present)

…and pushes it to:

`$REGISTRY/$REGISTRY_NAMESPACE/os:<tag>`

This is a handy pattern because it makes the artifact retrievable anywhere a container runtime can pull from.

---

## Procedure B: Retrieve the artifact (any host)

### Option 1: Pull + extract from registry (preferred when available)

On a machine with access to the registry and a container CLI:

```bash
./tools/pull-os-artifact.sh registry.example.dev/ourbox/os:<tag> ./deploy-from-registry
ls -lah ./deploy-from-registry
```

You should see:

* `os.img.xz`
* `os.info`
* `build.log`

---

### Option 2: Copy the `os.img.xz` over SSH (pragmatic + universal)

If hostname DNS doesn’t resolve, use the LAN IP or add `/etc/hosts`.

Example:

```bash
scp johnb@<build-host-ip>:/techofourown/img-ourbox-mini-rpi/deploy-from-registry/os.img.xz /root/os.img.xz
```

---

## Procedure C: Validate the artifact (before flashing)

On the machine that will flash:

```bash
ls -lh /root/os.img.xz
xz -t /root/os.img.xz
sha256sum /root/os.img.xz | tee /root/os.img.xz.sha256
```

If `xz -t` succeeds, the artifact is at least structurally valid.

---

## Procedure D: Flash to the SYSTEM NVMe (Raspberry Pi)

### 1) Identify DATA vs SYSTEM safely

**DATA** should be:

* `/dev/disk/by-label/OURBOX_DATA` → e.g. `/dev/nvme0n1p1`

**SYSTEM target** should be identified by `by-id` serial:

```bash
DATA_PART="/dev/disk/by-label/OURBOX_DATA"
SYS_DISK="/dev/disk/by-id/<your-system-nvme-by-id>"
SYS_DEV="$(readlink -f "$SYS_DISK")"

echo "DATA_PART=$DATA_PART -> $(readlink -f "$DATA_PART")"
echo "SYS_DISK=$SYS_DISK -> $SYS_DEV"
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL,MOUNTPOINTS "$SYS_DEV"
```

Confirm:

* DATA points at the correct partition (and is not going to be written)
* SYSTEM points at the raw disk (e.g. `/dev/nvme1n1`) and has no mounted partitions

---

### 2) Flash (destructive to SYSTEM disk)

**This will overwrite the SYSTEM disk.**

Recommended streaming flash:

```bash
# Replace /dev/nvmeXnY with your SYSTEM device (NOT a partition)
xzcat /root/os.img.xz | dd of="$SYS_DEV" bs=4M conv=fsync status=progress
sync
```

Then re-read partition table:

```bash
partprobe "$SYS_DEV" || true
lsblk -f "$SYS_DEV"
```

Expected outcome:

* SYSTEM disk now has:

  * a FAT boot partition (`bootfs`)
  * an ext4 root partition (`rootfs`)

---

## Boot Transition Notes

After flashing:

1. Power down:

   ```bash
   shutdown -h now
   ```
2. Remove SD card (or keep it as rescue and adjust boot order)
3. Boot and confirm the root filesystem is now NVMe:

   ```bash
   findmnt /
   ```

   Expect `/` to be from something like `/dev/nvme1n1p2` (or equivalent).

---

## OurBox-specific contracts to verify after boot

### 1) OurBox release contract file

```bash
cat /etc/ourbox/release
```

Expect keys like:

* `OURBOX_PRODUCT`
* `OURBOX_DEVICE`
* `OURBOX_TARGET`
* `OURBOX_SKU`
* `OURBOX_VARIANT`
* `OURBOX_VERSION`
* `OURBOX_RECIPE_GIT_HASH`

### 2) Data mount contract (label-based)

```bash
grep -n 'OURBOX_DATA' /etc/fstab
findmnt /var/lib/ourbox || true
ls -lah /var/lib/ourbox
```

Expected:

* `/etc/fstab` contains:
  `LABEL=OURBOX_DATA /var/lib/ourbox ext4 defaults,noatime,nofail,...`
* If the DATA disk is present, it should mount automatically.

### 3) SSD hygiene timer

```bash
systemctl status fstrim.timer --no-pager
```

---

## Troubleshooting

### “Container pigen_work already exists”

* Remove it: `nerdctl rm -v pigen_work`
* Or continue: `CONTINUE=1 ...`

### Host can’t resolve “centroid” (or any build host name)

* Use IP for SCP/SSH
* Or add a hosts entry:

  ```bash
  echo "<build-host-ip> centroid" >> /etc/hosts
  ```

### Registry TLS/CA issues on pull

* Ensure your registry CA is installed in system trust store (host-dependent)
* Or bypass registry retrieval and use SCP

### DATA disk not mounted after boot

* Confirm label exists:

  ```bash
  ls -l /dev/disk/by-label/OURBOX_DATA
  ```
* Check systemd mount timing:

  ```bash
  journalctl -b | grep -i ourbox
  journalctl -b | grep -i 'var-lib-ourbox'
  ```

---

## Open Questions (future work)

* Should artifact tags be standardized (SKU + variant + version + git hash)?
* Should we generate and publish:

  * `.bmap` (when `bmaptool` is available)
  * checksums/signatures (sha256 + GPG or Sigstore)
  * SBOM as a first-class artifact
* Do we want a “no-registry” publishing path (e.g., `make artifact` producing a single tarball)?
* Should first-boot behavior be hardened for appliance use (SSH keys, user creation policy, wizard/no wizard)?

---

## References

* `docs/rfcs/RFC-0001-field-note-nvme-hygiene-used-drives.md`
* `docs/decisions/ADR-0001-adopt-rpi-os-lite.md`
* `tools/build-image.sh`
* `tools/publish-os-artifact.sh`
* `tools/pull-os-artifact.sh`
* `pigen/stages/stage-ourbox-mini/*`

```
