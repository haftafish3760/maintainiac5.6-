# Inventory Trade-Pack Mac Repair Handoff

Generated: 2026-07-11 EDT

## Working Folder and Authority

Work only in:

`/Users/rbbie/Documents/Maintainiac_5.6_Active`

This Mac Mini folder is authoritative. The Windows parser work has already been
transferred here. Do not return to the Windows computer, edit another checkout,
or replace this folder from an older branch.

Before editing:

1. Confirm `pwd` matches the exact path above.
2. Run `git branch --show-current` and `git status --short`.
3. Read `PROJECT_RULES.md`.
4. Preserve all unrelated working-tree changes.
5. Do not touch camera, OCR capture, expenses, PDF, invoices, mileage, or UI.
6. Do not commit, push, delete, upload to Firebase, or rewrite history unless
   the user explicitly authorizes it.

## Explicit Scope Exception

Do not spend time splitting existing oversized files merely to satisfy the
500-line rule. The user explicitly does not want that cleanup now. Existing
large parser files may remain large if they work.

New files and necessary additions should still be kept focused. Do not make an
existing large file substantially worse when the repair can remain narrow.

## Product Intent

Maintainiac will ship on Android and iOS. Inventory receipt intake should let a
user photograph a store receipt, extract its text, match purchased materials,
review or correct the matches, and add approved quantities to inventory.

Trade catalogs must not bloat the base application. Intended modes:

- A lean bundled catalog with common items for basic usefulness.
- Free compressed trade-pack downloads stored locally for offline parsing.
- Users may install one or many packs according to their trade and storage.
- Optional subscription-based hosted assistance may use trade-pack data online
  without storing the full catalog on the phone.
- Local-only inventory and downloaded packs must work without Firebase,
  subscription, hosted backup, or an internet connection.
- Cloud backup is opt-in and separate from pack delivery and cloud parsing.

The application ships a compiled parser engine. Firebase packs are validated
data consumed by that engine. Never download or execute Dart source from
Firebase.

## Existing Foundation to Preserve

Audit and reuse these existing systems:

- `work_supply_trade_pack_manifest.dart`
- `work_supply_trade_pack_export_writer.dart`
- `work_supply_trade_pack_import_validator.dart`
- `work_supply_trade_pack_install_guard.dart`
- `work_supply_trade_pack_delivery_policy.dart`
- `work_supply_trade_pack_tiers.dart`

The repository already models:

- versioned trade-pack IDs
- trade, market, tier, locale, item, and chunk metadata
- gzip chunk files
- compressed and uncompressed size estimates
- SHA-256 validation
- bundled manifest reads instead of one Firestore read per item
- `local_gzip_pack` delivery
- subscription-marked `cloud_catalog_query` delivery

Preserve that work. Large immutable pack chunks belong in Firebase Storage.
Firestore should contain compact manifest, version, entitlement, and status
metadata—not one document that must be read for every catalog item.

## Immediate Confirmed Problem

The current analyzer failures primarily show a partially completed Dart
file-extraction operation. They do not prove that thousands of scoring rules
are individually broken.

Seventeen files contain:

`part of 'work_supply_receipt_parser.dart';`

but the parent parser does not declare them with matching `part` directives:

- `work_supply_receipt_parser_terms_part_1.dart`
- `work_supply_receipt_parser_terms_part_2.dart`
- `work_supply_receipt_parser_terms_part_3.dart`
- `work_supply_receipt_parser_terms_part_4.dart`
- `work_supply_receipt_parser_terms_part_5.dart`
- `work_supply_receipt_parser_trade_scores_cabinets_countertops.dart`
- `work_supply_receipt_parser_trade_scores_carpentry.dart`
- `work_supply_receipt_parser_trade_scores_electrical.dart`
- `work_supply_receipt_parser_trade_scores_hvac.dart`
- `work_supply_receipt_parser_trade_scores_hvac_duct.dart`
- `work_supply_receipt_parser_trade_scores_hvac_equipment.dart`
- `work_supply_receipt_parser_trade_scores_hvac_final.dart`
- `work_supply_receipt_parser_trade_scores_hvac_install_support.dart`
- `work_supply_receipt_parser_trade_scores_hvac_service.dart`
- `work_supply_receipt_parser_trade_scores_hvac_tools_hydronic.dart`
- `work_supply_receipt_parser_trade_scores_plumbing.dart`
- `work_supply_receipt_parser_trade_scores_windows_doors.dart`

Because these files are disconnected from the parent library, analysis reports:

- undefined `WorkSupplyItem`
- undefined `_normalize`
- undefined `_HvacReceiptScoreContext`
- undefined HVAC helper scoring functions
- cascading `double`-to-`int` score errors
- unused extracted functions and term collections

Old implementations are still present in connected files, especially
`work_supply_receipt_parser_trade_scores_core.dart` and
`work_supply_receipt_parser_terms.dart`. Several scorer names exist both in the
connected core file and in a disconnected extracted file. Therefore, simply
adding all 17 `part` declarations will create duplicate-definition errors.

## Required Minimal Repair

The goal is clean compilation while preserving current parser behavior. Do not
redesign the parser and do not perform general file-size cleanup.

### Step 1: Record the baseline

Run and save the exact current failures from:

```bash
flutter analyze
```

Then run the narrow existing materials/parser tests needed to establish which
paths currently work. Do not modify unrelated failures.

### Step 2: Map each orphan to its connected implementation

For every orphan file:

1. Identify every function, class, constant, and term collection it defines.
2. Search the connected parent/core files for the same symbol.
3. Compare the implementations.
4. Record whether each extracted copy is identical, newer, older, or divergent.
5. Use current tests, audit artifacts, and handoff documents to decide which
   implementation is authoritative. Do not guess from filename or timestamp.

### Step 3: Choose the smallest safe resolution

For each orphan group, use one of these outcomes:

- If the orphan is an exact redundant copy and the connected implementation is
  authoritative, remove or quarantine the orphan only with user approval.
- If the extracted file is authoritative, remove only its confirmed duplicate
  from the connected core file and add the extracted file as a parent `part`.
- If the copies diverge, stop and report the differences before choosing one.

Do not rewrite scoring rules merely to silence analysis.

Suggested repair groups:

1. Term files.
2. Carpentry, cabinets/countertops, and windows/doors.
3. Electrical.
4. Plumbing.
5. HVAC as one atomic group.

The HVAC files must be handled together because the main scorer owns
`_HvacReceiptScoreContext` and calls the equipment, duct, service,
install/support, tools/hydronic, and final scorers.

### Step 4: Interpret remaining errors correctly

After library wiring is repaired, rerun scoped analysis. Only then address any
remaining real type or scoring error.

Do not apply `.toInt()` to unresolved score results as a shortcut. Current
numeric errors are likely cascading from unresolved helper functions.

## False Fixes That Are Not Allowed

- Do not add independent imports to every `part` file.
- Do not copy `WorkSupplyItem`, `_normalize`, or the HVAC context into each file.
- Do not make private helpers public just to bypass library boundaries.
- Do not rewrite or simplify thousands of scoring rules.
- Do not delete extracted files merely because analysis calls them unused.
- Do not perform a broad 500-line cleanup.
- Do not move executable Dart scoring code into Firebase.
- Do not store/query each catalog item as a separate Firestore document.
- Do not require subscription for free local pack downloads.
- Do not upload receipts, inventory, or learned corrections without explicit
  user opt-in and a documented privacy boundary.

## Base-Install Storage Direction (2026-07-11)

- Do not ship inventory catalog items in the base app unless a later release
  explicitly approves a very small default set.
- The base app may ship only the lightweight abbreviation, merchant
  normalization, and parsing-rule layer needed to interpret common receipt
  shorthand; that layer is not an installed inventory catalog.
- For precise item resolution, use either an explicitly user-downloaded offline
  pack or the opt-in hosted pack-query service. A network-unavailable user must
  retain a clear manual entry/review fallback.
- Measure the 92-95% parser goal against a versioned, labeled corpus of
  supported merchants and trade packs. Do not describe it as 100% coverage of
  every store, abbreviation, or SKU.

## OCR Ownership Boundary (2026-07-12)

The inventory parser lane is strictly downstream of OCR and receipt capture.
Another Codex owner may change camera capture, image cleanup, long-receipt
stitching, OCR recognition, or OCR confidence. Do not edit those systems from
this lane.

This parser lane may consume only the OCR handoff contract: normalized receipt
text, optional line candidates, OCR confidence where available, merchant hints,
receipt date/total metadata, and source references needed for user review. The
parser is responsible for normalizing merchant/item shorthand, resolving an
optional local or hosted trade pack, assigning parser confidence, and returning
reviewable inventory suggestions. Parser changes must not require a particular
OCR engine or change OCR output semantics without an explicit cross-owner
agreement.

## Local Pack Requirements to Preserve or Audit Later

This is secondary to restoring compilation:

- Show pack name, tier, version, locale, item count, and download/storage size.
- Download to temporary storage.
- Validate schema, pack ID, compatible version, paths, item counts,
  decompression limits, and SHA-256 before activation.
- Install atomically so interruption never destroys the last working pack.
- Keep installed version, size, checksum, and validation status in a registry.
- Support explicit update and removal.
- Pack removal must not delete inventory records created from that pack.
- Installed packs and inventory must continue working offline.

## Hosted Subscription Boundary

Do not build this during the compile repair. Preserve the intended boundary for
later implementation:

- Subscription grants hosted parser/catalog-query access only.
- Local records remain owned by the user.
- Free pack downloads remain free.
- Send normalized candidate lines rather than receipt images when sufficient.
- Explain what leaves the device and require opt-in.
- Enforce authentication, entitlement, quotas, and rate limits server-side.
- Query through a bounded server index or Cloud Function, not unrestricted
  client-side scans of Firebase data.
- Return ranked candidates with pack/version evidence for user review.
- Always provide downloaded-pack, lean-local, or manual fallback.

## Inventory Truth

- Parser output is a suggestion until the user approves it.
- User-approved local inventory records are the source of truth.
- Preserve receipt reference, merchant, date, quantity, unit cost, matched item
  ID, pack ID/version, confidence, and user correction where applicable.
- Cloud backup is opt-in and independent of cloud parser subscription.

## Verification Gates

Stop at the first failure and fix its root cause before broadening.

1. Format only touched files.
2. Analyze the parent parser and the current repair group.
3. Run trade-specific parser regression tests.
4. Run existing pack manifest/export/import/install/version tests.
5. Run repository-wide `flutter analyze` after scoped checks are clean.
6. Run the relevant materials/parser suite.
7. Run `flutter build apk --debug`.

Do not claim Firebase readiness from local unit tests. Use Firebase Emulator or
a staging project for later Storage, Firestore rules, Cloud Functions,
entitlement, quota, and billing verification. Never write test data to
production Firebase.

## Required Completion Report

Report:

- exact files changed
- orphan-to-connected symbol map
- duplicate definitions removed or intentionally retained
- parser behavior changes, expected to be none
- exact commands and results
- remaining analyzer or test failures
- local-pack gaps found
- hosted/Firebase gaps found
- confirmation that no Firebase production write occurred
- confirmation whether anything was committed or pushed

Completion for this assignment means clean parser compilation with existing
behavior preserved. It does not mean every trade pack or hosted subscription
service is production-ready.
