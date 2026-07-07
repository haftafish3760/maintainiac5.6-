# Plumbing Core Parser Readiness Roadmap

This roadmap pins the active Maintainiac inventory/parser QA work to Plumbing
Core only. Do not use it to justify OCR, camera, expenses, UI, PDF, or unrelated
module work.

## Operating Rules

- Fix structure before broad proof runs.
- Do not start broad or heavy parser shards while a family still has unfinished
  fixture coverage, parser routing gaps, metadata-rule gaps, or known failures.
- Use cheap validation first: `dart format`, targeted `dart analyze`, generator
  isolation tests, and focused fixture-ID parser reruns.
- Treat every parser failure as evidence. Fix the route, fixture, metadata rule,
  or catalog expectation that is actually wrong; do not cap, hide, waive, or
  weaken confidence to get green output.
- Promote a family into readiness evidence only after focused parser proof is
  clean for that family.
- Read readiness from
  `build/parser_qa_curation/plumbing_core/latest_plumbing_core_readiness_audit.json`
  after the readiness audit, not from stale console output.
- Commit and push only meaningful milestones with human-readable EDT labels.

## Current Family Order

1. Finish `toilet and faucet repair`.
   - Complete fixture coverage for tank repair, closet/flange/seals, faucet
     washers, O-rings, cartridges/stems, aerators, assortments, trim, pop-ups,
     basket strainers, and sink repair kits.
   - Use focused fixture-ID reruns for failures before shard reruns.
   - Run 80-case shards only after the current failure list is clean.
   - Promote evidence only after all toilet/faucet shards pass.
2. Clean remaining `unclassified plumbing core` rows.
   - Reclassify obvious well, tubular, consumable, drain, or repair rows into
     existing families where appropriate.
   - Add new family buckets only when the current taxonomy cannot honestly
     represent the item.
3. Run final Plumbing Core readiness audit.
   - Verify every family is release-ready or has a documented manual-review
     reason that does not falsely claim release readiness.
4. Prepare Mac handoff.
   - Provide exact branch, commit, commands, report paths, and remaining
     validation scope.

## Validation Ladder

1. Formatting and analyzer on touched files.
2. Generator isolation test for the affected family.
3. Focused generated parser rerun for failed fixture IDs.
4. Family shard rerun.
5. Readiness audit.
6. Progress memory update.
7. Human-readable commit and push.
