# Reusable Parsing QA Checkpoint

Last updated: 2026-07-09 11:25 PM EDT

- Primary reusable branch: `codex/reusable-parsing-qa-foundation`
- Windows working branch: `codex/inventory-parser-backup-20260702-2056`
- Windows execution commit: `2b52b6b`
- Validated floor commit: `8e9771d`
- Ready for Mac measurement wave: `true`
- Ready to claim 90-95 percent: `false`
- Remaining measured gap count: `38`
- Next trades by remaining gap: `hvac`

## Windows Next

- Keep Windows ownership on inventory-specific Work Supplies parser/code hardening.
- Do not claim 90-95 percent PEH readiness until the Mac wave closes the remaining measured gaps.
- Keep the branch below a 90-95 percent claim until the hvac remaining measured Mac wave clears.

## Mac Mini Next

- Run the Mac PEH measurement wave commands from the packet on branch codex/reusable-parsing-qa-foundation.
- Prioritize hvac because they still have measured coverage gaps.
- After the heavier run finishes, execute `dart run tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart --root .` to rebuild the PEH and reusable handoff artifacts together.

## First Mac Measurement Command

`dart run tool/work_supply_parser_qa_run_generated_fixtures.dart --fixture build/parser_qa_generated/work_supply_parser/hvac/residential/core/en-US/generated_fixtures.json --max-cases 25 --chunk-size 25 --min-pass-rate 0.90 --timeout-ms 900000 --stale-report-timeout-ms 240000 --report-dir build/parser_qa_pipeline/mac_peh_core_measurement_25/hvac/residential/core/en-US/reports`

## Expected Local Windows Refresh State

Immediately after a Windows-side handoff sync or PEH restamp, it is normal for
these local docs to be modified until the next artifact-sync commit:

- `docs/reusable_parsing_qa_checkpoint.json`
- `docs/reusable_parsing_qa_checkpoint.md`
- `docs/reusable_parsing_qa_handoff_index.md`
- `docs/reusable_parsing_qa_handoff_marker.md`
- `docs/reusable_parsing_qa_mac_handoff_packet.json`
- `docs/reusable_parsing_qa_mac_runbook.md`
- `docs/reusable_parsing_qa_scope_boundary.md`

If the live handoff is healthy, `dart run tool/reusable_parsing_qa_handoff_summary.dart --root .`
will report `expectedLocalDocsRefreshDirty: true` for this state.
