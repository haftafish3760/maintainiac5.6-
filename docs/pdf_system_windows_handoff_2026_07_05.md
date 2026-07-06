# Maintainiac 5.6 PDF System Windows Handoff

Date: 2026-07-05

## Current Mission

Build and harden Maintainiac's PDF system until it is a serious, professional-grade subsystem for the actual app scope:

- Receipt PDFs and receipt PDF proof handling
- Invoice PDFs
- Estimate PDFs
- Expense/export/report PDFs for Maintainiac-owned records
- Storage, sharing, printing, export, privacy, security, failure recovery, and QA coverage around those flows

This is not a general office PDF application. Do not expand the scope into arbitrary PDF editing, generic PDF form handling, unrelated office documents, or a full general-purpose PDF viewer.

## Hard Boundaries

Do not touch these areas unless the user explicitly reopens them:

- Camera
- OCR engine behavior
- Parser behavior
- Inventory/work-supplies implementation
- General expense parsing rules

PDF may integrate with confirmed app records and receipt proof handoff, but do not change the parser, OCR, camera, or inventory logic.

## GitHub Branch Information

Remote repository:

```text
https://github.com/haftafish3760/maintainiac5.6-.git
```

Remote branch that has been pushed to:

```text
origin/codex/pdf-system
```

Current local working branch in this worktree:

```text
codex/pdf-system-pass-61
```

Current local branch tracks:

```text
origin/codex/pdf-system
```

Current pushed remote tip at the time of this handoff:

```text
cd5f3bdc3 Expand incoming share PDF QA coverage
```

Important: the latest Pass 138-159 work described below is not committed and not pushed yet. It exists as local modified files in the current worktree.

## Current Worktree

The PDF worktree used here is:

```text
/private/tmp/maintainiac_pdf_system_worktree
```

The user may move work to Windows. If Windows Codex is starting fresh, it should pull or clone the GitHub repo and check out:

```bash
git fetch origin
git checkout codex/pdf-system
```

If the Pass 138-159 local changes have not been pushed by the Mac model yet, Windows will not have them until they are committed and pushed or otherwise transferred.

## User Workflow Rules

The user wants large bundled passes, not tiny commits or tiny pushes.

Rules:

- Number every pass internally.
- Do not push every pass.
- Push only at a meaningful milestone or roughly every 30 minutes if the work is worth preserving.
- If close to a real milestone, finish the milestone before pushing.
- Commit messages must be human-readable and include the date/time and what was completed.
- Do QA and regression as work is built.
- If any test/analyze/gate/build failure occurs, stop feature work and fix it properly before continuing.
- Do not hide failures or move past them.
- Do not create duplicate fake users, fake Hive, fake Firebase mirrors, or duplicate QA reporting if shared app QA backbone exists.

## Current Open Pass

Current open pass range:

```text
Pass 138-159
```

Status:

- Bundled, not pushed.
- Approximately 17 files changed.
- Current diff stat at handoff time: more than 1,200 insertions and about 112 deletions.
- Focused QA passed for the changed areas.
- A timed full `tool/pdf_quality_gate.sh` later passed in 89 seconds before the later Pass 139-159 additions.
- The later Pass 139-159 additions were verified with targeted analyze and focused regression tests, not another full gate.

## Pass 138 Work Completed Locally

### 1. PDF Scope Correction

Updated:

- `docs/document_engine_operating_directive.md`
- `test/document_engine_operating_directive_test.dart`

Purpose:

- Tightened the Document Engine scope to Maintainiac's actual needs.
- Clarified that the PDF system is for receipts, invoices, estimates, and exports/reports from app-owned records.
- Clarified that this is not a generic office PDF suite.
- Preserved read-only behavior, confirmed-data-only behavior, privacy boundaries, and no parser/OCR/camera/inventory mutation.

### 2. Export/Report QA Registry

Updated:

- `test/fixtures/pdf_qa/fixture_pack_inventory.json`
- `test/pdf_qa_fixture_inventory_test.dart`
- `test/pdf_quality_gate_contract_test.dart`
- `tool/pdf_quality_gate.sh`

Purpose:

- Added export/report generation to the PDF QA registry.
- Added registry keys for export report scope, app-scope-only reports, no UI-owned PDF pagination, atomic export writes, partial file absence, symlinked export directory handling, and filtered export PDF behavior.
- Added more PDF quality gate coverage for expense export and receipt assistance-related tests.

### 3. Expense Export File Writer Hardening

Updated:

- `lib/screens/expenses/data/expense_export_file_writer.dart`
- `test/expense_export_test.dart`

Implemented:

- Atomic CSV/manifest writes through `.partial` files.
- Cleanup on write failure.
- Unique export directories so existing exports are not overwritten.
- Symlink-aware directory collision handling using `followLinks: false`.
- Regression tests for:
  - safe unique directories
  - no leftover partial files after successful export
  - symlinked export directory names are skipped
  - existing export folders are not overwritten

### 4. Generated PDF Validation Hardening

Updated:

- `lib/shared/pdf/app_generated_pdf_models.dart`
- `test/app_generated_pdf_service_test.dart`
- `test/fixtures/pdf_qa/fixture_pack_inventory.json`

Implemented:

- Stricter PDF header validation.
- `%PDF-` alone is no longer accepted as enough.
- Header now requires a numeric version pattern like `%PDF-1.7` or `%PDF-2.0`.
- Regression tests for fake versionless headers and short headers.

### 5. Expense Export Summary PDF Bug Fix

Updated:

- `lib/screens/expenses/data/expense_export_models.dart`
- `lib/screens/expenses/data/expense_export_handoff.dart`
- `test/app_generated_pdf_service_test.dart`
- `test/fixtures/pdf_qa/fixture_pack_inventory.json`

Bug found:

- The expense export summary PDF could include receipt lines that were excluded by the selected category filter.

Fix:

- Added `filteredLinesFor(receipt)` to `ExpenseExportSnapshot`.
- Updated PDF summary generation and deterministic hash input to use filtered lines only.

Regression:

- Business-only export summary PDF now proves personal lines and personal amounts are excluded.

### 6. Invoice/Estimate Landscape Pagination Bug Fix

Updated:

- `lib/screens/invoices/data/invoice_pdf_template_renderer.dart`
- `lib/screens/invoices/data/invoice_pdf_pagination.dart`
- `test/invoice_document_engine_layout_contract_test.dart`
- `test/fixtures/pdf_qa/fixture_pack_inventory.json`

Bug found:

- Landscape artwork templates visibly render 7 line rows per page, but the shared paginator could place more than 7 line items on continuation/final pages.
- That created a risk of dropped or invisible line items in landscape invoice/estimate PDFs.

Fix:

- `invoicePdfPageCountForRecord` now accepts an optional template.
- Landscape artwork templates use fixed 7-line page capacity.
- Rendering uses fixed 7-line pagination for landscape templates.

Regression:

- 17-line landscape invoice now produces 3 landscape pages and proves later line totals are present.

## Pass 139-159 Work Completed Locally

### 1. Expense Export Privacy Guard

Updated:

- `lib/screens/expenses/data/expense_export_models.dart`
- `lib/screens/expenses/data/expense_export_file_writer.dart`
- `lib/screens/expenses/data/expense_export_handoff.dart`
- `test/expense_export_test.dart`

Implemented:

- Expense exports now run a privacy preflight before CSV/manifest files or summary PDFs are written.
- Blocks VINs, license plates, passenger data, patient data, private source paths, payment fragments, and unconfirmed OCR text.
- Regression proves private export data is blocked before any export directory receives files.

### 2. Expense Export ZIP Containment

Updated:

- `lib/screens/expenses/data/expense_export_handoff.dart`
- `test/expense_export_test.dart`

Implemented:

- Export ZIP builder now only accepts regular files.
- Blocks files outside the prepared export folder.
- Blocks duplicate ZIP entry names.
- Blocks symlinked file entries.
- Atomic ZIP write now verifies the partial and final ZIP file before returning.

### 3. Expense Export Internal ID Redaction

Updated:

- `lib/screens/expenses/data/expense_export_models.dart`
- `test/expense_export_test.dart`

Implemented:

- CSV exports no longer expose raw receipt IDs or line IDs.
- Export CSVs now use export-only references such as `receipt_0001` and `receipt_0001_line_0001`.
- Regression proves raw expense receipt and line IDs are not present in exported CSV text.

### 4. Expense Export Base Folder Safety

Updated:

- `lib/screens/expenses/data/expense_export_file_writer.dart`
- `test/expense_export_test.dart`

Implemented:

- Export writer refuses symlinked base export directories.
- Regression proves a symlinked export base does not receive files and does not modify the outside target.

### 5. Invoice/Estimate Internal ID Guard

Updated:

- `lib/screens/invoices/data/invoice_pdf_export_verifier.dart`
- `test/invoice_pdf_export_verifier_contract_test.dart`

Implemented:

- Invoice PDF export verification now checks internal-looking line item IDs and payment IDs, not just the invoice record ID.
- Regression blocks internal line/payment IDs if they appear in generated PDF text.
- Regression also proves normal visible line labels such as service/material line text are not falsely blocked.

### 6. QA Registry Updates

Updated:

- `test/fixtures/pdf_qa/fixture_pack_inventory.json`

Implemented:

- Added registry keys for expense export privacy blocking, public export references, ZIP containment, ZIP write verification, symlinked base folder blocking, invoice line/payment ID blocking, and the invoice internal-ID false-positive regression.

## Focused Verification Already Passed

These focused checks passed after the local Pass 138 changes:

```bash
dart analyze lib/screens/expenses/data/expense_export_file_writer.dart test/expense_export_test.dart
flutter test test/expense_export_test.dart -r compact
```

```bash
dart analyze lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart
flutter test test/app_generated_pdf_service_test.dart -r compact
```

```bash
dart analyze lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/data/expense_export_handoff.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart
flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact
```

```bash
dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart
flutter test test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact
```

```bash
dart analyze docs/document_engine_operating_directive.md lib/screens/expenses/data/expense_export_file_writer.dart lib/screens/expenses/data/expense_export_handoff.dart lib/screens/expenses/data/expense_export_models.dart lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart test/document_engine_operating_directive_test.dart test/expense_export_test.dart test/pdf_qa_fixture_inventory_test.dart test/pdf_quality_gate_contract_test.dart
bash -n tool/pdf_quality_gate.sh
flutter test test/app_generated_pdf_service_test.dart test/document_engine_operating_directive_test.dart test/expense_export_test.dart test/pdf_qa_fixture_inventory_test.dart test/pdf_quality_gate_contract_test.dart -r compact
```

Additional checks passed:

```bash
python3 -m json.tool test/fixtures/pdf_qa/fixture_pack_inventory.json >/tmp/fixture_pack_inventory.check.json
git diff --check
```

Timed full gate result before Pass 139-159:

```bash
SECONDS=0; bash tool/pdf_quality_gate.sh; gate_status=$?; printf '\nPDF_FULL_GATE_SECONDS=%s\n' "$SECONDS"; exit $gate_status
```

Result:

```text
All tests passed.
PDF_FULL_GATE_SECONDS=89
```

Focused checks passed after Pass 139-194:

```bash
dart analyze lib/screens/expenses/data/expense_export_file_writer.dart lib/screens/expenses/data/expense_export_handoff.dart lib/screens/expenses/data/expense_export_models.dart lib/screens/invoices/data/invoice_pdf_export_verifier.dart test/expense_export_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_qa_fixture_inventory_test.dart
flutter test test/expense_export_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact
```

```bash
flutter test test/app_generated_pdf_service_test.dart test/document_engine_operating_directive_test.dart test/expense_export_test.dart test/invoice_document_engine_layout_contract_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_qa_fixture_inventory_test.dart test/pdf_quality_gate_contract_test.dart -r compact
```

```bash
dart analyze lib/shared/pdf/app_generated_pdf_models.dart lib/screens/expenses/data/expense_export_file_writer.dart lib/screens/expenses/data/expense_export_handoff.dart lib/screens/expenses/data/expense_export_models.dart lib/screens/invoices/data/invoice_pdf_export_verifier.dart test/app_generated_pdf_service_test.dart test/expense_export_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_qa_fixture_inventory_test.dart
flutter test test/app_generated_pdf_service_test.dart test/expense_export_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact
```

```bash
dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart
flutter test test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact
```

```bash
dart analyze lib/screens/expenses/data/expense_export_models.dart lib/screens/expenses/data/expense_export_handoff.dart test/expense_export_test.dart test/pdf_qa_fixture_inventory_test.dart
flutter test test/expense_export_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact
```

Important failure/fix:

- The first changed-test bundle failed because the new invoice internal-ID guard was too broad and treated normal fixture IDs such as `service-line-1` as leaked internal IDs.
- Work stopped immediately.
- The verifier was narrowed to IDs that actually look internal, such as IDs containing `internal`, `firebase`, `firestore`, `hive`, `record`, `uuid`, UUIDs, or long hex IDs.
- A regression was added so normal visible line labels do not trip the guard.
- The changed-test bundle was rerun and passed.
- A later layout QA run failed because `pdf` package `TextOverflow` does not support `ellipsis`.
- Work stopped immediately, the invoice renderer was switched to supported `TextOverflow.span`, and a no-hard-clip regression was added.
- A later expense export QA run failed because the new PDF-summary assertion needed the Flutter test binding.
- Work stopped immediately, `TestWidgetsFlutterBinding.ensureInitialized()` was added to the expense export suite, and the focused QA reran green.

## Current Modified Files

At handoff time, Pass 138-194 modifies:

```text
docs/document_engine_operating_directive.md
lib/screens/expenses/data/expense_export_file_writer.dart
lib/screens/expenses/data/expense_export_handoff.dart
lib/screens/expenses/data/expense_export_models.dart
lib/screens/invoices/data/invoice_pdf_export_verifier.dart
lib/screens/invoices/data/invoice_pdf_pagination.dart
lib/screens/invoices/data/invoice_pdf_template_renderer.dart
lib/shared/pdf/app_generated_pdf_models.dart
test/app_generated_pdf_service_test.dart
test/document_engine_operating_directive_test.dart
test/expense_export_test.dart
test/fixtures/pdf_qa/fixture_pack_inventory.json
test/invoice_document_engine_layout_contract_test.dart
test/invoice_pdf_export_verifier_contract_test.dart
test/pdf_qa_fixture_inventory_test.dart
test/pdf_quality_gate_contract_test.dart
tool/pdf_quality_gate.sh
```

## Recommended Next Steps

1. If this bundle is being treated as a milestone, run the full PDF gate again:

```bash
bash tool/pdf_quality_gate.sh
```

2. If it fails, stop and fix the failure properly. Add or update a regression test if the failure exposes a real bug.

3. If it passes, this Pass 138-194 bundle is a meaningful checkpoint. Commit it with a human-readable message similar to:

```text
2026-07-05 HH:MM - Pass 138-194 - Harden PDF exports, validation, invoice pagination, and export privacy

Pass 138-194 hardens Maintainiac PDF scope and QA registry, atomic expense export writes,
generated PDF validation, filtered export summary PDFs, landscape invoice pagination,
expense export privacy, ZIP containment, export ID redaction, invoice export ID guards,
OCR export metadata privacy coverage, no-hard-clip invoice layout behavior, and deterministic
penny allocation for expense exports.
Focused QA passed. Full PDF gate should be rerun if this is the milestone push.
```

4. Push only the PDF branch:

```bash
git push origin HEAD:codex/pdf-system
```

Do not push unrelated branches.

## Do Not Rebuild Existing Work

Do not restart the PDF system from scratch. Continue forward from the existing implementation and harden the gaps that remain.

Before adding new work, inspect what already exists in:

```text
lib/shared/pdf
lib/shared/documents
lib/shared/widgets/receipt_capture/receipt_pdf*
lib/screens/invoices/data/*pdf*
lib/screens/expenses/data/expense_export*
test/*pdf*
test/*document_engine*
test/fixtures/pdf_qa/fixture_pack_inventory.json
tool/pdf_quality_gate.sh
```

## Remaining High-Level Work

The system is not 100% complete. Remaining work should continue in large bundled passes:

- More real render-level PDF checks for invoice/estimate/export PDFs.
- More PDF import torture fixtures.
- More receipt PDF handoff failure recovery checks.
- More export package failure-injection checks.
- Stronger performance logging for huge PDFs and weak devices.
- More compatibility checks for Android print/share, iOS share/Files, Acrobat, Drive, Preview, Chrome, and platform print previews.
- More privacy leak tests for support diagnostics, Command 1, filenames, logs, QA reports, and share text.
- More regression IDs for every confirmed bug.

Keep using the shared Maintainiac QA backbone wherever possible. Do not create duplicate fake infrastructure.
