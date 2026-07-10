# Plumbing Core Parser Readiness Roadmap

This roadmap pins the active Maintainiac inventory/parser QA work to Plumbing
Core only. Do not use it to justify OCR, camera, expenses, UI, PDF, or unrelated
module work.

## Objective

Make Plumbing Core the first release-quality inventory/parser package. The
target is not "the tests are green"; the target is a catalog and parser path
that a residential service plumber can trust for common truck-stock, repair,
service, and box-store receipt lines in English and Spanish.

This roadmap is the order of work. Do not skip ahead to broad proof runs while
the item model, metadata, fixture coverage, parser behavior, or focused
regressions are still incomplete.

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
- Number and timestamp passes in progress memory and meaningful status notes.
- Prefer scripts and cheap gates when they prove the behavior. Do not use a
  slow Flutter path when a deterministic Dart/tool path can prove the same
  catalog, fixture, or parser contract.
- Keep tests surgical. A family can be split into smaller shards when that
  makes failures easier to diagnose, improves runtime, or reduces machine
  throttling.
- Validate while building, but do not re-run expensive whole-family or
  whole-package checks after every small edit.
- If a command is long-running, write the command, start time, report path, and
  expected timeout before it starts. Inspect final logs only unless it fails,
  stalls, or asks for input.

## Professional Workflow

1. Define the family scope.
   - Decide what belongs in Plumbing Core for a normal residential service
     plumber: daily truck-stock, common repair parts, installation consumables,
     and common box-store/supply-house receipt items.
   - Do not include large or uncommon items in Core only because they are
     technically plumbing. Move those to Standard, Professional, or Complete.
   - Complete is all known plumbing items. Core is the high-frequency release
     set, not a random percentage of the catalog.
2. Curate the catalog items.
   - For each family, confirm the item belongs in Plumbing Core.
   - Add missing residential Core items before final proof runs.
   - Move mis-tiered items out of Core instead of making the parser pretend
     they are common.
   - Keep item edits family-scoped so failures can be traced.
3. Complete item metadata.
   - Every release-ready item needs canonical name, trade, tier, family,
     material, size, connection/style/type, use case, aliases, merchant
     abbreviations, Spanish terms where applicable, ambiguity notes, and parser
     risk tags.
   - Shared-use items such as PVC, copper fittings, condensate/drain parts, and
     general valves need context rules instead of forced confidence caps.
   - Metadata must help the parser decide when to match, when to ask the user
     for review, and when another trade context is more likely.
4. Generate realistic fixtures.
   - Use synthetic merchant receipt families, not copied real receipts.
   - Cover box-store, supply-house, hardware-store, abbreviated, noisy,
     misspelled, Spanish, mixed-case, truncated, and multi-item line formats.
   - Include ambiguous receipts that combine plumbing with electrical or HVAC
     style wording.
   - Include negative fixtures for similar-looking non-core or wrong-family
     items.
5. Prove parser behavior surgically.
   - Run focused fixture-ID checks first.
   - Fix parser routes, fixture expectations, or metadata rules based on the
     exact failure.
   - Add a regression for every confirmed parser bug.
   - Only after focused failures are clean, run the family shard.
6. Promote evidence.
   - A family becomes release-ready only after metadata gates, generator tests,
     parser fixture evidence, readiness audit, and progress memory agree.
   - Do not mark a family ready based on token scans, docs, or smoke checks
     alone.
7. Handoff and platform validation.
   - Windows proves deterministic catalog/parser behavior.
   - Mac validates platform-specific build/runtime behavior later.
   - Mac handoff must include branch, commit, exact commands, fixture/report
     paths, expected runtime, and remaining risk.

## Validation Ladder

Use the cheapest reliable proof first, then move up only when the lower rung is
clean.

1. Static structure checks.
   - Catalog family/tier membership script.
   - Metadata completeness script.
   - Duplicate/alias collision script.
   - Ambiguity-risk script.
2. Touched-file checks.
   - `dart format` on touched files.
   - Targeted `dart analyze` on touched tool/test/parser files.
3. Generator checks.
   - Family recipe isolation tests.
   - Fixture-count and fixture-shape tests.
   - Start-index/window regression tests for shard runners.
4. Focused parser checks.
   - Failed fixture IDs only.
   - Risk-tag or family-only slices.
   - Negative ambiguity fixtures.
5. Family shard checks.
   - Smaller chunks when faster and clearer.
   - No broad all-family shard until focused failures are clean.
6. Readiness audit.
   - Verify release-ready counts, critical counts, warning counts, and family
     promotion evidence.
7. Progress and commit gate.
   - Update progress memory with start/end time, report paths, what failed, what
     was fixed, and what is still not ready.
   - Commit and push a meaningful human-readable milestone.

## Plumbing Core Work Map

### Phase 1: Stop Drift and Stabilize Tools

- Confirm the generated fixture runner correctly treats `--max-cases` as a
  window length after `--start-index`.
- Keep the regression test for that runner behavior.
- Do not start another long toilet/faucet shard until the runner regression is
  confirmed.

Exit criteria:
- Runner regression passes.
- Touched runner files format/analyze clean.

### Phase 2: Finish Toilet/Faucet Repair

- Complete shard 2 and shard 3 after the runner fix is proven.
- Fix any failures by fixture ID before rerunning full shards.
- Confirm fixture coverage for tank repair, closet/flange/seals, faucet
  washers, O-rings, cartridges/stems, aerators, assortments, trim, pop-ups,
  basket strainers, and sink repair kits.
- Promote toilet/faucet repair only after all shards pass.

Exit criteria:
- Toilet/faucet parser evidence is clean.
- Readiness audit reports the family release-ready with zero critical rows.

### Phase 3: Plumbing Core Catalog Reality Check

- Audit Core membership family by family, starting with already-evidenced
  families.
- Identify missing daily-use residential service items.
- Identify items that are plumbing but too uncommon/large/specialty for Core.
- Keep water heaters, large fixtures, specialty commercial/industrial parts,
  and uncommon large pipe sizes out of Core unless they are normal residential
  service stock.
- Keep water-softener service supplies, common well-service supplies, toilet
  repair, faucet repair, PEX, copper, PVC DWV, angle stops, supply lines,
  valves, sump discharge, water-heater service parts, brass adapters, and
  service consumables in scope when they are normal residential service items.

Exit criteria:
- Plumbing Core has a documented family-by-family membership decision.
- Mis-tiered Core items are moved or flagged.
- Missing Core items are added or listed as release-blocking gaps.

### Phase 4: Metadata Completion

- Fill required metadata for each Core item family.
- Add aliases and merchant abbreviations that actually help receipt parsing.
- Add Spanish terms for release-relevant items.
- Add ambiguity notes for shared-use items.
- Add parser risk tags for items likely to collide with electrical, HVAC,
  generic tools, merchant names, or receipt noise.

Exit criteria:
- Metadata completeness script passes for Plumbing Core.
- Ambiguity-risk script produces no unhandled critical collisions.

### Phase 5: Parser Behavior and Regression Lock

- Run focused parser fixtures for each family after metadata is complete.
- Add regressions for confirmed bugs.
- Fix route precedence instead of weakening confidence.
- Use review-required outcomes for genuinely ambiguous lines when context is
  insufficient.

Exit criteria:
- Family fixtures pass.
- Negative ambiguity fixtures behave correctly.
- Confirmed parser bugs have permanent regression coverage.

### Phase 6: Plumbing Core Release Gate

- Run readiness audit.
- Verify release-ready counts directly from JSON.
- Verify no critical rows, no hidden warnings, no unsupported family promotion,
  and no smoke-only evidence passing as release proof.
- Update progress memory.
- Commit and push the milestone.

Exit criteria:
- Plumbing Core is ready for Mac validation.
- Mac handoff document includes exact branch, commit, commands, report paths,
  and unresolved risks.

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

## Estimated Remaining Passes

These are planning estimates, not promises. The count depends on how many real
catalog membership and metadata defects the checks expose.

- Plumbing Core to Mac-handoff quality: roughly 220-450 focused passes.
- Toilet/faucet completion: roughly 20-60 passes if shard 2/3 failures stay
  local and the runner fix is clean.
- Core catalog reality check and metadata hardening: roughly 100-220 passes.
- Final family proof, readiness audit, documentation, and milestone push:
  roughly 60-170 passes.

Do not spend passes proving broad runtime behavior before the family catalog and
metadata gates are clean.
