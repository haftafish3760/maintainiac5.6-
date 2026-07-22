# Expense Receipt Storage And Duplicate Contract

This document is a release-blocking product contract for every Codex worker
that changes the Maintainiac Expense app, receipt camera/OCR handoff, drafts,
proof storage, cloud restore, or Work Supplies / Materials receipt parsing.
Current implementation status and deferred decisions are tracked in
`docs/expense_ocr_camera_living_handoff.md`.

## Product And Module Identity

- Maintainiac contains multiple apps/modules under one roof.
- Expenses is the owner of expense receipts and their proof lifecycle.
- Work Supplies, Materials, and Inventory are three names for one existing
  module. OCR must not create a parallel Inventory system.
- A Materials receipt may propose individual inventory acquisitions only after
  mandatory user review. Confirmed inventory cost includes the item's allocated
  tax and receipt adjustments, with exact-cent reconciliation.

## User Review Is Mandatory

OCR and parsers produce suggestions. The user must review the receipt before
anything is saved, categorized, routed to Fuel, or added to Work Supplies /
Materials inventory. No confidence score bypasses this review.

## Storage Ownership Boundary

Maintainiac receives only the image, PDF, or file the user explicitly selects.
It must not browse, index, modify, overwrite, or delete unrelated device files.

| Artifact | Ownership | Required behavior |
| --- | --- | --- |
| Gallery, Files, share-provider, or picker original | User-owned external source | Read-only. Never modify, overwrite, or delete. |
| Maintainiac app-private import copy | Maintainiac working copy | Keep while its session/draft is recoverable; delete after completion if unused or after the user explicitly deletes/discards the owning draft or proof. |
| Native camera candidate inside Maintainiac storage | Maintainiac working copy | Keep during review and interruption recovery; delete when unselected after completion or explicit discard. |
| OCR raster page, crop preview, stitch preview, or `.partial` output | Maintainiac temporary working artifact | Delete after the operation/session finishes; never upload or count as proof storage. |
| Selected receipt proof inside Maintainiac storage | User-confirmed app record | Keep until the user explicitly deletes that proof inside Maintainiac. Never age-clean or overwrite it. |
| Interrupted receipt session | Recoverable user draft | Keep its app-private artifacts until the user resumes, completes, or explicitly deletes/discards the draft. Never delete solely because it is old. |

Deleting an app-private copy never grants permission to delete its external
source. Path checks must prove the deletion target is inside a Maintainiac-owned
root before deletion. Imported originals remain untouched even when their
Maintainiac draft, working copy, or proof is explicitly deleted.

## Session And Draft Lifecycle

1. Capture/import creates app-private candidates and a recoverable checkpoint.
2. A phone call, app backgrounding, crash, or interrupted review retains the
   draft and its candidates.
3. Retakes remain available during review so the user can change selection.
4. Successful completion promotes only selected proof and deletes unused
   app-private candidates and scratch artifacts.
5. Explicit draft deletion removes the draft and only the app-private artifacts
   owned by that draft.
6. Explicit proof deletion removes only the selected app-private proof chosen by
   the user. It does not touch the imported/gallery/file original.
7. Automatic age-based cleanup must never erase a recoverable draft or selected
   proof.

Cloud backup must upload only confirmed records and selected proof. Rejected
photos, unused retakes, OCR scratch images, failed outputs, and other temporary
artifacts must never be uploaded or charged against the user's storage quota.

## Duplicate Receipt Contract

Maintainiac warns; the user decides. Duplicate detection must never silently
delete, merge, overwrite, or suppress a legitimate receipt.

The warning system should use, where available:

- exact proof SHA-256 match;
- normalized merchant, receipt date, total, tax, receipt number, category,
  vehicle, and payment context;
- near-date and near-amount evidence for a lower-confidence warning;
- local ledger and authorized account restore/sync metadata without exposing
  raw receipt images or OCR text.

The review must let the user view the existing receipt, return to edit the
current receipt, cancel, or save anyway. A save-anyway decision and its optional
reason remain in the audit record. Duplicate detection is a warning system, not
a deletion system.

## Current 5.7 Implementation Evidence

The local Expense implementation already includes the core warning flow:

- `expense_receipt_duplicate_models.dart` defines confidence, candidates, and
  explicit user choices.
- `expense_ledger_duplicate_helpers.dart` compares proof hashes and receipt
  metadata.
- `expense_receipt_save_actions.dart` runs the check before proof promotion and
  ledger save.
- `expense_receipt_duplicate_dialog.dart` exposes View Existing, Edit Current,
  Cancel, and Save Anyway.
- receipt serialization, Firestore documents, and cloud restore preserve or
  review duplicate evidence.
- `test/expense_duplicate_detection_test.dart` is the focused regression suite.

## Release-Blocking Reminder For Future Expense Work

Do not mark duplicate protection complete merely because local-ledger tests
pass. Before release, the Expense worker must remind the product owner to decide
and verify the account-wide duplicate-warning behavior across authorized device
restore/sync. Current local and restore-planner coverage must be audited against
that requirement. This reminder stays open until device/account evidence proves
the full behavior.

## Deferred Draft Retention And Visual Similarity System

This is an explicitly deferred product direction, not authorization for a
partial implementation during repository consolidation. Until the complete
system is implemented and verified, 5.7 keeps recoverable drafts indefinitely
and performs no age-based draft deletion.

The future system must be delivered as a complete, multi-pass subsystem:

- the user chooses draft retention during onboarding and later in settings;
- the default retention period is 90 days;
- a dashboard reminder begins when a draft reaches 7 days old;
- advance notice appears before the selected retention deadline;
- exact and similar matching compares drafts with other drafts and saved
  receipts using proof hash, merchant/vendor, date, time, total, receipt
  number, and other available receipt evidence;
- a similarity reminder shows one safe thumbnail from the draft's
  Maintainiac-owned proof when available;
- Review, Save, Keep, and Delete remain explicit user actions;
- Save opens and completes mandatory receipt review rather than bypassing it;
- Delete requires confirmation and can remove only that draft and its
  Maintainiac-owned files, never an imported original or unrelated proof;
- missing thumbnails, inaccessible files, crashes, concurrent edits,
  migration, notification timing, accessibility, and cloud/account behavior
  require dedicated regression coverage.

Do not implement isolated pieces of this design. Retention, warnings,
similarity evidence, UI actions, cleanup boundaries, migration, and QA must be
planned and delivered together in a future dedicated Expense effort.

Any change to this contract requires explicit product-owner approval plus
targeted regression tests for ownership boundaries, draft interruption,
completion cleanup, explicit deletion, duplicate warning, save-anyway audit,
and cloud-restore behavior.
