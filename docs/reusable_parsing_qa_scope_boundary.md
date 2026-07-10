# Reusable Parsing QA Scope Boundary

Last updated: 2026-07-09 20:46 EDT

This file is the explicit boundary between reusable parser QA foundation work
and inventory-specific Windows work.

Validated floor:

- Branch: `codex/reusable-parsing-qa-foundation`
- Validated floor commit: `b085844`

## Reusable Parser QA Foundation

These artifacts are intended to stay reusable across parser domains and can be
consumed by the Mac Mini lane without rebuilding them from scratch:

- `test/support/parser_qa_platform/`
- `test/support/qa_harness/`
- `tool/reusable_parsing_qa_handoff_refresh.dart`
- `tool/reusable_parsing_qa_handoff_status.dart`
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

- `build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json`
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
