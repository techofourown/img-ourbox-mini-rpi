# img-ourbox-mini-rpi

Build repository for **OurBox Mini** OS images targeting **Raspberry Pi hardware** (Pi 5 + dual NVMe).

This repo produces an NVMe-bootable OS that mounts `/var/lib/ourbox` and boots into an airgapped
single-node k3s runtime via `ourbox-bootstrap`.

## Docs

- Operator runbook: [`docs/OPS.md`](./docs/OPS.md)
- Contracts reference: [`docs/reference/contracts.md`](./docs/reference/contracts.md)

## Happy path (build → publish → flash → boot)

```bash
git clone --recurse-submodules <REPO_URL>
./tools/fetch-airgap-platform.sh
OURBOX_VARIANT=dev OURBOX_VERSION=dev ./tools/build-image.sh
./tools/publish-os-artifact.sh deploy
./tools/pull-os-artifact.sh <registry-image-ref> ./deploy-from-registry
sudo ./tools/flash-system-nvme.sh ./deploy-from-registry/os.img.xz /dev/disk/by-id/<SYSTEM_NVME_ID>
sudo ./tools/preboot-userconf.sh /dev/nvme1n1 <new-user>
# Boot validation and troubleshooting: see docs/OPS.md
```
