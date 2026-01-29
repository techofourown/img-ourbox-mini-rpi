---
typeId: product_family
recordId: ourbox
fields:
  name: OurBox
  description: Hardware product family for OurBox appliances.
  modelDefinition: Model = size/form-factor class.
  trimDefinition: Trim = intent label.
  skuDefinition: SKU = exact BOM/software build (including colors/capacities/vendors).
---
# OurBox product family

This repository is the source of truth for OurBox naming and identifiers.

## Definitions

- **Model = size/form-factor class.** Models represent physical contracts (mounting/enclosure class).
- **Trim = intent.** Trims describe configuration intent, not detailed specs.
- **SKU = exact BOM/software build.** SKUs capture buildable, traceable variants (including color,
  capacity, vendor swaps, and region bundles).

## Current identifiers

- Model identifier: **OurBox Matchbox** `TOO-OBX-MBX-01`
- Default trim: **Base**
- SKU identifier for this repo’s build target: `TOO-OBX-MBX-BASE-001`
