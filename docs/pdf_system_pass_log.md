# PDF System Pass Log

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
