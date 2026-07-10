# Reusable Parsing QA Mac Mini Runbook

Last updated: 2026-07-09 20:46 EDT

This runbook is the plain-English companion to:

- `docs/reusable_parsing_qa_handoff_marker.md`
- `docs/reusable_parsing_qa_scope_boundary.md`
- `docs/reusable_parsing_qa_checkpoint.md`
- `docs/reusable_parsing_qa_mac_handoff_packet.json`

## Start Here

1. Check out branch `codex/reusable-parsing-qa-foundation`.
2. Confirm the branch is at or after validated floor commit `b085844`.
3. Read `docs/reusable_parsing_qa_handoff_marker.md` before running anything.
4. Read `docs/reusable_parsing_qa_scope_boundary.md` to separate reusable parser QA work from
   inventory-specific Windows ownership.
5. Read `docs/reusable_parsing_qa_checkpoint.md` to see the current
   Windows-next versus Mac-next checkpoint from live PEH evidence.
6. Use `docs/reusable_parsing_qa_mac_handoff_packet.json` as the exact command
   source of truth.

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
2. Roll up the Electrical and HVAC Mac wave results.
3. Refresh the PEH status stack after the Mac wave outputs exist.
4. Continue broader reusable receipt/parsing-core extraction only after the
   current PEH measurement lane is advanced from this checkpoint.

## Current Measurement Reality

- Plumbing already has the stronger Windows-side generated evidence.
- Electrical already has the current Windows-side sample-sized proof.
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

- `build/parser_qa_pipeline/mac_electrical_core_generated_run_status_25.json`
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
