---
typeId: product_family
recordId: ourbox
fields:
  name: OurBox
  description: OurBox hardware product family records.
---
# OurBox product family

OurBox naming follows the organization-wide schema:

- **Model = size/form-factor class** (physical contract).
- **Trim = intent label** (not a spec sheet).
- **SKU = exact BOM + software build**, including incidental variants such as color, capacity, or
  vendor substitutions.

SKU identifiers are manufacturer part numbers and must start with `TOO-`.

## Canonical identifiers

- **Model ID format:** `TOO-OBX-<MODEL>-<GEN>`
- **SKU / Part Number format:** `TOO-OBX-<MODEL>-<TRIM>-<SEQ>`

## Active model vocabulary

| Model | Token | Intent |
|---|---|---|
| Matchbox | MBX | Raspberry Pi-class mounting / small-form-factor appliance |
| Tinderbox | TBX | Micro-ATX class enclosure / desktop-class server |

(Reserved tokens: FBX, CBX, WBX.)
