# img-ourbox-mini-rpi

Build repository for **OurBox Matchbox Base** (`TOO-OBX-MBX-BASE-001`) OS images targeting
**Raspberry Pi hardware** (Pi 5 + dual NVMe).

This repo produces an NVMe-bootable OS that mounts `/var/lib/ourbox` and boots into an airgapped
single-node k3s runtime via `ourbox-bootstrap`.

## Naming definitions (source of truth)

- **Model = size/form-factor class.**
- **Trim = intent.**
- **SKU = exact BOM/software build** (including colors, capacities, vendors).

## Docs

- Operator runbook: [`docs/OPS.md`](./docs/OPS.md)
- Contracts reference: [`docs/reference/contracts.md`](./docs/reference/contracts.md)

## Happy path (build → publish → flash → boot)

```bash
git clone --recurse-submodules https://github.com/techofourown/img-ourbox-mini-rpi.git
cd img-ourbox-mini-rpi
./tools/ops-e2e.sh
```
