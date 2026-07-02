# Receipt Camera OCR Master Pass Plan Archive - Pass 47 of estimated 55: Synthetic End-To-End Receipt Regression Matrix

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Pass 47 of estimated 55: Synthetic End-To-End Receipt Regression Matrix

Status: complete.

Goal:
- Prove the receipt pipeline against repeatable synthetic receipt cases before relying on real-world phone testing.

Scope:
- Audit existing synthetic Lowe's, Home Depot, Walmart, CVS, fuel, return, wrinkled/noisy, and long receipt tests.
- Add missing end-to-end expectations for OCR text normalization, parser results, review flags, business/personal/mixed classification, proof metadata, and export readiness.
- Keep synthetic images/text privacy-safe and deterministic.
- Keep maintenance-specific receipt setup untouched.

Done:
- The receipt system has a repeatable regression matrix showing what is covered and what still requires real-device testing.
- Added an end-to-end synthetic matrix that parses all fixture packs into real `ExpenseReceiptRecord` objects, checks saved proof/OCR metadata, verifies business plus personal totals reconcile, and exports the records.
- The matrix proves export readiness includes proof metadata and OCR review metadata while keeping raw OCR text out of the receipt CSV.
- Existing regression report still covers 14 fixtures across core, materials, noisy OCR, damaged, and trade supply packs with 14/14 ready fixtures.
- Focused analyzer plus end-to-end matrix, regression report, long retail torture, and export tests pass.

### Pass 48 of estimated 55: Receipt Stitching And OCR Handoff Stress Matrix

Status: complete.

Goal:
- Prove stitched, multi-photo, duplicate-overlap, and missing-section receipt inputs hand off safely to OCR/parser review.

Scope:
- Audit existing receipt stitching and combined OCR text stress tests.
- Add matrix expectations for overlap suppression, section ordering, missing middle section warnings, and fallback-to-separate OCR behavior.
- Confirm long receipt handoff does not trust low-confidence or incomplete stitched output.
- Confirm older-device limits remain bounded and do not require all images in memory forever.

Done:
- Multi-photo receipt capture has repeatable stress coverage before real-device long-receipt testing.
- Added a section handoff matrix that drives multi-section receipt text through OCR app-fill and the expense parser.
- The matrix covers ordered overlap suppression, missing middle sections, out-of-order sections, and similar-but-different overlap lines that must not be deleted.
- Missing and out-of-order sections now have regression coverage proving they stay reviewable and are not treated as trusted math.
- Focused analyzer plus stitching, combined OCR, and long-retail torture tests pass.

### Pass 49 of estimated 55: Receipt Camera Capability And Low-End Device Stress Review

Status: complete.

Goal:
- Prove receipt capture, stitching, OCR limits, and saved proof behavior stay bounded on older and lower-capability devices.

Scope:
- Audit receipt device capability detection, camera capture policy, PDF/OCR limits, stitching output limits, data saver defaults, and low-storage behavior.
- Add or tighten tests for light, medium, and heavyweight capability tiers.
- Confirm manual capture always works even when automatic capture is not confident.
- Confirm long-receipt stitching falls back cleanly when output size exceeds a device tier.
- Confirm user-facing labels do not expose creepy device details, while diagnostics keep privacy-safe capability context.

Done:
- Low-end device behavior is covered before broader camera UI/device testing resumes.
- Stitch output limits now live in the shared receipt capability policy instead of private review-screen UI code.
- Photo review uses `ReceiptDeviceCapability.stitchLimits`, so older, medium, and heavyweight devices share the same tested limits everywhere.
- Capability tests now cover stitch output ceilings, low-end camera defaults, large-photo review on older phones, and no raw hardware detail leakage in setup/settings surfaces.
- Focused analyzer plus assistance policy, OCR service, stitching, and combined OCR handoff tests pass.

### Pass 50 of estimated 55: Receipt Review Route And Classification Contract

Status: complete.

Goal:
- Prove the app-assisted receipt flow routes to receipt review/classification after photo OCR instead of dropping the user back into a plain attachment screen.

Scope:
- Audit receipt attachment import actions, expense receipt entry routing, app-assisted mode handling, and classification landing tests.
- Add or tighten source/behavior tests proving `Read Receipt` leads to parsed review rows.
- Confirm business, personal, and mixed classification choices remain available after OCR.
- Confirm quick classify and detailed item modes are user-facing choices with plain wording, not developer jargon.
- Keep maintenance-specific receipt setup out of scope.

Done:
- App-assisted receipt capture has a tested route contract from accepted photos to review/classification.
- The assisted receipt review source-contract test now covers the reviewed-photo import path.
- The test proves attachment state is published, reviewed OCR photos are read for app-assisted review, and temporary OCR copies are cleaned up after handoff.
- The test covers stitched, separate-photo fallback, multi-photo, and single-photo success messages that direct the user to parsed receipt lines below.
- Focused analyzer plus assisted review, saved receipt detail, and expense telemetry tests pass.

### Pass 51 of estimated 55: Receipt Data Saver Preview And OCR Source Contract

Status: complete.

Goal:
- Prove OCR reads the best prepared receipt source before saved-copy shrinking, while the user can still choose a smaller cloud/local proof copy after review.

Scope:
- Audit image preparation, OCR source photo paths, data saver preview, saved proof copies, and attachment metadata.
- Add or tighten tests proving OCR source paths are separate from saved proof copies when needed.
- Confirm data saver language remains user-friendly and not developer/compression jargon.
- Confirm grayscale/space-saving copies are for saved proof/storage, not the first OCR read.
- Confirm selected saved-copy level persists without changing raw OCR diagnostic text.

Done:
- Receipt photo reading and receipt proof storage are contractually separated.
- Added prepared saved-proof preview helpers so the preview estimates and preview image use the same OCR-prepared source as the final saved proof copy.
- Photo review now uses `previewPreparedBackupFile` and `optimizePreparedBackupFile`, preventing the UI from previewing an unprepared camera image while saving a prepared receipt proof.
- Data saver tests now prove OCR source and saved proof are separate, prove final backup quality/size matches the prepared preview pipeline, and tolerate only tiny JPEG score variance.
- Source-contract tests now cover prepared preview helpers, OCR-before-backup order, and reviewed-photo handoff cleanup.
- Focused analyzer plus data saver, camera help, assisted review, and OCR service tests pass.

### Pass 52 of estimated 55: Receipt Saved Proof Lifecycle And Cleanup Audit

Status: complete.

Goal:
- Prove temporary receipt OCR artifacts, data-saver previews, stitch previews, best-shot extras, and saved proof files are kept or deleted at the right time.

Scope:
- Audit generated file cleanup in camera review, attachment import, proof storage, drafts, and saved expense records.
- Add or tighten tests proving saved proof files are preserved while temporary OCR/stitch/preview artifacts are cleaned after handoff.
- Confirm cleanup never deletes the saved receipt proof path or user-selected source still needed by the receipt.
- Confirm cleanup is best-effort and cannot crash the receipt workflow.

Done:
- Receipt file lifecycle has explicit regression coverage before real-device long receipt testing.
- Prepared backup preview helpers now await cleanup of temporary OCR-prepared source files instead of leaving cleanup fire-and-forget.
- Added a direct cleanup test proving prepared backup preview/optimization leaves the saved optimized proof and does not leak temporary enhanced OCR artifacts.
- Source-contract coverage now checks review-screen cleanup hooks, best-shot cleanup, stitch/data-saver preview cleanup, and imported OCR source cleanup that skips saved receipt photo paths.
- Existing proof storage lifecycle tests still prove staged proof promotion, rollback, orphan cleanup, draft retention, and staged-copy deletion behavior.
- Focused analyzer plus data saver, camera help, proof storage lifecycle, and draft storage lifecycle tests pass.

### Pass 53 of estimated 55: Receipt Final Synthetic Stress And Coverage Review

Status: complete.

Goal:
- Run the broadest practical synthetic receipt/camera/OCR/parser/export regression set and identify any remaining hardening passes before moving to real-device receipt tests or PDF/invoice hardening.

Scope:
- Run focused receipt camera/OCR/parser/export/telemetry tests together.
- Review the pass plan for remaining gaps versus the receipt camera/OCR/product standard.
- Fix small discovered gaps where safe; otherwise add explicit next-pass items.
- Do not push a device build unless the user asks.

Done:
- The receipt capture/OCR/parser foundation has a current synthetic QA snapshot and a short remaining-work list.
- Focused analyzer passed for shared receipt capture, expense entry, export models, and the receipt/camera/OCR/export/telemetry/storage tests used in this pass.
- Camera/settings tests passed: data saver, camera help, quality guidance, capture layout, assistance policy, and settings store.
- OCR/stitch/parser tests passed: stitching, combined OCR handoff, OCR service, end-to-end regression matrix, regression report, and long retail torture.
- Expense/export/storage tests passed: assisted receipt review, saved receipt OCR detail, export, telemetry, proof lifecycle, and draft lifecycle.
- Synthetic regression report stayed at 14/14 ready fixtures, 100.0% pass, 95.6% quality, 98.8% readiness, and 0 issue buckets.

### Pass 54 of estimated 55: Receipt Real-Device Readiness Checklist And Manual Test Script

Status: complete.

Goal:
- Convert the synthetic receipt evidence into a practical S24/S9/iPhone manual test checklist so real-device testing is deliberate instead of random.

Scope:
- Define exact phone test flows for single-photo receipts, long multi-photo receipts, add-photo order changes, manual capture, auto guidance, save-space preview, app-assisted review, manual/no-assist mode, PDF import, and proof recovery.
- Keep the checklist privacy-safe and written in plain language.
- Identify the small number of device builds worth pushing instead of reinstalling after every tweak.
- List remaining pass candidates before moving into heavier PDF/invoice hardening.

Done:
- User has a concise receipt-device test script that says what to tap, what should happen, what must never happen, and what evidence to report back.
- Added `docs/receipt_real_device_test_script.md` covering single-photo receipts, long multi-photo receipts, save-space preview, app-assisted review, manual/no-assist mode, PDF receipt import, interruption recovery, and failure reporting.
- The script names the expected behavior and "must never happen" checks for each flow so S24/S9/iPhone testing is useful instead of vague.

### Pass 55 of estimated 55: Receipt Remaining Gaps And PDF/Invoice Bridge Decision

Status: complete.

Goal:
- Decide whether the receipt camera/OCR foundation is ready for real-device validation, or whether one more code-hardening pass is needed before moving into PDF/invoice hardening.

Scope:
- Review remaining product-standard gaps against the synthetic evidence and real-device script.
- Identify the smallest safe next code pass if there is a known gap.
- Separate receipt-camera/OCR work from invoice PDF generation/send/receive hardening.
- Do not touch maintenance-specific receipt paths.

Done:
- The next work lane is explicit: either device validation, a named receipt gap fix, or the next PDF/invoice hardening pass.
- Decision: receipt camera/OCR foundation is ready for controlled real-device validation, not random stress testing.
- Fixed a remaining user-facing wording gap: saved receipt detail and OCR summaries now say receipt lines are ready for review instead of showing developer-facing parser/raw-line language.
- Kept raw/parser line counts in storage, exports, privacy-safe diagnostics, and Command One-ready telemetry where they are useful for debugging and health reporting.
- Focused analyzer and OCR/detail tests pass after the wording fix.

## PDF And Invoice Hardening Track

### PDF Pass 56 of up to 200: Generated PDF Boundary Validation

Status: complete.

Goal:
- Make every app-generated PDF prove it is a safe, complete PDF before Maintainiac writes, previews, archives, prints, shares, or stores it as invoice/document proof.

Scope:
- Add shared generated-PDF validation for empty bytes, missing PDF header, missing EOF marker, over-large files, and unsupported active PDF features.
- Sanitize generated PDF filenames through one shared helper.
- Apply validation to temporary generated PDF writes, printing, sharing, and permanent generated-document archive.
- Share the already prepared preview file instead of silently generating another temporary PDF from the share button.
- Keep invoice PDF bytes generated from structured invoice data; do not store invoice PDFs inside invoice ledger records.

Done:
- `AppGeneratedPdfDocument` exposes validation and sendable status.
- `AppGeneratedPdfService` refuses invalid generated PDFs before temporary write, print, or share.
- `AppGeneratedPdfArchiveService` refuses invalid generated PDFs before permanent document archive.
- `AppGeneratedPdfPreviewScreen` shares the already prepared preview file.
- Focused analyzer passed for generated PDF services, invoice renderer/factory, and related tests.
- Focused tests passed for generated PDF service and invoice template PDF factory.

### PDF Pass 57 of up to 200: Invoice PDF Send/Archive Lifecycle Audit

Status: complete.

Goal:
- Prove invoice and estimate PDFs can be generated, previewed, shared/sent, printed, archived, and later recovered without duplicate temp buildup, incomplete files, or private-data backup mistakes.

Scope:
- Audit invoice PDF preview entry points and record-specific PDF generation.
- Confirm permanent archive links generated invoice PDFs to invoice records without storing PDF bytes in the invoice ledger.
- Add lifecycle tests for record-specific invoice/estimate PDFs, archive duplicate handling, and file hash/byte-size metadata.
- Keep customer contact/payment data as structured invoice data; generated PDFs remain derived artifacts.
- Do not touch maintenance-specific PDF flows unless a shared generated-PDF utility requires it.

Done:
- Invoice PDF send/archive lifecycle has focused regression coverage and a short remaining gap list before incoming invoice/document PDF work.
- Record-specific invoice PDFs are now tested as sendable, safe-named, archived permanent document proof linked to the invoice record, and excluded from invoice ledger maps.
- Record-specific estimate PDFs are tested as generated estimate documents archived as invoice document proof.
- Focused analyzer passed for invoice PDF factory/renderer, generated PDF services, archive service, and tests.
- Focused tests passed for generated PDF service, invoice template PDF factory, and invoice ledger store.

### PDF Pass 58 of up to 200: Incoming Invoice/Document PDF Routing

Status: complete.

Goal:
- Make incoming/shared invoice, estimate, proposal, job, and contractor PDFs route to document/invoice proof handling instead of being mistaken for ordinary expense receipts.

Scope:
- Audit incoming shared PDF classification and destination UI.
- Strengthen invoice/estimate/job-document keyword handling without reading or storing private content in diagnostics.
- Add tests for incoming invoice PDFs, estimate PDFs, manual PDFs, and regular receipts.
- Keep maintenance receipt routing untouched.

Done:
- Shared invoice/estimate PDFs are suggested as job/invoice documents and can be saved as read-only proof without forcing the expense receipt flow.
- Invoice, estimate, proposal, work order, scope of work, bill-to, amount-due, balance-due, and payment-terms signals now weigh strongly toward job/contractor document routing.
- The job/contractor document suggestion copy now uses user-facing language and explains read-only proof instead of saying an internal feature is not wired.
- Incoming invoice and estimate PDF widget tests prove those PDFs are not mistaken for ordinary expense receipts.
- Existing generic receipt PDF, other document PDF, and PDF torture routing tests still pass.

### PDF Pass 59 of up to 200: Generated PDF Preview And Share Failure Recovery

Status: complete.

Goal:
- Make generated invoice/estimate PDF preview, share, print, and failure states clear and recoverable before deeper invoice-delivery work.

Scope:
- Audit `AppGeneratedPdfPreviewScreen` for validation errors, missing temp files, incomplete prepared files, and share/print dismissals.
- Add tests for preview error wording and share-file failure handling without needing a real platform share sheet.
- Confirm the user sees plain language and can regenerate instead of being stuck.
- Keep this pass focused on generated invoice/estimate PDFs, not maintenance PDFs.

Done:
- Generated PDF UI and service failure states are covered by tests and use user-safe recovery copy.
- Preview generation failures now show a plain-language error plus a `Try Again` action.
- Share and print platform failures now show friendly recovery messages instead of only handling generated-PDF validation errors.
- Preview sharing continues to use the already prepared generated file.
- Widget tests cover retry after preparation failure, friendly share failure, and friendly print failure.
- Focused analyzer and generated PDF preview/service tests pass.

### PDF Pass 60 of up to 200: Invoice PDF Delivery Metadata And Audit Trail

Status: complete.

Goal:
- Track invoice/estimate PDF generation and delivery attempts as structured, privacy-safe invoice events without storing PDF bytes or private document text in the invoice ledger.

Scope:
- Audit invoice audit events and delivery-related status transitions.
- Add structured helpers for PDF generated, previewed, shared/sent, printed, archived, and failed delivery attempts where feasible.
- Preserve local-first invoice records and keep generated PDFs as derived artifacts.
- Add tests proving delivery metadata is useful without embedding PDF bytes or customer/private document text.

Done:
- Added structured `InvoicePdfDeliveryEvent` records for generated, previewed, archived, shared, sent, printed, and failed PDF actions.
- `InvoiceRecord` now preserves `pdfEvents` through copy, map serialization, and reload.
- Added record helpers for generated, previewed, archived, shared, printed, and failed PDF delivery events.
- PDF event metadata stores action type, timestamp, safe filename, byte size, hash, source id, and reason code without storing PDF bytes, PDF paths, customer names, addresses, emails, notes, share text, or document body text.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 61 of up to 200: Invoice PDF Firestore/Backup Shape Audit

Status: complete.

Goal:
- Make sure invoice PDF metadata and delivery events have a cost-safe, privacy-safe backup shape for future Firestore mirroring.

Scope:
- Audit invoice daily backup batches and generated PDF document attachment metadata.
- Ensure invoice PDF events stay small enough to live in structured ledger records without storing PDF bytes or local-only paths.
- Add tests for Firestore-like map payload shape, event count bounds, and privacy-safe document metadata.

Done:
- Added a bounded invoice PDF delivery history limit so one invoice cannot grow an unlimited delivery log.
- Invoice record PDF event helpers keep only the newest bounded delivery events.
- Added tests proving invoice daily backup batches include PDF metadata, exclude PDF bytes and local paths, and keep event history bounded.
- Documented invoice/estimate Firestore backup scope, derived PDF artifact handling, and forbidden PDF event content.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 62 of up to 200: Invoice PDF Form Action Wiring

Status: complete.

Goal:
- Make invoice form preview/share/print/save actions update the invoice record PDF delivery trail where feasible.

Scope:
- Audit current invoice form PDF preview, archive, share, and error paths.
- Wire generated, archived, shared/printed/failed metadata into saved invoice records without changing user-facing workflow unless necessary.
- Keep generated PDFs as derived artifacts and avoid storing file paths or PDF bytes in invoice records.
- Add focused tests around record updates if the existing UI/service seams allow it safely.

Done:
- Invoice final save now records generated and archived PDF delivery events before saving the permanent proof hash.
- Invoice preview now records generated and previewed PDF events after the temporary PDF is prepared.
- Invoice preview/archive failures now record structured failure reason codes where the invoice form owns the failing action.
- The visible invoice workflow stays unchanged.
- Focused analyzer and invoice/PDF ledger tests pass.

### PDF Pass 63 of up to 200: Invoice PDF Preview Action Callback Seam

Status: complete.

Goal:
- Let preview/share/print surfaces report PDF actions back to the owning record without coupling generic PDF widgets directly to invoice storage.

Scope:
- Audit current generated PDF preview and receipt PDF viewer seams.
- Add an optional callback/action-result object where generic preview widgets can report share/print/open failures.
- Keep callbacks privacy-safe: event type and reason code only, no PDF text or local paths.
- Add focused widget/service tests if the preview seams support it safely.

Done:
- Added `AppGeneratedPdfPreviewAction` and `AppGeneratedPdfPreviewActionEvent`.
- `AppGeneratedPdfPreviewScreen` now has an optional `onAction` callback for preview opened, share completed/dismissed/failed, and print opened/dismissed/failed.
- Failure callbacks use reason codes only and do not expose PDF text, share text, file paths, or customer content.
- Added widget tests for share failure callback, print failure callback, and successful share/print action reporting.
- Focused analyzer and generated PDF preview/service tests pass.

### PDF Pass 64 of up to 200: Invoice PDF Preview Surface Decision And Wiring

Status: complete.

Goal:
- Decide and implement the clean invoice preview surface so invoice-generated PDFs can report share/print/open activity without duplicate PDF writes or confusing navigation.

Scope:
- Compare the current invoice form preview path against `AppGeneratedPdfPreviewScreen`.
- Avoid duplicate temporary writes where possible.
- If the shared generated-PDF preview becomes the invoice surface, wire action callbacks into `InvoiceRecord` PDF delivery events.
- If invoice stays on the lightweight PDF viewer, document why and keep share/print tracking limited to the generated-PDF preview surface.

Done:
- Invoice form preview now uses `AppGeneratedPdfPreviewScreen` instead of separately writing a temporary PDF and pushing the plain PDF viewer.
- The shared generated-PDF preview reports prepared and preparation-failed events in addition to preview/share/print results.
- Invoice preview actions translate generic preview callbacks into invoice PDF delivery events for generated, shared, printed, and failed actions.
- Added a narrow invoice form testing seam for PDF preview factory/service injection without changing production defaults.
- Fixed invoice form draft creation so ledger notifications do not fire during dependency building.
- Added widget coverage proving invoice preview records generated, shared, and printed PDF events with only one temporary PDF preparation.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 65 of up to 200: PDF Preparation Failure And Retry Audit

Status: complete.

Goal:
- Make retry behavior and preparation failures produce useful, bounded, privacy-safe diagnostics without duplicate or misleading invoice history.

Scope:
- Verify generated-PDF preview retry behavior after preparation failure.
- Ensure invoice records can distinguish preparation failure from share/print failure.
- Keep repeated retries bounded by the existing PDF event history cap.
- Add tests for preparation failure followed by successful retry where feasible.

Done:
- Generated-PDF preview retry tests now assert preparation failure and later prepared events.
- Invoice preview widget coverage proves a preparation failure records a failed invoice PDF event and successful retry records a generated PDF event.
- Repeated retry history remains bounded by the existing invoice PDF event cap.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 66 of up to 200: PDF Delivery Event Semantics Cleanup

Status: complete.

Goal:
- Make PDF delivery event names and semantics precise enough for future Command One/support views.

Scope:
- Review whether dismissed share/print flows should be tracked as completed actions, cancelled actions, or no-ops.
- Add event types if needed so histories do not confuse a closed share sheet with a successful send.
- Preserve privacy-safe event maps and backward compatibility for existing events.
- Add focused tests for dismissed share/print behavior.

Done:
- Added `InvoicePdfDeliveryEventType.cancelled`.
- Added `InvoicePdfDeliveryEvent.cancelled` and `InvoiceRecord.recordPdfDeliveryCancelled`.
- Invoice preview now maps dismissed share sheets to `cancelled/share_sheet_dismissed` and closed print flows to `cancelled/print_flow_dismissed`.
- Added generated-PDF preview tests for dismissed share/print action callbacks.
- Added invoice preview tests proving dismissed share/print actions are not stored as successful shared/printed events.
- Focused analyzer and generated PDF/invoice ledger tests pass.

### PDF Pass 67 of up to 200: Invoice PDF Final Save Event Completeness

Status: pending.

Goal:
- Make final save/archive history as complete and truthful as preview history.

Scope:
- Verify final save records generated, archived, hash, and failure reason codes.
- Add focused tests around successful permanent PDF proof save and archive failures if feasible.
- Keep final save from storing PDF bytes, local paths, or private rendered PDF text.

Done:
- Saving an invoice or estimate with permanent PDF proof leaves the same quality of structured history as preview/share/print paths.
