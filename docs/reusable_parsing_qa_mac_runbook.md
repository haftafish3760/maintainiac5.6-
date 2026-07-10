# Reusable Parsing QA Mac Mini Runbook

Last updated: 2026-07-09 11:32 PM EDT

This runbook is the plain-English companion to:

- `docs/reusable_parsing_qa_handoff_marker.md`
- `docs/reusable_parsing_qa_scope_boundary.md`
- `docs/reusable_parsing_qa_checkpoint.md`
- `docs/reusable_parsing_qa_mac_handoff_packet.json`

## Start Here

1. Check out branch `codex/reusable-parsing-qa-foundation`.
2. Confirm the branch is at or after validated floor commit `8e9771d`.
3. Read `docs/reusable_parsing_qa_handoff_marker.md` before running anything.
4. Read `docs/reusable_parsing_qa_scope_boundary.md` to separate reusable parser QA work from
   inventory-specific Windows ownership.
5. Read `docs/reusable_parsing_qa_checkpoint.md` to see the current
   Windows-next versus Mac-next checkpoint from live PEH evidence.
6. Use `docs/reusable_parsing_qa_mac_handoff_packet.json` as the exact command
   source of truth.
7. On the Windows execution branch, run
   `dart run tool/reusable_parsing_qa_handoff_status.dart --root .`
   and require `parityOk: true` before trusting the live PEH Mac packet.
8. For one concise checkpoint readout, run
   `dart run tool/reusable_parsing_qa_handoff_summary.dart --root .`
   and confirm the remaining gap, blockers, and execution commit match the
   packet you plan to follow.
9. If you want one compact “what do I run next on the Mac Mini?” packet, run
   `dart run tool/reusable_parsing_qa_mac_handoff_brief.dart --root .`
   and use that readout instead of reconstructing the next wave from multiple
   docs by hand.
10. If the Windows execution commit advanced and the packet/script pair needs
   to be refreshed together, prefer
   `dart run tool/work_supply_parser_qa_finalize_live_handoff.dart --root . --branch codex/reusable-parsing-qa-foundation --commit 8e9771d --commit-full <full sha> --label "<validated floor label>" --updated-at "YYYY-MM-DD HH:MM EDT"`
   before handing the wave back to the Mac Mini.
11. If you need only the packet/script restamp without the reusable sync and
    summary wrapper, run
    `dart run tool/work_supply_parser_qa_peh_core_restamp_handoff.dart --root .`.
12. After the Mac Mini copies its rollups back to Windows, run
    `dart run tool/work_supply_parser_qa_peh_core_post_mac_refresh.dart --root .`
    so the PEH refresh, reusable checkpoint, reusable status, and reusable
    summary all move together instead of being refreshed piecemeal.
13. Treat the following locally modified docs as normal immediately after a
    Windows-side sync/restamp unless another signal says otherwise:
    - `docs/reusable_parsing_qa_checkpoint.json`
    - `docs/reusable_parsing_qa_checkpoint.md`
    - `docs/reusable_parsing_qa_handoff_index.md`
    - `docs/reusable_parsing_qa_handoff_marker.md`
    - `docs/reusable_parsing_qa_mac_handoff_packet.json`
    - `docs/reusable_parsing_qa_mac_runbook.md`
    - `docs/reusable_parsing_qa_scope_boundary.md`
    Use `dart run tool/reusable_parsing_qa_handoff_summary.dart --root .` to
    confirm that this is the expected local refresh state by checking for
    `expectedLocalDocsRefreshDirty: true`.

## What Windows Already Finished

Do not rebuild these unless a new regression proves they are wrong:

- Shared parser QA platform backbone in `test/support/parser_qa_platform/`
- Reusable parser QA reporting and gating artifacts
- Mixed-trade PEH ambiguity hardening for overlapping PVC and copper wording
- Review-only estimate/invoice section routing boosts
- HVAC thermostat-wire versus thermostat hardening
- HVAC humidifier water-panel wording hardening

## What The Mac Mini Should Do Next

1. Run the heavier PEH generated-fixture measurement wave from the reusable
   parsing baseline.
2. Roll up the active Mac measurement wave results.
3. Refresh the PEH status stack after the Mac wave outputs exist.
4. Continue broader reusable receipt/parsing-core extraction only after the
   current PEH measurement lane is advanced from this checkpoint.

## Merchant Extraction Ownership

- Do not start a separate merchant-extraction buildout while PEH measurement is
  still the active blocker.
- If the immediate task is inventory receipt parsing for merchant-style lines,
  abbreviations, or context boosts, treat it as Work Supplies parser
  ownership.
- If the follow-up task is a shared merchant extraction layer meant to power
  multiple receipt/parser domains, treat it as reusable parser QA/platform
  ownership after the current PEH handoff step is complete.

## Current Measurement Reality

- Plumbing already has the stronger Windows-side generated evidence.
- Electrical already has the stronger Windows-side measured evidence.
- HVAC is the remaining top measured gap from the current PEH artifacts.
- The branch is ready for a Mac measurement wave.
- The branch is not yet ready for a `90-95%` claim across PEH.

## Do Not Duplicate

- Do not re-add the same mixed-trade PEH ambiguity regressions.
- Do not re-document review-only estimate/invoice routing.
- Do not re-fix thermostat wire versus thermostat behavior.
- Do not re-fix humidifier water-panel wording.
- Do not recreate branch labeling or older handoff artifacts.

## Expected Mac Outputs

The current packet expects these outputs to exist after the Mac wave:

- `build/parser_qa_pipeline/mac_hvac_core_generated_run_status_25.json`
- `build/parser_qa_pipeline/peh_core_mac_wave_status.json`
- `build/parser_qa_pipeline/peh_core_merged_status_rollup.json`
- `build/parser_qa_pipeline/peh_core_claim_readiness.json`

## Ownership Boundary

The Windows lane still owns:

- Ongoing Work Supplies parser/code edits in this thread
- Inventory-specific PEH hardening before broader parser-domain extraction is
  declared complete
- Windows-side roadmap and progress-memory maintenance

The Mac Mini lane should focus on:

- Heavier generated-fixture measurement work
- Mac-side rollups and refresh
- Broader reusable parser-domain follow-through after the current PEH handoff
  step

## Expected Local Windows State

After a Windows-side handoff sync or PEH restamp, it is normal for these three
docs to be locally modified before the next artifact-sync commit:

- `docs/reusable_parsing_qa_checkpoint.json`
- `docs/reusable_parsing_qa_checkpoint.md`
- `docs/reusable_parsing_qa_handoff_index.md`
- `docs/reusable_parsing_qa_handoff_marker.md`
- `docs/reusable_parsing_qa_mac_handoff_packet.json`
- `docs/reusable_parsing_qa_mac_runbook.md`
- `docs/reusable_parsing_qa_scope_boundary.md`

That state is expected when the live execution checkpoint moved forward and the
local branch has refreshed the handoff packet/checkpoint for the Mac Mini. The
machine-readable confirmation is `expectedLocalDocsRefreshDirty: true` in
`dart run tool/reusable_parsing_qa_handoff_summary.dart --root .`.

The preferred one-command Windows-side checkpoint refresh is
`dart run tool/work_supply_parser_qa_finalize_live_handoff.dart ...`. It emits
`QA_PARSER_LIVE_HANDOFF_FINALIZE` with `restampExit`, `syncExit`,
`summaryExit`, `handoffClean`, `windowsExecutionCommit`,
`packetExecutionHeadAligned`, `scriptExecutionHeadAligned`,
`expectedLocalDocsRefreshDirty`, `localModifiedFiles`,
`measurementCommandCount`, and `rollupCommandCount` so the Mac handoff can be
validated from one readout instead of piecing together separate commands.
