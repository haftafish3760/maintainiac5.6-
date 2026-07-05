# PDF System Pass Log

## Pass 111 - 2026-07-05 11:05 EDT - PDF health diagnostics privacy guard

- Scope: PDF health diagnostics and Command 1-safe summary contracts only. No
  inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added PDF health event and snapshot models for generated PDF, import,
    export, archive, share, print, preview, and package extraction diagnostics.
  - Kept Command 1 payloads limited to counts, buckets, safe tokens, issue
    codes, risk codes, page-count buckets, and byte-size buckets.
  - Added regression coverage proving customer names, source paths, raw
    recovery text, and private identifiers stay out of PDF diagnostics.
  - Added the diagnostics suite to the PDF quality gate and fixture registry.
- Verification completed 2026-07-05 11:05 EDT:
  - `dart format lib/shared/pdf/app_pdf_health_diagnostics.dart test/pdf_health_diagnostics_test.dart`
  - `flutter test test/pdf_health_diagnostics_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_health_diagnostics.dart test/pdf_health_diagnostics_test.dart`

## Pass 110 - 2026-07-05 10:54 EDT - Shared receipt source guard

- Scope: generated receipt PDF source-module contract only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Documented that supplier/vendor invoices used for inventory proof stay in
    the shared receipt flow.
  - Added regression coverage for vendor-invoice receipt source modules.
  - Added the vendor-invoice receipt source case to the PDF QA fixture
    registry.
- Verification completed 2026-07-05 10:54 EDT:
  - `dart format test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze test/app_receipt_pdf_document_test.dart`

## Pass 109 - 2026-07-05 10:49 EDT - Document package extraction cleanup hardening

- Scope: document export package extraction cleanup safety only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Inspected extraction cleanup targets without following symlinks.
  - Removed stale extraction symlink entries without deleting their external
    targets.
  - Hardened extraction file collision checks so partial symlinks cannot be
    followed during writes.
  - Preserved existing rollback behavior when a real directory blocks package
    creation.
  - Added regression coverage proving extraction cleanup preserves an outside
    symlink target.
  - Added the extraction symlink cleanup case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:49 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`

## Pass 108 - 2026-07-05 11:18 EDT - Receipt line quantity preflight hardening

- Scope: generated receipt PDF confirmed-line validation only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added receipt PDF preflight validation for non-finite confirmed line
    quantities.
  - Converted what would have been a low-level formatter/layout failure into a
    user-facing receipt PDF block.
  - Added regression coverage for invalid confirmed receipt quantities.
  - Added the non-finite quantity case to the PDF QA fixture registry.
- Verification completed 2026-07-05 11:18 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`

## Pass 107 - 2026-07-05 11:11 EDT - Document package import cleanup hardening

- Scope: document export package import cleanup safety only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Inspected stale document-package import cleanup targets without following
    symlinks.
  - Removed app-owned symlink cleanup entries without deleting their external
    targets.
  - Reused the same safe delete path for normal extraction cleanup and rollback
    cleanup.
  - Added regression coverage proving package-import cleanup preserves a
    symlink target outside app document storage.
  - Added the package-import symlink cleanup case to the PDF QA fixture
    registry.
- Verification completed 2026-07-05 11:11 EDT:
  - `dart format lib/shared/documents/app_document_import_service.dart test/app_document_store_test.dart`
  - `flutter test test/app_document_store_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_import_service.dart test/app_document_store_test.dart`

## Pass 106 - 2026-07-05 11:03 EDT - Document proof cleanup symlink hardening

- Scope: shared document proof cleanup safety only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Normalized document cleanup paths through absolute paths before app-owned
    storage checks.
  - Switched attachment deletion to inspect filesystem entities without
    following symlinks.
  - Deleted app-owned symlink entries without deleting their external targets.
  - Added regression coverage proving document deletion preserves a symlink
    target outside app document storage.
  - Added the symlink-cleanup case to the PDF QA fixture registry.
- Verification completed 2026-07-05 11:03 EDT:
  - `dart format lib/shared/documents/app_document_store.dart test/app_document_store_test.dart`
  - `flutter test test/app_document_store_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_store.dart test/app_document_store_test.dart`

## Pass 105 - 2026-07-05 10:56 EDT - Generated PDF archive directory hardening

- Scope: generated PDF permanent document archive storage safety only. No
  inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Verified permanent generated-PDF archive folders are real directories
    without following symlinks after creation.
  - Blocked symlinked archive folders before permanent PDF bytes are written.
  - Added regression coverage proving a symlinked archive folder cannot redirect
    generated invoice PDFs outside app-owned document storage.
  - Added the symlinked-archive-directory case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:56 EDT:
  - `dart format lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_archive_recovery_test.dart`
  - `flutter test test/app_generated_pdf_archive_recovery_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_archive_recovery_test.dart`

## Pass 104 - 2026-07-05 10:48 EDT - Generated PDF storage directory hardening

- Scope: generated PDF temporary storage safety only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Verified the generated-PDF storage path is a real directory without
    following symlinks after creation.
  - Blocked symlinked generated-PDF temp directories before any PDF bytes are
    written.
  - Added regression coverage proving a symlinked temp directory cannot redirect
    generated PDFs outside app-owned temp storage.
  - Added the symlinked-temp-directory case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:48 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart`

## Pass 103 - 2026-07-05 10:40 EDT - Receipt proof image validation hardening

- Scope: generated receipt PDF proof-image validation only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Validated receipt proof images by decoding PNG/JPEG payloads instead of
    trusting file headers alone.
  - Blocked corrupt image payloads before PDF rendering.
  - Added render-safety limits for extreme image dimensions and pixel counts.
  - Preserved existing byte-count and batch-size failures as first-pass
    preflight checks.
  - Added regression coverage for corrupt proof payloads and unsafe dimensions.
  - Added the new proof-image failure cases to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:40 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`

## Milestone - 2026-07-05 10:32 EDT - Passes 101-102 package filename hardening

- Scope: shared document export package filename safety only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Stripped dangerous executable-style trailing extensions from proof filenames
    written into document export ZIP packages.
  - Blocked imported package entries with dangerous executable-style trailing
    extensions before package read/extraction.
  - Kept legitimate PDF and image proof extensions while removing disguised
    suffixes such as `.exe` and `.scr`.
  - Added export and import regression coverage plus PDF QA fixture registry
    entries for both cases.
- Verification completed 2026-07-05 10:32 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 102 - 2026-07-05 10:31 EDT - Export package import filename hardening

- Scope: shared document export package import/read entry names only. No
  inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Blocked imported document export ZIP entries with dangerous executable-style
    trailing extensions.
  - Applied the same dangerous-extension deny list during package read and
    extraction entry verification.
  - Added regression coverage proving a disguised PDF package entry is refused
    before import/extraction.
  - Added the hostile import-entry filename case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:31 EDT:
  - `dart format lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`

## Pass 101 - 2026-07-05 10:24 EDT - Export package proof filename hardening

- Scope: shared document export package proof entry names only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Stripped dangerous executable-style trailing extensions from proof filenames
    written into document export ZIP packages.
  - Preserved legitimate `.pdf` and image proof extensions after stripping
    disguised suffixes such as `.exe` and `.scr`.
  - Added regression coverage proving hostile proof display names are exported
    as safe package entries.
  - Added the proof-entry filename case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:24 EDT:
  - `dart format lib/shared/documents/app_document_export_manifest.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze test/pdf_qa_fixture_inventory_test.dart`

## Milestone - 2026-07-05 10:22 EDT - Passes 99-100 filename privacy hardening

- Scope: shared generated-PDF filename and metadata privacy only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Stripped dangerous executable-style trailing extensions from generated PDF
    filenames.
  - Added generated-PDF filename privacy preflight coverage.
  - Fixed separator-normalized VIN and license-plate detection for filenames
    and metadata.
  - Added new filename security/privacy cases to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:22 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 100 - 2026-07-05 10:20 EDT - Generated PDF filename privacy

- Scope: shared generated-PDF privacy validation only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added regression coverage proving generated PDF filenames are part of the
    privacy preflight.
  - Fixed vehicle privacy detection so underscore/hyphen-separated `vin` and
    `plate` labels are blocked in filenames and metadata.
  - Verified private filenames are refused before temporary generated-PDF
    writes.
  - Added the filename/privacy cases to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:20 EDT:
  - `dart format lib/shared/pdf/app_pdf_privacy_policy.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_privacy_policy_contract_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_privacy_policy.dart test/app_generated_pdf_service_test.dart test/pdf_privacy_policy_contract_test.dart`
  - `flutter test test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze test/pdf_qa_fixture_inventory_test.dart`

## Pass 99 - 2026-07-05 10:18 EDT - Generated PDF filename hardening

- Scope: shared generated-PDF filename safety only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Stripped dangerous executable-style trailing extensions before generated
    PDF filenames are finalized.
  - Prevented disguised names such as `.pdf.exe`, `.scr`, and `.ps1` from
    surviving in app-generated PDF names.
  - Added regression coverage in generated-PDF service and cross-platform
    filename tests.
  - Added the hostile trailing-extension case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:18 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart test/pdf_cross_platform_contract_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_cross_platform_contract_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart test/pdf_cross_platform_contract_test.dart`
  - `flutter test test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze test/pdf_qa_fixture_inventory_test.dart`

## Milestone - 2026-07-05 10:15 EDT - Passes 96-98 invoice failure recovery

- Scope: invoice/estimate PDF content failure recovery and date preflight only.
  No inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added safe user-facing PDF preflight failure messages.
  - Recorded explicit preview and archive content-blocked failure reasons.
  - Added final-save and preview regressions for empty draft PDF blocks.
  - Added due-date-before-issue-date PDF preflight.
  - Updated the PDF QA fixture registry for each new failure case.
- Verification completed 2026-07-05 10:15 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 98 - 2026-07-05 10:13 EDT - Invoice date preflight

- Scope: invoice/estimate PDF generation content guard only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Blocked invoice PDFs when the due date is before the issue date.
  - Added a safe user-facing date failure message.
  - Added regression coverage and fixture-registry tracking for impossible
    invoice dates.
- Verification completed 2026-07-05 10:13 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart`
  - `flutter test test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 97 - 2026-07-05 10:12 EDT - Invoice archive preflight recovery

- Scope: invoice/estimate PDF final-save failure handling only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added regression coverage proving final save blocks empty draft PDFs with
    the explicit content-preflight failure path.
  - Verified the final-save failure records `archive_pdf_content_blocked`
    instead of a generic archive failure.
  - Added the final-save preflight failure case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:12 EDT:
  - `dart format test/invoice_pdf_preview_action_tracking_test.dart`
  - `flutter test test/invoice_pdf_preview_action_tracking_test.dart -r compact`
  - `dart analyze test/invoice_pdf_preview_action_tracking_test.dart lib/screens/invoices/home/invoice_form_screen.dart`
  - `flutter test test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze test/pdf_qa_fixture_inventory_test.dart`

## Pass 96 - 2026-07-05 10:11 EDT - Invoice preflight failure recovery

- Scope: invoice/estimate PDF failure handling only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added safe user-facing messages for invoice PDF content preflight blocks.
  - Recorded explicit preview/archive content-blocked PDF failure reason codes.
  - Added regression coverage proving empty drafts are blocked without a
    generic PDF failure.
  - Added the preflight failure case to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:11 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_template_renderer.dart lib/screens/invoices/home/invoice_form_screen.dart test/invoice_pdf_preview_action_tracking_test.dart`
  - `flutter test test/invoice_pdf_preview_action_tracking_test.dart -r compact`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart lib/screens/invoices/home/invoice_form_screen.dart test/invoice_pdf_preview_action_tracking_test.dart`
  - `flutter test test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze test/pdf_qa_fixture_inventory_test.dart`

## Milestone - 2026-07-05 10:09 EDT - Passes 92-95 invoice preflight hardening

- Scope: invoice/estimate PDF generation and preview QA only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added invoice PDF content preflight for missing line items and blank line
    items.
  - Added numeric preflight for non-finite line values, unsafe tax rates,
    unsafe discounts, and non-finite payments.
  - Added identity preflight for missing document number, company, or client.
  - Re-aligned preview action regressions to use PDF-ready confirmed records
    under the stricter preflight rules.
  - Added all new guard cases to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:09 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 95 - 2026-07-05 10:08 EDT - Invoice preview regression alignment

- Scope: invoice/estimate PDF preview tests only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Updated invoice PDF preview action tests to use a PDF-ready confirmed
    record instead of an empty draft.
  - Preserved share, print, retry, cancel, and archive event regression
    coverage under the stricter invoice PDF preflight rules.
- Verification completed 2026-07-05 10:08 EDT:
  - `dart format test/invoice_pdf_preview_action_tracking_test.dart`
  - `flutter test test/invoice_pdf_preview_action_tracking_test.dart -r compact`
  - `dart analyze test/invoice_pdf_preview_action_tracking_test.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart`

## Pass 94 - 2026-07-05 10:04 EDT - Invoice identity preflight

- Scope: invoice/estimate PDF generation content guard only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Blocked invoice/estimate PDF generation when the business document number
    is missing.
  - Blocked invoice/estimate PDF generation when company or client identity is
    missing.
  - Added regression coverage for missing business identity blocks.
  - Added the new identity guard to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:04 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart`
  - `flutter test test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 93 - 2026-07-05 10:02 EDT - Invoice numeric preflight

- Scope: invoice/estimate PDF generation content guard only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Blocked non-finite invoice line quantities, prices, and tax rates before
    PDF rendering.
  - Blocked negative line tax rates, negative discounts, over-100% discounts,
    excessive fixed discounts, and non-finite payments.
  - Added regression coverage for unsafe line-item, discount, and payment
    content.
  - Added the new numeric guards to the PDF QA fixture registry.
- Verification completed 2026-07-05 10:02 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart`
  - `flutter test test/invoice_document_engine_layout_contract_test.dart -r compact`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/pdf_qa_fixture_inventory_test.dart -r compact`

## Pass 92 - 2026-07-05 10:00 EDT - Invoice content preflight

- Scope: invoice/estimate PDF generation content guard only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added invoice PDF content preflight before rendering.
  - Blocked missing line-item documents from exporting as professional PDFs.
  - Blocked blank invoice/estimate line items before PDF generation.
  - Added regression coverage and fixture-registry entries for both blocks.
- Verification completed 2026-07-05 10:00 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart`
  - `flutter test test/invoice_document_engine_layout_contract_test.dart -r compact`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart`

## Milestone - 2026-07-05 09:56 EDT - Passes 89-91 receipt privacy and source modules

- Scope: shared receipt PDF privacy, source metadata, and archive linking only.
  No inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added receipt PDF privacy preflight before PDF generation.
  - Added private line item and proof image label regressions.
  - Added configurable source modules for shared receipt flows.
  - Sanitized receipt source modules and generated PDF archive linked modules.
- Verification completed 2026-07-05 09:56 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 91 - 2026-07-05 09:56 EDT - Receipt source module sanitizing

- Scope: generated PDF receipt metadata and archive linking only. No
  inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Sanitized receipt PDF source module keys while preserving
    `inventory_receipts` style module routing.
  - Sanitized generated PDF archive linked-module values before writing
    permanent document attachments.
  - Added regression coverage for sanitized receipt source modules and archive
    linked modules.
  - Added those source-module cases to the PDF QA fixture registry.
- Verification completed 2026-07-05 09:56 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart lib/shared/documents/app_generated_pdf_archive_service.dart test/app_receipt_pdf_document_test.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart test/app_generated_pdf_service_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart lib/shared/documents/app_generated_pdf_archive_service.dart test/app_receipt_pdf_document_test.dart test/app_generated_pdf_service_test.dart`

## Pass 90 - 2026-07-05 09:55 EDT - Shared receipt source module

- Scope: shared receipt PDF generation metadata only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added configurable receipt PDF source modules so the same receipt document
    path can represent expense receipts, inventory/material receipts, vendor
    invoices, job proof, and future receipt flows.
  - Kept the default source module as `receipts`.
  - Added regression coverage for a generated receipt PDF using an
    `inventory_receipts` source module without touching inventory logic.
  - Added shared-source-module coverage to the PDF QA fixture registry.
- Verification completed 2026-07-05 09:55 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`

## Pass 89 - 2026-07-05 09:55 EDT - Receipt privacy preflight

- Scope: shared receipt PDF generation privacy only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added receipt PDF privacy preflight before PDF bytes are generated.
  - Extended privacy checks to receipt line descriptions, categories, units,
    notes, receipt metadata, source IDs, and proof image labels.
  - Added regression coverage for private line item text and private proof image
    labels.
  - Added the new receipt privacy blocks to the PDF QA fixture registry.
- Verification completed 2026-07-05 09:55 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`

## Milestone - 2026-07-05 09:51 EDT - Passes 86-88 long receipt hardening

- Scope: shared receipt PDF generation and render QA only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added deterministic long-receipt line section planning and sectioned
    rendering.
  - Added receipt totals/proof-image free-space guards.
  - Added proof-image size regression coverage.
  - Added a long receipt generator to deterministic PDF generation and Poppler
    render smoke gates.
  - Fixed the render smoke gate for Poppler padded page image names on 10+
    page PDFs.
- Verification completed 2026-07-05 09:51 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 88 - 2026-07-05 09:51 EDT - Long receipt render gate

- Scope: shared PDF render QA only. No inventory, camera, native capture, OCR
  engine, or parser behavior changes.
- Bundled work:
  - Added a long confirmed receipt PDF generator using the shared receipt
    renderer.
  - Added deterministic long-receipt generation and Poppler render coverage to
    the PDF quality gate.
  - Fixed the render smoke gate to handle Poppler's padded page image names for
    documents with 10 or more pages.
  - Added contract and fixture-registry coverage for the long receipt render
    gate.
- Verification completed 2026-07-05 09:51 EDT:
  - `dart format tool/generate_long_receipt_pdf.dart lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze tool/generate_long_receipt_pdf.dart tool/generate_sample_receipt_pdf.dart lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `dart run tool/generate_long_receipt_pdf.dart /tmp/maintainiac_pass88_long_receipt.pdf`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `flutter test test/app_receipt_pdf_document_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`

## Pass 87 - 2026-07-05 09:49 EDT - Receipt image size regressions

- Scope: shared receipt PDF image validation only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added regression coverage for per-image proof size limits.
  - Added regression coverage for total embedded proof image batch limits.
  - Added those receipt generation guards to the PDF QA fixture registry.
- Verification completed 2026-07-05 09:49 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`

## Pass 86 - 2026-07-05 09:47 EDT - Long receipt pagination

- Scope: shared receipt PDF generation only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added deterministic line-section planning for long receipt PDFs.
  - Added explicit page sections so long receipt line items keep repeated
    context instead of relying on one oversized table.
  - Added free-space guards before totals and proof image sections.
  - Added regression coverage for 160-line receipt pagination and section
    planning.
- Verification completed 2026-07-05 09:48 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`

## Milestone - 2026-07-05 09:41 EDT - Passes 84-85 receipt image embedding and render proof

- Scope: shared receipt PDF generation and render QA only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added receipt proof image embedding for portrait and landscape receipt
    images with deterministic hashing and size/type guards.
  - Added the image-backed receipt sample to the render smoke gate fixture.
  - Added receipt-image regression coverage to the PDF QA registry.
- Verification completed 2026-07-05 09:41 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 85 - 2026-07-05 09:40 EDT - Receipt proof render fixture

- Scope: shared PDF render QA fixture only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Updated the sample receipt PDF generator to include synthetic portrait and
    landscape proof images.
  - Added the embedded-image receipt sample to the PDF QA fixture registry.
  - Verified Poppler rendering for the generated multi-page receipt PDF.
- Verification completed 2026-07-05 09:40 EDT:
  - `dart format tool/generate_sample_receipt_pdf.dart lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `dart analyze tool/generate_sample_receipt_pdf.dart lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `dart run tool/generate_sample_receipt_pdf.dart /tmp/maintainiac_pass85_receipt.pdf`
  - `bash tool/pdf_render_smoke_gate.sh`

## Pass 84 - 2026-07-05 09:38 EDT - Receipt proof image embedding

- Scope: shared receipt PDF generation only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added receipt proof image embedding for portrait and landscape receipt
    images with contain scaling.
  - Added image count, empty image, unsupported image, per-image size, and
    total image size guards.
  - Added deterministic proof-image hashing and PDF QA registry coverage.
- Verification completed 2026-07-05 09:39 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart`

## Milestone - 2026-07-05 09:34 EDT - Passes 82-83 receipt PDF validation and archive proof

- Scope: shared receipt PDF validation and generated receipt PDF archive mapping
  only. No inventory, camera, native capture, OCR engine, or parser behavior
  changes.
- Bundled work:
  - Blocked receipt PDF generation for empty confirmed lines and mismatched
    totals.
  - Added generated receipt PDF archive proof coverage for document storage,
    links, safe filename, and hash.
- Verification completed 2026-07-05 09:34 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 83 - 2026-07-05 09:32 EDT - Receipt PDF archive mapping

- Scope: generated receipt PDF archive behavior only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added regression coverage proving generated receipt PDFs archive as app
    document proof without invoice-ledger storage.
  - Verified receipt archive IDs, linked receipt metadata, safe file naming,
    permanent storage path, and SHA-256 proof hash.
  - Added receipt archive mapping coverage to the PDF QA registry.
- Verification completed 2026-07-05 09:33 EDT:
  - `dart format test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 82 - 2026-07-05 09:31 EDT - Receipt PDF confirmed-total guards

- Scope: shared receipt PDF generation validation only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Blocked receipt PDF generation when confirmed line items are empty.
  - Blocked receipt PDF generation when confirmed totals do not match receipt
    totals.
  - Added regression coverage and fixture registry entries for these guards.
- Verification completed 2026-07-05 09:32 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_receipt_pdf_document.dart test/app_receipt_pdf_document_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Milestone - 2026-07-05 09:29 EDT - Pass 81 confirmed receipt PDFs

- Scope: shared receipt PDF generation only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added reusable confirmed receipt PDF generation with deterministic output,
    user-confirmation guardrails, privacy validation, and portrait/landscape
    support.
  - Added receipt PDF generation to the shared PDF quality gate and fixture
    registry.
  - Moved the sample receipt render smoke fixture onto the shared receipt
    renderer.
- Verification completed 2026-07-05 09:29 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 81 - 2026-07-05 09:24 EDT - Confirmed receipt PDF generation

- Scope: shared confirmed receipt PDF generation only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added a reusable receipt PDF renderer for confirmed receipt data.
  - Added receipt PDF validation for user confirmation, privacy blocks,
    deterministic output, and portrait/landscape page formats.
  - Added a generated PDF receipt kind and archive mapping.
  - Moved the sample receipt PDF tool onto the shared receipt renderer instead
    of one-off PDF drawing.
  - Wired receipt generation into the PDF quality gate and fixture registry.
- Verification completed 2026-07-05 09:28 EDT:
  - `dart format lib/shared/pdf/app_receipt_pdf_document.dart tool/generate_sample_receipt_pdf.dart test/app_receipt_pdf_document_test.dart`
  - `flutter test test/app_receipt_pdf_document_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart lib/shared/documents/app_generated_pdf_archive_service.dart lib/shared/pdf/app_receipt_pdf_document.dart tool/generate_sample_receipt_pdf.dart test/app_receipt_pdf_document_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `dart run tool/generate_sample_receipt_pdf.dart /tmp/maintainiac_pass81_receipt.pdf`

## Milestone - 2026-07-05 09:21 EDT - Passes 78-80 render and share hardening

- Scope: PDF/Document Engine QA and generated PDF share/storage only. No
  inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added landscape PDF render smoke coverage with actual rendered PNG
    orientation assertions.
  - Hardened generated PDF sharing against outside-storage and symlinked paths.
  - Hardened generated PDF destination allocation against symlink reservations.
- Verification completed 2026-07-05 09:21 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 80 - 2026-07-05 09:19 EDT - Generated PDF symlink reservation

- Scope: generated PDF storage allocation only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Treated files, directories, and symlinks as reserved generated PDF names
    without following links.
  - Blocked broken destination and partial symlinks from being reused as write
    targets.
  - Added regression coverage for symlink reservation.
  - Added symlink reservation coverage to the PDF QA registry.
- Verification completed 2026-07-05 09:20 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_storage.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_storage.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 79 - 2026-07-05 09:18 EDT - Generated PDF share path ownership

- Scope: generated PDF share preflight only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Blocked sharing prepared PDFs from outside app-generated temporary storage.
  - Blocked symlinked generated PDF share paths before byte and hash checks.
  - Added regression coverage for outside-path and symlink share attempts.
  - Added share path ownership cases to the PDF QA registry.
- Verification completed 2026-07-05 09:19 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 78 - 2026-07-05 09:16 EDT - Landscape render smoke gate

- Scope: PDF render QA tooling only. No inventory, camera, native capture, OCR
  engine, or parser behavior changes.
- Bundled work:
  - Added a landscape invoice render fixture to the Poppler smoke gate.
  - Added rendered PNG orientation assertions so portrait and landscape pages
    cannot silently swap.
  - Extended the PDF quality-gate contract to lock landscape render coverage.
  - Added landscape render coverage to the PDF QA registry.
- Verification completed 2026-07-05 09:17 EDT:
  - `dart format test/pdf_render_gate_invoice_generator_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash -n tool/pdf_render_smoke_gate.sh`
  - `python3 -m py_compile tool/pdf_render_pixel_assertions.py`
  - `flutter test test/pdf_render_gate_invoice_generator_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `bash tool/pdf_render_smoke_gate.sh`

## Milestone - 2026-07-05 09:15 EDT - Passes 71-77 storage and orientation hardening

- Scope: PDF/Document Engine only. No inventory, camera, native capture, OCR
  engine, or parser behavior changes.
- Bundled work:
  - Hardened generated PDF temp cleanup, stale partial recovery, partial share
    blocking, encrypted output blocking, and source metadata privacy.
  - Added shared PDF page sizing for portrait and landscape output.
  - Fixed landscape invoice PDF output to use true horizontal pages.
  - Blocked private archive labels before permanent generated PDF writes.
- Verification completed 2026-07-05 09:15 EDT:
  - `bash tool/pdf_quality_gate.sh`

## Pass 77 - 2026-07-05 09:13 EDT - Generated PDF archive label privacy

- Scope: generated PDF archive metadata privacy only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Blocked private data in custom generated PDF archive titles and notes before
    permanent file writes.
  - Added regression coverage proving blocked archive labels leave no record or
    file behind.
  - Added coverage proving source record metadata stays linked internally
    without leaking into human-facing document labels.
  - Added archive label privacy cases to the PDF QA registry.
- Verification completed 2026-07-05 09:14 EDT:
  - `dart format lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_archive_recovery_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_archive_recovery_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_archive_recovery_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 76 - 2026-07-05 09:11 EDT - Document page orientation support

- Scope: shared Document Engine page sizing and invoice PDF orientation only.
  No inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added a shared PDF page spec for letter, legal, A4, portrait, and
    landscape output.
  - Moved invoice page sizing through the shared page spec instead of hardcoded
    letter pages.
  - Fixed the landscape invoice template so it emits true horizontal PDF pages.
  - Added regression coverage that reads PDF MediaBox values for vertical and
    horizontal documents.
  - Added portrait/landscape page format coverage to the PDF QA registry.
- Verification completed 2026-07-05 09:12 EDT:
  - `dart format lib/shared/pdf/app_pdf_page_spec.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_page_spec.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 75 - 2026-07-05 09:08 EDT - Generated PDF source metadata privacy

- Scope: generated PDF validation privacy and PDF QA fixture inventory only.
  No inventory, camera, native capture, receipt parser, or OCR engine behavior
  changes.
- Bundled work:
  - Included generated PDF source module and source record ID in validation
    privacy checks.
  - Blocked generated PDFs whose source metadata contains private identifiers
    such as VINs before write, share, print, or archive.
  - Added regression coverage and fixture inventory tracking.
- Verification completed 2026-07-05 09:12 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 74 - 2026-07-05 09:06 EDT - Generated PDF encryption block

- Scope: generated PDF validation and PDF QA fixture inventory only. No
  inventory, camera, native capture, receipt parser, or OCR engine behavior
  changes.
- Bundled work:
  - Blocked generated PDFs that contain an `/Encrypt` marker.
  - Kept encrypted generated output in the unsupported-output failure path
    before write, share, print, or archive.
  - Added regression coverage and fixture inventory tracking.
- Verification completed 2026-07-05 09:06 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 73 - 2026-07-05 09:05 EDT - Generated PDF share partial guard

- Scope: generated temporary PDF share preflight and PDF QA fixture inventory
  only. No inventory, camera, native capture, receipt parser, or OCR engine
  behavior changes.
- Bundled work:
  - Blocked sharing `.partial` generated PDF paths even if their bytes and hash
    match the generated document.
  - Kept the failure user-safe and pathless.
  - Added regression coverage and fixture inventory tracking.
- Verification completed 2026-07-05 09:05 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 72 - 2026-07-05 09:04 EDT - Temporary generated PDF partial recovery

- Scope: generated temporary PDF storage recovery and PDF QA fixture inventory
  only. No inventory, camera, native capture, receipt parser, or OCR engine
  behavior changes.
- Bundled work:
  - Added stale `.pdf.partial` cleanup before temporary generated PDF writes.
  - Cleared stale partials that block the requested generated PDF filename.
  - Preserved fresh partials and wrote to a copy filename instead.
  - Kept cleanup non-recursive so nested support/customer files are not swept.
  - Added regression coverage and fixture inventory tracking.
- Verification completed 2026-07-05 09:04 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 71 - 2026-07-05 09:02 EDT - Generated PDF cleanup scope

- Scope: generated temporary PDF cleanup hardening and PDF QA fixture inventory
  only. No inventory, camera, native capture, receipt parser, or OCR engine
  behavior changes.
- Bundled work:
  - Stopped temporary generated-PDF cleanup from recursing into nested folders.
  - Preserved nested support/customer files even when they look like stale PDF
    or `.pdf.partial` files.
  - Kept direct generated PDF and direct partial cleanup behavior unchanged.
  - Added regression coverage and fixture inventory tracking.
- Verification completed 2026-07-05 09:02 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 70 - 2026-07-05 08:58 EDT - Generated package index total verification

- Scope: generated document export package index verification and PDF QA
  fixture inventory only. No inventory, camera, native capture, receipt parser,
  or OCR engine behavior changes.
- Bundled work:
  - Verified generated package index `totalBytes` against the planned package
    byte total before writing any ZIP package.
  - Blocked package byte builders that return a valid ZIP with correct files
    and hashes but a mismatched index total.
  - Preserved no-output/no-source-mutation behavior when generated package
    index verification fails.
  - Added regression coverage and fixture inventory tracking.
- Verification completed 2026-07-05 08:58 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 69 - 2026-07-05 08:56 EDT - Document package byte-total integrity

- Scope: document export package index integrity and PDF QA fixture inventory
  only. No inventory, camera, native capture, receipt parser, or OCR engine
  behavior changes.
- Bundled work:
  - Verified the package index `totalBytes` value against the canonical
    manifest byte length plus verified proof-entry byte lengths.
  - Blocked hand-edited packages whose file hashes still match but whose index
    byte total no longer matches the package contents.
  - Added regression coverage for byte-total tampering and fixture inventory
    tracking.
- Verification completed 2026-07-05 08:56 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 68 - 2026-07-05 08:54 EDT - Document package ZIP verification safety

- Scope: document export package ZIP-byte verification and PDF QA fixture
  inventory only. No inventory, camera, native capture, receipt parser, or OCR
  engine behavior changes.
- Bundled work:
  - Converted malformed ZIP bytes returned by a package byte builder into a
    typed document package exception.
  - Preserved the no-output/no-source-mutation behavior when generated ZIP
    verification fails before writing.
  - Added regression coverage for malformed generated ZIP bytes and fixture
    inventory tracking.
- Verification completed 2026-07-05 08:54 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 67 - 2026-07-05 08:53 EDT - Document package source-read privacy

- Scope: document export package build failure privacy and PDF QA fixture
  inventory only. No inventory, camera, native capture, receipt parser, or OCR
  engine behavior changes.
- Bundled work:
  - Converted proof-file read failures during ZIP byte construction into a
    typed, pathless document package exception.
  - Added a regression where a proof file disappears after package planning but
    before ZIP construction.
  - Verified the failure message does not leak the local temp/source path.
  - Added fixture inventory tracking for source-read failure privacy.
- Verification completed 2026-07-05 08:53 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 66 - 2026-07-05 08:51 EDT - Document package share preflight

- Scope: document export package share preflight and PDF QA fixture inventory
  only. No inventory, camera, native capture, receipt parser, or OCR engine
  behavior changes.
- Bundled work:
  - Routed package share planning through the same import preview preflight used
    by package import and extraction.
  - Blocked malicious packages with rewritten hashes and private PDF proof text
    before the app builds a share plan.
  - Blocked malicious packages with active PDF proof content before platform
    share can be invoked.
  - Added regressions for private-proof and active-proof package share
    preflight, plus fixture inventory tracking.
- Verification completed 2026-07-05 08:51 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 65 - 2026-07-05 08:50 EDT - Document package extraction preflight

- Scope: direct document export package extraction hardening and PDF QA
  fixture inventory only. No inventory, camera, native capture, receipt parser,
  or OCR engine behavior changes.
- Bundled work:
  - Routed direct package extraction through the same import preview preflight
    used by package save.
  - Blocked malicious packages with rewritten hashes and private PDF proof text
    before extraction creates any import directory.
  - Blocked malicious packages with active PDF proof content before extraction
    writes files.
  - Preserved source packages and avoided extraction-folder creation on blocked
    preflight.
  - Added regressions for private-proof and active-proof extraction preflight,
    plus fixture inventory tracking.
- Verification completed 2026-07-05 08:50 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`

## Pass 64 - 2026-07-05 08:47 EDT - Document package import proof preflight

- Scope: shared app document export package import preflight, hostile package
  defense, and PDF QA fixture inventory only. No inventory, camera, native
  capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Rechecked imported package proof bytes during import preview, not only
    package hashes and manifest metadata.
  - Blocked imported PDF proof files that contain active PDF content before any
    save or extraction path can trust them.
  - Blocked imported PDF proof files that contain private PDF text such as VINs
    or passenger data, even when the malicious package manifest was rewritten
    to match the file hash.
  - Blocked unsupported proof kinds and MIME pairings so package import cannot
    downgrade unknown text attachments into photos through enum fallbacks.
  - Added regressions for private PDF proof import, active PDF proof import,
    unsupported proof kind import, and fixture inventory tracking.
- Verification completed 2026-07-05 08:47 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 63 - 2026-07-05 08:43 EDT - Shared receipt PDF orientation hardening

- Scope: shared PDF receipt proof inspection, Document Engine directive
  guardrails, privacy/support documentation, and PDF QA fixture inventory only.
  No inventory, camera, native capture, receipt parser, or OCR engine behavior
  changes.
- Bundled work:
  - Documented the shared receipt proof flow for expenses,
    inventory/material receipts, vendor invoices, job proof, maintenance proof,
    and future modules.
  - Preserved the rule that PDF receipt handling prepares, validates, stores,
    previews, and hands off proof without mutating parser, OCR, inventory, or
    expense classification behavior.
  - Added the support/debugging privacy boundary: humans see non-identifying
    operational evidence by default; Codex support access is limited to
    opted-in app repair work with synthetic or redacted regressions.
  - Added portrait and landscape document signals for PDF proof inspection.
  - Hardened orientation detection to use true page-box dimensions from
    MediaBox and CropBox values, including non-zero and reversed coordinates.
  - Added regressions for portrait, landscape, mixed orientation, offset page
    boxes, reversed boxes, crop boxes, and fixture inventory tracking.
- Verification completed 2026-07-05 08:43 EDT:
  - `dart format lib/shared/documents/app_document_import_service.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/app_document_store_test.dart test/document_engine_operating_directive_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/receipt_pdf_torture_test.dart`
  - `flutter test test/app_document_store_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/receipt_pdf_torture_test.dart test/document_engine_operating_directive_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_import_service.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/app_document_store_test.dart test/document_engine_operating_directive_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/receipt_pdf_torture_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 61 - 2026-07-05 06:37 EDT - Document package import stale cleanup

- Scope: shared app document package import cleanup, crash-recovery storage
  hygiene, and PDF QA fixture inventory only. No inventory, camera, native
  capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added stale document-package import cleanup for app-owned extraction
    folders left behind by interrupted imports.
  - Covered both complete extraction folders and `.partial` extraction folders
    while preserving foreign/customer folders.
  - Ran stale cleanup before package extraction so retries start from a clean
    import workspace without deleting the source ZIP package.
  - Kept cleanup fenced to deterministic
    `maintainiac-document-export-<hash>` directory names.
  - Added regressions for stale partial cleanup, stale complete cleanup,
    foreign folder preservation, pre-extraction cleanup, extracted-file
    cleanup, saved proof preservation, and source package preservation.
  - Updated the shared PDF fixture inventory for document package import
    crash-recovery cleanup coverage.
- Verification completed 2026-07-05 06:37 EDT:
  - `dart format lib/shared/documents/app_document_import_service.dart test/app_document_store_test.dart`
  - `flutter test test/app_document_store_test.dart -r compact`

## Pass 60 - 2026-07-05 06:33 EDT - Document export package import save

- Scope: shared app document export package import materialization, proof
  promotion rollback, extraction cleanup, and PDF QA fixture inventory only.
  No inventory, camera, native capture, receipt parser, or OCR engine behavior
  changes.
- Bundled work:
  - Added `saveDocumentExportPackage` to import verified Maintainiac document
    export ZIP packages through the existing app document import service.
  - Routed package import through preview validation and verified extraction
    before creating any app document record.
  - Converted verified extracted package entries into read-only proof
    attachments, then reused the existing proof-storage promotion path instead
    of adding a duplicate storage writer.
  - Preserved source ZIP packages while cleaning extracted package files after
    both successful imports and failed record saves.
  - Preserved existing rollback behavior so proof files promoted before a save
    failure are removed from permanent storage and the import can be retried.
  - Added regressions for package import save, linked proof ownership,
    extraction cleanup, failed-save rollback cleanup, source ZIP preservation,
    and stored record visibility.
  - Updated the shared PDF fixture inventory for document export package
    import-save coverage.
- Verification completed 2026-07-05 06:33 EDT:
  - `dart format lib/shared/documents/app_document_import_service.dart test/app_document_store_test.dart`
  - `flutter test test/app_document_store_test.dart test/app_document_export_package_writer_test.dart -r compact`
  - `flutter test test/app_document_store_test.dart test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_import_service.dart lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_store_test.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 59 - 2026-07-05 06:29 EDT - Document export package import preview

- Scope: shared app document export package import-preview validation,
  package metadata ownership checks, and PDF QA fixture inventory only. No
  inventory, camera, native capture, receipt parser, or OCR engine behavior
  changes.
- Bundled work:
  - Added `previewZipPackageImport` to verify a document export ZIP package
    before any caller imports extracted files into app records.
  - Added typed import-preview metadata for package identity, document kind,
    document title, timestamps, and verified proof attachments.
  - Kept preview metadata pathless while preserving package hashes,
    manifest hash, safe entry names, display names, MIME types, byte counts,
    and read-only proof state.
  - Revalidated imported package manifests against the PDF privacy policy so
    hostile or hand-edited packages cannot reintroduce VINs, license plates,
    passenger data, patient data, private paths, or unconfirmed OCR text.
  - Cross-checked manifest attachments against the package index so mismatched
    hashes, byte counts, kinds, display names, or mutable proof flags are
    blocked before import.
  - Added regressions for successful import preview, pathless preview maps,
    private manifest refusal, and manifest/index mismatch blocking.
  - Updated the shared PDF fixture inventory for document export package
    import-preview coverage.
- Verification completed 2026-07-05 06:29 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart -r compact`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 58 - 2026-07-05 06:25 EDT - Document export package extraction

- Scope: shared app document export package extraction, import-side storage
  safety, and PDF QA fixture inventory only. No inventory, camera, native
  capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added verified document export ZIP extraction after package readback
    validation, so malformed, unsafe, oversized, missing-index, or tampered
    packages are refused before import files are written.
  - Extracted manifest, package index, and proof files into deterministic
    app-owned import folders with copy-directory allocation for repeated
    imports.
  - Added atomic per-file `.partial` writes with byte-count and SHA-256
    verification before promotion.
  - Kept extraction result metadata pathless while returning directory name,
    package file name, package hash, manifest hash, document kind, document
    ID, verified entries, and extracted byte count.
  - Preserved source packages and proof files through successful extraction,
    tamper blocking, folder-preparation failures, and copy-directory imports.
  - Tightened package entry-name validation to reject nested path separators
    before readback or extraction accepts a package.
  - Added regressions for verified extraction, pathless extraction metadata,
    tampered-package refusal before writing, source preservation on folder
    failure, copy-directory extraction, and safe extracted hashes.
  - Updated the shared PDF fixture inventory for document export package
    extraction/import coverage.
- Verification completed 2026-07-05 06:25 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart -r compact`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 57 - 2026-07-05 06:20 EDT - Document export package platform share

- Scope: shared app document export package platform-share invocation,
  pre-share verification, and PDF QA fixture inventory only. No inventory,
  camera, native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added `shareZipPackage` to route verified document export ZIP packages to
    `SharePlus` with subject, text, MIME type, file name, and file path.
  - Kept platform sharing behind an injectable share invoker so QA can prove
    pre-share verification without opening fragile UI flows.
  - Ensured `shareZipPackage` rebuilds and verifies the share plan before
    invoking the platform share sheet.
  - Blocked tampered packages before the injected or real share invoker can be
    called.
  - Added regressions for successful verified invocation, MIME/file metadata,
    pathless public share-plan maps, and tampered-package preflight blocking.
  - Updated the shared PDF fixture inventory for platform share invocation and
    preflight blocking.
- Verification completed 2026-07-05 06:20 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 56 - 2026-07-05 06:17 EDT - Document export package share plan

- Scope: shared app document export package share-plan preparation, pre-share
  readback validation, and PDF QA fixture inventory only. No inventory, camera,
  native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added a verified share plan for document export ZIP packages with MIME
    type, subject, message, byte count, package hash, manifest hash, document
    kind, document ID, and verified file entries.
  - Routed share-plan creation through package readback so malformed, unsafe,
    oversized, partial, missing-index, or tampered packages are refused before
    a caller opens the platform share sheet.
  - Kept share-plan public metadata pathless while preserving the internal file
    path only for the eventual platform share call.
  - Normalized app-name text used in the share subject/message to avoid control
    characters and unstable whitespace.
  - Added regressions for verified share metadata, pathless share-plan maps,
    MIME type, subject/message content, and tampered package refusal.
  - Updated the shared PDF fixture inventory for document package share-plan
    coverage.
- Verification completed 2026-07-05 06:17 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 55 - 2026-07-05 06:14 EDT - Document export package zip-bomb guard

- Scope: shared app document export package readback budgets, unsupported ZIP
  entry blocking, and PDF QA fixture inventory only. No inventory, camera,
  native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added readback limits for package entry count, metadata entry size, proof
    entry size, and total uncompressed ZIP size before entry bytes are trusted.
  - Blocked unsupported directory and symbolic-link archive entries during
    package readback so export packages are treated as files-only proof
    bundles.
  - Preserved existing package file-size, malformed ZIP, unsafe entry-name,
    manifest, index, and proof-hash verification after the new budget checks.
  - Added regressions for entry-count overflow, metadata-size overflow,
    proof-size overflow, total-uncompressed-size overflow, and directory-entry
    blocking.
  - Updated the shared PDF fixture inventory for ZIP bomb and unsupported-entry
    coverage.
- Verification completed 2026-07-05 06:14 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 54 - 2026-07-05 06:11 EDT - Document export package partial recovery

- Scope: shared app document export package stale-partial cleanup, fresh-partial
  preservation, and PDF QA fixture inventory only. No inventory, camera, native
  capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added stale app-owned ZIP `.partial` cleanup before document export package
    writes allocate their destination file.
  - Limited cleanup to `maintainiac-*.zip.partial` files older than 12 hours so
    user files, foreign packages, complete ZIP packages, and fresh in-flight
    writes are preserved.
  - Preserved fresh matching partials by writing the new export package to a
    deterministic copy filename instead of deleting possible active work.
  - Kept source proof files untouched through cleanup, rollback, and successful
    package writes.
  - Added regressions for stale partial deletion, foreign partial preservation,
    complete package preservation, fresh partial preservation, and copy-name
    allocation after a fresh partial.
  - Updated the shared PDF fixture inventory for document export package
    stale/fresh partial recovery.
- Verification completed 2026-07-05 06:11 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 53 - 2026-07-05 06:09 EDT - Document export package readback verification

- Scope: shared app document export package readback validation, package index
  metadata, malformed package blocking, and PDF QA fixture inventory only. No
  inventory, camera, native capture, receipt parser, or OCR engine behavior
  changes.
- Bundled work:
  - Added a deterministic package index entry beside the manifest inside
    exported document ZIP packages.
  - Added package readback validation that verifies the ZIP, manifest hash,
    package index, proof entry names, proof byte counts, proof SHA-256 hashes,
    document ID, document kind, and total proof bytes.
  - Blocked malformed ZIP packages, empty packages, `.partial` packages,
    missing package indexes, unsafe entry names, unexpected entries, duplicate
    entries, and tampered proof bytes before accepting package metadata.
  - Kept package readback results pathless while preserving export file name,
    package hash, manifest hash, document kind, document ID, and verified file
    entries.
  - Added regressions for readback success, pathless readback metadata,
    malformed ZIP blocking, unsafe entry blocking, missing index blocking, and
    tampered proof blocking.
  - Updated the shared PDF fixture inventory for package readback and malformed
    package coverage.
- Verification completed 2026-07-05 06:09 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 52 - 2026-07-05 06:03 EDT - Document export zip package writer

- Scope: shared app document export package writing, deterministic ZIP output,
  rollback behavior, and PDF QA gate wiring only. No inventory, camera, native
  capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added `AppDocumentExportPackageWriter` for verified document export ZIP
    creation on top of the shared document export package plan.
  - Added deterministic ZIP bytes with a fixed modified timestamp, stable
    manifest entry name, safe verified proof entry names, and manifest hash
    verification.
  - Added atomic `.partial` package writes with byte-count and SHA-256
    verification before and after promotion.
  - Added rollback behavior so failed package writes remove partial output and
    leave source records/proof files untouched.
  - Kept result metadata pathless while returning file name, package hash,
    manifest hash, file entries, byte count, and storage warning state.
  - Added regressions for deterministic ZIP output, manifest/file-entry
    verification, duplicate entry preservation, tampered ZIP rejection, source
    proof preservation, pathless result metadata, and rollback on rename
    failure.
  - Wired package-writer coverage into the shared PDF quality gate, gate
    contract, and PDF fixture inventory.
- Verification completed 2026-07-05 06:03 EDT:
  - `dart format lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/app_document_export_package_writer_test.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart lib/shared/documents/app_document_export_package_writer.dart test/app_document_export_manifest_test.dart test/app_document_export_package_writer_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 51 - 2026-07-05 05:58 EDT - Document export package entry naming

- Scope: shared app document export package entry naming and PDF QA fixture
  inventory only. No inventory, camera, native capture, receipt parser, or OCR
  engine behavior changes.
- Bundled work:
  - Added deterministic package entry names for verified document export files.
  - Sanitized package entry names against path separators, traversal fragments,
    Windows-style source paths, control characters, and unsafe filename
    characters.
  - Added collision handling so duplicate display names become stable copy
    names instead of overwriting each other in a future package writer.
  - Kept source filesystem paths out of exported file metadata while preserving
    internal read paths for the eventual writer.
  - Added regressions for duplicate PDF names, Windows/macOS path display
    labels, traversal-like photo labels, unique entry names, pathless package
    metadata, and manifest map exposure.
  - Updated the shared PDF fixture inventory for safe package entry naming.
- Verification completed 2026-07-05 05:58 EDT:
  - `dart format lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart`
  - `flutter test test/app_document_export_manifest_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 50 - 2026-07-05 05:55 EDT - Document export storage safety gate

- Scope: shared app document export package storage preflight and PDF QA
  fixture inventory only. No inventory, camera, native capture, receipt parser,
  or OCR engine behavior changes.
- Bundled work:
  - Added export-package storage preflight using the shared app storage guard
    before a document export package plan is returned.
  - Added package scratch-space accounting so export package planning reserves
    room for manifest and temporary package creation instead of checking only
    saved proof bytes.
  - Blocked document export packages when free storage is below the protected
    device reserve.
  - Preserved export package creation with explicit warnings when storage is
    low or free-space verification is unavailable.
  - Kept exported package metadata pathless while carrying storage warning
    state in the package plan.
  - Added regressions for low-storage blocking, low-storage warning, unknown
    storage warning, and verified storage-clear package creation.
  - Updated the shared PDF fixture inventory for document export storage
    blocking and warning cases.
- Verification completed 2026-07-05 05:55 EDT:
  - `dart format lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart`
  - `flutter test test/app_document_export_manifest_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 49 - 2026-07-05 05:52 EDT - Document export PDF content safety gate

- Scope: shared app document export package safety, PDF proof content scanning,
  and PDF QA fixture inventory only. No inventory, camera, native capture,
  receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Routed exported PDF proof files through the shared PDF security policy
    before package creation.
  - Routed exported PDF proof file bytes through the shared PDF privacy policy
    before package creation.
  - Blocked active PDF content and private PDF content in export packages even
    when file size and hash integrity are otherwise valid.
  - Preserved verified photo-proof package support without treating image bytes
    as PDF content.
  - Added regressions for active PDF proof blocking, private PDF proof blocking,
    and verified photo proof inclusion.
  - Updated the shared PDF fixture inventory for document export active/private
    PDF proof blocking.
- Verification completed 2026-07-05 05:52 EDT:
  - `dart format lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart`
  - `flutter test test/app_document_export_manifest_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 48 - 2026-07-05 05:48 EDT - Document export package integrity gate

- Scope: shared app document export package planning, proof-file integrity,
  deterministic manifest JSON, and PDF QA fixture inventory only. No inventory,
  camera, native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added deterministic manifest JSON generation and SHA-256 fingerprints for
    document export package plans.
  - Added verified export package file planning that checks read-only proof
    files before export without modifying source records or proof files.
  - Blocked missing proof files, `.partial` files, unreadable files, byte-size
    mismatches, hash mismatches, mutable proofs, and unsupported attachment
    types before export package creation.
  - Kept exported package metadata pathless by exposing public attachment IDs,
    display names, sizes, hashes, and read-only proof state without source
    filesystem paths.
  - Added regressions for package determinism, manifest hash, total byte count,
    file hash verification, tampered proof blocking, partial-file blocking,
    missing-file blocking, and wrong-size blocking.
  - Updated the shared PDF fixture inventory for document export package
    integrity cases.
- Verification completed 2026-07-05 05:48 EDT:
  - `dart format lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart`
  - `flutter test test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 47 - 2026-07-05 05:44 EDT - Document export manifest privacy gate

- Scope: shared app document export metadata, pathless manifest generation,
  privacy blocking, and PDF QA gate wiring only. No inventory, camera, native
  capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added `AppDocumentExportManager` as a shared export-manager foundation for
    app-wide read-only document records.
  - Added deterministic, pathless document export manifests that expose public
    document and attachment IDs instead of app-internal record IDs or source
    file paths.
  - Reused shared PDF privacy policy checks so document exports block private
    metadata, private attachment labels/signals, unconfirmed OCR suggestions,
    VINs, patient/passenger data, payment fragments, private paths, and
    internal IDs before a manifest is produced.
  - Added regression coverage for deterministic manifests, private metadata
    blocking, attachment-signal blocking, path stripping, public IDs, and typed
    blocked-export failures.
  - Wired document export manifest coverage into the shared PDF quality gate,
    gate contract, and PDF fixture inventory.
- Verification completed 2026-07-05 05:44 EDT:
  - `dart format lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_document_export_manifest.dart test/app_document_export_manifest_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 46 - 2026-07-05 05:39 EDT - Generated PDF archive recovery hardening

- Scope: generated PDF permanent archive storage, recovery cleanup, final
  write verification, and PDF QA gate wiring only. No inventory, camera,
  native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added stale `.pdf.partial` cleanup for generated PDF archive storage with a
    12-hour recovery window.
  - Added final permanent file byte-count and SHA-256 verification after rename,
    so archive writes are verified both before and after promotion.
  - Preserved fresh partial reservations so active or recent writes move the
    requested archive to a copy filename instead of deleting in-flight work.
  - Added archive recovery regressions for stale versus fresh partials, final
    hash and byte integrity, save-failure rollback, replacement cleanup, unsafe
    filename sanitization, and source-contract coverage.
  - Wired archive recovery coverage into the shared PDF quality gate, gate
    contract, and PDF fixture inventory.
- Verification completed 2026-07-05 05:39 EDT:
  - `dart format lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_archive_recovery_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/app_generated_pdf_archive_recovery_test.dart test/app_generated_pdf_service_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_archive_recovery_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 45 - 2026-07-05 05:31 EDT - Invoice PDF export verifier matrix

- Scope: invoice generated-PDF export verification, privacy/security blocking,
  searchable text diagnostics, and PDF QA gate wiring only. No inventory,
  camera, native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added `InvoicePdfExportVerifier` to validate generated invoice/estimate
    PDFs after deterministic rendering and before export.
  - Kept hard blocking focused on unsafe generated PDFs, active content,
    private data, unconfirmed OCR text, source paths, and internal record ID
    leakage.
  - Added QA diagnostics for missing searchable text, document labels, invoice
    numbers, and rendered money totals without falsely blocking otherwise safe
    PDFs when text extraction is imperfect.
  - Exposed invoice record export metadata from the privacy guard so render
    preflight and post-render verification share the same privacy source.
  - Added a verifier regression matrix covering malformed PDFs, incomplete
    PDFs, active JavaScript/open actions, embedded files, URI actions, VINs,
    passenger data, patient data, payment fragments, private source paths,
    unconfirmed OCR suggestions, internal IDs, invoice/estimate labels,
    missing totals, missing numbers, and QA-only nonblocking findings.
  - Wired verifier coverage into the shared PDF quality gate, gate contract,
    and PDF fixture inventory.
- Verification completed 2026-07-05 05:31 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_export_verifier.dart lib/screens/invoices/data/invoice_pdf_privacy_guard.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/invoice_document_engine_layout_contract_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_export_verifier.dart lib/screens/invoices/data/invoice_pdf_privacy_guard.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_document_engine_layout_contract_test.dart test/invoice_pdf_export_verifier_contract_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 44 - 2026-07-04 17:15 EDT - Invoice Document Engine layout QA bundle

- Scope: invoice Document Engine PDF generation, shared PDF text extraction,
  generated PDF privacy preflight, and PDF QA gate wiring only. No inventory,
  camera, native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added invoice PDF privacy preflight so VINs, license plates, passenger
    data, and other blocked private fields are rejected before render/export.
  - Added a reusable invoice Document Engine fixture factory for invoices,
    estimates, missing optional fields, missing logos, huge invoices, long
    text, pagination boundaries, decimal refunds, and overpayments.
  - Added invoice Document Engine layout contract coverage for multi-page
    invoices, estimate templates, template determinism, huge invoices,
    missing optional fields/logos, decimal-safe totals, pagination boundaries,
    and private export blocking.
  - Hardened shared PDF text extraction for ToUnicode CMap glyph streams so
    generated PDF QA can verify searchable money text even when the PDF engine
    embeds font-specific glyph codes.
  - Wired the invoice layout suite and decoder regression into the shared PDF
    quality gate and fixture inventory.
- Verification completed 2026-07-04 17:15 EDT:
  - `dart format lib/shared/pdf/app_pdf_text_decoder.dart test/pdf_text_decoder_contract_test.dart test/invoice_document_engine_layout_contract_test.dart test/helpers/invoice_document_engine_fixture_factory.dart lib/screens/invoices/data/invoice_pdf_privacy_guard.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/pdf_text_decoder_contract_test.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_text_decoder.dart test/pdf_text_decoder_contract_test.dart lib/screens/invoices/data/invoice_pdf_privacy_guard.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/helpers/invoice_document_engine_fixture_factory.dart test/invoice_document_engine_layout_contract_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 43 - 2026-07-04 17:04 EDT - Compressed PDF stream security bundle

- Scope: shared PDF text decoding, generated PDF security/privacy validation,
  receipt PDF risk flagging, and PDF QA fixture inventory only. No inventory,
  camera, native capture, receipt parser, or OCR engine behavior changes.
- Bundled work:
  - Added shared FlateDecode PDF stream extraction with broken-stream safety,
    stream-count caps, and decoded-size caps.
  - Routed generated PDF privacy scans through shared decoded PDF stream text so
    compressed private text cannot bypass export blocking.
  - Routed generated PDF security scans through shared decoded PDF stream text
    so compressed active content cannot bypass export blocking.
  - Expanded active-content detection to cover reset/import form actions, named
    actions, rendition actions, movie actions, and sound actions.
  - Added a reusable PDF security fixture factory for synthetic active,
    escaped-name, compressed-stream, private-text, and broken-stream fixtures.
  - Added generated/receipt cross-surface security fixture matrix coverage.
  - Added generated privacy fixture matrix coverage for raw, hex, compressed,
    and metadata-only private export leaks.
  - Updated the PDF QA fixture inventory for compressed text, compressed active
    content, compressed private text, broken compressed streams, form-data
    actions, named/media actions, and Unicode filename spoofing fixtures.
- Verification completed 2026-07-04 17:04 EDT:
  - `dart format lib/shared/pdf/app_pdf_privacy_policy.dart lib/shared/pdf/app_pdf_security_policy.dart lib/shared/pdf/app_pdf_text_decoder.dart test/helpers/pdf_security_fixture_factory.dart test/pdf_privacy_policy_contract_test.dart test/pdf_security_policy_contract_test.dart test/pdf_text_decoder_contract_test.dart test/receipt_pdf_inspector_security_flags_test.dart`
  - `flutter test test/pdf_text_decoder_contract_test.dart test/pdf_security_policy_contract_test.dart test/pdf_privacy_policy_contract_test.dart test/receipt_pdf_inspector_security_flags_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_privacy_policy.dart lib/shared/pdf/app_pdf_security_policy.dart lib/shared/pdf/app_pdf_text_decoder.dart test/helpers/pdf_security_fixture_factory.dart test/pdf_privacy_policy_contract_test.dart test/pdf_security_policy_contract_test.dart test/pdf_text_decoder_contract_test.dart test/receipt_pdf_inspector_security_flags_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 42 - 2026-07-04 16:54 EDT - PDF filename spoofing guard

- Scope: generated PDF filename safety and cross-platform QA only. No
  inventory, camera, native capture, receipt text engine, or parser behavior
  changes.
- Bundled work:
  - Hardened generated PDF filename cleaning against bidi override, isolate,
    zero-width, and BOM format-control characters that can spoof file names on
    Android, iOS, macOS, Windows, and share targets.
  - Added cross-platform filename regressions for RTL override, isolate, and
    BOM-style hidden characters.
  - Re-ran generated PDF service coverage to prove the safer filename path
    remains compatible with write/share/archive behavior.
- Verification completed 2026-07-04 16:54 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_models.dart test/pdf_cross_platform_contract_test.dart`
  - `flutter test test/pdf_cross_platform_contract_test.dart test/app_generated_pdf_service_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart test/pdf_cross_platform_contract_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 41 - 2026-07-04 16:52 EDT - Render edge clipping guard

- Scope: PDF render QA tooling only. No inventory, camera, native capture,
  receipt text engine, or parser behavior changes.
- Bundled work:
  - Added rendered-page edge-ink assertions to the Poppler PDF render smoke
    gate so edge-clipped or near-bleed broken output cannot pass as merely
    nonblank.
  - Extended render diagnostics to report edge ink ratios with every rendered
    page sample.
  - Added a gate contract regression so the render edge guard cannot be removed
    silently.
- Verification completed 2026-07-04 16:52 EDT:
  - `dart format test/pdf_quality_gate_contract_test.dart`
  - `python3 -m py_compile tool/pdf_render_pixel_assertions.py`
  - `flutter test test/pdf_quality_gate_contract_test.dart -r compact`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `dart analyze test/pdf_quality_gate_contract_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 40 - 2026-07-04 16:49 EDT - Decimal-safe PDF money rounding

- Scope: shared PDF money formatting and generated PDF regressions only. No
  inventory, camera, native capture, receipt text engine, or parser behavior
  changes.
- Bundled work:
  - Replaced binary floating-point cent rounding in shared PDF money formatting
    with deterministic decimal-string cent rounding.
  - Added rounding regressions for half-cent values that commonly fail with raw
    double multiplication.
  - Re-ran generated PDF service regressions because expense export PDFs depend
    on the shared money formatter.
- Verification completed 2026-07-04 16:49 EDT:
  - `dart format lib/shared/pdf/app_pdf_formatters.dart test/pdf_formatters_contract_test.dart`
  - `flutter test test/pdf_formatters_contract_test.dart test/app_generated_pdf_service_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_formatters.dart test/pdf_formatters_contract_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 39 - 2026-07-04 16:47 EDT - Generated PDF storage hygiene

- Scope: generated PDF storage cleanup and preview display formatting only. No
  inventory, camera, native capture, receipt text engine, or parser behavior
  changes.
- Bundled work:
  - Added shared PDF file-size formatting for preview surfaces.
  - Routed generated PDF preview size display through the shared formatter.
  - Hardened generated PDF cleanup so it only removes stale generated PDF and
    partial PDF files, leaving unrelated files in the temp directory alone.
  - Added regressions for readable size formatting, preview size display, and
    non-PDF cleanup safety.
- Verification completed 2026-07-04 16:47 EDT:
  - `dart format lib/shared/pdf/app_pdf_formatters.dart lib/shared/pdf/app_generated_pdf_preview_screen.dart lib/shared/pdf/app_generated_pdf_service.dart test/pdf_formatters_contract_test.dart test/app_generated_pdf_service_test.dart test/app_generated_pdf_preview_screen_test.dart`
  - `flutter test test/pdf_formatters_contract_test.dart test/app_generated_pdf_service_test.dart test/app_generated_pdf_preview_screen_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_formatters.dart lib/shared/pdf/app_generated_pdf_preview_screen.dart lib/shared/pdf/app_generated_pdf_service.dart test/pdf_formatters_contract_test.dart test/app_generated_pdf_service_test.dart test/app_generated_pdf_preview_screen_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 38 - 2026-07-04 16:43 EDT - Expense export PDF shared formatting

- Scope: expense export generated PDF and share formatting only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Routed expense export PDF totals, line totals, share text, and display dates
    through shared PDF formatters.
  - Routed expense export deterministic seed money values through the shared
    money formatter so output stays stable across decimal edge cases.
  - Added regression coverage for small negative decimal totals and source
    guards that keep expense export money formatting centralized.
- Verification completed 2026-07-04 16:43 EDT:
  - `dart format lib/screens/expenses/data/expense_export_handoff.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_formatters_contract_test.dart -r compact`
  - `dart analyze lib/screens/expenses/data/expense_export_handoff.dart test/app_generated_pdf_service_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 37 - 2026-07-04 16:39 EDT - Mobile PDF source-path privacy

- Scope: generated PDF privacy validation and QA only. No inventory, camera,
  native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Hardened private source-path detection for Android shared storage, Android
    app-private storage, and iOS private container paths.
  - Added regression coverage so generated PDF validation blocks those mobile
    paths before write/share/export.
- Verification completed 2026-07-04 16:39 EDT:
  - `dart format lib/shared/pdf/app_pdf_privacy_policy.dart test/pdf_privacy_policy_contract_test.dart`
  - `flutter test test/pdf_privacy_policy_contract_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_privacy_policy.dart test/pdf_privacy_policy_contract_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 36 - 2026-07-04 16:37 EDT - Shared PDF text decoder

- Scope: shared PDF text decoding infrastructure and QA only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added a shared PDF text decoder for Latin and UTF-16 hex-string payloads.
  - Routed generated PDF security scans, generated PDF privacy scans, and
    receipt PDF document-signal detection through the shared decoder.
  - Removed duplicate PDF hex decoding logic from those PDF surfaces.
  - Added decoder contract coverage and included it in the PDF quality gate.
- Verification completed 2026-07-04 16:37 EDT:
  - `dart format lib/shared/pdf/app_pdf_text_decoder.dart lib/shared/pdf/app_pdf_security_policy.dart lib/shared/pdf/app_pdf_privacy_policy.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/pdf_text_decoder_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/pdf_text_decoder_contract_test.dart test/pdf_security_policy_contract_test.dart test/pdf_privacy_policy_contract_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_quality_gate_contract_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_text_decoder.dart lib/shared/pdf/app_pdf_security_policy.dart lib/shared/pdf/app_pdf_privacy_policy.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/pdf_text_decoder_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 35 - 2026-07-04 16:34 EDT - Hex-encoded PDF privacy detection

- Scope: generated PDF privacy validation and QA only. No inventory, camera,
  native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added PDF hex-string decoding to generated PDF privacy scans so private
    export data cannot hide inside text-layer hex payloads.
  - Added UTF-16 BOM-aware decoding for PDF privacy scans.
  - Added regression coverage for hex-encoded VIN/passenger data and binary hex
    payload rejection.
- Verification completed 2026-07-04 16:34 EDT:
  - `dart format lib/shared/pdf/app_pdf_privacy_policy.dart test/pdf_privacy_policy_contract_test.dart`
  - `flutter test test/pdf_privacy_policy_contract_test.dart -r compact`
  - `dart analyze lib/shared/pdf/app_pdf_privacy_policy.dart test/pdf_privacy_policy_contract_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 34 - 2026-07-04 16:29 EDT - Temporary generated PDF write verification

- Scope: generated PDF temporary write integrity and QA only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added SHA-256 verification before temporary generated PDF partial files are
    renamed into share/print/export-ready paths.
  - Extended source-level regression coverage so temporary generated writes
    must verify both byte count and hash before rename.
- Verification completed 2026-07-04 16:29 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart`
  - `dart analyze lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 33 - 2026-07-04 16:27 EDT - PDF signal fixture gap closure

- Scope: receipt PDF inspection signal decoding and PDF QA fixture inventory
  only. No inventory, camera, native capture, receipt text engine, or parser
  behavior changes.
- Bundled work:
  - Added UTF-16 BOM-aware PDF hex-string decoding for receipt document signal
    detection.
  - Added regression coverage for UTF-16 hex text-layer receipt signals and
    binary hex payload rejection.
  - Closed the image-only, text-layer, rotated/cropped, and PDF privacy/security
    fixture inventory items from partial to covered.
  - Added a fixture inventory guard so partial PDF QA suites cannot re-enter the
    shared gate unnoticed.
- Verification completed 2026-07-04 16:27 EDT:
  - `dart format lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_qa_fixture_inventory_test.dart test/receipt_pdf_torture_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 32 - 2026-07-04 16:19 EDT - PDF external action detection

- Scope: shared PDF security policy only. No inventory, camera, native capture,
  receipt text engine, or parser behavior changes.
- Bundled work:
  - Added decoding for simple PDF hex-string payloads before security scans.
  - Hardened external-link detection for hex-encoded URI targets.
  - Hardened external navigation detection for remote go-to actions.
  - Added regression coverage proving generated PDF validation and receipt PDF
    risk flags both surface these external-link risks.
- Verification completed 2026-07-04 16:19 EDT:
  - `dart format lib/shared/pdf/app_pdf_security_policy.dart test/pdf_security_policy_contract_test.dart`
  - `dart analyze lib/shared/pdf/app_pdf_security_policy.dart test/pdf_security_policy_contract_test.dart`
  - `flutter test test/pdf_security_policy_contract_test.dart test/receipt_pdf_inspector_security_flags_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 31 - 2026-07-04 16:17 EDT - Generated PDF brand and privacy hardening

- Scope: generated PDF naming and export privacy only. No inventory, camera,
  native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Corrected generated PDF default filenames and temporary storage directory
    naming to use Maintainiac spelling.
  - Hardened generated PDF privacy detection for unlabeled 17-character VINs.
  - Hardened generated PDF privacy detection for short `Plate:` vehicle labels.
  - Added regression coverage for default generated PDF names, temp storage
    path naming, unlabeled VINs, and short plate labels.
- Verification completed 2026-07-04 16:17 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_models.dart lib/shared/pdf/app_generated_pdf_service.dart lib/shared/pdf/app_pdf_privacy_policy.dart test/app_generated_pdf_service_test.dart test/pdf_cross_platform_contract_test.dart test/pdf_privacy_policy_contract_test.dart`
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart lib/shared/pdf/app_generated_pdf_service.dart lib/shared/pdf/app_pdf_privacy_policy.dart test/app_generated_pdf_service_test.dart test/pdf_cross_platform_contract_test.dart test/pdf_privacy_policy_contract_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_cross_platform_contract_test.dart test/pdf_privacy_policy_contract_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`
- Failure handled:
  - Fixed two patch mistakes in this pass before continuing: a missed test patch
    context and an invalid test constructor.

## Pass 30 - 2026-07-04 16:12 EDT - Shared PDF formatters

- Scope: shared PDF formatting infrastructure and invoice renderer adoption
  only. No inventory, camera, native capture, receipt text engine, or parser
  behavior changes.
- Bundled work:
  - Added shared PDF money, date, and quantity formatters for reusable Document
    Engine output.
  - Routed invoice PDF date, money, and quantity rendering through the shared
    formatters.
  - Added cent-safe formatter contract coverage, including floating-point
    rounding cases and negative values.
  - Added the formatter contract to the shared PDF quality gate.
- Verification completed 2026-07-04 16:12 EDT:
  - `dart format lib/shared/pdf/app_pdf_formatters.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/pdf_formatters_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze lib/shared/pdf/app_pdf_formatters.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/pdf_formatters_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/pdf_formatters_contract_test.dart test/invoice_template_pdf_factory_test.dart test/invoice_pdf_money_precision_test.dart test/pdf_quality_gate_contract_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 29 - 2026-07-04 16:08 EDT - Long-text invoice render smoke gate

- Scope: render-level invoice PDF QA only. No inventory, camera, native
  capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added a long-text invoice render fixture with no-break business strings.
  - Extended the Poppler render smoke gate to render every page of that fixture.
  - Kept pixel-level checks across the normal invoice, long-text invoice,
    receipt sample, and simple invoice sample.
- Verification completed 2026-07-04 16:08 EDT:
  - `bash -n tool/pdf_render_smoke_gate.sh`
  - `dart format test/pdf_render_gate_invoice_generator_test.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze test/pdf_render_gate_invoice_generator_test.dart test/pdf_quality_gate_contract_test.dart`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `flutter test test/pdf_quality_gate_contract_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`
- Failure handled:
  - Accidentally ran `dart format` against a shell script during verification.
    No source was changed by that failed command. Verification was rerun with
    the correct shell syntax gate.

## Pass 28 - 2026-07-04 16:06 EDT - Invoice PDF long-text layout hardening

- Scope: invoice/estimate PDF renderer layout safety only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added explicit one-line clipping to invoice PDF headers, metadata, party
    blocks, table cells, totals, continuation footer, and signature labels.
  - Added bounded terms rendering so unusually long confirmed terms cannot
    consume the final page layout.
  - Added regression coverage for pathological long business text and no-break
    tokens across invoice number, parties, line items, unit labels, and terms.
- Verification completed 2026-07-04 16:06 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_template_pdf_factory_test.dart`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_template_pdf_factory_test.dart`
  - `flutter test test/invoice_template_pdf_factory_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 27 - 2026-07-04 16:02 EDT - Document import failure rollback

- Scope: shared app document PDF import/save lifecycle only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added a shared app document import service for read-only document saves.
  - Routed the document review screen through the shared service instead of
    keeping save/promotion logic in the widget.
  - Added storage rollback for the failure where proof promotion succeeds but
    document record saving fails.
  - Added regression coverage proving the promoted PDF is deleted, the staged
    proof is restored for retry, and the original source PDF remains untouched.
  - Added the new document import service and regression test to the shared PDF
    quality gate.
- Verification completed 2026-07-04 16:02 EDT:
  - `dart format lib/shared/documents/app_document_import_service.dart lib/shared/documents/app_document_review_screen.dart lib/shared/widgets/receipt_capture/receipt_proof_storage.dart test/app_document_store_test.dart`
  - `dart analyze lib/shared/documents/app_document_import_service.dart lib/shared/documents/app_document_review_screen.dart lib/shared/widgets/receipt_capture/receipt_proof_storage.dart test/app_document_store_test.dart`
  - `flutter test test/app_document_store_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 26 - 2026-07-04 15:58 EDT - App document PDF lifecycle cleanup

- Scope: app document/generated PDF storage lifecycle only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - App document deletion now removes app-owned PDF proof files while preserving
    original source files.
  - App document store clearing can optionally remove app-owned attachment files.
  - Re-archiving a generated PDF for the same source record now deletes the
    replaced app-owned generated proof after the new record is saved.
  - Added regressions for app document deletion cleanup and generated archive
    replacement cleanup.
- Verification completed 2026-07-04 15:58 EDT:
  - `dart format lib/shared/documents/app_document_store.dart lib/shared/documents/app_generated_pdf_archive_service.dart test/app_document_store_test.dart test/app_generated_pdf_service_test.dart`
  - `dart analyze lib/shared/documents/app_document_store.dart lib/shared/documents/app_generated_pdf_archive_service.dart test/app_document_store_test.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_document_store_test.dart test/app_generated_pdf_service_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 25 - 2026-07-04 21:41 EDT - Passenger and patient export privacy

- Scope: generated PDF privacy policy and QA only. No inventory, camera,
  native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Hardened PDF export privacy detection for passenger/rider labels with
    colon-separated or plain labeled names, phones, emails, and addresses.
  - Hardened patient data detection for direct patient labels, patient MRN, and
    diagnosis-style labels without requiring overly specific wording.
  - Added regression coverage proving generated PDF validation blocks these
    private labels before write/share/export.
- Verification completed 2026-07-04 21:41 EDT:
  - `dart analyze lib/shared/pdf/app_pdf_privacy_policy.dart test/pdf_privacy_policy_contract_test.dart`
  - `flutter test test/pdf_privacy_policy_contract_test.dart test/app_generated_pdf_service_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 24 - 2026-07-04 21:32 EDT - Hex text-layer receipt signals

- Scope: receipt PDF inspection signal detection and QA only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added simple PDF hex-string decoding to receipt PDF document-signal
    inspection so text-layer receipt hints such as total can be detected when
    the PDF stores text as hex strings.
  - Added regression coverage for hex encoded text-layer receipt signals.
  - Extended the PDF QA fixture inventory for hex text-layer coverage.
- Verification completed 2026-07-04 21:32 EDT:
  - `dart analyze lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/receipt_pdf_inspector_edge_cases_test.dart test/receipt_pdf_torture_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 23 - 2026-07-04 21:21 EDT - Cross-platform PDF filename hardening

- Scope: PDF filename safety and cross-platform QA only. No inventory, camera,
  native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Hardened generated PDF filename cleanup against control characters,
    leading/trailing separators, extensionless reserved Windows device names,
    and dot-only names.
  - Hardened receipt PDF proof storage metadata and stored proof filenames
    against reserved Windows device names.
  - Extended the cross-platform PDF contract and fixture inventory with
    reserved-device-name and control-character filename cases.
- Verification completed 2026-07-04 21:21 EDT:
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart lib/shared/widgets/receipt_capture/receipt_proof_storage_file_names.dart test/pdf_cross_platform_contract_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/pdf_cross_platform_contract_test.dart test/pdf_qa_fixture_inventory_test.dart test/app_generated_pdf_service_test.dart test/receipt_pdf_torture_storage_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 22 - 2026-07-04 21:09 EDT - Shared PDF destination allocator

- Scope: generated PDF file destination allocation and PDF test reliability
  only. No inventory, camera, native capture, receipt text engine, or parser
  behavior changes.
- Bundled work:
  - Added one shared generated-PDF destination allocator for temporary and
    permanent generated PDF writes.
  - Kept `.partial` reservations from being reused, including copy-suffix
    destinations, across both generated PDF storage paths.
  - Fixed a full-gate PDF fixture collision by moving active-content PDF tests
    into isolated temp directories instead of shared system-temp filenames.
  - Added regression coverage for partial-file reservation.
- Verification completed 2026-07-04 21:09 EDT:
  - `dart analyze lib/shared/pdf/app_generated_pdf_storage.dart lib/shared/pdf/app_generated_pdf_service.dart lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart -r compact`
  - `dart analyze test/helpers/receipt_pdf_test_support.dart test/receipt_pdf_inspector_security_flags_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/receipt_pdf_hardening_test.dart`
  - `flutter test test/receipt_pdf_inspector_security_flags_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/receipt_pdf_hardening_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 21 - 2026-07-04 20:49 EDT - PDF brand-copy regression

- Scope: generated PDF user-facing copy and QA only. No inventory, camera,
  native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Corrected misspelled Maintainiac brand copy in generated PDF validation,
    storage, sharing, printing, and preview failure messages.
  - Updated affected preview/action tests to assert the corrected PDF-facing
    messages.
  - Added a PDF quality-gate regression so the misspelled brand string cannot
    return in the generated PDF surfaces.
- Verification completed 2026-07-04 20:49 EDT:
  - `dart analyze lib/shared/pdf/app_generated_pdf_preview_screen.dart lib/shared/documents/app_generated_pdf_archive_service.dart lib/shared/pdf/app_generated_pdf_service.dart lib/shared/pdf/app_generated_pdf_models.dart test/app_generated_pdf_preview_screen_test.dart test/invoice_pdf_preview_action_tracking_test.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/app_generated_pdf_preview_screen_test.dart test/invoice_pdf_preview_action_tracking_test.dart -r compact`
  - `dart format test/pdf_quality_gate_contract_test.dart`
  - `bash tool/pdf_quality_gate.sh`

## Pass 20 - 2026-07-04 20:36 EDT - Generated PDF archive rollback

- Scope: generated PDF permanent archive failure recovery and QA only. No
  inventory, camera, native capture, receipt text engine, or parser behavior
  changes.
- Bundled work:
  - Added hash verification after permanent generated-PDF writes so archive
    storage now verifies both byte count and SHA-256 before renaming the
    partial file into place.
  - Added rollback when the document-store record save fails after a permanent
    PDF file was written, preventing orphaned generated PDFs.
  - Added regression coverage for record-save failure cleanup and source-code
    guard coverage for permanent-write hash verification.
- Verification completed 2026-07-04 20:35 EDT:
  - `dart format lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_service_test.dart`
  - `dart analyze lib/shared/documents/app_generated_pdf_archive_service.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 19 - 2026-07-04 20:24 EDT - Receipt PDF proof metadata privacy

- Scope: receipt PDF proof storage metadata privacy and QA only. No inventory,
  camera, native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added safe metadata filename generation for stored receipt proofs so staged
    and permanent PDF records do not keep source path fragments, traversal
    markers, platform separators, or unsafe filename characters.
  - Kept app-owned storage paths sanitized while preserving existing PDF proof
    copy verification, hash verification, staging, promotion, cancel, and
    cleanup behavior.
  - Added regression coverage for hostile source paths and original filenames
    containing private-looking text, path separators, traversal, and invalid
    filename characters.
  - Strengthened the cross-platform PDF contract to assert both stored paths and
    stored original-filename metadata are safe.
- Verification completed 2026-07-04 20:23 EDT:
  - `dart format lib/shared/widgets/receipt_capture/receipt_proof_storage.dart lib/shared/widgets/receipt_capture/receipt_proof_storage_file_names.dart test/pdf_cross_platform_contract_test.dart test/receipt_pdf_torture_storage_test.dart`
  - `dart analyze lib/shared/widgets/receipt_capture/receipt_proof_storage.dart test/pdf_cross_platform_contract_test.dart test/receipt_pdf_torture_storage_test.dart`
  - `flutter test test/pdf_cross_platform_contract_test.dart test/receipt_pdf_torture_storage_test.dart test/receipt_proof_storage_lifecycle_test.dart test/receipt_proof_storage_hardening_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 18 - 2026-07-04 20:07 EDT - All-page render smoke gate

- Scope: PDF render QA tooling only. No inventory, camera, native capture,
  receipt text engine, or parser behavior changes.
- Bundled work:
  - Upgraded the render smoke gate from first-page-only rendering to all-page
    rendering for each PDF fixture.
  - Added page-count verification against Poppler output so missing rendered
    pages fail the gate.
  - Required the real invoice renderer fixture to stay multi-page, then checked
    every rendered invoice page with the pixel assertions.
  - Strengthened the quality-gate contract so future edits cannot quietly
    remove all-page rendering, page-count checks, or the multi-page invoice
    fixture.
- Verification completed 2026-07-04 20:06 EDT:
  - `dart format test/pdf_quality_gate_contract_test.dart`
  - `bash -n tool/pdf_render_smoke_gate.sh`
  - `dart analyze test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/pdf_quality_gate_contract_test.dart test/pdf_render_gate_invoice_generator_test.dart -r compact`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `bash tool/pdf_quality_gate.sh`

## Pass 17 - 2026-07-04 19:53 EDT - Cent-safe invoice PDF money

- Scope: invoice/estimate financial calculations used by generated PDFs and
  related QA only. No inventory, camera, native capture, receipt text engine, or
  parser behavior changes.
- Bundled work:
  - Added shared cent-based invoice money helpers that calculate line subtotals,
    tax, discounts, payments, totals, and balances with scaled integer math
    instead of floating-point accumulation.
  - Exposed cent totals on invoice records while preserving the existing double
    getters for current UI and PDF renderer compatibility.
  - Added regression coverage for decimal quantities, small decimal prices,
    tax rounding, percent discounts, amount discounts, payments, negative refund
    lines, and PDF generation using those values.
  - Included the money-precision suite in the shared PDF quality gate.
- Failure fixed during pass:
  - The first focused run used incorrect expected totals in the new regression
    test. The expectations were corrected against the cent-level calculation
    that invoice PDFs now use.
- Verification completed 2026-07-04 19:52 EDT:
  - `dart format lib/screens/invoices/data/invoice_ledger_models.dart lib/screens/invoices/data/invoice_record.dart test/invoice_pdf_money_precision_test.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze lib/screens/invoices/data/invoice_ledger_models.dart lib/screens/invoices/data/invoice_record.dart test/invoice_pdf_money_precision_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/invoice_pdf_money_precision_test.dart test/invoice_template_pdf_factory_test.dart test/app_generated_pdf_service_test.dart test/pdf_quality_gate_contract_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 16 - 2026-07-04 19:33 EDT - Render pixel gate and pagination regression

- Scope: PDF render QA and invoice pagination only. No inventory, camera,
  native capture, receipt text engine, or parser behavior changes.
- Bundled work:
  - Added pixel-level PNG assertions to the PDF render smoke gate so rendered
    PDFs must have sane dimensions, real ink, color variation, and not render
    as blank or mostly black pages.
  - Added a Flutter-backed render-gate invoice fixture that exercises the real
    invoice renderer, not only a small command-line sample PDF.
  - Fixed invoice pagination when the line count leaves an eleven-line final
    chunk, which previously could ask for a sublist beyond the available line
    items.
  - Added regression coverage for the invoice pagination edge case and included
    the real renderer fixture in the shared PDF quality gate.
- Failure fixed during pass:
  - The strengthened render gate exposed a real paginator range error for a
    42-line invoice. The paginator now uses named capacities and balanced
    continuation chunks so it cannot overrun line-item bounds.
- Verification completed 2026-07-04 19:32 EDT:
  - `dart format lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_template_pdf_factory_test.dart test/pdf_render_gate_invoice_generator_test.dart tool/generate_sample_invoice_pdf.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze lib/screens/invoices/data/invoice_pdf_template_renderer.dart test/invoice_template_pdf_factory_test.dart test/pdf_render_gate_invoice_generator_test.dart tool/generate_sample_invoice_pdf.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/invoice_template_pdf_factory_test.dart test/pdf_render_gate_invoice_generator_test.dart test/pdf_quality_gate_contract_test.dart -r compact`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `bash tool/pdf_quality_gate.sh`

## Pass 15 - 2026-07-04 15:56 EDT - Deterministic generated PDFs

- Scope: generated PDF determinism, sample render tooling, and regression
  coverage only. No inventory, camera, native capture, OCR engine, or parser
  behavior changes.
- Bundled work:
  - Added a shared generated-PDF determinism helper that normalizes PDF document
    IDs from stable confirmed input seeds.
  - Applied deterministic IDs to invoice/estimate PDFs, expense export summary
    PDFs, and render-smoke sample PDFs.
  - Added invoice and expense-export regressions proving the same confirmed
    input produces byte-identical PDF output.
  - Added deterministic sample comparisons to the PDF quality gate.
- Failure fixed during pass:
  - The first probe showed otherwise identical sample PDFs differed only by the
    PDF `/ID` value generated from random/time data. The helper now replaces
    that value with a stable hash.
- Verification completed 2026-07-04 15:55 EDT:
  - `dart format lib/shared/pdf/app_pdf_determinism.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart lib/screens/expenses/data/expense_export_handoff.dart tool/generate_sample_invoice_pdf.dart tool/generate_sample_receipt_pdf.dart test/invoice_template_pdf_factory_test.dart test/app_generated_pdf_service_test.dart`
  - `dart analyze lib/shared/pdf/app_pdf_determinism.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart lib/screens/expenses/data/expense_export_handoff.dart tool/generate_sample_invoice_pdf.dart tool/generate_sample_receipt_pdf.dart test/invoice_template_pdf_factory_test.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/invoice_template_pdf_factory_test.dart test/app_generated_pdf_service_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 14 - 2026-07-04 15:27 EDT - Generated PDF privacy guard

- Scope: generated PDF validation, export metadata privacy, and QA coverage
  only. No inventory, camera, native capture, OCR engine, or parser behavior
  changes.
- Bundled work:
  - Added a shared PDF privacy policy for generated document bytes, titles,
    file names, share subjects, and share text.
  - Blocked generated PDF send/save/print paths when exported content appears
    to contain VINs, license plates, passenger data, patient data, payment
    fragments, unconfirmed OCR suggestions, private source paths, or internal
    IDs.
  - Added regression coverage for private PDF bytes, exported metadata, service
    refusal before writes, and ordinary confirmed business PDFs.
  - Included the privacy contract in the PDF quality gate and QA fixture
    registry.
- Failure fixed during pass:
  - The first focused run missed `Card ending 4242` and also produced a false
    positive against an ordinary generated estimate PDF. The policy was
    tightened to catch last-four payment labels while requiring stronger
    context for patient and license-plate signals.
- Verification completed 2026-07-04 15:26 EDT:
  - `dart format lib/shared/pdf/app_pdf_privacy_policy.dart lib/shared/pdf/app_generated_pdf_models.dart test/pdf_privacy_policy_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze lib/shared/pdf/app_pdf_privacy_policy.dart lib/shared/pdf/app_generated_pdf_models.dart test/pdf_privacy_policy_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/pdf_privacy_policy_contract_test.dart test/app_generated_pdf_service_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 13 - 2026-07-04 14:58 EDT - Embedded PDF typography

- Scope: PDF font/theme generation and QA only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added embedded Roboto PDF fonts and shared PDF typography loaders for app,
    tests, and render tools.
  - Wired invoice, expense export, render-smoke, and PDF fixture generation to
    use embedded fonts instead of default Helvetica.
  - Added PDF typography contract coverage and included it in the PDF quality
    gate.
  - Removed PDF-owned wording that suggested a separate branch of effort.
- Verification completed 2026-07-04 14:58 EDT:
  - `dart format lib/shared/pdf/app_pdf_typography.dart test/helpers/pdf_test_typography.dart tool/pdf_tool_typography.dart test/pdf_typography_contract_test.dart test/pdf_quality_gate_contract_test.dart tool/generate_sample_invoice_pdf.dart tool/generate_sample_receipt_pdf.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart lib/screens/expenses/data/expense_export_handoff.dart test/helpers/pdf_torture_fixtures.dart test/receipt_pdf_hardening_test.dart`
  - `dart analyze lib/shared/pdf/app_pdf_typography.dart test/helpers/pdf_test_typography.dart tool/pdf_tool_typography.dart tool/generate_sample_invoice_pdf.dart tool/generate_sample_receipt_pdf.dart lib/screens/invoices/data/invoice_pdf_template_renderer.dart lib/screens/expenses/data/expense_export_handoff.dart test/helpers/pdf_torture_fixtures.dart test/receipt_pdf_hardening_test.dart`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `flutter test test/receipt_pdf_hardening_test.dart test/receipt_pdf_torture_test.dart test/invoice_template_pdf_factory_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 1 - 2026-07-04 13:33 EDT - Shared PDF security policy and QA registry

- Scope: PDF behavior/security QA only. No inventory, camera, native capture,
  OCR engine, or parser behavior changes.
- Bundled work:
  - Added a shared active-content policy for generated PDFs and receipt PDFs.
  - Wired generated invoice/estimate PDF validation to the shared policy.
  - Wired receipt PDF risk flag detection to the shared policy.
  - Added a PDF QA fixture inventory covering malformed, large, encrypted,
    image-only, text-layer, rotated/cropped, ownership, cleanup, privacy,
    receipt review, and invoice-generation coverage.
  - Added contract tests proving the PDF QA registry exists and that generated
    PDFs plus receipt PDFs use the same active-content security policy.
- Regression rule: shared-policy behavior is now guarded by direct tests so
  future PDF bug fixes can extend one policy instead of drifting between receipt
  and invoice code paths.
- Verification completed 2026-07-04 13:36 EDT:
  - `dart analyze lib/shared/pdf lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart test/app_generated_pdf_service_test.dart test/pdf_qa_fixture_inventory_test.dart test/pdf_security_policy_contract_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart test/pdf_security_policy_contract_test.dart test/pdf_qa_fixture_inventory_test.dart test/receipt_pdf_inspector_security_flags_test.dart -r compact`
  - `flutter test test/receipt_pdf_torture_test.dart test/receipt_pdf_torture_storage_test.dart test/receipt_pdf_hardening_test.dart test/receipt_pdf_import_copy_test.dart -r compact`
  - `flutter test test/cloud_backup_pdf_policy_test.dart test/incoming_receipt_share_pdf_hardening_test.dart -r compact`

## Pass 2 - 2026-07-04 13:36 EDT - PDF structure signal coverage

- Scope: PDF inspector behavior and PDF QA fixture registry only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added document signals for likely text layers, rotated pages, and cropped
    pages.
  - Added image-only detection to receipt PDF inspections so scanned PDFs can
    remain proof-safe while warning that assisted reading may need page imagery.
  - Added torture fixtures for image-layer and cropped-page PDFs.
  - Extended PDF edge-case tests and torture tests for text-layer, image-only,
    rotated, and cropped PDF behavior.
  - Updated the PDF QA inventory so those areas are tracked as partial
    coverage instead of unstarted gaps.
- Verification completed 2026-07-04 13:36 EDT:
  - `dart format lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspection.dart test/helpers/pdf_torture_fixtures.dart test/receipt_pdf_torture_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `dart analyze lib/shared/widgets/receipt_capture/receipt_pdf_inspector.dart lib/shared/widgets/receipt_capture/receipt_pdf_inspection.dart test/helpers/pdf_torture_fixtures.dart test/receipt_pdf_torture_test.dart test/receipt_pdf_inspector_edge_cases_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/receipt_pdf_inspector_edge_cases_test.dart test/receipt_pdf_torture_test.dart test/pdf_qa_fixture_inventory_test.dart -r compact`

## Pass 3 - 2026-07-04 13:36 EDT - Dedicated PDF quality gate

- Scope: PDF gate composition and contract test only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added `tool/pdf_quality_gate.sh` as the surgical PDF rerun command.
  - Included PDF behavior, storage, privacy/security, import/export, invoice
    generation, receipt PDF review, fixture registry, and performance-profile
    suites.
  - Intentionally excluded unstable PDF UI tests until those screens are stable.
  - Added a contract test so the gate keeps those boundaries.
  - Added cross-platform filename, temp-directory, and receipt proof storage
    coverage for Android, iOS, macOS, and Windows-style path inputs.
  - Hardened generated PDF and receipt proof names against traversal-looking
    `..` segments and normalized generated `.pdf` extensions.
- Verification completed 2026-07-04 13:45 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_models.dart lib/shared/widgets/receipt_capture/receipt_proof_storage_file_names.dart test/pdf_cross_platform_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze lib/shared/pdf/app_generated_pdf_models.dart lib/shared/widgets/receipt_capture/receipt_proof_storage_file_names.dart tool/pdf_quality_gate.sh test/pdf_cross_platform_contract_test.dart test/pdf_quality_gate_contract_test.dart`
  - `flutter test test/pdf_cross_platform_contract_test.dart test/pdf_quality_gate_contract_test.dart test/app_generated_pdf_service_test.dart test/receipt_pdf_torture_storage_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 8 - 2026-07-04 13:51 EDT - Escaped PDF active-name detection

- Scope: PDF security policy and regression coverage only. No inventory,
  camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Decoded PDF name escape sequences before active-content detection.
  - Added generated-PDF and receipt-PDF regressions for escaped active names.
  - Added escaped active-name fixture coverage to the PDF QA registry.
- Verification completed 2026-07-04 13:59 EDT:
  - `dart format lib/shared/pdf/app_pdf_security_policy.dart test/pdf_security_policy_contract_test.dart test/receipt_pdf_inspector_security_flags_test.dart`
  - `dart analyze lib/shared/pdf/app_pdf_security_policy.dart test/pdf_security_policy_contract_test.dart test/receipt_pdf_inspector_security_flags_test.dart test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/pdf_security_policy_contract_test.dart test/receipt_pdf_inspector_security_flags_test.dart test/pdf_qa_fixture_inventory_test.dart test/app_generated_pdf_service_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 9 - 2026-07-04 13:54 EDT - Document Engine directive preservation

- Scope: Document Engine/PDF operating rules and QA guardrails only. No
  inventory, camera, native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Preserved Maintainiac's reusable Document Engine directive in repo docs.
  - Added a contract test so required PDF rules cannot silently drift.
  - Wired the directive contract into the shared PDF quality gate.
  - Saved the directive in Codex memory for future PDF continuity.
- Verification completed 2026-07-04 13:58 EDT:
  - `dart format test/document_engine_operating_directive_test.dart`
  - `dart analyze test/document_engine_operating_directive_test.dart`
  - `flutter test test/document_engine_operating_directive_test.dart -r compact`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `bash tool/pdf_quality_gate.sh`

## Pass 7 - 2026-07-04 13:55 EDT - PDF QA registry sync

- Scope: PDF QA fixture registry only. No inventory, camera, native capture,
  OCR engine, or parser behavior changes.
- Bundled work:
  - Added cross-platform storage and render-smoke coverage to the PDF QA
    registry.
  - Extended the registry contract so those areas remain tracked.
- Verification completed 2026-07-04 13:58 EDT:
  - `dart format test/pdf_qa_fixture_inventory_test.dart`
  - `dart analyze test/pdf_qa_fixture_inventory_test.dart`
  - `flutter test test/pdf_qa_fixture_inventory_test.dart test/pdf_quality_gate_contract_test.dart test/pdf_cross_platform_contract_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 6 - 2026-07-04 13:53 EDT - Generated PDF temp write verification

- Scope: generated PDF temporary storage hardening only. No inventory, camera,
  native capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Verified temporary generated PDF byte count before final rename.
  - Added regression coverage so temp writes cannot skip the byte-count guard.
- Verification completed 2026-07-04 13:55 EDT:
  - `dart format lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart`
  - `dart analyze lib/shared/pdf/app_generated_pdf_service.dart test/app_generated_pdf_service_test.dart`
  - `flutter test test/app_generated_pdf_service_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 5 - 2026-07-04 13:48 EDT - PDF render smoke gate

- Scope: PDF render-level QA tooling only. No inventory, camera, native capture,
  OCR engine, or parser behavior changes.
- Bundled work:
  - Added a sample invoice PDF generator for render smoke checks.
  - Added a Poppler-backed render smoke gate for generated receipt and invoice
    PDFs.
  - Added the render smoke gate to the PDF quality gate.
- Verification completed 2026-07-04 13:52 EDT:
  - `dart format tool/generate_sample_invoice_pdf.dart test/pdf_quality_gate_contract_test.dart`
  - `dart analyze tool/generate_sample_invoice_pdf.dart test/pdf_quality_gate_contract_test.dart`
  - `bash tool/pdf_render_smoke_gate.sh`
  - `flutter test test/pdf_quality_gate_contract_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`

## Pass 4 - 2026-07-04 13:43 EDT - PDF warning privacy regression

- Scope: PDF inspector privacy regression only. No inventory, camera, native
  capture, OCR engine, or parser behavior changes.
- Bundled work:
  - Added a regression test proving PDF warnings do not expose embedded customer
    names, emails, card fragments, or source paths.
  - Kept the warning useful by allowing only safe signal labels such as active
    content and generic receipt hints.
- Verification completed 2026-07-04 13:45 EDT:
  - `dart format test/receipt_pdf_inspector_edge_cases_test.dart`
  - `dart analyze test/receipt_pdf_inspector_edge_cases_test.dart`
  - `flutter test test/receipt_pdf_inspector_edge_cases_test.dart -r compact`
  - `bash tool/pdf_quality_gate.sh`
