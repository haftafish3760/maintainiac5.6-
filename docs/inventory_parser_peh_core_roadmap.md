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
   - Mixed-trade receipts are mandatory PEH proof, not stretch coverage.
   - Small shared materials such as `3/4 in PVC` and `1 in PVC` must stay
     conservative until the receipt provides trade context like `conduit`,
     `condensate`, `dwv`, `sch40`, `san tee`, or similar disambiguating words.
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

## Current Windows Snapshot

Generated from the current Windows-side evidence on 2026-07-09.

- Plumbing Core
  - `1241` Core rows
  - `1241` release-ready rows
  - measured generated benchmark status already recorded at `100/100` checked,
    `0` failures, `100` parser calls
  - still has one focused Windows runtime bottleneck around the Menards PVC
    sanitary-tee parser rerun, so Mac remains the better place for the final
    focused runtime proof
- Electrical Core
  - `1902` Core rows
  - `1902` release-ready rows
  - readiness audit currently reports `readyForMacValidation=true`
  - focused Windows generated evidence now includes clean `en-US` and `es-US`
    checkpoints at `25/25` each and an aggregate
    `windows_electrical_core_generated_run_status_50.json` rollup at
    `50/50`, `0` failures, `1.0000` pass rate, and `88` parser calls
  - Electrical is no longer the active PEH gap on this branch; HVAC is the
    only remaining measured-coverage gap
- HVAC Core
  - `2695` Core rows
  - `2695` release-ready rows
  - readiness audit currently reports `readyForMacValidation=true`
  - next required Windows evidence is the measured generated-status layer, not
    another broad catalog rewrite
  - the HVAC core generated-fixture corpus now front-loads the Windows/Mac
    sample around the highest-value service families first:
    dangerous filter review, dual-run capacitor, contactor, condensate pump,
    thermostat wire, humidifier water panel, flame sensor, and condensate
    coupling

## Immediate Execution Order

1. Keep Plumbing as the active trade until Windows-side focused/runtime-safe
   proof is exhausted.
2. Preserve the refreshed Plumbing `100`-case measured status artifact with the
   `0.90` pass-rate gate.
3. Preserve the refreshed Electrical trade rollup at `50/50` checked cases,
   `0` failures, `1.0000` pass rate, and `88` parser calls.
4. Preserve the refreshed HVAC sample rollup at `12` checked cases and keep it
   clearly labeled as sample-sized evidence, not final proof.
5. Hand off the next broader Electrical/HVAC measurement wave to Mac using the
   canonical PEH measurement plan.

## Active Execution Map

This is the exact ordered map for the current branch. Do not drift out of this
order unless a shared parser rule blocks the active step.

### Stage 1: Windows checkpoint governance

1. Preserve the current branch truth in machine-readable artifacts.
   - `peh_core_windows_status_rollup.json`
   - `peh_core_mac_wave_commands.json`
   - `peh_core_handoff_readiness.json`
2. Preserve the explicit remaining-gap artifact so the branch cannot overclaim
   progress.
   - `peh_core_measurement_gap.json`
   - Current remaining checked coverage:
     - Plumbing: `0`
     - Electrical: `0`
     - HVAC: `38`
3. Keep the harness-governance layer enforcing those artifacts and fields.
4. Do not claim `90-95%` PEH readiness while Electrical/HVAC are still below
   their measured target counts.

### Stage 2: Plumbing Windows completion

1. Keep Plumbing as the active Windows trade until there is no meaningful
   Windows-safe parser/catalog/fixture work left.
2. Preserve the measured `100/100` generated checkpoint.
3. Preserve or refresh focused runtime-safe evidence for the remaining Menards
   PVC sanitary-tee path.
4. Do not reopen broad Plumbing catalog rewrites unless new evidence proves a
   real gap.

### Stage 3: Electrical measured expansion

1. Use the existing Electrical release-ready catalog and metadata baseline.
2. Preserve the clean Windows `en-US` focused checkpoint at `25/25` checked,
   `0` failures, `1.0000` pass rate, and `44` parser calls.
3. Preserve the matching clean Windows `es-US` focused checkpoint at `25/25`
   checked, `0` failures, `1.0000` pass rate, and `44` parser calls.
4. Preserve the Electrical Windows trade rollup at `50/50` checked with local
   safety flags clean.
5. Refresh the branch rollup and measurement-gap artifacts after each accepted
   evidence increase.

### Stage 4: HVAC measured expansion

1. Use the existing HVAC release-ready catalog and metadata baseline.
2. Expand measured generated evidence from the current `12`-case sample toward
   the `50`-checked target.
   - Preserve the new front-loaded sample order so the first Windows/Mac slice
     exercises the highest-value HVAC service families before broader coverage
     fills in the rest of the corpus.
3. Fix only real parser/metadata misses surfaced by the generated-fixture wave.
4. Refresh the branch rollup and measurement-gap artifacts after each accepted
   evidence increase.

### Stage 4B: Mixed PEH ambiguity proof

1. Add explicit mixed-trade PEH regressions for overlapping receipt language.
2. Force conservative review behavior for bare shared-material lines such as:
   - `3/4 PVC`
   - `1 IN PVC`
   - `3/4 PVC CPLG`
   - `1 IN PVC TEE`
3. Force direct-trade selection only when the receipt adds strong context such
   as:
   - Electrical: `conduit`, `terminal adapter`, `male adapter`
   - HVAC: `cond`, `condensate`, `drain`, `trap`, `vent`
   - Plumbing: `dwv`, `sch40`, `pressure`, `cleanout`, `san tee`
4. Treat mixed-trade receipt proof as part of PEH readiness, not a post-claim
   cleanup item.

### Stage 5: Mac handoff and heavier validation

1. Hand off only the exact next Electrical/HVAC measurement commands recorded
   in `peh_core_mac_wave_commands.json`.
2. Track Mac progress through `peh_core_mac_wave_status.json` instead of chat
   memory or folder browsing.
   - Electrical expected checked total: `50`
   - HVAC expected checked total: `50`
   - Merge is blocked until both trade rollups exist, stay local-only safe, and
     clear the `0.90` pass-rate floor.
3. Track final claim readiness through `peh_core_claim_readiness.json`.
   - The claim gate must stay red until Plumbing is ready from the Windows
     rollup and Electrical/HVAC are merge-ready from the Mac wave.
4. Build the first mixed-platform PEH checkpoint through
   `peh_core_merged_status_rollup.json`.
   - Plumbing source: Windows rollup
   - Electrical source: Mac rollup
   - HVAC source: Mac rollup
5. Refresh the downstream PEH truth stack through
   `work_supply_parser_qa_peh_core_refresh.dart` whenever new Mac evidence
   lands, so Mac-wave status, merged rollup, and claim readiness are rebuilt
   together.
6. Publish the external run contract through
   `peh_core_mac_handoff_packet.json` so the Mac side gets one canonical
   machine-readable packet instead of scattered commands.
7. Materialize that packet into `peh_core_mac_handoff.sh` before external
   execution so the Mac side can run one prepared script with POSIX-safe paths.
8. Roll the Mac evidence back into the Windows-side rollup rather than making
   undocumented claims in chat.
9. Claim `90-95%` only after:
   - Plumbing measured evidence remains clean
   - Electrical measured evidence clears target
   - HVAC measured evidence clears target
   - `peh_core_claim_readiness.json` reports `readyToClaimNinetyPlus=true`
   - `peh_core_merged_status_rollup.json` reports `readyToClaimNinetyPlus=true`
   - branch rollup reports `readyToClaimNinetyPlus=true`

### 1. Plumbing Core

Status: active until Windows-side catalog, metadata, fixture, and focused
generated-validation work are exhausted.

Order:

1. Reconfirm exact Plumbing Core count and family distribution.
2. Reconfirm Core membership against normal residential service-truck reality.
3. Add any missing release-one Core items that belong in normal residential
   truck stock.
4. Move or flag non-Core/specialty rows without deleting useful catalog data.
5. Complete release-ready metadata on every Plumbing Core row.
6. Complete English, Spanish, merchant-abbreviation, and ambiguity-negative
   coverage for those rows.
7. Complete synthetic fixture coverage for every required Plumbing Core family.
8. Run Windows-safe focused validation first.
9. Fix focused misses with parser/metadata regressions.
10. Preserve measured Plumbing generated validation with the `0.90` floor.
11. Repeat focused hardening until Windows has no meaningful Plumbing work left
    except heavier platform validation.
12. Hand Plumbing to Mac only after the measured Windows evidence is as high as
    this machine can safely prove; on the current branch that means the
    refreshed `100/100` status artifact plus the focused Menards runtime proof
    remaining for Mac.

### 2. Electrical Core

Start only after Plumbing Core is Windows-complete except for heavier Mac
validation, unless a shared parser collision requires a joint Plumbing /
Electrical fix.

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
12. Refresh or preserve a measured Electrical generated-status artifact on
    Windows when it can be done from existing reports without heavy reruns.
13. Create or refresh the Electrical Mac validation handoff.

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

Start only after Electrical Core is Windows-complete except for heavier Mac
validation, unless a shared parser collision requires a joint Electrical / HVAC
fix.

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
12. Refresh or preserve a measured HVAC generated-status artifact on Windows
    when it can be done from existing reports without heavy reruns.
13. Create or refresh the HVAC Mac validation handoff.

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
- Use measured generated-fixture pass-rate gates for release claims.
  - A green readiness audit is not enough to claim `90-95%` accuracy.
  - We must record `checked`, `failureCount`, `passRate`, and `parserCalls`
    from the generated fixture runner.
  - `0.90` is the minimum release floor for any PEH Core accuracy claim.
  - `0.95` is the stretch target after the first measured floor is cleared.
  - We raise the floor only with real evidence, not optimism.
- Use focused parser fixture reruns for changed families.
- Use family shards after focused failures are clean.
- Use full Core validation only at trade-level milestones.
- On this Windows machine, prefer Dart/tooling checks and focused generated
  slices before broad Flutter-based validation, because startup cost is high and
  can hide true parser behavior.
- While a long run is active, do not watch it. Work on the next catalog or
  fixture batch, then inspect final logs.
- On this Windows box, treat `dart run` compile crashes inside the current
  FFI/build-hook path as environment failures unless a narrower parser or audit
  signal proves they are caused by inventory/parser code.

## Validation Ladder

1. Catalog scope and family membership.
2. Release-ready metadata depth.
3. English, Spanish, abbreviation, and ambiguity-negative coverage.
4. Synthetic fixture coverage for the family being edited.
5. Windows-safe focused generated validation.
6. Trade-level measured generated validation with the `0.90` floor.
7. Mixed-trade PEH ambiguity validation across plumbing/electrical/HVAC shared
   materials.
8. Mac-side heavier validation after Windows-side hardening is exhausted.

## Accuracy Phase Roadmap

### Pass 5060-5062: Measurement Gate

- Finish the generated fixture runner accuracy gate.
- Add `--min-pass-rate` support and write `passRate` into aggregate reports.
- Add regression tests so the runner fails when measured accuracy drops below
  the requested floor.
- Keep this gate local-only and inventory/parser/QA-only.

### Pass 5063-5068: Plumbing Accuracy Proof

- Run focused Plumbing Core generated validation samples with the `0.90` floor.
- Record actual measured pass rate and top misses.
- Fix the biggest miss families first, then rerun the same sample.
- Do not claim `95%` until repeated measured runs support it.

### Pass 5069-5076: Electrical Accuracy Proof

- Run focused Electrical Core generated validation samples with the same floor.
- Repair the most frequent abbreviation, ambiguity, and merchant-style misses.
- Rerun until the measured sample clears the floor or the exact blockers are
  documented.

### Pass 5077-5084: HVAC Accuracy Proof

- Run focused HVAC Core generated validation samples with the same floor.
- Repair the top misses in controls, condensate, filters, and duct/service
  stock wording.
- Rerun until the measured sample clears the floor or the exact blockers are
  documented.

### Pass 5085+: Rollup and Handoff

- Capture the measured PEH Core percentages in progress memory and reports.
- Push milestone commits with human-readable EDT labels.
- Prepare the Mac validation handoff using measured Windows-side evidence,
  not just readiness audits.
- Keep Electrical and HVAC sample-sized Windows evidence explicitly labeled as
  sample-sized until the broader `25 + 25` Mac wave clears the same gate.

## Completion Definition

Each trade can move to Mac validation only when:

- Core membership is intentionally curated.
- Required Core items are present or documented as release-blocking gaps.
- All Core rows have release-ready metadata.
- English and Spanish terms are present.
- Ambiguity rules exist for cross-trade/shared-use items.
- Synthetic receipt fixtures cover the family.
- Focused parser evidence is clean.
- Measured generated-fixture validation clears the agreed minimum pass-rate
  floor for the active release claim.
- Mixed-trade PEH ambiguity regressions are clean for shared materials like
  small PVC, tubing, and overlapping service-stock wording.
- Readiness audit reports zero critical, zero needs-work, and all Core rows
  release-ready.
- The milestone commit is pushed with a human-readable EDT label.
