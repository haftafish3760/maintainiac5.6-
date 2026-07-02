# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 272 / Total Pass 352: Native Staging Diagnostics Recovery Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 272 / Total Pass 352: Native Staging Diagnostics Recovery Batch

Status: complete.

What changed:
- Updated native capture staging so the policy diagnostics added in Pass 271
  survive the local-first handoff instead of being stripped by the safe
  diagnostics allowlist.
- Preserved device tier, policy label, camera resolution tier, workload tier,
  ready hold time, assisted-shot counts, live-analysis pixel budgets, cleanup
  pixel budgets, stitch output limits, and session control bounds.
- Strengthened the accepted native capture staging test so those values are
  proven in three places: per-photo diagnostics, the recovery manifest, and the
  Hive recovery index.
- Kept the privacy boundary intact: private receipt text and unknown
  private-looking keys are still dropped from recovery diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart test/receipt_native_capture_staging_test.dart test/receipt_native_camera_contract_test.dart`

Next camera-only focus:
- Continue with capture-to-review recovery surface: make sure recoverable native
  captures are exposed to the receipt review flow with clear Resume/Discard
  actions and ordered long-receipt section handling.

### Receipt Camera Reopen Pass 273 / Total Pass 353: Recovery Surface Stale-Photo Guard Batch

Status: complete.

What changed:
- Hardened the interrupted native capture Resume path so it verifies staged
  receipt photo files still exist before opening receipt review.
- If an interrupted recovery record is stale, the panel now discards the dead
  recovery record and tells the user the saved receipt photos are no longer on
  the device instead of opening an empty or confusing review screen.
- Resume now passes only existing staged photo paths into receipt review while
  preserving capture diagnostics for each recovered path.
- Strengthened the attachment panel source guard so Resume/Discard recovery
  remains visible and stale staged photos stay handled deliberately.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`

Next camera-only focus:
- Continue with capture-to-review continuity: make the accepted recovered
  sections enter the same Next-to-filled-receipt review path as fresh native
  captures, with ordered-section and partial-receipt diagnostics intact.

### Receipt Camera Reopen Pass 274 / Total Pass 354: Recovered Sections Assisted-Review Continuity Guard Batch

Status: complete.

What changed:
- Audited the accepted-photo handoff and verified recovered native receipt
  sections use the same `_reviewPickedPhotoPaths` path as fresh native captures.
- Strengthened assisted-review source guards so accepted photo review must call
  the expense screen handoff callback, start the receipt read status, run OCR
  against the review result, and only then clean temporary OCR photos.
- Strengthened interrupted-capture panel guards so Resume must open review with
  existing recovered photo paths, preserve diagnostics per path, and clear the
  recovery record only after the recovered review is accepted.
- Kept this pass camera/receipt-flow focused; no PDF, Firebase, or maintenance
  logic was changed.

Validation:
- `dart format test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/expense_receipt_assisted_review_flow_test.dart test/receipt_attachment_panel_actions_test.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart`

Next camera-only focus:
- Continue with captured-photo quality calibration against native camera
  complaints: improve diagnostics and thresholds so clear receipt photos are
  not rated poorly while dark, blurry, glary, or cut-off captures still produce
  actionable guidance.

### Receipt Camera Reopen Pass 275 / Total Pass 355: Bright Receipt Quality Calibration Batch

Status: complete.

What changed:
- Split receipt photo lighting into true glare failure versus bright-but-usable
  receipt paper so clear white receipt photos are not treated like automatic
  retakes only because the paper is bright.
- Raised the hard glare threshold and added `isBrightButReadable` guidance:
  bright readable photos now tell the user to check for glare and tap Next if
  the store, date, total, and item prices are readable.
- Kept true overexposed photos as critical retake cases.
- Added a bright readable receipt test and updated true-glare fixtures to use
  the hard glare range.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart`

Observed unrelated failure:
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_image_data_saver_test.dart test/receipt_ocr_service_test.dart` failed only in `test/receipt_ocr_service_test.dart` on existing PDF overflow wording: expected `Only the first 1 receipt PDFs`, actual `PDF safety warning. Use the PDF as proof only or attach a safe copy.`

Next camera-only focus:
- Continue with native saved-photo brightness mismatch handling: tighten the
  evidence shown when the live preview looked acceptable but the saved image is
  dim, soft, or lower quality than expected.

### Receipt Camera Reopen Pass 276 / Total Pass 356: Native Saved-Photo Warning Model Batch

Status: complete.

What changed:
- Added `ReceiptNativeSavedPhotoReviewWarning` as the single model-layer
  decision for saved-photo review warnings from native capture diagnostics.
- Classified native saved-photo cases into stable codes for darker-than-preview,
  dimmer-than-preview, blur risk, glare risk, and check-sharpness cases.
- Updated the receipt photo review controls to consume the model warning instead
  of duplicating stringly typed diagnostic logic in the widget.
- Added tests proving the saved-photo warning model explains preview/capture
  mismatch clearly and that the review controls stay wired to the shared model.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Continue with capture preview/save parity: use native capture diagnostics and
  quality evidence to reduce false warnings for clear receipts while still
  surfacing actual dim, soft, or glare-prone saved photos.

### Receipt Camera Reopen Pass 277 / Total Pass 357: Native Saved-Photo Numeric Evidence Batch

Status: complete.

What changed:
- Added saved-photo numeric brightness and edge-score diagnostics to the native
  Android CameraX capture result.
- Added matching saved-photo numeric brightness and edge-score diagnostics to
  the native iOS AVFoundation capture result.
- Cleared iOS saved-photo quality state when a captured JPEG cannot be decoded
  so stale quality evidence cannot leak into the next capture.
- Preserved the new numeric diagnostics through local native capture staging,
  manifest recovery, and Hive recovery index.
- Strengthened native bridge and staging tests so brightness/sharpness evidence
  cannot disappear before receipt review or future telemetry.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_quality_guidance_test.dart`

Next camera-only focus:
- Continue with review guidance calibration using the saved-photo numeric
  evidence, especially false low-quality warnings on clear S24/S25 receipt
  captures.

### Receipt Camera Reopen Pass 278 / Total Pass 358: Saved-Photo False Warning Calibration Batch

Status: complete.

What changed:
- Updated saved-photo warning decisions to use numeric native brightness and
  edge-score evidence instead of relying only on coarse buckets.
- Suppressed borderline dim warnings when the saved photo is near the readable
  range and has enough edge evidence for receipt text.
- Suppressed glare warnings for bright-but-readable paper when numeric evidence
  shows the saved photo is not truly washed out.
- Stopped surfacing a native warning for merely `captured_soft`; only actual
  blur-risk diagnostics become a saved-photo warning.
- Added tests for readable borderline dim captures and bright readable receipt
  paper so clear S24/S25-style photos are not treated like failures.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Continue with native capture/photo-review parity: make sure quality warnings
  are actionable, not noisy, and keep Next available when the photo is readable.

### Receipt Camera Reopen Pass 279 / Total Pass 359: Accepted Capture Warning Summary Batch

Status: complete.

What changed:
- Added privacy-safe saved-photo warning summaries to
  `ReceiptPhotoReviewResult`.
- Accepted receipt review results now expose warning codes, warning counts, and
  a boolean health flag for native saved-photo quality concerns.
- The summaries reuse the same model decision as the review UI, so future
  telemetry and Command One health views will not drift from what the user saw.
- Added tests proving dim saved-photo warnings are counted while borderline
  readable captures are not falsely counted as warnings.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart`

Next camera-only focus:
- Continue connecting native saved-photo warning summaries into expense camera
  diagnostics without collecting receipt text, merchant, address, or amounts.

### Receipt Camera Reopen Pass 280 / Total Pass 360: Expense Camera Telemetry Warning Summary Batch

Status: complete.

What changed:
- Added saved-photo camera warning counts and a saved-photo quality warning flag
  to privacy-safe expense telemetry metadata.
- Wired accepted receipt photo review results into the `ocrStarted` telemetry
  handoff so Command One can later show camera save-quality health without
  private receipt content.
- Added saved-photo warning counts, total warning-event count, and top warning
  code to the expense health snapshot.
- Updated Command Center schema expectations and privacy tests for the new
  camera health fields.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/receipt_camera_result_test.dart`

Next camera-only focus:
- Continue tightening native camera capture/review evidence and then move into
  live-device UI validation when the next build is ready for phone testing.

### Receipt Camera Reopen Pass 281 / Total Pass 361: Native Warning Action Strip Batch

Status: complete.

What changed:
- Routed native saved-photo warnings into the photo review recovery/action strip,
  not just the small status row.
- Added title/detail fields to the UI warning adapter so dim, dark, blur, or
  glare warnings can show concise action copy beside Retake, Crop, and Add
  Photo.
- Kept Next available; this pass improves guidance visibility without blocking
  readable receipt photos.
- Added source guards so the recovery strip remains connected to the native
  warning model.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart`

Next camera-only focus:
- Continue reducing camera-review confusion by keeping warning copy visible,
  short, and tied to concrete user actions.

### Receipt Camera Reopen Pass 282 / Total Pass 362: Saved-Photo Warning Rate Batch

Status: complete.

What changed:
- Added `savedPhotoQualityWarningRate` to the expense health snapshot.
- The rate uses accepted receipt photo reviews as the denominator through
  `ocrStartedCount`, matching the camera handoff event that carries the saved
  photo warning metadata.
- Updated Command Center schema expectations and privacy-safe telemetry tests so
  future admin views can show frequency of saved-photo quality warnings, not
  only raw counts.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue hardening camera-health telemetry while keeping it content-free, then
  move back into native capture/review polish.

### Receipt Camera Reopen Pass 283 / Total Pass 363: Saved-Photo Health Threshold Batch

Status: complete.

What changed:
- Added saved-photo quality warning rate to the expense health attention logic.
- If 10% or more accepted receipt photo handoffs report saved-photo quality
  warnings, the expense camera health now moves to `review`.
- Kept severe health state reserved for harder failures such as save failures
  and high sync failure rate.
- Added a focused telemetry test proving frequent camera saved-photo warnings
  affect Command One health without exposing receipt content.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue native capture/review polish, especially reducing false saved-photo
  warnings while preserving accurate health signals.

### Receipt Camera Reopen Pass 284 / Total Pass 364: Native Warning Strip Color Batch

Status: complete.

What changed:
- Fixed the photo review recovery/action strip so noncritical native camera
  warnings no longer render as a green success panel.
- The strip now derives accent color, icon, and panel background from the native
  saved-photo warning adapter when a native warning is present.
- Critical warnings stay amber/dark warning; warning-level issues use a warning
  panel while still keeping Next available.
- Added source guards so the review strip remains wired to native warning color
  and panel color.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart`

Next camera-only focus:
- Continue review UI polish and live-device readiness checks for the receipt
  photo flow.

### Receipt Camera Reopen Pass 285 / Total Pass 365: Saved-Photo Warning Severity Summary Batch

Status: complete.

What changed:
- Added saved-photo warning severity summaries to accepted receipt photo review
  results so warning-level and critical-level native camera issues are counted
  separately.
- Added severity counts to privacy-safe expense OCR-start telemetry metadata.
- Added saved-photo critical warning count/rate to the expense health snapshot
  and Command Center payload.
- Updated schema expectations and tests so Command One can later separate
  ordinary camera review warnings from critical saved-photo problems without
  storing receipt text, merchant names, addresses, notes, or totals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue native capture/review hardening and reduce false saved-photo
  warnings while keeping severe camera evidence visible to Command One.

### Receipt Camera Reopen Pass 286 / Total Pass 366: Top Saved-Photo Warning Severity Batch

Status: complete.

What changed:
- Added `topSavedPhotoWarningSeverity` to the expense telemetry health snapshot
  and Command Center payload.
- Kept the field derived from privacy-safe saved-photo warning severity buckets
  only; it does not expose receipt images, receipt text, merchant names,
  addresses, notes, or amounts.
- Updated Command Center schema expectations and focused telemetry tests so
  warning and critical camera saved-photo issues stay distinguishable.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue native camera capture/review hardening and keep improving the
  actionable evidence Command One will need for receipt camera health.

### Receipt Camera Reopen Pass 287 / Total Pass 367: Saved-Photo Warning Action Batch

Status: complete.

What changed:
- Added `topSavedPhotoWarningAction` to the expense telemetry health snapshot
  and Command Center payload.
- Mapped the top native saved-photo warning code into concrete, privacy-safe
  operator guidance for exposure, dim photo, blur, and glare issues.
- Updated schema expectations and tests so Command One can show what to inspect
  or tune instead of only showing a warning code.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue tightening the native receipt capture/review loop and keep the
  warning evidence actionable without collecting private receipt content.

### Receipt Camera Reopen Pass 288 / Total Pass 368: Native Pre-Capture Exposure Assist Batch

Status: complete.

What changed:
- Added a native pre-capture exposure assist step on Android CameraX and iOS
  AVFoundation. Manual shutter still starts capture immediately, but the native
  camera now gets one final exposure-bias adjustment when the live feed is
  clearly dark or overbright before the saved proof photo is written.
- Added privacy-safe diagnostics for the pre-capture exposure decision and
  adjustment count so dark-preview-versus-dark-saved-photo issues can be
  tracked without receipt content.
- Preserved the new diagnostics through native staging/recovery and included
  summary buckets in expense OCR-start telemetry.
- Updated native bridge, staging, and telemetry tests to keep the behavior
  wired on both platforms.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `cd android && ./gradlew :app:compileDebugKotlin`
- `xcrun swiftc -parse ios/Runner/ReceiptCameraViewController.swift`

Next camera-only focus:
- Validate this native exposure pass, then continue tightening saved-photo
  quality and review flow behavior before moving anywhere near PDF work.

### Receipt Camera Reopen Pass 289 / Total Pass 369: Pre-Capture Exposure Health Snapshot Batch

Status: complete.

What changed:
- Aggregated pre-capture exposure decision buckets into the expense telemetry
  health snapshot and Command Center payload.
- Added pre-capture exposure adjustment count/rate and top pre-capture exposure
  decision so Command One can tell whether the camera was trying to brighten or
  dim photos before capture.
- Kept the data privacy-safe: only decision codes and counts are recorded, not
  receipt images, OCR text, merchant names, addresses, notes, or amounts.
- Updated schema expectations, focused telemetry tests, and the Firestore
  sanitizer snapshot helper.

Validation:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart`

Next camera-only focus:
- Validate this Command One visibility pass, then continue camera capture/review
  hardening around saved-photo quality and long-receipt flow.
