# Receipt Camera And OCR Product Standard

Maintainiac receipt capture is not a generic scanner. The goal is a worker-grade receipt system that lets a driver, contractor, or small business owner capture proof, let the app fill a reviewable receipt form, classify business/personal/mixed use, and save the record quickly without hiding important details.

## Product Targets

- Clear image first, OCR second, storage saving third.
- Maintainiac owns the production receipt camera UI; Android uses CameraX and
  iOS uses AVFoundation under a Maintainiac service bridge.
- Stock phone camera apps are fallback/import paths, not the normal receipt
  camera.
- OCR must read from the cleanest prepared source image before any saved-copy size reduction.
- Saved receipt images are optimized for storage and backup after OCR has had the best available image.
- The receipt image is the workspace. Controls must stay small, edge-anchored, and out of the way.
- The default review preview should keep roughly 75-80 percent of the screen height available for the receipt whenever possible.
- Long receipts are expected. Multi-photo capture and stitching are normal workflow, not an edge case.
- If stitching is not confident, the app must safely review photos separately in order.
- The user must always know the next step: add another photo, crop, stitch, save space, or fill the receipt review.
- App-assisted receipt fill must lead into receipt review/classification, not dump the user back into an attachment list.

## Benchmark Lessons

### Adobe Scan Standard

Use this as the image cleanup benchmark.

- Automatic crop should be helpful but never trap the user.
- Perspective correction and straightening should improve readability.
- Shadows, paper tint, and low contrast should be reduced during OCR preparation.
- Final saved proof should look clean and readable.

### Microsoft Lens Standard

Use this as the camera experience benchmark.

- Capture should feel fast and obvious.
- Android receipt capture should use Maintainiac UI backed by CameraX.
- iOS receipt capture should use Maintainiac UI backed by AVFoundation.
- Do not send users through a Play Services scanner download before they can photograph a receipt.
- Camera controls belong on screen edges.
- Manual shutter must always work, even when automatic guidance is uncertain.
- Tap-to-focus and pinch-to-zoom should behave like a normal camera app.
- The app can guide the user, but it must not block a good manual photo.

### Expensify Standard

Use this as the OCR/parser benchmark.

- Merchant, date, total, tax, line amounts, returns, and receipt type must be parsed and scored.
- Parser confidence should be visible as review state, not developer jargon.
- User corrections should improve future local matching.
- Receipt content stays private; diagnostics must describe failure causes without exposing private receipt text.

### Genius Scan Standard

Use this as the long receipt and batch workflow benchmark.

- Multiple photos should be easy to add.
- Photo order must be clear.
- Overlap detection should stitch when safe.
- Manual overlap adjustment should exist when automatic stitching is unsure.
- Fallback to separate ordered OCR is better than a bad stitch.

### Google Drive Scanner Standard

Use this as the clutter test.

- The default path must be obvious.
- Avoid controls that require explanation before the user can continue.
- Settings are available, but the capture surface should not look like a settings screen.

## Maintainiac-Specific Standard

Maintainiac wins by adding business context the scanner apps do not own.

- Classify whole receipt as business, personal, or mixed.
- For mixed receipts, classify each line as business, personal, or split.
- Split lines must calculate the business amount, personal amount, and tax allocation.
- Simple mode can show amounts and classification without requiring full descriptions.
- Detailed mode can expose full item descriptions, quantity, unit, category, tax, and inventory fields.
- Materials receipts may optionally update inventory only after user confirmation.
- Expenses launched from the expense app stay expense-first unless the user chooses inventory tracking.
- Vehicle expenses must respect vehicle usage: business-only, personal-only, or mixed business/personal mileage.
- Camera, OCR, parser, and storage choices must adapt to device capability without exposing private device details in normal UI.

## Never Do

- Never hide the receipt behind a large bottom sheet during review.
- Never require scrolling a control panel just to find the continue action.
- Never OCR the smaller saved proof when a cleaner prepared source exists.
- Never silently update inventory from a receipt without review.
- Never show raw developer diagnostics to normal users.
- Never rely on cloud/AI to make basic receipt capture work.
- Never block a manual capture because the automatic checker is not satisfied.
- Never call user-facing storage controls "compression"; use save-space or backup-size language.
- Never ship a capture flow that returns the user to an attachment screen when app-assisted receipt review is expected.

## Done Means

- A single clear receipt can be captured, reviewed, read, parsed, classified, and saved quickly.
- A long receipt can be captured in sections, stitched when safe, or reviewed separately when stitching is unsafe.
- The user can zoom and inspect the image before filling the receipt review.
- OCR receives the best prepared source image.
- The saved proof image is storage-conscious and readable.
- The next screen after app-assisted fill is the receipt review/classification workflow.
- Every failure has a user-safe explanation and a privacy-safe diagnostic event.

The real-device checklist for proving these behaviors lives in `docs/receipt_real_device_test_script.md`.

## Hardening Pass Map

This receipt system should be hardened in deliberate passes. Each pass should leave the app working and tested before the next pass starts.

The detailed numbered execution plan lives in `docs/receipt_camera_ocr_master_pass_plan.md`. Use that file for `Pass NN of 40` tracking and build cadence.

1. **App-Assisted Handoff**
   - `Read Receipt` must lead into receipt review/classification.
   - The user must see clear reading status and review status.
   - Successful parsing must scroll to the review controls.

2. **Capture Surface**
   - Keep camera controls on the edges.
   - Preserve manual shutter, continuous autofocus/readability guidance,
     pinch-to-zoom, flash, brightness assist, and settings.
   - Remove user-facing device capability clutter.

3. **Live Capture Guidance**
   - Show short, useful guidance only.
   - Never block manual capture because the guide is uncertain.
   - Auto capture must require stable readable frames.

4. **Photo Review Surface**
   - Keep the receipt visible.
   - Make crop, stitch, save-space, retake, remove, and add-photo actions obvious.
   - Keep heavy controls out of the default preview state.

5. **Image Cleanup**
   - Prepare OCR source image first.
   - Improve grayscale, contrast, shadow reduction, straightening, and perspective correction.
   - Keep saved proof image readable at the selected save-space level.

6. **Long Receipt Capture**
   - Make multi-photo capture first-class.
   - Keep order obvious.
   - Warn against squeezing long receipts into one unreadable photo.

7. **Stitching**
   - Stitch when overlap confidence is safe.
   - Support different zoom distances between receipt sections.
   - Allow manual overlap adjustment.
   - Fall back to ordered separate OCR when stitching is unsafe.

8. **OCR Reliability**
   - Read photo, PDF, and imported text through the shared OCR service.
   - Handle unreadable, duplicate, overlapping, faded, wrinkled, and long receipt inputs.
   - Keep older-phone time and memory limits enforced.

9. **Parser Review**
   - Show merchant, date, subtotal, tax, total, lines, confidence, and review reasons.
   - Use user-safe language, not developer labels.
   - Make correction and confirmation fast.

10. **Business/Personal/Mixed Classification**
    - Classify the whole receipt.
    - For mixed receipts, classify each line.
    - Support split line percentages and tax allocation.

11. **Materials And Inventory Bridge**
    - Expense receipts stay expense-first.
    - Materials inventory updates require explicit confirmation.
    - Parsed material lines should stage inventory changes, not silently commit them.

12. **Vehicle And Profile Context**
    - Vehicle operating costs respect business/personal mileage share.
    - Work profiles, selected vehicle, contractor mode, and employee permissions must shape what the receipt flow allows.

13. **Diagnostics And Privacy**
    - Record success rate, failure step, confirmed cause, processing time, parser confidence, correction rate, and abandonment.
    - Never store private receipt content in analytics.
    - Security/abuse telemetry may be identifiable only when enforcement requires it.

14. **Real-Device QA**
    - Test S9-class, S24/S25-class, and iPhone-class devices.
    - Test good, wrinkled, faded, blurry, long, multi-photo, fuel, retail, return, PDF, and imported-text receipts.
    - Only call the flow ready when it survives real receipt testing.
