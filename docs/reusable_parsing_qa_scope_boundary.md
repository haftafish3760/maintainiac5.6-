# Reusable Parsing QA Scope Boundary

Last updated: 2026-07-09 11:17 PM EDT

This file is the explicit boundary between reusable parser QA foundation work
and inventory-specific Windows work.

Validated floor:

- Branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `8e9771d`

## Reusable Parser QA Foundation

These artifacts are intended to stay reusable across parser domains and can be
consumed by the Mac Mini lane without rebuilding them from scratch:

- `test/support/parser_qa_platform/`
- `test/support/qa_harness/`
- `tool/reusable_parsing_qa_handoff_refresh.dart`
- `tool/reusable_parsing_qa_handoff_parity.dart`
- `tool/reusable_parsing_qa_handoff_status.dart`
- `tool/reusable_parsing_qa_handoff_summary.dart`
- `docs/reusable_parsing_qa_handoff_index.md`
- `docs/reusable_parsing_qa_handoff_marker.md`
- `docs/reusable_parsing_qa_scope_boundary.md`
- `docs/reusable_parsing_qa_mac_runbook.md`
- `docs/reusable_parsing_qa_mac_handoff_packet.json`

## Inventory-Specific Windows Ownership

These artifacts are still owned by the current Windows-side Work Supplies
inventory/parser lane and should not be re-authored on the Mac Mini unless a
new regression or handoff explicitly says otherwise:

- `lib/screens/work_supplies/data/work_supply_receipt_parser.dart`
- `test/support/work_supply_parser_qa/`
- `docs/inventory_parser_peh_core_roadmap.md`
- `build/parser_qa_pipeline/peh_core_windows_status_rollup.json`
- `build/parser_qa_pipeline/peh_core_measurement_gap.json`
- `build/parser_qa_pipeline/peh_core_handoff_readiness.json`

## Mac Mini Measurement Outputs

The Mac Mini lane is expected to produce or refresh these heavier validation
artifacts from the reusable baseline:

- `build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json`
- `build/parser_qa_pipeline/peh_core_mac_wave_status.json`
- `build/parser_qa_pipeline/peh_core_merged_status_rollup.json`
- `build/parser_qa_pipeline/peh_core_claim_readiness.json`

## Rule

If a task changes reusable parser QA infrastructure, handoff boundary files, or
shared parser-platform behavior, it belongs in the reusable lane.

If a task changes Work Supplies parser behavior, PEH inventory-specific hardening,
or Windows-owned roadmap/progress state, it stays in the Windows lane until a
new committed handoff explicitly promotes it.

## Merchant Extraction Boundary

- Merchant extraction for Work Supplies inventory receipts is not a separate
  free-floating lane right now.
- If the work is about merchant-aware parser behavior, merchant abbreviation
  recipes, merchant fixture families, merchant-context review safety, or
  merchant-related QA gates for Work Supplies receipt parsing, it belongs to
  the current Windows inventory/parser lane.
- If the work is about building a reusable merchant extraction contract,
  reusable merchant normalization platform pieces, or parser-domain tooling
  meant to serve multiple receipt/parser domains beyond Work Supplies, it
  belongs to the reusable parser QA lane.
- The Mac Mini should not start a broader reusable merchant-extraction rewrite
  while the current PEH measurement wave is still the active blocker.
- Broader reusable merchant extraction can begin only after the current PEH
  handoff checkpoint is advanced and explicitly says that broader parser-domain
  extraction is next.
