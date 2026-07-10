# Reusable Parsing QA Handoff Marker

Last updated: 2026-07-09 11:58 PM EDT

Purpose: prevent duplicate work between the Windows parser/QA lane and the Mac
Mini lane.

## Git Marker

- Primary reusable branch: `codex/reusable-parsing-qa-foundation`
- Current Windows working branch: `codex/inventory-parser-backup-20260702-2056`
- Validated floor commit: `8e9771d`
- Commit label:
  `Reusable parsing QA 2026-07-09 09:20 PM EDT: relax stale packet assertion`

The Mac Mini side should start from branch `codex/reusable-parsing-qa-foundation`.
Treat the branch tip as authoritative.
Treat commit `8e9771d` as the last Windows-validated floor, not as a promise
that the handoff docs already describe their own just-created commit.

Companion machine-readable packet:
`docs/reusable_parsing_qa_mac_handoff_packet.json`

Companion scope boundary map:
`docs/reusable_parsing_qa_scope_boundary.md`

Companion next-action checkpoint:
`docs/reusable_parsing_qa_checkpoint.md`

Companion plain-English runbook:
`docs/reusable_parsing_qa_mac_runbook.md`

## Handoff Rule

When the Mac Mini lane starts, this file is the first thing it should read.
If chat instructions and this file disagree, this file wins until a newer
committed handoff marker replaces it.

The explicit reusable-versus-inventory ownership split lives in
`docs/reusable_parsing_qa_scope_boundary.md`.
The current Windows-next versus Mac-next checkpoint lives in
`docs/reusable_parsing_qa_checkpoint.md`.
Windows should refresh the full handoff stack with
`dart run tool/reusable_parsing_qa_handoff_sync.dart ...` instead of running
separate refresh and checkpoint commands by hand.

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
4. Use the machine-readable packet for the exact current Mac-side command order
   instead of copying commands out of old chat or stale artifacts.

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

Start from branch `codex/reusable-parsing-qa-foundation`, confirm it is at or after validated floor commit
`8e9771d`, read this marker first, then continue only with heavier validation,
broader reusable parsing-core extraction, or new parser-domain consumers that
are not already listed as Windows-complete above.
