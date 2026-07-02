# Receipt Camera OCR Master Pass Plan Archive - Pass 26 of estimated 55: Receipt Photo Quality And Auto-Capture Tuning

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Pass 26 of estimated 55: Receipt Photo Quality And Auto-Capture Tuning

Status: complete.

Goal:
- Make automatic capture helpful without trapping the user or refusing good photos.

Scope:
- Manual shutter always works.
- Auto capture needs stable readable frames.
- Quality score copy is plain-language.
- Tap-to-focus copy matches real behavior.
- Best-photo candidate selection does not confuse single-photo flow.

Done:
- Camera helps the user get a clear photo but does not fight them.
- Tapping the shutter now always uses the manual capture path, even when assisted or auto capture is active.
- Auto capture remains available only after stable readable frames meet the stricter auto policy.
- Focused analyzer and camera layout/quality tests guard the behavior.

### Pass 27 of estimated 55: Receipt Review Action Surface

Status: complete.

Goal:
- Make the after-photo review screen feel like a professional receipt scanner, not a hidden scroll panel.

Scope:
- Single-photo review should say `Review Receipt Photo`, not `Choose the best receipt photo`.
- The primary action should be visible as `Read Receipt` or `Use Photo`.
- Compact controls should not bury the continue action.
- Multi-photo controls should explain adding another photo and reading the full receipt.
- Saved-copy wording should be plain-language and not sound like a final save.

Done:
- User can take one photo and immediately see how to continue.
- User can add another receipt section for a long receipt without confusing it with saving the expense.
- Focused review tests cover the single-photo and multi-photo wording.
- Single-photo review now says `Review receipt photo` and `Review receipt photo, then read it.`
- Multi-photo review now says `receipt sections` and makes order/read intent clearer.
- `Saved copy` / `Save Space` UI copy is replaced with `Backup image` / `Backup Size`.
- Focused analyzer and review/help/assisted-flow tests pass.

### Pass 28 of estimated 55: Receipt Review Flow Routing

Status: complete.

Goal:
- After photo review, app-assisted receipts should continue into parsed receipt review instead of dumping the user back into an attachment-only state.

Scope:
- Confirm photo-review result returns OCR source paths, saved proof paths, stitch metadata, and quality metadata.
- Confirm expense receipt import reads reviewed photos immediately when app-assisted fill is on.
- Confirm success copy tells the user to review parsed lines, not simply that a photo attached.
- Confirm manual/no-assist mode can still attach proof photos without forcing OCR.
- Keep the route scoped to expenses and shared receipt capture, avoiding maintenance-specific flows.

Done:
- Assisted expense receipt photo flow reads the receipt and lands the user in review/classification.
- Manual proof-only flow still works.
- Focused tests cover both routes.
- Reviewed photos now report that parsed lines should be reviewed below after OCR finishes.
- Tests guard app-assisted opt-out, missing imported-text callback, empty OCR sources, and OCR-before-cleanup ordering.

### Pass 29 of estimated 55: Long Receipt Section Guardrails

Status: complete.

Goal:
- Help users capture long receipts in readable top-to-bottom sections without mixing up order or squeezing tiny text into one blurry photo.

Scope:
- Keep previous-section ghost guide when adding/retaking later sections.
- Make single-photo and multi-photo review copy explain sections plainly.
- Keep ordering controls available only when needed.
- Keep stitching optional with safe fallback to reading ordered photos separately.
- Avoid blocking receipt save when stitch confidence is low.

Done:
- Long receipt users can add sections, check order, review stitch, and still continue if stitching is not confident.
- Focused tests guard the section flow and fallback wording.
- Adding or retaking into multiple receipt sections now opens the photo-order review step automatically.
- Previous-section guide handoff remains wired into add/retake camera launches.
- Focused analyzer and camera/stitching tests pass.

### Pass 30 of estimated 55: Receipt Review Device UI Batch

Status: deferred until user asks for device install.

Goal:
- Put the current camera/review UI batch on the S24 Ultra only after the bundled review changes are worth inspecting.

Scope:
- Build/install debug app only if the S24 is available and user wants the UI batch.
- Do not uninstall unrelated Maintainiac builds.
- Verify the app launches.
- Let user inspect live camera, after-photo review, add-section order flow, and read-receipt handoff.

Done:
- S24 Ultra has the latest meaningful UI batch for review.
- Any device-only defects are listed as the next UI pass.

### Pass 31 of estimated 55: Separate OCR Fallback Guardrails

Status: complete.

Goal:
- Make ordered separate-photo OCR safer for long receipts when stitching is unavailable, low-confidence, or intentionally skipped.

Scope:
- Suppress true section-boundary overlap.
- Do not remove legitimate duplicate item lines inside the same section.
- Do not remove legitimate duplicate item lines that appear later in a different section when they are not overlap.
- Warn when neighboring receipt sections have no repeated text and may be missing a middle section.
- Keep raw text intact for proof/review while parser text is cleaned for app-assisted fill.

Done:
- OCR overlap suppression is boundary-aware instead of global.
- Missing section gaps now create a review warning without changing text.
- Legitimate duplicate item lines are preserved.
- Focused analyzer and OCR long-receipt tests pass.

### Pass 32 of estimated 55: OCR Diagnostics Hardening

Status: complete.

Goal:
- Make OCR outcomes explainable without exposing private receipt content.

Scope:
- Confirmed warning kinds for duplicate overlap, possible section gap, photo quality, skipped proof-only sources, PDF safety, PDF too large, unreadable files, plugin unavailable, and no readable text.
- Diagnostics should summarize severity, counts, source type, and review needs without storing receipt text.
- Command One-safe health data should remain content-free.

Done:
- OCR diagnostics clearly say what failed or needs review and why.
- Focused diagnostics tests cover warning kinds and severity.
- OCR diagnostics now expose privacy-safe warning-kind counts.
- Expense OCR review records persist warning-kind counts through draft, ledger, and Firestore-shaped receipt backups.
- Section-gap OCR warnings map to `possible_missing_receipt_section` instead of a vague or duplicate-text cause.
- Focused analyzer and OCR diagnostics/storage tests pass.

### Pass 33 of estimated 55: Parser Field Confidence Hardening

Status: complete.

Goal:
- Improve receipt parser confidence for merchant, date, subtotal, tax, total, payment, and receipt identifiers without trusting bad OCR too quickly.

Scope:
- Merchant/date/total confidence labels.
- Explicit subtotal/tax/total reconciliation.
- Fuel, retail, and trade-supply receipt field patterns.
- Negative/return lines should be understood as adjustments, not confidence penalties by themselves.
- Parser warnings should remain content-safe for diagnostics.

Done:
- Parser field extraction has clearer confidence and review reasons.
- Focused parser tests cover core field extraction and suspicious math.
- Parse results and diagnostics now expose field confidence for merchant, date, time, subtotal, tax, total, line items, and receipt math.
- Known merchant profiles, OCR dates, explicit totals, inferred totals, fallback dates, and line/math reconciliation now get distinct review reasons.
- Focused analyzer and parser torture tests pass.

### Pass 34 of estimated 55: Parser Review Failure Reasons

Status: complete.

Goal:
- Make parser failures and review states explain exact root causes in plain language for receipt review and future Command One metrics.

Scope:
- Normalize parser warning kinds without storing receipt content.
- Distinguish missing fields, inferred fields, line mismatch, subtotal/tax/total mismatch, too many low-confidence lines, and catalog/material review.
- Keep negative coupon/discount/return lines from lowering confidence when they reconcile.
- Make tests prove the failure reason points at the exact failing parser stage.

Done:
- Receipt parser review reasons are specific enough to route UI help and diagnostics.
- Focused parser tests cover missing, mismatched, inferred, and low-confidence receipt states.
- Parser diagnostics now distinguish inferred subtotal/tax/total and fallback receipt dates from generic low confidence.
- Parser failure evidence includes content-free field review labels for Command One summaries.
- Focused analyzer, parser diagnostics, parser, and expense telemetry tests pass.

### Pass 35 of estimated 55: Parser Review UI Guidance

Status: complete.

Goal:
- Surface parser field confidence and exact review causes in the assisted receipt review UI using plain language.

Scope:
- Show user-facing parser guidance without raw diagnostic jargon.
- Prioritize merchant/date/total/math/line review warnings.
- Keep private receipt content out of telemetry and diagnostics.
- Avoid changing maintenance-specific receipt behavior.

Done:
- Assisted receipt review explains what needs checking and why.
- Focused UI or widget tests cover the guidance surface.
- Receipt entry now stores the latest parser field confidences and clears stale confidence state when loading drafts or saved receipts.
- Receipt Fill Review now shows a compact `Fields to check` summary with plain-language merchant/date/total/math/line guidance.
- Focused analyzer and assisted review/parser tests pass.

### Pass 36 of estimated 55: Privacy-Safe Parser Health Metrics

Status: complete.

Goal:
- Feed parser field confidence and review causes into local telemetry summaries without storing receipt text or private item details.

Scope:
- Add content-free parser field review counts where telemetry already tracks parser outcomes.
- Include exact parser cause buckets for inferred totals, fallback dates, receipt math, line mismatch, and line review.
- Keep raw receipt text, merchant names, addresses, notes, and item descriptions out of telemetry.

Done:
- Expense telemetry can summarize parser health by field/cause.
- Focused privacy tests prove no private receipt content is stored.
- Privacy-safe receipt parse events now include parser review cause and field review keys.
- Command Center health snapshots now count parser review causes and field review keys without merchant names, receipt text, item names, or amounts.
- Existing app-assisted parse flow already queues these privacy-safe parse events.
- Focused analyzer, receipt privacy, parser diagnostics, and expense telemetry tests pass.

### Pass 37 of estimated 55: Receipt Backup Image Pipeline Audit

Status: complete.

Goal:
- Confirm the receipt image pipeline reads OCR from the best available image first, then creates space-saving backup copies without making OCR worse.

Scope:
- Audit original/captured image, enhanced image, stitched image, backup-size preview, and saved proof path.
- Ensure OCR is not forced to read only from heavily compressed backup copies.
- Keep backup/storage wording user-friendly: save space, backup image, phone/cloud storage.
- Add tests around OCR-before-backup-copy behavior where practical.

Done:
- Receipt photo proof storage remains lean without sacrificing OCR input quality.
- Focused tests document the order of operations.
- `ReceiptImageProcessor.prepareForOcrAndBackup` now makes the clean OCR source and smaller backup copy explicit outputs.
- Photo review save uses the clean OCR source for reading and the backup copy for stored proof.
- Focused analyzer and image/camera review tests pass.

### Pass 38 of estimated 55: Receipt Proof Storage And Backup Metadata

Status: complete.

Goal:
- Make saved receipt proof metadata clear enough for local storage, export, cloud backup, and Command One cost/health reporting.

Scope:
- Audit saved proof records for data saver level, byte size, source type, staged/permanent path handling, and cloud-safe fields.
- Confirm optimized receipt proof paths are kept out of Firestore backup documents.
- Confirm local proof files remain recoverable for drafts and saved receipts.
- Avoid changing maintenance-specific receipt behavior.

Done:
- Receipt proof records preserve storage-size metadata without syncing private local paths.
- Focused storage and Firestore document tests pass.
- Firestore receipt proof pointers now include backup byte size and a safe backup size bucket for cost/storage health reporting.
- Local proof paths, raw OCR, imported proof text, and raw line OCR remain excluded from backup documents.
- Focused analyzer, Firestore backup, and proof storage lifecycle tests pass.

### Pass 39 of estimated 55: Receipt PDF OCR Safety Review

Status: complete.

Goal:
- Harden receipt PDF input so readable PDFs work, unsafe PDFs stay proof-only, and older phones avoid expensive PDF work.

Scope:
- Audit PDF inspection, page limits, timeout behavior, and OCR warning mapping.
- Confirm PDF proof storage remains read-only and cloud backup metadata stays lean.
- Confirm unreadable or unsafe PDFs never block saving the receipt proof.
- Keep invoice PDF generation separate from receipt PDF import unless a shared utility is clearly appropriate.

Done:
- PDF receipt import behavior is predictable, bounded, and explainable.
- Focused PDF OCR/proof tests pass.
- OCR service now tracks planned PDF page work before reading instead of assuming every PDF read used the maximum page cap.
- Device-specific PDF page-limit warnings explain when only the front pages will be read while the full PDF remains saved as read-only proof.
- Focused analyzer plus OCR/PDF/share/proof torture tests pass.

### Pass 40 of estimated 55: Receipt Import Failure Recovery

Status: complete.

Goal:
- Make failed receipt import/reading states recoverable without losing proof attachments or trapping the user in the wrong screen.

Scope:
- Audit photo/PDF/imported-text failure branches after app-assisted reading.
- Confirm failed OCR does not discard attachments, staged proof records, or user-entered receipt info.
- Confirm retry/manual-entry messaging uses plain receipt language and avoids developer terms.
- Keep maintenance-specific receipt flows untouched.

Done:
- Failed receipt reading leaves the user with proof saved, clear recovery choices, and no duplicate staged attachments.
- The attachment panel now has separate reading, success, warning, and failed visual states.
- Receipt-reading failures now keep clear plain-language recovery copy: keep proof, try another photo, retake, or continue manually.
- The add-more action after proof exists now says `Add More Proof` instead of implying a new receipt.
- Focused analyzer plus attachment/OCR/PDF import tests pass.

### Pass 41 of estimated 55: Receipt Review Classification Completion

Status: complete.

Goal:
- Finish the app-assisted receipt review handoff so a read receipt naturally lands on business/personal/mixed classification with line-level review instead of feeling like a plain attachment return.

Scope:
- Audit the expense receipt review panel for whole-receipt classification, mixed receipt line controls, and split tax/total recap.
- Make sure simple mode and detailed mode wording is plain and receipt-specific.
- Confirm OCR success routes to review and failure routes to recover/manual entry.
- Keep the separate detailed item editor route; do not rebuild it inline.

Done:
- After receipt reading succeeds, the user can classify the receipt and its lines without guessing what screen they are on.
- Assisted review order now starts with `What Maintainiac Found`, then whole-receipt classification, then parser line evidence, then the totals recap.
- The review copy now tells the user to check store, date, totals, and line confidence before saving.
- Focused analyzer, assisted review, parser, and parser diagnostic tests pass.

### Pass 42 of estimated 55: Receipt Data Saver Preview Completion

Status: complete.

Goal:
- Make receipt save-space choices understandable and previewable without making users learn image-compression terms.

Scope:
- Audit data saver wording, preview sizes, backup image labels, and review controls.
- Confirm OCR uses the best available source before backup-size reduction.
- Confirm users can understand what is stored locally/cloud-backed versus what is used temporarily for reading.
- Keep the data saver settings out of the way of receipt crop/review.

Done:
- Users can pick a storage-saving receipt proof level with clear language and without hurting OCR accuracy.
- Data saver copy now uses `saved proof` language instead of making users think about compression.
- Photo review and settings now explain that OCR uses the clear photo first, then the smaller proof copy is kept.
- The saved-proof preview panel now labels the actual kept image and storage details clearly.
- Focused analyzer plus camera help, data-saver image, and camera layout tests pass.

### Pass 43 of estimated 55: Receipt Save Readiness Guardrails

Status: complete.

Goal:
- Prevent users from saving confusing assisted receipts without clear line, classification, proof, and review state.

Scope:
- Audit save validation for parsed lines, missing proof, unreviewed parser lines, mixed receipt allocations, and subtotal/tax/total math.
- Keep warnings plain-language and actionable.
- Confirm save guardrails do not block simple manual expense entry unnecessarily.
- Keep maintenance-specific save behavior untouched.

Done:
- Expense receipt save gives clear reasons when the receipt needs another review step before saving.
- Save readiness now runs before duplicate detection, proof persistence, and ledger save.
- The readiness dialog explains unreviewed app-filled lines, OCR no-text/blocking/partial/review warnings, and receipt subtotal versus line subtotal mismatches.
- The user can review the receipt or save anyway after verification; simple manual entry is still only hard-blocked when no lines exist.
- Abandoned readiness review records privacy-safe telemetry with confirmed issue kinds, not receipt content.
- Focused analyzer plus assisted review, telemetry, and duplicate-save tests pass.

### Pass 44 of estimated 55: Saved Receipt Detail And Calendar Recovery

Status: complete.

Goal:
- Make saved receipt review from calendar/detail screens preserve the same proof, OCR review, classification, totals, and edit context the user just created.

Scope:
- Audit saved expense receipt detail and calendar entry routes.
- Confirm proof thumbnails/PDF pointers open without losing receipt context.
- Confirm business/personal/split totals and receipt OCR review metadata are visible in plain language.
- Confirm edit routes reuse the receipt flow instead of creating a disconnected duplicate path.
- Keep maintenance-specific receipt handling untouched.

Done:
- A saved receipt can be found later, reviewed, understood, and edited without losing app-assisted receipt context.
- Calendar day entries and home ledger rows now open saved receipt detail first instead of immediately dropping into edit mode.
- Saved receipt detail now shows a receipt breakdown with business total, personal total, split-line count, proof count, and OCR/read status.
- Saved receipt line totals use the receipt's allocated total so tax/adjustment context is preserved during later review.
- Saved receipt photos are tappable and open a pinch-zoom proof viewer; saved PDFs still open the PDF proof viewer.
- Focused analyzer plus saved receipt detail, assisted review, and telemetry tests pass.

### Pass 45 of estimated 55: Receipt Calendar Add/Edit/Delete Diagnostics

Status: complete.

Goal:
- Make calendar-side receipt actions explain exactly what failed and keep Command One-ready diagnostics privacy-safe.

Scope:
- Audit add-line, edit-line, copy-line, delete-line, full-receipt edit, and delete-receipt paths from saved receipt detail/calendar.
- Confirm each action records success/failure where appropriate without private receipt content.
- Confirm failures show plain recovery messages instead of silent no-ops.
- Confirm calendar entries stay chronological by receipt date/time after edits.
- Keep maintenance-specific receipt behavior untouched.

Done:
- Calendar-side receipt edits are observable, recoverable, and do not silently fail.
- Calendar receipt delete, line edit, line copy, and line delete failures have distinct confirmed-cause diagnostics for future Command One health views.
- Calendar-side recovery copy is source-guarded so failures remain plain-language instead of silent.
- The telemetry aggregation test now covers all four calendar receipt action failure causes.
- Focused analyzer plus saved receipt detail, assisted review, and telemetry tests pass.

### Pass 46 of estimated 55: Receipt Export Proof Bundle Readiness

Status: complete.

Goal:
- Make exported receipt records preserve proof status, OCR review status, business/personal totals, and line details without bloating user data.

Scope:
- Audit expense export models and file writer for receipt proof metadata.
- Confirm exports can include proof references/counts without embedding giant private images by default.
- Confirm business, personal, split, tax, and total fields match saved receipt detail.
- Confirm export events distinguish completed, blocked, and failed outcomes.
- Keep invoice/maintenance PDF export behavior untouched.

Done:
- Expense receipt export data is complete enough for recordkeeping while staying storage-conscious.
- Receipt CSV now includes proof count, proof types, saved proof byte total, OCR review status, OCR warning count, parser line count, and requested PDF pages.
- Export manifests now summarize proof count, proof bytes, missing-proof receipts, OCR-reviewed receipts, and receipts needing OCR review.
- Export privacy notes state that raw OCR text and receipt images are not embedded by default.
- Existing line export keeps tax-adjusted totals, business amounts, personal amounts, and split percentages.
- Focused analyzer plus export and telemetry tests pass.
