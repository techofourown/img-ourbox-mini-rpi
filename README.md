# img-ourbox-mini-rpi

Build repository for **OurBox Mini** OS images targeting **Raspberry Pi hardware** (Pi 5 + dual NVMe).

This repo produces an NVMe-bootable OS that mounts `/var/lib/ourbox` and boots into an airgapped
single-node k3s runtime via `ourbox-bootstrap`.

## Product identity (Model → Trim → SKU)

- **Model** = size/form-factor class (physical contract).
- **Trim** = intent label (not a spec sheet).
- **SKU** = exact BOM + software load, including incidental variants like color or capacity.

The OurBox Mini build in this repo targets the **OurBox Matchbox Base** SKU:
`TOO-OBX-MBX-BASE-001`.

## Docs

- Operator runbook: [`docs/OPS.md`](./docs/OPS.md)
- Contracts reference: [`docs/reference/contracts.md`](./docs/reference/contracts.md)

## Happy path (build → publish → flash → boot)

```bash
git clone --recurse-submodules https://github.com/techofourown/img-ourbox-mini-rpi.git
cd img-ourbox-mini-rpi
./tools/ops-e2e.sh
```
