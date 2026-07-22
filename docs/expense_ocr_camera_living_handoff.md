# Expenses, OCR, And Receipt Camera Living Handoff

> Routing note: this combined document is retained as historical consolidation
> evidence. Current rolling records are split between
> `docs/system_handoffs/expenses.md` and
> `docs/system_handoffs/receipt_capture_ocr_long_receipt.md`. Update the owning
> system document first; do not add unrelated systems here.

This is the living handoff for the next Codex worker assigned to Maintainiac's
Expenses, receipt OCR, receipt camera, long-receipt, or related review lane.
Update it whenever a product decision, implementation checkpoint, validation
result, or unresolved requirement changes.

## Authoritative Checkout

- Folder: `/Users/rbbie/Documents/Maintainiac_5.7_Active`
- Branch: `codex/maintainiac-5.7-consolidation-20260722`
- Remote: `https://github.com/haftafish3760/maintainiac5.6-.git`
- New consolidation commits begin with `[5.7]`.
- Verify checkout, branch, remote, and dirty-worktree ownership before edits.

## Mandatory Product Rules

1. OCR and parsers produce suggestions. The user reviews every receipt before
   saving, routing, categorizing, or adding items to inventory.
2. Never silently choose Fuel versus Expenses versus Work Supplies / Materials.
3. Work Supplies, Materials, and Inventory are one existing system. Do not
   create a parallel inventory module.
4. Confirmed Materials items preserve exact after-tax per-item cost with
   exact-cent receipt reconciliation.
5. Imported gallery, Files, share-provider, and picker originals are read-only.
   Never modify, overwrite, or delete them.
6. Selected proof remains until the user explicitly deletes it in Maintainiac.
7. Duplicate detection warns. It never silently deletes, merges, overwrites,
   or suppresses a receipt.
8. Source repositories remain read-only during consolidation.

Read `docs/expense_receipt_storage_and_duplicate_contract.md` before changing
receipt persistence, drafts, proof cleanup, duplicate handling, OCR handoff, or
cloud restore.

## Current Draft Behavior

5.7 currently does not delete recoverable drafts because they are old. Startup
performs recovery inspection only. Completion removes only its unchanged draft
and staged app-private copies. Explicit draft deletion removes only that draft
and its app-private staging. Permanent proof and external originals remain
outside those deletion paths.

Do not reintroduce seven-day age cleanup as an isolated change.

## Deferred Draft Retention And Visual Duplicate Review

The product owner chose the following direction and explicitly deferred its
implementation because it is a large dedicated subsystem:

- users choose draft retention during onboarding and in settings;
- default retention is 90 days;
- dashboard reminders begin when a draft reaches 7 days old;
- advance warning appears before the selected deletion deadline;
- similarity checks compare drafts with drafts and saved receipts;
- evidence includes proof hash, merchant/vendor, date, time, total, receipt
  number, and other available receipt metadata;
- reminders show one safe thumbnail from the draft's Maintainiac-owned proof
  when available;
- actions include Review, Save, Keep, and Delete;
- Save opens mandatory receipt review and never silently persists a suspected
  duplicate;
- Delete is explicit, confirmed, and limited to the selected draft's
  Maintainiac-owned files;
- external originals and unrelated completed proof are never deleted.

Do not implement isolated pieces. This requires dedicated architecture,
settings, onboarding, dashboard, similarity, thumbnail, notification,
migration, cleanup, accessibility, crash-recovery, cloud, and regression work.
The product owner stated that it is not being implemented during consolidation.

## Verified 5.7 Checkpoints

- `9da6749c`: documented receipt ownership, mandatory review, and duplicate
  warning behavior.
- `16ef2f82`: enforced receipt recovery and app-private cleanup boundaries;
  analyzer clean and 38 focused tests passed.
- `6bf01ced`: reconciled OCR evidence provenance, candidate extraction,
  quality-prioritized photo selection, and stalled-read recovery; analyzer
  clean and 39 focused tests passed.
- `63e2d49c`: integrated parser-missing OCR candidates into editable review
  without overwriting parser/user values; analyzer clean and 25 focused tests
  passed.
- `361a85e0`: reconciled Basic, Detailed Items, and Quick Classify receipt
  amount fields; analyzer clean and 12 focused tests passed.

## Consolidation And Validation Boundary

The old OCR branch's whole-batch analyzer failure is not proof every source
capability is obsolete. Continue feature-level comparison using behavior,
symbols, imports, tests, and current 5.7 equivalents. Never add an older
parallel Expense job, vehicle, queue, deletion, Firebase, or profile store just
because its filename is absent; 5.7 may contain the newer centralized owner.

Format changed Dart files, run `flutter analyze`, run focused regression tests,
repair and rerun exact failures, and record evidence here. Platform builds and
final project-wide tests remain required before final consolidation completion.

## Living Update Log

- 2026-07-22: Created after the product owner deferred configurable draft
  retention and visual duplicate review.
- 2026-07-22: Recorded verified checkpoints through `63e2d49c`.
- 2026-07-22: Split current routing into dedicated Expenses and Receipt System
  handoffs and recorded checkpoint `361a85e0`.
