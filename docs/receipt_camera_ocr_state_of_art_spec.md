# Receipt Camera OCR State Of Art Spec

This file is the working spec for finishing Maintainiac's receipt camera, scanner, OCR, parsing, PDF/text extraction, and app-assisted expense review system.

The goal is not to clone another product. The goal is to combine the best product lessons from strong scanner and expense apps, then add Maintainiac-specific business logic.

## Native Camera Reset

The previous decision to use the phone's stock camera surface as the production receipt capture path is revoked.

Maintainiac must own the receipt camera UI and UX. Android receipt capture should be built on CameraX through a Maintainiac native bridge. iOS receipt capture should be built on AVFoundation through the same Maintainiac service contract. Flutter may render the Maintainiac screen and call the bridge, but Flutter `camera` is not the production camera engine and Samsung/Apple camera apps are not the production capture UI.

The native rebuild contract lives in `docs/receipt_native_camera_service_spec.md`.

## North Star

Maintainiac should let a driver, contractor, or small business owner:

1. Capture a clear receipt photo quickly.
2. Add more photos for a long receipt without confusion.
3. Let the app clean, crop, stitch, OCR, and parse the receipt.
4. Review what the app found.
5. Mark the whole receipt or each line as business, personal, or split.
6. Save a local-first expense record with readable proof and privacy-safe diagnostics.

Clear image comes first. OCR comes second. Storage saving comes third.

OCR must use the clearest prepared source image available before the app creates a smaller backup proof image.

## Product Benchmarks

### Adobe Scan Lane - Image Cleanup

Maintainiac should learn from Adobe Scan's document cleanup:

- Edge detection.
- Auto-crop.
- Perspective correction.
- Straightening.
- Shadow reduction.
- Paper tint cleanup.
- Clean black-and-white or grayscale document look.
- Readable final proof image.

### Microsoft Lens Lane - Camera Experience

Maintainiac should learn from Microsoft Lens' capture feel:

- Fast capture.
- Easy framing.
- Controls on the edges.
- Tap-to-focus.
- Pinch-to-zoom.
- Manual capture always works.
- Guidance helps without blocking the user.
- The user should not feel like they are operating a developer tool.

### Expensify Lane - Receipt Intelligence

Maintainiac should learn from Expensify's receipt extraction:

- Merchant detection.
- Date and time detection.
- Subtotal, tax, total, payment, returns, discounts, and negative-line handling.
- Line amount extraction.
- Receipt-to-expense workflow.
- Confidence and correction workflow.
- Local correction learning.

### Genius Scan Lane - Long Receipt Workflow

Maintainiac should learn from Genius Scan's multi-page workflow:

- Batch capture.
- Add another photo without annoyance.
- Clear photo order.
- Long receipt section guidance.
- Stitch when confident.
- Fall back to ordered separate OCR when stitching is not safe.

### Scanner Pro / CamScanner Lane - Polish

Maintainiac should borrow polish lessons:

- Smooth review screens.
- Clean filter previews.
- Small, obvious controls.
- Fast transitions.
- Professional scan feel.
- PDF output and document export after the camera flow is stable.

### Maintainiac Lane - Business Logic

Maintainiac must go beyond generic scanner apps:

- Whole receipt business/personal/mixed classification.
- Simple price-only review mode.
- Detailed line-item review mode.
- Split percentages.
- Tax allocation across business/personal/split lines.
- Vehicle/profile awareness.
- Materials/inventory opt-in.
- Local-first storage.
- Privacy-safe diagnostics.

## Hard Rules

- Do not block manual capture because automatic guidance is uncertain.
- Do not OCR the smaller saved proof image when a cleaner OCR source exists.
- Do not hide the receipt behind a large bottom panel.
- Do not return the user to an attachment list when app-assisted review is expected.
- Do not require Google Play Services document-scanner downloads before a user can photograph a receipt.
- Do not work on PDF before the camera/photo review path is stable unless the active pass explicitly says PDF.
- Do not work on maintenance receipt parsing until the shared camera flow is ready.
- Do not expose raw device capability details in normal user UI.
- Do not silently update inventory from an expense receipt.
- Do not store private receipt text/images in analytics.

## Realistic Pass Budget

As of this spec reset, the active numbered pass is **Pass 112**.

The full receipt system is now capped at **300 total passes** for tracking, but the work stops earlier if the system is actually proven. The cap is not a target. It is a guardrail that gives enough room for camera polish, image cleanup, OCR, parsing, PDF/text import, diagnostics, stress testing, and real-device QA without pretending the job is smaller than it is.

Expected remaining work from Pass 112:

- **Camera/photo review only:** about 30-45 more serious passes.
- **Image cleanup, crop, edge, stitch hardening:** about 20-30 more serious passes.
- **OCR/parser/review/classification:** about 25-35 more serious passes.
- **PDF/text/invoice handoff after camera is stable:** about 10-18 more serious passes.
- **Diagnostics, storage, security, QA, real-device polish:** about 15-25 more serious passes.

That puts the realistic remaining range around **95-140 serious bundled passes** from this point, with the likely finish around **Pass 210-270** if no major product decision changes the scope.

## Pass Cadence

- Report every pass as `Pass NN`.
- Keep the current file set narrow.
- Bundle related work safely.
- Run focused tests often.
- Run full builds after meaningful UI/lifecycle/parser batches.
- Push/install to devices only when requested or after a meaningful UI batch.
- Keep the active goal open until the system is proven against this spec.

## Master Pass Map

### Phase 1 - Spec Reset And Current Stability

**Pass 112 - Master Receipt System Spec Reset**
- Create this spec.
- Update the master plan to use the 300-pass cap.
- Finish verification from the previous camera lifecycle pass.

**Pass 113 - Expense Receipt Review Detail Settings Contract**
- Surface the existing simple-vs-detailed expense receipt review default inside
  Expense Receipt Settings.
- Use plain wording: show prices only, or show full item details.
- Reuse `ExpenseReceiptReviewStyle` so settings and receipt review stay in
  sync.

**Pass 114 - Native Capture And Long Receipt Overlay Decision**
- Confirm production Android receipt capture uses Maintainiac UI over CameraX,
  not the phone camera app.
- Confirm production iOS receipt capture uses Maintainiac UI over AVFoundation,
  not Apple Camera.
- Confirm Flutter `camera` is not the production engine.
- Define the native service contract for long-receipt ghost overlap, camera
  settings, safe capture, and OCR source handoff.

Decision:
- The production path is a Maintainiac-native receipt camera.
- Android uses CameraX through the Maintainiac native bridge.
- iOS uses AVFoundation through the Maintainiac native bridge.
- Stock phone camera apps are fallback/import paths only.
- Long receipt overlap, ghost guides, live edge signals, and capture settings
  belong in Maintainiac's UI/service contract.
- Existing OCR, image processing, stitching, and review work should be reused
  where it is correct.

**Pass 115 - Camera Permission And Fallback UX**
- Make permission denial, settings recovery, scanner fallback, and camera unavailable states plain and usable.
- Avoid raw developer wording.

### Phase 2 - Microsoft Lens Camera Experience

**Pass 116 - Capture Surface Edge Layout**
- Keep back, settings, flash, and primary shutter in professional positions.
- Remove or hide nonessential clutter.
- Ensure top controls never sit in the middle of the camera view.

**Pass 117 - Pinch Zoom And Continuous Focus Contract**
- Verify pinch-to-zoom during live capture.
- Verify continuous autofocus, sharpness/readability guidance, and exposure
  behavior.
- Add fallback messaging only when a device truly cannot support it.

**Pass 118 - Brightness And Exposure Baseline**
- Investigate why Maintainiac images can look darker than native camera output.
- Remove harmful exposure assumptions.
- Add safe exposure compensation only when supported and beneficial.

**Pass 119 - Manual Shutter Always Works**
- Ensure manual capture fires even if guidance is not satisfied.
- Auto capture must be optional and conservative.

**Pass 120 - Live Guidance Tone And Timing**
- Replace noisy guidance with short useful instructions.
- Guidance should say what to do next, not scold.

**Pass 121 - Capability-Based Camera Settings**
- Use device capability to choose safe capture defaults.
- Older devices get safer preview/live-analysis settings.
- Strong devices can use heavier live assistance.

**Pass 122 - First-Use Camera Setup**
- Explain assisted receipt capture, long receipts, save-space preview, and privacy once.
- Keep setup skippable and editable later.

**Pass 123 - Camera UI Device Batch**
- Run S24/S25/S9-class layout checks when devices are available.
- Fix obvious layout issues before deeper OCR work.

### Phase 3 - Photo Review And Scanner Pro Polish

**Pass 124 - Post-Capture Review Layout**
- Make the receipt image about 75-80 percent of the screen where possible.
- Keep bottom controls compact.
- Make primary action obvious.

**Pass 125 - Review Top Bar And Exit Polish**
- One clear back/close path.
- No duplicate confusing back/X controls.
- No trapped route.

**Pass 126 - Thumbnail Strip And Photo Count**
- Show small ordered thumbnails for multiple receipt sections.
- Make `Add Another Photo` plain text/icon enough to be understood.

**Pass 127 - Single Photo Review Simplification**
- Do not say "choose best photo" when there is only one photo.
- Show quality and next action in plain language.

**Pass 128 - Long Receipt Review Simplification**
- Make top-to-bottom order visible.
- Make retake/remove/reorder actions clear.

**Pass 129 - Save-Space Preview UX**
- Use "Receipt Backup Image Size" or save-space language, not compression jargon.
- Show expected size and visual preview.
- Keep OCR source separate from backup proof.

**Pass 130 - Crop Review Usability**
- Make crop handles reachable.
- Ensure the receipt bottom is visible and editable.
- Avoid controls blocking crop edges.

**Pass 131 - Filter Preview Usability**
- Provide readable preview modes: original, clean grayscale, high contrast, black and white.
- Default to the best OCR-safe clean source.

**Pass 132 - Review Animation And Responsiveness**
- Remove laggy interactions.
- Keep transitions simple and smooth.

### Phase 4 - Adobe Scan Image Cleanup

**Pass 133 - Image Quality Measurement Audit**
- Revisit blur, brightness, contrast, skew, crop, and readability scoring.
- Stop rejecting good images for weak reasons.

**Pass 134 - Receipt Bounds Detection**
- Improve receipt paper/text region detection without blocking save.
- Detect probable missing top/bottom edges as warnings.

**Pass 135 - Auto-Crop Foundation**
- Generate a suggested crop from detected bounds.
- Always allow manual correction.

**Pass 136 - Perspective Correction Foundation**
- Add perspective/deskew preparation where safe.
- Fall back to original when correction confidence is low.

**Pass 137 - Shadow And Tint Cleanup**
- Improve grayscale, contrast, paper tint, and shadow reduction for OCR.

**Pass 138 - Clean Proof Generation**
- Produce readable saved proof variants after OCR source prep.
- Respect selected backup size.

**Pass 139 - Enhancement Safety Gates**
- Compare enhanced source against original.
- Keep original OCR source fallback when enhancement makes text worse.

**Pass 140 - Image Cleanup Test Fixtures**
- Add synthetic and real-like receipt image fixtures for blur, skew, shadows, wrinkles, and faded ink.

### Phase 5 - Genius Scan Long Receipt And Stitching

**Pass 141 - Long Receipt Capture Guidance**
- Tell users not to squeeze tiny text into one photo.
- Encourage readable sections from top to bottom.

**Pass 142 - Section Overlap Guide**
- Show previous section ghost/overlap guidance when adding another photo.
- Keep it visual and nonblocking.

**Pass 143 - Stitch Confidence Audit**
- Validate overlap matching with duplicate lines, missing overlap, zoom differences, and lighting changes.

**Pass 144 - Manual Stitch Adjustment**
- Let users adjust overlap if automatic stitch is unsure.
- Keep fallback easy.

**Pass 145 - Stitched Image Review**
- Show the full stitched receipt when confident.
- Let user inspect/zoom before moving on.

**Pass 146 - Ordered Separate OCR Fallback**
- If stitch confidence is low, OCR photos separately in top-to-bottom order.
- Deduplicate overlap lines.

**Pass 147 - Long Receipt Memory Limits**
- Enforce old-device limits.
- Avoid giant stitched images on weak devices.

**Pass 148 - Long Receipt Stress Tests**
- Test 2, 3, 5, and many-photo receipts.
- Test overlap, out-of-order photos, removed photo, retake, and mixed zoom.

### Phase 6 - Expensify OCR And Parser Intelligence

**Pass 149 - OCR Source Contract**
- Ensure every photo/PDF/text import routes through shared OCR source models.
- OCR uses prepared source, not saved backup proof.

**Pass 150 - OCR Failure Cause Model**
- Record confirmed failure causes: blur, glare, too small text, timeout, no text, corrupt file, unsupported file, page limit.

**Pass 151 - Merchant Detection Hardening**
- Improve merchant aliases and regional vendor support without private analytics content.

**Pass 152 - Date/Time Detection Hardening**
- Handle multiple date formats, transaction date versus printed/return-policy dates.

**Pass 153 - Totals And Tax Hardening**
- Parse subtotal, tax, total, payment, balance, discounts, and returns.

**Pass 154 - Negative Line Semantics**
- Treat negative lines as returns, coupons, discounts, refunds, deposits, or corrections, not automatic confidence penalties.

**Pass 155 - Line Item Extraction**
- Extract item description, amount, quantity, package, unit price, SKU when present.

**Pass 156 - Simple Price-Only Review**
- Let users review only line prices and classify them quickly.

**Pass 157 - Detailed Line Review**
- Let users open detailed item fields when they need them.

**Pass 158 - Parser Confidence And Review Reasons**
- Show user-safe confidence reasons and what needs review.

**Pass 159 - Local Correction Learning**
- Remember corrected merchant, category, item, quantity/package, and line meaning locally.

**Pass 160 - Parser Test Matrix**
- Add Lowe's, Home Depot, Walmart, fuel, truck stop, regional convenience, returns, coupons, tax, and split fixtures.

### Phase 7 - Maintainiac Classification And Expense Save

**Pass 161 - Whole Receipt Classification**
- Business, personal, mixed at the receipt level.
- Fast save path for all-business or all-personal.

**Pass 162 - Mixed Line Classification**
- Business/personal/split per parsed line.
- Fast bulk actions.

**Pass 163 - Split Percentages**
- Support line-level split percentage and amount.
- Default 50/50 only when user chooses split without detail.

**Pass 164 - Tax Allocation**
- Allocate tax across business/personal/split based on taxable line amounts.

**Pass 165 - Vehicle/Profile Awareness**
- Attach vehicle/profile context when appropriate.
- Respect business/personal vehicle usage.

**Pass 166 - Materials/Inventory Opt-In Boundary**
- Expense material receipts stay expenses unless user opts into inventory.
- Inventory changes remain staged until confirmed.

**Pass 167 - Save Readiness Guardrails**
- Do not save incomplete or contradictory expense records.
- Explain what the user must fix.

**Pass 168 - Calendar And Backdated Expense Consistency**
- Backdated receipt saves update daily/weekly/monthly/90-day/year summaries correctly.

### Phase 8 - PDF/Text/Invoice Extraction After Camera Stability

**Pass 169 - Imported Text OCR Parity**
- Imported text uses the same parser/review path as camera OCR.

**Pass 170 - Receipt PDF Extraction**
- Extract text from receipt PDFs.
- Convert scanned PDFs through OCR where needed.

**Pass 171 - Invoice PDF Extraction Boundary**
- Route invoice PDFs without mixing expense receipt assumptions.

**Pass 172 - PDF Page Limits And Timeouts**
- Enforce device-safe and plan-safe limits.
- Explain failures.

**Pass 173 - PDF Proof Storage Policy**
- Store compact proof/metadata, not bloated duplicate PDFs when structured data can recreate the view.

**Pass 174 - PDF Test Matrix**
- Native text PDFs, scanned PDFs, multi-page PDFs, damaged PDFs, password/error cases.

### Phase 9 - Storage, Backup, Diagnostics, Security

**Pass 175 - Local-First Receipt Data Model Audit**
- Confirm Hive/local record is primary.
- Cloud backup remains mirror/sync, not source of truth.

**Pass 176 - Receipt Backup Size Enforcement**
- Enforce tiny/low/normal/high backup targets.
- Keep original temporary/local-only unless user explicitly keeps it.

**Pass 177 - Offline Queue And Sync Diagnostics**
- Queue receipt telemetry and backup events locally.
- Summarize later without private content.

**Pass 178 - Expense Screen Telemetry**
- Track opened, abandoned, saved, failed, OCR started/completed/failed, correction opened, correction saved, sync state.

**Pass 179 - OCR/Parser Diagnostic Events**
- Track engine, processing time, confidence, failure step, cause, device tier, app version.
- Do not track raw receipt text or images.

**Pass 180 - Abuse And Security Hooks**
- Add task-level abuse hooks for AI/OCR misuse later.
- Security telemetry may identify account/device enough to enforce limits.

**Pass 181 - Firestore Cost Shape Review**
- Ensure future sync/backup does not write one document per tiny line when bundled daily/receipt docs are better.

### Phase 10 - Real Device And Synthetic QA

**Pass 182 - Synthetic Receipt Generator**
- Create legal synthetic receipt fixtures for stores, fuel, returns, coupons, long receipts, faded/wrinkled OCR text.

**Pass 183 - Camera Regression Widgets**
- Guard layout, wording, control density, and next-step routing.

**Pass 184 - Image Processing Unit Tests**
- Test cleanup, crop, stitch, fallback, size targets, and OCR source selection.

**Pass 185 - Parser Regression Tests**
- Test merchant, date, total, tax, lines, negative lines, categories, and split math.

**Pass 186 - Expense Save Integration Tests**
- Prove app-assisted receipt review creates the right expense records.

**Pass 187 - Low-End Device Stress**
- Simulate memory/time limits for S9-class devices.

**Pass 188 - Flagship Device Quality Stress**
- Test high-resolution inputs without bloating backup storage.

**Pass 189 - iOS Receipt Flow Audit**
- Verify iPhone camera/scanner behavior and fallback paths.

**Pass 190 - Android Receipt Flow Audit**
- Verify Android native camera/document fallback behavior.

**Pass 191 - Real Receipt Manual QA Batch**
- Test real Lowe's, Walmart, fuel, wrinkled, faded, long, and folded receipts.

**Pass 192 - Accessibility And Plain-Language QA**
- Check labels, tap targets, readable copy, no developer jargon.

**Pass 193 - Performance QA**
- Check capture latency, OCR latency, parser latency, save latency, memory, and file size.

**Pass 194 - Privacy QA**
- Verify no private content goes to diagnostics.
- Verify saved proof policy and local cleanup.

**Pass 195 - Command Center Telemetry Contract**
- Ensure the user-facing app emits the summarized health data Command 1 needs later.

### Phase 11 - Final Hardening

Final hardening details were archived to keep the active state-of-art spec under the 500-line file limit.

- Archive: `docs/receipt_camera_ocr_state_of_art_spec_archive_final_hardening.md`.
