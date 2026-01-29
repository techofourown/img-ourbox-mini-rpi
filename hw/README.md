---
typeId: product_family
recordId: ourbox
fields:
  name: OurBox
  description: OurBox hardware product family.
---
# OurBox product family

## Naming schema (Model → Trim → SKU)

- **Model** = size/form-factor class (physical contract).
- **Trim** = intent label (not a spec sheet).
- **SKU** = exact BOM + software load, including incidental variants like color or capacity.

For authoritative model, trim, and SKU/part number rules, see
`hw/docs/decisions/ADR-0001-ourbox-model-trim-sku-part-numbers.md`.

## Current repo context

This repository builds the OS image for the OurBox Mini appliance, which maps to the
**OurBox Matchbox Base** SKU: `TOO-OBX-MBX-BASE-001`.
