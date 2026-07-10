# Reusable Parsing QA Handoff Marker

Last updated: 2026-07-09 20:00 EDT

Purpose: prevent duplicate work between the Windows parser/QA lane and the Mac
Mini lane.

## Git Marker

- Primary reusable branch: `codex/reusable-parsing-qa-foundation`
- Current Windows working branch: `codex/inventory-parser-backup-20260702-2056`
- Current reusable-foundation commit: `8c48415`
- Commit label:
  `Reusable parsing QA 2026-07-09 20:00 EDT: add Mac handoff marker`

The Mac Mini side should start from `codex/reusable-parsing-qa-foundation`
unless a newer handoff marker says otherwise.

## Handoff Rule

When the Mac Mini lane starts, this file is the first thing it should read.
If chat instructions and this file disagree, this file wins until a newer
committed handoff marker replaces it.

## Completed On Windows

These pieces are already done enough that the Mac Mini side should treat them
as the current baseline, not rebuild them from scratch:

- Shared parser QA platform backbone already exists in
  `test/support/parser_qa_platform/`.
- Reusable reporting/gating artifacts already exist for parser QA platform
  status, duration, failure digest, watchdog, release readiness, and exports.
- Inventory parser adapter already proves reusable parser-platform behavior is
  not strictly inventory-locked.
- Mixed-trade PEH ambiguity hardening has already been added for overlapping
  PVC and copper receipt language.
- Estimate-section and invoice-section routing rules already exist as
  review-only ranking boosts, not silent confirmation.
- HVAC-specific fixes already landed for thermostat wire vs thermostat and
  humidifier water-panel wording.

## Files Touched In The Current Reusable Baseline

- `docs/inventory_parser_peh_core_roadmap.md`
- `docs/materials_catalog_intelligence_contract.md`
- `lib/screens/work_supplies/data/work_supply_receipt_parser.dart`
- `test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart`
- `test/support/work_supply_parser_qa/work_supply_parser_estimate_section_qa.dart`
- `test/work_supply_hvac_receipt_parser_test.dart`
- `test/work_supply_parser_regression_lock_behavior_test.dart`

## Mac Mini Should Pick Up Here

The Mac Mini lane should continue from the reusable baseline above and focus on
work that benefits from heavier validation or broader parser-domain reuse:

1. Run heavier generated-fixture and mixed-trade measurement waves from the
   reusable baseline instead of rebuilding the same Windows-side ambiguity work.
2. Continue extracting receipt-interpretation behavior that is truly generic to
   parsing in general, not only Work Supplies inventory.
3. Reuse shared parser-platform pieces for future parser domains such as fuel,
   maintenance, invoice/estimate import, and other text-to-structured-data
   flows.

## Do Not Duplicate On Mac Mini

Do not spend Mac Mini passes redoing these Windows-complete tasks unless a new
regression proves they are wrong:

- Re-adding the same mixed-trade PVC/copper ambiguity regressions.
- Re-documenting estimate/invoice section routing as review-only.
- Re-fixing thermostat-wire and water-panel HVAC cases.
- Re-creating the reusable parser QA branch label.

## Windows Still Owns

Until a later handoff says otherwise, the Windows lane still owns:

- Ongoing Work Supplies parser/code edits in this thread.
- Inventory-specific PEH parser hardening before broader parser-domain
  extraction is declared complete.
- The current local progress memory and Windows-side roadmap updates.

## Mac Mini Safe Starting Instruction

Start from branch `codex/reusable-parsing-qa-foundation` at or after commit
`8c48415`, read this marker first, then continue only with heavier validation,
broader reusable parsing-core extraction, or new parser-domain consumers that
are not already listed as Windows-complete above.
