# Codex 5.3 Spark Maintenance Receipt Operating Manual

## Mission

Continue building Maintainiac's commercial-grade, local-first maintenance
receipt parser and maintenance-setup system for every maintenance item. OCR
supplies plain text. The maintenance system interprets that text, presents
editable suggestions, and writes only after explicit user confirmation.

This manual governs one 100-pass Spark wave in the same Codex conversation.
It does not authorize another repository, branch, worktree, checkout, push,
camera change, OCR change, Firebase change, or device session.

## Absolute workspace

- Work only in `/Users/rbbie/Documents/Maintainiac_5.7_Active`.
- Before every pass, run `pwd` and `git status --short --branch`.
- Do not work from `Maintainiac_5.6_Active`.
- Do not create a repository, branch, worktree, clone, or sibling folder.
- Do not switch branches.
- Do not commit or push unless the user explicitly asks during the Spark wave.
- Never stage unrelated dirty work.

## Wave boundary

- Read the current counter in
  `docs/maintenance_receipt_parser_pass_log.md`.
- Spark starts at the next unaccepted pass number.
- Spark may complete at most 100 accepted passes.
- Failed, interrupted, abandoned, question-only, status-only, Git-only, and
  documentation-only cycles do not count.
- After the hundredth accepted Spark pass, stop all implementation.
- Do not begin a 101st Spark pass.
- Produce the return handoff described below and wait for the stronger model.

Example: if the last accepted pass is 38, Spark may accept Passes 39-138. It
must stop after Pass 138.

## What one pass means

A pass is one bounded file/work edit cycle that ends only when every relevant
test is green.

One pass has all of these stages:

1. Read the pass log, roadmap, this manual, and current Git status.
2. Name one coherent problem family.
3. Identify the smallest authoritative production files.
4. Identify the regression fixture or test that can prove the gap.
5. Check every target file's line count before editing.
6. Add or tighten the regression first when practical.
7. Make one bundled, coherent implementation change.
8. Format only the files touched by the pass.
9. Run the smallest relevant analyzer/test command.
10. If it fails, stop all new feature work.
11. Fix the root cause without weakening the expected behavior.
12. Rerun the exact failed check.
13. Run broader regression when shared parser behavior changed.
14. Run `git diff --check`.
15. Record the pass only after every required check is green.

Do not count:

- opening or reading a file;
- answering a question;
- Git inspection;
- a failed or interrupted check;
- a change reverted before acceptance;
- documentation bookkeeping without app/test work;
- a push, commit, or PR;
- a test rerun with no edit cycle.

## Bundling rule

Bundle related wording, layouts, and safety cases when they share one parser
cause. Do not make a separate pass for every alias.

Good pass bundles:

- one maintenance family across several merchant layouts;
- one ambiguity class across purchase and service receipts;
- one field such as viscosity across clean, fragmented, and damaged text;
- one review safety rule plus its draft/application regressions;
- one fixture schema improvement plus the evaluator that consumes it.

Bad pass bundles:

- unrelated oil, tires, storage, UI, and Firebase work together;
- one alias per pass when ten safe aliases share the same rule;
- broad rewrites without a failing fixture;
- mass catalog expansion without collision tests;
- changes made only to increase a test count.

## File-size rule

- Every source, test, fixture, script, and maintenance receipt document must
  stay at 499 lines or fewer.
- Never let a file reach 500 lines.
- Split by real responsibility before adding behavior.
- Use descriptive filenames, not numbered catch-all names.
- `tool/maintenance_receipt_qa_gate.sh` enforces the receipt-lane limit.

## Owned production lane

Primary parser files:

- `lib/screens/maintenance/data/maintenance_receipt_parser.dart`
- `lib/screens/maintenance/data/maintenance_receipt_parser_catalog.dart`
- `lib/screens/maintenance/data/maintenance_receipt_parser_engine.dart`
- `lib/screens/maintenance/data/maintenance_receipt_parser_support.dart`
- `lib/screens/maintenance/data/maintenance_receipt_review.dart`
- `lib/screens/maintenance/data/maintenance_receipt_review_commands.dart`
- `lib/screens/maintenance/data/maintenance_receipt_application_service.dart`

Maintenance-owned review files:

- `lib/screens/maintenance/maintenance_receipt_review_flow.dart`
- `lib/screens/maintenance/maintenance_receipt_review_screen.dart`
- `lib/screens/maintenance/maintenance_receipt_review_item_card.dart`
- `lib/screens/maintenance/maintenance_receipt_apply_dialog.dart`

Primary evidence:

- `test/fixtures/maintenance_receipts/synthetic_corpus.json`
- `test/maintenance_receipt_*_test.dart`
- `tool/maintenance_receipt_qa_gate.sh`
- `docs/maintenance_receipt_parser_roadmap.md`
- `docs/maintenance_receipt_parser_pass_log.md`

Shared maintenance/state files may be edited only when the pass cannot be
correct without the change. Inspect their full current diff first. Preserve
other owners' changes. Do not use receipt work as permission for broad cleanup.

## Forbidden lanes

Do not edit:

- camera capture;
- image cleanup;
- crop, perspective, glare, blur, shadow, or stitching;
- OCR recognition or OCR duplicated-line removal;
- device-capability work;
- trip/GPS tracking;
- contractor or gig-driver dashboards;
- expenses, Materials, invoices, PDF, or unrelated parsers;
- Firebase rules, cloud functions, cloud storage, or deployment;
- the reusable/shared QA harness.

Duplicate-line cleanup remains OCR-owned. The maintenance parser does not
deduplicate recognized lines. The parser may handle conservative character
substitutions and fragmented descriptions only when regression evidence proves
safety.

## Product invariants

- Manual maintenance setup must work without a receipt.
- Receipt suggestions are optional assistance.
- Basic is the default setup mode.
- Basic stores the item plus mileage/time intervals only.
- Advanced requires explicit selection.
- Advanced stores reviewed item-specific details.
- Engine Oil Advanced details require oil type and oil weight when known.
- Oil brand and quart quantity are not required fields.
- Every current manual maintenance item must have a parser/review path.
- A parts purchase never proves installation.
- An estimate, recommendation, declined item, return, exchange, or refund never
  silently becomes completed service.
- Every candidate requires a user decision.
- Every inferred field remains editable.
- Final durable application requires a separate explicit confirmation.
- Parser output never changes the global odometer.
- Receipt odometer evidence never outranks the user's confirmed odometer.
- Active vehicle identity uses the stable vehicle ID, not a nickname.
- An active-vehicle change invalidates stale review commands.
- Raw receipt text never enters finalized maintenance records.
- Local storage is immediate truth.
- Cloud/AI is optional and never required for the basic parser.

## Accuracy contract

The user's minimum release floor is 90% for every supported maintenance family
and required field. Do not hide a weak family inside a strong aggregate.

Measure separately:

- item-family precision;
- item-family recall;
- per-item action accuracy;
- purchase versus completed-service classification;
- merchant;
- receipt kind;
- exact candidate set;
- service date;
- service odometer;
- due odometer;
- mileage interval;
- month interval;
- each supported Advanced detail field;
- clean versus fragmented versus conservatively damaged recognized text;
- merchant/layout family.

Zero-tolerance safety failures:

- purchase-only evidence becoming completed service;
- declined/estimated/returned work becoming completed service without explicit
  contradiction confirmation;
- silent global odometer mutation;
- wrong stable vehicle assignment;
- durable write before final consent;
- raw receipt text in finalized records;
- post-review command tampering accepted;
- parser dependency on camera, OCR, Firebase, Hive, or expenses.

Synthetic development fixtures can drive implementation but cannot prove
commercial accuracy. Real release evidence requires consented, unseen receipt
text that was not used to write the parser rules.

## Fixture procedure

For each fixture:

1. Use synthetic text or consented/redacted real recognized text.
2. Never commit private raw receipts, VINs, emails, phones, addresses, payment
   numbers, customer identifiers, or proof paths.
3. Label merchant, receipt kind, expected candidates, expected action, forbidden
   candidates, and any expected fields.
4. Preserve the source's meaningful line layout.
5. Do not add duplicated-line variants; OCR owns that failure family.
6. Add clean, spacing/case/CRLF, fragmented, or conservative damage variants
   only when they model the parser boundary.
7. Require exact candidate sets unless a documented test needs otherwise.
8. Add negative-neighbor receipts that must not produce the candidate.
9. Add purchase and service evidence separately.
10. Add return/estimate/declined neighbors where applicable.

Never change expected output merely to match current parser behavior. Expected
output represents the product truth.

## Required commands

At pass start:

```sh
pwd
git status --short --branch
```

Focused checks should name exact changed files:

```sh
dart format --output=none --set-exit-if-changed <changed dart files>
dart analyze <changed production and test files>
flutter test <focused test files> -r compact
git diff --check
```

Run the milestone gate when parser-wide behavior, review commands, durable
application, catalog coverage, accuracy measurement, or the gate itself changes:

```sh
sh tool/maintenance_receipt_qa_gate.sh
git diff --check
```

Do not modify the shared QA harness to make maintenance pass. Maintenance may
extend only its maintenance-owned gate and tests.

## Failure procedure

On any red or interrupted check:

1. Do not record the pass.
2. Do not start another feature.
3. Save the exact failing command and first actionable failure.
4. Decide whether the defect is production behavior, test setup, or fixture
   truth.
5. Never lower the 90% floor.
6. Never remove a safety assertion to get green.
7. Fix the narrow root cause.
8. Rerun the exact failed check.
9. Rerun the broader gate if shared behavior changed.
10. Record the pass only after green.

If the same blocker survives three serious attempts, stop and return a blocker
handoff. Do not drift into another lane.

## Pass-log procedure

After green:

1. Add one numbered entry to
   `docs/maintenance_receipt_parser_pass_log.md`.
2. State the problem family.
3. State the production behavior added or corrected.
4. State the focused checks that passed.
5. State whether the full maintenance gate passed.
6. Update Last accepted pass and Next pass.
7. Update the roadmap only when capability or evidence changed materially.
8. Verify both documents remain under 500 lines.

Never pre-record a pass. Never count an interrupted gate.

## Anti-drift audit every 20 Spark passes

At Spark pass 20, 40, 60, 80, and 100 of this wave:

1. Run the full maintenance receipt gate.
2. Inspect `git status --short --branch`.
3. List every changed file since the previous audit.
4. Confirm all files belong to maintenance receipt/manual maintenance scope.
5. Confirm no camera/OCR/shared-harness/device/GPS/Firebase files changed.
6. Confirm every receipt-lane file is under 500 lines.
7. Confirm the pass ledger has no gaps or duplicate numbers.
8. Confirm Basic remains default and Advanced remains explicit.
9. Confirm purchases cannot become history without installation confirmation.
10. Confirm parser output cannot mutate odometer or durable state.
11. Confirm the accuracy floor was not reduced.
12. Record the audit inside that pass entry.

The stronger-model architecture review still occurs every 200-300 accepted
passes across the overall project. This 100-pass Spark wave returns earlier for
an additional stronger-model review.

## Spark work order

Use this priority order unless a red regression forces a repair:

1. Strengthen fixture schema for expected dates, odometers, intervals, and
   Advanced fields.
2. Add negative-neighbor fixtures for every catalog family.
3. Expand merchant/layout variants across all maintenance families.
4. Expand service-invoice performed/declined/estimate separation.
5. Expand auto-parts purchase/return/exchange/core-credit separation.
6. Expand fragmented recognized-text layouts without duplicate-line logic.
7. Add conservative dirty/faded character variants with original evidence
   preservation.
8. Add cross-item collision matrices.
9. Add locale/date/currency variants without guessing unsupported formats.
10. Add malformed, bounded-input, fuzz, and metamorphic tests.
11. Improve field-level accuracy reporting and failure digests.
12. Add real-receipt holdout plumbing without committing private receipt text.

Do not spend the wave polishing broad UI. Parser/review correctness and QA are
the assigned work.

## Stop and escalate immediately

Stop before editing if:

- a required change touches camera/OCR ownership;
- a required change touches Firebase/durable-storage ownership outside the
  existing confirmed maintenance contract;
- a shared file contains overlapping work that cannot be preserved safely;
- a test expectation conflicts with a user requirement;
- an item name conflicts with the manual catalog;
- a proposed normalization could create broad false positives;
- a file would reach 500 lines;
- Git status shows an unexpected branch or repository;
- the full gate is already red before the pass;
- the user asks to pause or changes scope.

## Hundred-pass return handoff

After the hundredth accepted Spark pass, provide:

- starting and ending accepted pass numbers;
- exact number of accepted, failed, interrupted, and uncounted cycles;
- changed-file inventory;
- last full-gate command and result;
- test count and accuracy metrics by family/field;
- unresolved false positives and false negatives;
- remaining unsupported layouts and merchants;
- privacy/security findings;
- line-count audit;
- confirmation that forbidden lanes stayed untouched;
- exact next recommended pass;
- any decision that requires the user or stronger model.

Then stop. Do not continue implementation until the stronger model reviews the
wave in this same conversation.

## Completion language

Never call the parser world-class, commercial-grade, 90% accurate, complete, or
release-ready from synthetic tests alone. Report exactly what current evidence
proves and what remains unproven.
