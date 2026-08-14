# Maintenance Receipt Parser Roadmap

Status: commercial-grade completion remains unproven. Manual maintenance,
local persistence, pure text parsing, editable review, restartable drafts, and
confirmation-gated application foundations exist. Real-receipt holdout
accuracy, broader maintenance-family depth, device evidence, and release gates
remain incomplete.

The complete roadmap through Pass 73 is preserved in
[`maintenance_receipt_parser_roadmap_archive_through_pass_073.md`](maintenance_receipt_parser_roadmap_archive_through_pass_073.md).
Pass evidence through Pass 90 is linked from the living pass ledger.

Canonical checkout: `/Users/rbbie/Documents/Maintainiac_5.7_Active`

## Non-negotiable boundaries

- Do not create another repository, branch, worktree, checkout, or sibling
  implementation.
- OCR supplies text. Do not modify camera, OCR, image cleanup, stitching, PDF,
  or native capture code in this lane. Duplicate recognized lines are OCR-owned.
- Keep the parser deterministic, local-first, and free of Hive, Firebase,
  camera, OCR, expense, and widget dependencies.
- Receipt output is editable evidence. Never create history, begin tracking,
  or mutate canonical odometer state before explicit user confirmation.
- A purchase never proves installation. Estimates, recommendations, declined
  work, findings, and advisory narrative never prove completed service.
- Stable vehicle ID is identity; nickname is display text. Each maintenance
  screen uses the shared active vehicle and `GlobalOdometerController` truth.
- Firebase/durable storage and Materials/Inventory remain separately owned.
- Keep every maintenance receipt source, test, fixture, gate, roadmap, and pass
  ledger file below 500 lines.

## Implemented foundation

- Manual catalog covers 59 periodic/time-only maintenance families.
- Basic setup defaults to mileage/time intervals only; Advanced opt-in retains
  reviewed item details such as oil type and viscosity.
- Merchant-neutral parsing recognizes parts purchases and service invoices
  without depending on exact Advance Auto Parts, O'Reilly, NAPA, AutoZone, or
  other store layouts.
- Review distinguishes receipt schedule evidence, editable app suggestions,
  and user-reviewed values. Vehicle/OEM schedule confirmation remains explicit.
- Printed service/due mileage and dates outrank catalog fallback suggestions.
- Time-only completed maintenance can omit odometer evidence; missing evidence
  is displayed as Not recorded and never changes canonical odometer state.
- Local review drafts, command integrity, duplicate protection, atomic
  application, restart recovery, and stable vehicle identity are implemented.

## Highest-priority remaining work

1. Expand deterministic maintenance-family extraction depth using distinct
   behaviors, not superficial merchant/layout fixtures.
2. Build consented, locked real-receipt holdouts separated by maintenance
   family, merchant/layout family, field, and recognized-text damage class.
3. Measure precision, recall, false positives, latency, memory, and recovery;
   the user-set release floor is 90% per supported family and required field,
   not merely aggregate accuracy.
   A green synthetic development gate is not real-receipt holdout proof.
4. Close manual/review/application gaps before UI polish: mixed services,
   time-only work, returns/exchanges, warranties, estimates, and next-due
   provenance must remain confirmation-gated.
5. Preserve zero-tolerance invariants: no purchase-to-service false positive,
   no silent odometer mutation, and no bypass of final confirmation.
6. Run architecture/drift review every 200-300 accepted passes, with a stronger
   model checking this roadmap, pass ledger, boundaries, and QA evidence.

## Pass and QA procedure

1. Declare one coherent file or file-group scope.
2. Search existing coverage before adding a test; extend or parameterize first.
3. Add a test only for a genuinely distinct uncovered behavior. More than five
   new regression tests in one pass requires prior coverage-gap approval.
4. Run changed-file analysis and direct Tier 1 tests until green.
5. Run Tier 2 for feature/shared-contract changes or every 10 passes, Tier 3 at
   checkpoints/every 50 passes, and Tier 4 before release candidates.
6. Record production files, existing/new/consolidated tests, executed tiers,
   uncovered risks, and before/after test counts. Increment only after green.

Pass history lives in `maintenance_receipt_parser_pass_log.md`. The current
accepted pass is 106; the next pass is 107. Full history through Pass 90 is linked
from both canonical documents.

## Handoff

Read this file, the living pass ledger, and the archive links first. Then run:

```sh
git status --short --branch
```

Do not edit unrelated dirty files. Never weaken coverage or thresholds merely
to get green. Use `tool/maintenance_receipt_qa_gate.sh` only at the execution
tier that owns the full checkpoint; ordinary passes use impact-selected tests.
