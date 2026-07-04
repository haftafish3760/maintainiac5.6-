# PDF System Pass Log

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
