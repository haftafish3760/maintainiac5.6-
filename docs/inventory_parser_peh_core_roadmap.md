# PEH Core Inventory Parser Roadmap

This is the active roadmap for release-one Plumbing, Electrical, and HVAC Core
inventory/parser work. It exists to prevent drift and to keep the work ordered
like a professional catalog/parser team would handle it.

## Boundaries

- Work only in inventory/catalog/parser/QA support.
- Do not touch OCR, camera, expenses, UI, PDF, maintenance, or unrelated app
  modules from this roadmap.
- Do not use scraped vendor catalogs or copied real receipts.
- External data is allowed only when the source and license are safe enough to
  document in the repo.
- Hive/local remains the source of truth for user inventory records.
- Parser output remains suggestion data until the user confirms it.

## Professional Order

1. Build the catalog scope first.
   - Decide which items belong in Core for normal residential service work.
   - Add missing Core items before final parser proof.
   - Move or flag items that are real trade items but not Core truck-stock.
   - Complete one trade before moving to the next unless a shared parser rule
     blocks both trades.
2. Complete metadata for those Core items.
   - Each release-ready item needs canonical identity, family, trade, tier,
     market scope, sizes, material/style/type, aliases, merchant abbreviations,
     Spanish terms, ambiguity negatives, source confidence, and parser risk
     tags.
   - Shared-use items need context rules instead of confidence caps.
   - Metadata must explain when the parser should match, ask for review, or
     prefer another trade context.
3. Generate synthetic receipt fixtures.
   - Cover box stores, supply houses, hardware stores, local/regional
     suppliers, counter-sale lines, unknown merchants, abbreviations, OCR-like
     noise, Spanish wording, and mixed-trade receipts.
   - Use synthetic examples only. Do not copy private receipts into the repo.
4. Run focused validation while building.
   - Use scripts and Dart/tool checks first when they prove the behavior.
   - Run focused parser fixtures for the family being edited.
   - Do not run broad/heavy shards until catalog scope and metadata gates are
     clean for that family.
5. Promote family evidence.
   - A family is release-ready only after catalog scope, metadata, fixture
     generation, focused parser behavior, ambiguity negatives, and readiness
     audit agree.
   - Smoke checks and token scans are not enough.
6. Run heavier shards after readiness gates.
   - Prefer isolated families and smaller chunks when they make failures more
     diagnosable and reduce machine throttling.
   - Run full Core validation after family shards are clean.
7. Handoff to Mac validation.
   - Windows proves deterministic catalog/parser behavior.
   - Mac validates platform/build/runtime behavior later.

## Trade Sequence

### 1. Plumbing Core

Status: ready for Mac validation based on the latest local readiness audit.

Required before reopening Plumbing:

- Only fix confirmed failures from the background full validation or Mac
  validation.
- Do not add new Plumbing Core items unless a documented catalog gap proves the
  item belongs in release-one Core.
- Every confirmed Plumbing parser bug gets a regression fixture.

### 2. Electrical Core

Active work now.

Order:

1. Audit exact Electrical Core count and family distribution.
2. Check catalog scope against residential service reality.
3. Add missing Core items for common residential service stock.
4. Move or flag non-Core/specialty rows without deleting useful catalog data.
5. Add Electrical Core metadata and parser-risk tags.
6. Add English and Spanish aliases/receipt patterns.
7. Add ambiguity negatives for plumbing/HVAC/general hardware collisions.
8. Add synthetic family fixtures.
9. Run focused family parser checks.
10. Fix failures with metadata/parser regressions.
11. Run Electrical readiness audit until release-ready rows equal Core rows.
12. Run isolated Electrical Core shards.
13. Create Electrical Mac validation handoff.

Primary Electrical Core families:

- Wire and cable.
- Boxes, covers, plates, and rings.
- Devices and controls.
- Breakers, panels, and load-center accessories.
- Conduit, raceway, fittings, straps, and bushings.
- Connectors, splices, staples, and consumables.
- Grounding and bonding.
- Lighting, smoke/CO, doorbell, and low-voltage service parts.
- Disconnects, surge protection, and small service equipment.

### 3. HVAC Core

Start only after Electrical Core is ready for Mac validation, unless a shared
parser collision requires a joint Electrical/HVAC fix.

Order:

1. Audit exact HVAC Core count and family distribution.
2. Check catalog scope against residential service truck reality.
3. Add missing Core items for common residential HVAC service stock.
4. Move or flag non-Core/specialty/equipment rows without deleting useful
   catalog data.
5. Add HVAC Core metadata and parser-risk tags.
6. Add English and Spanish aliases/receipt patterns.
7. Add ambiguity negatives for plumbing/electrical/general hardware collisions.
8. Add synthetic family fixtures.
9. Run focused family parser checks.
10. Fix failures with metadata/parser regressions.
11. Run HVAC readiness audit until release-ready rows equal Core rows.
12. Run isolated HVAC Core shards.
13. Create HVAC Mac validation handoff.

Primary HVAC Core families:

- Air filters and filter accessories.
- Condensate drains, pumps, pans, switches, and tubing.
- Thermostats, contactors, capacitors, relays, fuses, and transformers.
- Tape, mastic, foil tape, insulation, sealants, and service consumables.
- Basic duct/airflow service parts and small hardware.
- Refrigerant line service accessories that are normal truck-stock.
- Ignition/gas heat service parts that are normal residential service stock.
- Common service fasteners and supports.

## Testing Strategy

- Use cheap scripts to check counts, family membership, metadata depth,
  duplicate aliases, collision risk, Spanish coverage, fixture coverage, and
  readiness JSON.
- Use focused parser fixture reruns for changed families.
- Use family shards after focused failures are clean.
- Use full Core validation only at trade-level milestones.
- While a long run is active, do not watch it. Work on the next catalog or
  fixture batch, then inspect final logs.

## Completion Definition

Each trade can move to Mac validation only when:

- Core membership is intentionally curated.
- Required Core items are present or documented as release-blocking gaps.
- All Core rows have release-ready metadata.
- English and Spanish terms are present.
- Ambiguity rules exist for cross-trade/shared-use items.
- Synthetic receipt fixtures cover the family.
- Focused parser evidence is clean.
- Readiness audit reports zero critical, zero needs-work, and all Core rows
  release-ready.
- The milestone commit is pushed with a human-readable EDT label.
