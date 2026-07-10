# Inventory Parser Release 1 Acceptance Scorecard

This document captures the Release 1 parser hardening plan that must survive
chat/context compression. It is the measurable target for the inventory/materials
parser before claiming app-assisted receipt parsing is release-ready.

## Recommendation

Write the Release 1 parser acceptance scorecard into the repo first, then wire a
QA contract to enforce that the scorecard exists and remains current. That gives
the project measurable release gates instead of vague "world-class" targets.

Release 1 should not be treated as throwaway or knowingly subpar. Some companies
ship weak first versions because they have large teams and support pipelines to
absorb user pain. Maintainiac does not have that safety net yet, so Release 1
must be as strong as reasonably possible before users rely on it for business
records. That does not mean every possible inventory item is finished before
release, but it does mean the supported scope must be honest, measured,
review-safe, recoverable, and backed by regression tests.

QA harness completion is not the same thing as catalog completion. After the
QA harness and release gates are in place, inventory catalog expansion still continues in controlled batches, with generated item candidates, fixture
coverage, regression locks, and release-readiness evidence before promotion.

## Release 1 Priority Scope

Release 1 parser proof is focused on United States residential service work:

- Plumbing Core and Standard, English and Spanish.
- Electrical Core and Standard, English and Spanish.
- HVAC Core and Standard, English and Spanish.
- Common fasteners, consumables, sealants, hangers, straps, fittings, and tools
  that support those three trades.

Core does not mean the smallest possible list. Core means the highest
day-to-day residential service probability: service-truck stock plus common
same-day repair purchases from major stores and supply houses.

## Active Narrowed Workstream

The active workstream is temporarily narrowed to Residential Core only for
Plumbing, Electrical, and HVAC in en-US and es-US. Standard remains part of the
Release 1 plan, but it must not dilute the current Core push. The Core lane is
tracked by `inventory.release_one_core_manifest` and contains exactly six cells:

- `plumbing.residential.core.en-US`
- `plumbing.residential.core.es-US`
- `electrical.residential.core.en-US`
- `electrical.residential.core.es-US`
- `hvac.residential.core.en-US`
- `hvac.residential.core.es-US`

Do not count Standard, Professional, Complete, UI, OCR, camera, expenses, or
unrelated modules as progress against this narrowed Core-only lane. Core is not
release-ready until its catalog rows, parser fixtures, ambiguity behavior,
merchant-generic receipt behavior, Spanish coverage, review safety, and focused
rerun evidence are all proven for these six cells.

## Acceptance Areas

The scorecard must cover these areas before Release 1 parser sign-off:

- Plumbing, Electrical, and HVAC Core plus Standard.
- English and Spanish packs for the United States.
- Synthetic merchant fixtures for named major stores plus unknown, local,
  regional, and supply-house receipts.
- Fake-user parser review workflow.
- Clear-match accuracy target.
- False-confident maximum.
- Ambiguity review requirement.
- Hive/local-first save.
- Fake Firebase mirror-only behavior for QA.
- Immediate Firebase mirror sync when the user opted into cloud backup/sync.
- Portable parser core.
- Barcode and correction-learning safety.
- Real private receipt validation workflow.
- Release-readiness reporting per trade, pack, and locale.
- Merchant-agnostic fallback behavior when the store is unknown.

## Merchant-Agnostic Receipt Coverage

The parser must not be built only for popular stores. Named major-merchant
fixtures are required because they cover common receipt patterns, but they are
not the whole system.

The parser must be able to process inventory/material receipt text from:

- Lowe's.
- Home Depot.
- Walmart.
- Ace Hardware.
- True Value.
- Menards.
- Tractor Supply.
- Northern Tool.
- Ferguson.
- Grainger.
- SupplyHouse-style suppliers.
- HVAC supply houses.
- Electrical supply houses.
- Plumbing supply houses.
- local hardware stores.
- regional chains.
- small counter-sale suppliers.
- generic unknown merchants.
- invoices, quotes, packing-slip-like material lists, and emailed/PDF material
  receipts after text extraction.

Merchant-specific rules may boost ranking when the merchant is recognized, but
the parser must still work when the merchant is missing, misspelled, unknown, or
not in a merchant pack. Unknown merchant text must go through generic
normalization, item-family matching, size/unit extraction, conflict checks,
context scoring, and review-safety rules.

Named store fixtures are not the only release gate:

- merchant_specific_rules_boost_but_do_not_force_truth
- unknown_merchant_uses_generic_parser_pipeline
- misspelled_merchant_keeps_review_safe_fallback
- local_hardware_receipts_require_generic_coverage
- regional_supplier_receipts_require_generic_coverage
- counter_sale_receipts_require_generic_coverage
- merchant_absent_receipts_do_not_fail_parser
- named_store_fixtures_are_not_the_only_release_gate
- store_independence_proof_required
- receipt_wording_not_store_name_is_primary_evidence
- merchant_department_hint_is_supporting_evidence
- merchant_pack_missing_does_not_block_review_candidate

The release goal is broad receipt understanding, not store lock-in.

## Target Behavior

The parser should be sold and designed as app-assisted receipt parsing with
review, not as fully automatic no-review parsing.

Clear common Core items should usually become strong candidates. Ambiguous lines
must stay review-required instead of becoming confidently wrong. Examples:

- `3/4 PVC` may be plumbing pipe, electrical conduit, or HVAC condensate drain.
- `FOIL TAPE` may belong to HVAC, general supplies, or another trade context.
- `BOX` may be an electrical box, storage box, junction box, or packaging.
- `FILTER` may be HVAC, water, oil, or another service category.

Context can change ranking, but it must not erase ambiguity. Context signals may
include enabled trade packs, selected job type, active estimate section, vehicle
inventory, merchant type, previous user corrections, barcode evidence, and
nearby receipt words.

Ranked candidates must preserve the evidence ladder that produced the ranking:
enabled trade packs, active workflow context, active estimate/job trade section,
receipt-neighbor signals, merchant/department hints, conflict family, positive evidence,
negative evidence, warnings, and confidence reasons. These signals may boost or
demote candidates, but they must not silently confirm an item or hide realistic alternate trades
when evidence is mixed or missing.

## Accuracy Targets

Initial Release 1 scorecard targets should be conservative and measurable:

- Clear common Core item top candidate: target 95% or better in synthetic and
  reviewed private-real validation sets.
- Clear common Standard item top candidate: target 90% or better at first
  release, then improve through corrections and regression fixtures.
- False-confident ambiguous match rate: target below 1%, with a stretch goal
  below 0.5%.
- Receipt noise false-positive rate: target below 0.5%.
- Ambiguous overlap lines: target 99% review-required/ranked-candidate behavior,
  not forced single-item confidence.
- Spanish Core clear-item behavior: target 90% or better before release, then
  improve with reviewed fixtures and correction memory.

These numbers are release gates for parser behavior, not promises that every
receipt will need zero user review.

## Synthetic Merchant And Generic Receipt Fixtures

Build fake-but-realistic receipt fixtures for named major merchants, supply
houses, local/regional stores, and unknown merchants. Do not copy proprietary
retailer catalogs, scrape retailer databases, or commit private receipt text.

Fixture families should include:

- Lowe's-style abbreviations.
- Home Depot-style abbreviations.
- Ace/True Value/local hardware wording.
- Menards where applicable.
- Walmart small plumbing/electrical/HVAC sections.
- Tractor Supply well/pump/farm-hardware crossover wording.
- Northern Tool tool/material crossover wording.
- Ferguson and plumbing supply house wording.
- Grainger and industrial/supply-house wording.
- HVAC supply house wording.
- Electrical supply house wording.
- Regional/local hardware wording.
- Generic unknown merchant wording.
- Invoice-style line items.
- Counter-sale material receipts.
- Packing-slip-like material lists.
- PDF/email receipt text after extraction.
- Spanish receipt wording common in United States stores.
- Bad spacing, weird spacing, missing punctuation, all caps, OCR-like mistakes, quantities,
  returns, discounts, taxes, subtotal lines, payment lines, and mixed-trade
  receipts.
- Source-modality tags that prove generated fixtures are not store-only:
  `photo_ocr_text_after_extraction`,
  `uploaded_pdf_text_after_extraction`,
  `emailed_receipt_text_after_extraction`, `manual_pasted_receipt_text`,
  `invoice_style_material_line_text`, `quote_style_material_line_text`,
  `packing_slip_material_list_text`, `counter_sale_material_receipt_text`,
  `generic_unknown_merchant_receipt_text`, and
  `local_regional_supplier_receipt_text`.

Synthetic fixtures must include expected status: matched, review required,
unknown, or ignored noise.

## Fake-User Parser Review Workflow

Build QA that simulates a user using the parser without relying on unstable UI:

1. Receipt/OCR text arrives from an adapter.
2. Parser returns candidates, confidence, warnings, and review status.
3. User accepts, edits, rejects, or marks unknown.
4. Confirmed data writes to Hive/local storage first.
5. If cloud backup/sync is enabled, a Firebase mirror write is queued or sent
   immediately after the local write succeeds.
6. If Firebase is offline or fails, Hive/local truth remains intact and the
   sync queue retries later.
7. App restart must preserve local confirmed data and pending sync state.
8. User-confirmed data must never be silently overwritten by parser, OCR,
   Firebase, or a later pack update.

For QA, Firebase behavior must be fake/emulated/local-only unless a separate
explicit live integration profile is approved. Production parser tests must not
hit live Firebase.

## Firebase And Source Of Truth

Hive/local storage is the immediate source of truth. Firebase/Firestore is a
mirror, backup, and sync target, not the brain.

Firebase/Firestore is a mirror.
Firebase mirror sync should happen as soon as practical.

Rules:

- Saving a confirmed receipt/material/inventory action must commit locally first.
- If the user opted into cloud sync, Firebase mirror sync should happen as soon
  as practical after local save, not hours later.
- Firebase failure must not roll back local truth.
- Stale Firebase data must not overwrite newer local confirmed data.
- Conflict resolution must require safe merge/review rules, not blind
  server-wins behavior.
- Parser output remains suggestion data until the user confirms.
- User-confirmed financial/material data outranks OCR, parser, automation, and
  cloud mirror data.

## Portable Parser Core

The parser core must be environment-independent.

It should not know or care whether it is running:

- On the user's phone.
- In a backend service.
- In a QA harness.
- In a command-line batch tool.
- In a future cloud-hosted parser adapter.

The parser core should accept pure input:

- OCR/plain receipt text.
- Enabled trade packs.
- Parser settings.
- Merchant/context hints.
- Locale.
- Job/estimate section context.
- User correction memory.
- Barcode/SKU evidence when available.

The parser core should return pure output:

- Parsed candidates.
- Ranked possible matches.
- Confidence.
- Review status.
- Warnings.
- Missing evidence.
- Suggested action.
- Field/source attribution.

Adapters may wrap the core for mobile, server, QA, batch, Firebase-hosted packs,
or future cloud services. The core must not directly depend on Firebase, Hive,
Flutter widgets, camera/OCR APIs, network calls, file paths, or device state.

## Universal Parser Adapter Fields

Every parser QA domain adapter must support portable `qa_harness` and
`command_line` execution so tests and batch tools exercise the same contract as
mobile/server adapters. Every adapter must accept `localePackId` and
`userConfirmedContext`, and every parser output must include `confidence`,
`reviewStatus`, `warnings`, `evidence`, and `suggestedAction`. Inventory parser
outputs should also include ranked candidates so ambiguous material lines stay
reviewable instead of being silently forced into one item.

## Teachable Correction Memory

The parser should learn from user corrections, but safely.

Rules:

- Corrections become private local/user-owned memory first.
- Corrections must preserve before/after candidate evidence.
- Corrections should be scoped by merchant, locale, trade, pack version, and
  context when possible.
- Corrections may propose aliases, negative rules, fixture cases, confidence
  changes, or merchant rules.
- Corrections must not silently mutate official parser packs.
- Official pack promotion requires reviewed/manual approval.
- Private receipt text must not leak into official packs or admin reports.

## Barcode Evidence

Barcode scanning is useful, but it must be evidence, not unchecked truth.

Rules:

- Barcode capture belongs to the camera/barcode input side, not the parser core.
- Inventory parser can accept barcode/UPC/GTIN/vendor SKU evidence as input.
- Unknown barcodes stay review-only.
- Barcode collisions require review.
- Barcode and receipt disagreement requires review.
- User-confirmed barcode mappings become private local memory first.
- Official barcode mappings require licensed, public, manufacturer-provided, or
  manually reviewed source confidence.
- Retailer database scraping is forbidden.

## Real Private Receipt Validation

The user can test real Lowe's, Home Depot, Walmart, Ferguson, Ace, or other
receipts locally, but private receipt content must not be committed to the repo.

The validation workflow should record only safe summaries:

- Merchant category, not full private receipt text.
- Expected item family.
- Parser result category.
- Correct, review-required, unknown, or wrong.
- Failure reason.
- Whether a regression fixture should be created from a synthetic equivalent.

Private real receipts can inspire synthetic fixtures, but the committed fixture
must be rewritten as privacy-safe synthetic data.

## Serious-Team Additions

A professional team would also add:

- Release scorecards by trade, pack tier, locale, and merchant family.
- Merchant-agnostic fallback scorecards for unknown/local/regional receipts.
- Holdout fixture sets not used during tuning.
- Differential old-parser/new-parser comparison reports.
- Mutation/fault-injection tests that intentionally break aliases, size parsing,
  review status, dangerous-word handling, confidence thresholds, merchant rules,
  and trade-context boosts.
- Abuse/security tests for huge input, Unicode controls, path-like strings,
  injection-like SKU/barcode text, regex traps, and malformed imports.
- Performance budgets for cold start, warm cache, search/index lookup, fixture
  throughput, memory use, and low-end device behavior.
- Pack install/recovery tests for corrupt chunks, interrupted downloads,
  duplicate installs, missing locale packs, rollback, checksum mismatch, and
  not-enough-storage paths.
- Admin-safe observability for Command One: failure type, trade, pack, device
  class, parser version, correction category, and runtime without raw private
  receipt text.
- Regression rule: every confirmed parser bug gets a permanent fixture/test
  before it is considered fixed.
- Privacy/legal provenance checks for every official SKU, UPC, barcode, vendor,
  merchant, or brand mapping.
- Realistic release language: app-assisted parsing with review, not guaranteed
  no-review automation.
- Store-independence proof: named merchant rules must improve ranking but never
  become required for the parser to function.

## Release Gate Suite Mapping

The scorecard must stay tied to executable QA suites, not memory:

- `inventory.release_one_scorecard_contract`
- `inventory.release_one_residential_contract`
- `inventory.release_one_service_family_contract`
- `inventory.release_one_pack_balance`
- `inventory.merchant_independence_contract`
- `inventory.merchant_matrix_contract`
- `inventory.fixture_corpus_contract`
- `inventory.fixture_expectation_contract`
- `inventory.real_receipt_validation_contract`
- `inventory.fake_user_review_workflow`
- `inventory.hive_authority_contract`
- `inventory.hive_firestore_sync_contract`
- `inventory.parser_platform_contract`
- `inventory.portability_contract`
- `inventory.barcode_inventory_identity_contract`
- `inventory.human_correction_learning_contract`
- `inventory.confidence_calibration`
- `inventory.review_safety_contract`

If a release requirement is added here, it should either map to an existing
suite or create a new focused suite with a surgical rerun route before catalog
expansion depends on it.

## Next Implementation Order

Recommended order:

1. Wire this scorecard into a QA contract so it cannot be forgotten.
2. Expand synthetic merchant, regional/local, supply-house, and unknown-receipt
   fixture coverage for Plumbing/Electrical/HVAC Core.
3. Add fake-user parser review workflow tests with fake Hive and fake Firebase.
4. Enforce portable parser-core boundaries.
5. Expand teachable correction-memory tests.
6. Expand barcode evidence/provenance tests.
7. Add per-pack release-readiness scorecards.
8. Continue catalog/parser expansion and run accumulated release-one waves.

After QA hardening is complete, inventory catalog growth still continues. The
QA backbone should make future item expansion safer by proving new Plumbing,
Electrical, and HVAC items do not break existing aliases, merchant rules,
Spanish packs, ambiguity behavior, barcode/correction evidence, pack delivery,
or fake-user review workflows.
