# PDF / Document Engine Handoff - 2026-07-06

Timestamp: 2026-07-06 12:45 AM EDT

## Purpose

This file is the handoff for the next Codex model. It explains what was done in
the PDF / Document Engine lane, what was pushed, what remains unpushed, what is
wrong architecturally, and what the next model must not touch.

This is a handoff document only. It is not proof that the PDF system is
complete.

## Hard Boundaries

- Do not touch camera.
- Do not touch OCR engine behavior.
- Do not touch parser behavior.
- Do not touch inventory / materials / work-supplies implementation.
- Do not move app code until the Document Engine migration is planned and tested.
- Do not duplicate existing PDF, QA, fake-user, fake-Hive, fake-Firebase, or
  reporting infrastructure.
- If any analyze/test/build/gate fails, stop feature work, fix the failure
  properly, add or update a regression test when the failure exposes a real bug,
  and rerun the focused verification.

## Branch And Workspace Facts

Main active app on this Mac:

```text
/Users/rbbie/Documents/Maintainiac_5.6_Active
```

At the time this handoff file was created, that repo was on:

```text
codex/expense-camera
```

That active repo already had unrelated camera/receipt worktree changes:

```text
M docs/receipt_bug_regression_ledger.md
?? test/receipt_native_ios_guidance_warning_gate_test.dart
```

Do not overwrite or revert those. They are not PDF work from this lane.

The PDF work I did was in a separate worktree:

```text
/private/tmp/maintainiac_pdf_system_worktree
```

That worktree is on:

```text
codex/pdf-system-pass-61
```

It tracks/pushes to:

```text
origin/codex/pdf-system
```

Last pushed PDF commit:

```text
c93f3c364 2026-07-05 10:37 PM EDT - Pass 138-203 - Harden PDF export safety
```

Remote branch:

```text
origin/codex/pdf-system
```

## Important Warning

There are uncommitted PDF changes in:

```text
/private/tmp/maintainiac_pdf_system_worktree
```

Those changes were not pushed and should not be blindly accepted. They include
some useful hardening work, but they also include a started support-diagnostics
addition that was interrupted before focused tests were run.

Uncommitted diff at handoff time:

```text
11 files changed, 779 insertions(+), 23 deletions(-)
```

Uncommitted files:

```text
docs/pdf_system_windows_handoff_2026_07_05.md
lib/screens/expenses/data/expense_export_handoff.dart
lib/shared/documents/app_document_export_package_writer.dart
lib/shared/pdf/app_generated_pdf_models.dart
lib/shared/widgets/receipt_capture/receipt_pdf_inspection.dart
lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart
test/app_document_export_package_writer_test.dart
test/app_generated_pdf_service_test.dart
test/expense_export_test.dart
test/fixtures/pdf_qa/fixture_pack_inventory.json
test/receipt_pdf_inspector_edge_cases_test.dart
```

The safest next model should inspect that worktree carefully before deciding
whether to keep, split, fix, or discard the uncommitted changes.

## What Was Pushed

The pushed PDF branch already includes hardening around:

- Document Engine scope documentation.
- PDF QA registry expansion.
- Expense export atomic file writing.
- Expense export privacy preflight.
- Expense export ZIP containment.
- Generated PDF validation.
- Generated PDF privacy/security checks.
- Receipt PDF inspection hardening.
- Invoice/estimate landscape pagination bug fix.
- Invoice/export internal ID blocking.
- Document export package write/read/share/import/extract safety checks.
- Storage cleanup and partial-file handling.
- Focused QA and regression coverage for the above.

The pushed branch is not complete. It is only the current PDF lane state.

## Focused Verification That Passed Before The Interrupted Work

The last known green bundled verification before the later interrupted edits was:

```bash
git diff --check
python3 -m json.tool test/fixtures/pdf_qa/fixture_pack_inventory.json >/tmp/fixture_pack_inventory.check.json
dart analyze docs/pdf_system_windows_handoff_2026_07_05.md lib/shared/documents/app_document_export_package_writer.dart lib/screens/expenses/data/expense_export_handoff.dart lib/shared/pdf/app_generated_pdf_models.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspection.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/app_document_export_package_writer_test.dart test/app_generated_pdf_service_test.dart test/expense_export_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_qa_fixture_inventory_test.dart
flutter test test/app_document_export_package_writer_test.dart test/app_generated_pdf_service_test.dart test/expense_export_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact
```

Result:

```text
No issues found.
All tests passed.
```

That green result does not cover the later started diagnostics additions unless
the next model reruns verification after reviewing/fixing them.

## What Went Wrong Architecturally

The biggest issue is architecture, not just edge cases.

The user wanted Maintainiac's reusable Document Engine from the beginning. The
engine should be its own subsystem. Expense, invoice, estimate, receipt, export,
inventory, and future report flows should call into it. The current code still
has PDF-related logic living under screen-owned paths such as:

```text
lib/screens/expenses/...
lib/screens/invoices/...
```

That makes the PDF system look owned by expenses or invoices. That is not the
target architecture.

The target architecture is:

```text
Document Engine first.
Screens and record flows import/call what they need.
```

Do not "rip files out" quickly. Moving this correctly is a real architecture
migration and must be planned, bundled, verified, and regression-tested.

## Recommended Future Architecture

The next model should design a real Document Engine home, likely under a shared
path such as:

```text
lib/shared/document_engine/
```

or another clearly named shared subsystem path chosen consistently with the
repo.

Recommended conceptual modules:

```text
document_engine/core
document_engine/pdf_generation
document_engine/templates
document_engine/layout
document_engine/tables
document_engine/pagination
document_engine/import_export
document_engine/storage
document_engine/privacy
document_engine/security
document_engine/diagnostics
document_engine/receipt_support
document_engine/report_adapters
document_engine/invoice_estimate_adapters
```

The key rule:

```text
Expense, invoice, receipt, and inventory code should be adapters/consumers.
They should not own the PDF engine.
```

## Migration Plan For Next Codex

1. Audit current PDF-related files and classify each one:
   - true shared engine code
   - receipt PDF support
   - invoice/estimate adapter
   - expense export/report adapter
   - storage/privacy/security/diagnostics
   - tests/fixtures/gates

2. Create a written migration map before moving files.

3. Move only one coherent slice at a time:
   - shared formatters/page specs/security/privacy first
   - generated PDF service/storage/archive next
   - document export package code next
   - receipt PDF support next
   - invoice/estimate adapters next
   - expense report adapters next

4. After each slice:
   - update imports
   - run targeted analyze/tests for that slice
   - fix failures immediately
   - add regression coverage if a real bug is found

5. Do not run huge gates after tiny file moves. Use focused checks while moving.
   Run the full PDF gate only at meaningful migration milestones.

6. Do not touch camera/OCR/parser/inventory behavior while doing this.

## Remaining PDF Work

High-level remaining work:

- Correct Document Engine architecture and file ownership.
- More render-level PDF checks for invoice/estimate/export PDFs.
- More PDF import torture fixtures.
- More receipt PDF handoff failure recovery checks.
- More export package failure-injection checks.
- Stronger performance logging for huge PDFs and weak devices.
- Better Android/iOS share, print, Files/Drive/Preview compatibility evidence.
- More privacy leak tests for support diagnostics, Command 1, filenames, logs,
  QA reports, and share text.
- Regression IDs for every confirmed PDF bug.

## Handoff Folder Created For Review

A local review/export folder was created on the Mac:

```text
/Users/rbbie/Documents/Maintainiac_PDF_System_Two_Folders_2026-07-05_23-17_EDT
```

It contains:

```text
PDF_Code
PDF_Tests
```

Those folders were also pushed to the USB-connected Samsung S24 Ultra in:

```text
Documents/PDF_Code
Documents/PDF_Tests
Downloads/PDF_Code
Downloads/PDF_Tests
```

That phone transfer was only for handoff/review convenience. It is not part of
the app repo and should not be treated as architecture.

## Next Model First Steps

1. Work in the correct app repo and branch. Verify the branch first.
2. Inspect `/private/tmp/maintainiac_pdf_system_worktree` only if deciding what
   to do with my uncommitted PDF changes.
3. Do not merge the uncommitted changes blindly.
4. Treat `origin/codex/pdf-system` as the pushed PDF lane.
5. Plan the Document Engine architecture correction before moving any source
   files.
6. Keep all work away from camera/OCR/parser/inventory behavior unless the user
   explicitly reopens those areas.
