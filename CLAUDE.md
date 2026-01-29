# OurBox naming and identifiers

This repo is the source of truth for OurBox model/trim/SKU naming. Use the following definitions
in documentation, scripts, and frontmatter:

- **Model = size/form-factor class.**
- **Trim = intent.**
- **SKU = exact BOM/software build** (including colors, capacities, vendor swaps, and region bundles).

Identifier rules:

- Model identifiers: `TOO-OBX-<MODEL>-<GEN>` (e.g., `TOO-OBX-MBX-01`).
- SKU identifiers (manufacturer part numbers): `TOO-OBX-<MODEL>-<TRIM>-<SEQ>`.
- Only `TOO-` prefixed identifiers are allowed for SKUs/part numbers. `SKU-` and `CFG-` are banned.

Current build target for this repo:

- **OurBox Matchbox Base** — `TOO-OBX-MBX-BASE-001`.
