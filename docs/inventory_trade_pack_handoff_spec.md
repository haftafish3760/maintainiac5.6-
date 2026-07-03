# Inventory Trade Pack Handoff Spec

Date written: 2026-06-28 16:59 EDT

Project: Maintainiac 5.6

Workspace path on the Mac: `/Users/rbbie/Documents/Maintainiac_5.6`

## Hard Boundaries

- Work only in Maintainiac 5.6.
- Do not edit Maintainiac 5.5.
- Do not touch native camera, shared receipt capture, OCR image prep, receipt stitching, or expense receipt capture. Another model may be working there.
- Do not touch PDF import/render/preview/export systems while doing materials parser/catalog work.
- Do not edit Expenses receipt capture, OCR review, camera, or PDF pipeline. Materials may later consume the shared output, but this work must not change the shared pipeline.
- Do not push anything to Firebase yet.
- Do not create one Firestore document per catalog item. Trade packs must eventually publish as a manifest plus bundled storage chunks.
- Do not run full-catalog exhaustive parser tests after every edit. Use targeted tests first.
- Do not add random trades while Plumbing is still active.
- Keep generated/source files near the 500-line target when practical. Avoid multi-thousand-line files.
- Keep parser/catalog/identity logic independent of the current Work Supplies UI so future UI/UX changes do not break the catalog brain.

## Product Intent

Work Supplies is the inventory/materials system for Maintainiac. It supports contractors, gig drivers, delivery workers, and small companies that work from vehicles or small shops.

The catalog is not supposed to be a visible big-box-store browse tree. Its main job is to assist:

- manual inventory entry
- receipt line recognition
- add-to-inventory suggestions
- estimate and invoice material cost lookup
- package quantity math
- user-linked barcode lookup later
- local-first/offline usage

Users must always be able to add an item manually even if the preload catalog cannot identify it.

## Current Strategy

The app should not ship a huge all-trades catalog in the base install. Use trade packs:

- Core/basic pack: most common items.
- Standard pack: deeper but still common coverage.
- Professional pack: broader service-company coverage.
- Complete pack: full trade coverage.

Each pack must show the estimated size before download.

Large packs should eventually be downloaded from Firebase/hosted storage, but only as bundled files/chunks with one manifest read, not one read per item.

Older phones must use smaller parser limits and avoid professional/complete packs when the phone cannot handle them.

## Catalog Intelligence Contract

Use `docs/materials_catalog_intelligence_contract.md` as the source of truth for the catalog brain.

Important direction:

- Rich smart rows matter more than raw item count.
- Every item should support residential, lightIndustrial, and commercial scope tags.
- A single canonical item can belong to multiple scopes and pack tiers.
- Current default focus is residential plus light industrial, with commercial structured for later growth.
- Residential plumbing complete target is roughly 12,000 to 15,000 smart items before heavy commercial expansion.
- Whole residential/light-industrial catalog target is roughly 65,000 to 90,000 smart items, with a practical target near 75,000 smart items.
- Parser data must include aliases, receipt abbreviations, OCR mistake patterns, vendor/SKU mapping slots, attribute tokens, negative-match rules, confidence hints, normalization rules, parser priority, classification output, and version/source tracking.
- Do not add dumb rows that only have a name.
- OCR mistake patterns are parser tolerance rules only; do not edit OCR/camera/PDF/Expenses capture code.
- Parser and catalog data must remain UI-independent.

## Current Catalog State

Last verified catalog snapshot before this handoff:

- Total catalog items: `56,103`
- Plumbing items: `11,711`
- Plumbing categories: `14`
- Plumbing systems: `35`
- Plumbing item types: `163`
- Plumbing aliases: `60,744`
- Plumbing parser terms: `132,563`
- Plumbing readiness: `Strong`

Current active target:

- Plumbing target: `15,000` items
- Plumbing remaining to target: `3,289` items

This target covers catalog count only. The full materials system still needs parser hardening, receipt-to-inventory staging, receipt-to-estimate staging, Command One diagnostics, permissions, older-device tuning, and final QA.

Current broad pass estimate from the audit doc:

- Remaining catalog generation: about `39` quality passes at roughly `1,500` items per pass across all targeted trades.
- Full professional materials system from current state: about `82-115` passes.

These are estimates, not a finish line. Stop earlier only if current evidence proves the system is complete.

## Files To Read First

Read these before editing:

- `docs/work_supplies_spec.md`
- `screen_notes/inventory_materials.txt`
- `docs/materials_trade_pack_completion_audit.md`
- `lib/screens/work_supplies/data/work_supply_catalog.dart`
- `lib/screens/work_supplies/data/catalog/plumbing/plumbing_catalog.dart`
- `test/work_supply_plumbing_receipt_parser_test.dart`
- `lib/screens/work_supplies/data/work_supply_receipt_parser.dart`
- `lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_core.dart`

## Important Existing Work

### Trade Pack Infrastructure

Relevant files:

- `lib/screens/work_supplies/data/work_supply_trade_pack_tiers.dart`
- `lib/screens/work_supplies/data/work_supply_trade_pack_manifest.dart`
- `lib/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart`
- `lib/screens/work_supplies/data/work_supply_parser_device_profile.dart`
- `lib/screens/work_supplies/work_supply_settings_pack_panels.dart`
- `lib/screens/work_supplies/work_supply_settings_screen.dart`

What exists:

- Pack tiers exist.
- Pack manifest/chunk concepts exist.
- Install guard exists.
- Device profile limits exist.
- Pack settings UI shows pack size, manifest facts, and install facts.

Known unfinished item:

- Live metered-network detection is not implemented. The UI currently labels network cost as not verified instead of pretending it checked.

### Device/Storage Edge Cases

Current rules:

- Block pack install if free storage is too low.
- Block pack install if free storage cannot be verified.
- Warn on metered data when live detection is eventually wired.
- Keep older/light devices on smaller packs.

Verified tests before this handoff:

- `flutter test test/work_supply_trade_pack_install_guard_test.dart test/work_supply_parser_device_profile_test.dart --timeout 2m`
- Result: `6` tests passed.

## Plumbing Catalog Files

Current Plumbing files include:

- `lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_items.dart`
- `lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_service_truck_catalog.dart`
- `lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_drain_finish_catalog.dart`
- `lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_seals_service_catalog.dart`
- plus smaller hand-authored category files under `plumbing/`

Do not dump more into `generated_plumbing_service_truck_catalog.dart`; it is already near the 500-line target.

Line counts seen at handoff:

- `generated_plumbing_service_truck_catalog.dart`: `474` lines
- `generated_plumbing_drain_finish_catalog.dart`: `276` lines
- `generated_plumbing_seals_service_catalog.dart`: `246` lines
- `test/work_supply_plumbing_receipt_parser_test.dart`: `364` lines
- `work_supply_receipt_parser_trade_scores_core.dart`: `2333` lines

The parser scoring file is already too large by the preferred rule, but it existed in that shape. Do not make it much worse unless needed. Future cleanup should split trade scoring further when safe.

## Completed Plumbing Passes

### Service Truck Stock Pass

Added focused Plumbing service-truck stock:

- stop valve repair hardware
- water heater service parts and install accessories
- tubular drain service stock
- toilet tank, flange, and seal parts
- faucet aerators and repair assortments
- sump pump discharge/control support stock

Relevant file:

- `lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_service_truck_catalog.dart`

Parser polish completed:

- Water-heater anode/element lines no longer get stolen by generic water-heater connector/drain/dielectric/relief-valve matches.
- Pump check valves, high-water alarms, and float switches are separated so broad sump-pump matches do not steal those lines.

### Drain and Finish Service Stock Pass

Added:

- sink basket strainers and disposal flanges
- dishwasher drain hose, air gaps, branch tailpieces, and disposal connection kits
- tubular trap adapters, wall bends, trap arms, slip-joint trim hardware, and escutcheons
- cleanout plugs/covers and floor-drain finish parts
- closet-flange repair hardware and toilet finish trim

Relevant file:

- `lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_drain_finish_catalog.dart`

Verified before this handoff:

- `flutter test test/work_supply_plumbing_receipt_parser_test.dart --timeout 2m`
- `flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m`
- `flutter test test/work_supply_trade_pack_completion_audit_test.dart --timeout 2m`
- targeted Dart analysis on touched files

Result:

- Plumbing parser had `13` passing tests.
- Total catalog became `56,103`.
- Plumbing became `11,711`.

## Current In-Progress Work At Handoff

### Pass 54: Seals, Packing, and Thread Service Stock

This pass was started but not verified because the user interrupted the test run to request this handoff file.

Files added/changed in this pass:

- Added `lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_seals_service_catalog.dart`
- Updated `lib/screens/work_supplies/data/work_supply_catalog.dart`
- Updated `lib/screens/work_supplies/data/catalog/plumbing/plumbing_catalog.dart`
- Updated `lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_core.dart`
- Updated `test/work_supply_plumbing_receipt_parser_test.dart`

New intended coverage:

- faucet washers
- bib washers
- seat washers
- O-rings
- stem packing
- valve packing
- bonnet packing
- tank and flush seals
- closet seals
- hose bibb repair seals
- vacuum breaker repair
- pipe dope
- thread sealant
- PTFE/Teflon tape
- gas tape

Important: this pass has not been proven green yet.

First task for the next model:

1. Run:

   ```bash
   dart format lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_seals_service_catalog.dart \
     lib/screens/work_supplies/data/work_supply_catalog.dart \
     lib/screens/work_supplies/data/catalog/plumbing/plumbing_catalog.dart \
     lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_core.dart \
     test/work_supply_plumbing_receipt_parser_test.dart
   ```

2. Then run:

   ```bash
   flutter test test/work_supply_plumbing_receipt_parser_test.dart --timeout 2m
   ```

3. If it fails, fix the actual parser mismatch. Do not weaken the tests just to make them pass unless the parser is selecting a more specific correct item and the old assertion is only checking an outdated label.

4. After the Plumbing parser test passes, run:

   ```bash
   flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m
   flutter test test/work_supply_trade_pack_completion_audit_test.dart --timeout 2m
   dart analyze lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_seals_service_catalog.dart \
     lib/screens/work_supplies/data/work_supply_catalog.dart \
     lib/screens/work_supplies/data/catalog/plumbing/plumbing_catalog.dart \
     test/work_supply_plumbing_receipt_parser_test.dart
   ```

5. Update `docs/materials_trade_pack_completion_audit.md` with new catalog totals, Plumbing totals, and remaining count.

## Testing Strategy For The HP Desktop

The HP ProDesk has more RAM, but still avoid wasteful testing.

Routine tests:

```bash
flutter test test/work_supply_plumbing_receipt_parser_test.dart --timeout 2m
flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m
flutter test test/work_supply_trade_pack_completion_audit_test.dart --timeout 2m
flutter test test/work_supply_trade_pack_install_guard_test.dart test/work_supply_parser_device_profile_test.dart --timeout 2m
```

Use targeted trade parser tests:

```bash
flutter test test/work_supply_hvac_receipt_parser_test.dart --timeout 2m
flutter test test/work_supply_electrical_receipt_parser_test.dart --timeout 2m
```

Do not run full exhaustive neighbor/fuzzy catalog tests after every edit.

Full catalog or performance tests should be manual/explicit only, after a batch is complete.

Testing rule:

- Fast fixture tests should run constantly.
- Targeted real trade tests should run when parser logic changes.
- Full-catalog tests should be manual only.
- Heavy neighbor/fuzzy tests must be behind a separate command/flag and should not be run by default.
- Normal parser tests should aim to finish in under a few minutes.

## Parser Rules

The parser must help users avoid manual entry, but it must never pretend it knows something when confidence is weak.

Needed behavior:

- Use aliases, abbreviations, normalized terms, package words, and merchant/SKU space.
- Handle common stores and suppliers such as Lowe's, Home Depot, Ace, Ferguson, and supply houses.
- Keep trade scope in mind, but allow correction because some items cross trades.
- Store user-confirmed learning separately later.
- Support item package math later: each, pack, roll, tube, can, foot, box, case, bag, kit, etc.

When adding catalog data, add parser tests with receipt-like strings. Do not just add items.

Good test examples:

- all caps receipt wording
- shorthand terms
- size shorthand
- store-counter language
- ambiguous items that could get stolen by older broader matches

## Known Parser Conflict Pattern

Adding a more specific generated item can cause old parser tests to fail because the parser starts selecting a more specific correct item.

This happened with:

- water heater drain/relief items
- pump float/check/alarm items
- trap adapters
- dishwasher drain parts

How to handle:

- If the new item is actually more specific and correct, update the test assertion to validate the business truth, not the old exact display label.
- If the parser chooses a wrong family, fix scoring.
- If a new category steals a different real-world item, add negative scoring for the conflicting context.

## Next Plumbing Catalog Gaps

After finishing and verifying Pass 54, continue Plumbing one focused category at a time.

Likely high-value next areas:

- appliance/water supply accessory detail: icemaker kits, washer hoses, dishwasher connectors, hammer arrestors, outlet boxes
- gas connector/service detail: appliance connector sizes, sediment traps, gas shutoff accessories, leak-test supplies
- drain cleaning/service accessories: auger cables, cutter heads, drain bladders, test plugs, inflatable plugs
- pipe support and protection detail: stud guards, nail plates, isolators, pipe sleeves, pipe wrap, insulation, escutcheon variations
- pressure test and repair stock: gauges, test caps, plugs, boiler drains, hose adapters
- PEX tool/consumable detail if useful for service trucks: rings, clamps, sleeves, stub-outs, supports, bend supports

Do not move to HVAC/Electrical until Plumbing is acceptable unless the user explicitly redirects.

## Command One / Admin Diagnostics Requirements

Command One folder on the Mac was seen as:

- `/Users/rbbie/Documents/Comand 1`

Spelling matters: it is `Comand 1`, with one `m` and the numeral `1`.

Inventory-related diagnostics should eventually show:

- trade pack install blocked
- device parser limited
- barcode/SKU match attempted
- receipt parse completed
- inventory/estimate staging
- parser failure

Privacy rule:

- Do not send receipt text, receipt images, customer names, job addresses, locations, or user-private inventory content to Command One.
- Use summarized, content-free health events only.

## Firebase Rules For Future Work

Do not push trade packs to Firebase until packs are verified.

When publishing is approved:

- Upload bundled/chunked pack files.
- Upload one manifest per pack/version.
- Avoid per-item Firestore reads/writes.
- Include pack version, trade, tier, compressed size, uncompressed size if known, item count, parser term count, checksum/hash, and storage path.
- Keep local-first behavior; downloaded packs must work offline after install.

## Barcode Rules

Barcodes are part of the future inventory foundation, but do not scrape or preload manufacturer/retailer barcode databases.

Allowed:

- user scans a barcode
- user links it to their own inventory item
- user can have multiple barcodes for the same logical item
- barcode aliases are local/user-owned by default

Future opt-in sharing may be discussed later, but it needs abuse protection and removal rights.

## UI / UX Rules For Inventory

Work Supplies is a real utility app, not a toy catalog browser.

User-facing behavior:

- Home should show saved inventory and useful actions, not a giant catalog.
- Trade packs assist search and receipt review in the background.
- User should be able to add supplies with or without a receipt.
- Receipt proof is optional.
- The user must be able to assign receipt lines to company inventory, a vehicle, a job staging area, or custom location.
- Mixed business/personal receipts must be supported eventually.
- Line-level decisions matter because invoices/estimates may later reference specific receipt lines.

## Current Branch/Repo Safety

The worktree has many existing modified/untracked files from other work and other models. Do not revert unrelated files.

Especially avoid touching:

- `lib/shared/widgets/receipt_capture/`
- native Android/iOS camera files
- `lib/screens/expenses/`
- 5.5 project files

Before making broad edits, run:

```bash
git status --short
```

Use targeted diffs on files you touched.

## Handoff Summary For The Next Codex

You are continuing the Maintainiac 5.6 Work Supplies inventory/trade-pack buildout.

Start by finishing Pass 54:

- Verify `generated_plumbing_seals_service_catalog.dart`.
- Fix parser tests if needed.
- Run Plumbing targeted tests.
- Update audit totals.

Then continue Plumbing, one focused service-vehicle category at a time, until Plumbing is genuinely strong enough for receipt-to-inventory and receipt-to-estimate workflows.

Do not drift into other trades yet.

Do not touch camera/expense capture.

Do not push Firebase.

Do not edit 5.5.
