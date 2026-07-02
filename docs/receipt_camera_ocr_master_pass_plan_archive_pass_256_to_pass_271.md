# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 256 / Total Pass 336: Native Exposure Quality Scoring Calibration Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 256 / Total Pass 336: Native Exposure Quality Scoring Calibration Batch

Status: complete.

What changed:
- Calibrated receipt photo review scoring so photos that pass the internal
  `isLikelyReadable` checks cannot land in a weak-looking score band unless
  they are dark, glare-heavy, or very soft.
- Added a focused quality-guidance test for a tight but readable receipt frame
  so readable photos score at least 82 and do not ask for unnecessary review.
- Preserved critical retake behavior for dark receipts, glare, blank captures,
  and very soft photos.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_image_data_saver_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart`

Next camera-only focus:
- Continue with native camera brightness and saved-photo mismatch: compare the
  live preview brightness signals with the saved photo buckets and tune the
  native Android/iOS warnings so dark saved captures are explained correctly.

### Receipt Camera Reopen Pass 257 / Total Pass 337: Native Camera Brightness And Saved-Photo Mismatch Batch

Status: complete.

What changed:
- Raised native auto-brightness assist thresholds on Android CameraX and iOS
  AVFoundation so the camera starts helping while a receipt is dim, not only
  after it is already very dark.
- Android now treats `brightness <= 120.0` as `dark_assisted` and
  `brightness <= 70.0` as `too_dark_warning`.
- iOS now mirrors the same `brightness <= 120` and `brightness <= 70`
  thresholds.
- Preserved glare thresholds, auto-capture light checks, and saved-photo
  mismatch diagnostics.
- Updated native bridge source guards so Android and iOS stay aligned.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_quality_guidance_test.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart`

Next camera-only focus:
- Continue with device-tier guided capture policy: make the capability profile
  choose safer defaults for older phones while allowing newer devices to use
  heavier guidance, stitching, cleanup, and OCR-prep work.

### Receipt Camera Reopen Pass 258 / Total Pass 338: Device Tier Guided Capture Policy Batch

Status: complete.

What changed:
- Made receipt camera device-tier policy explicit in the native session config.
- The native bridge now receives `deviceTier`, `devicePolicyLabel`,
  `readyHoldMs`, `assistedShotCount`, `bestShotCandidateCount`, and
  `cameraResolutionTier` so CameraX/AVFoundation can prove which workload is
  being used.
- Older-phone safe mode now throttles live analysis harder, keeps manual
  capture available, disables auto capture, disables heavier sharpening/shadow
  cleanup, and keeps grayscale/contrast work available.
- Flagship mode keeps stronger live guidance, auto-capture eligibility,
  perspective/crop suggestions, sharpening, and shadow cleanup when storage is
  healthy.
- Storage-pressure mode now overrides the bridge payload so proof-copy limits,
  best-shot candidates, auto capture, and heavier cleanup stay safe even if the
  user selected stronger camera features.
- Updated bridge tests so raw settings cannot bypass the effective device policy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_assistance_policy_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`

Next camera-only focus:
- Continue with partial receipt detection and add-another-photo prompts: after
  capture, decide whether the photo likely contains the whole receipt, explain
  why another photo may be needed, and feed the long-receipt ghost-guide flow.

### Receipt Camera Reopen Pass 259 / Total Pass 339: Partial Receipt Detection And Add-Another Prompt Batch

Status: complete.

What changed:
- Added `ReceiptPhotoCoverageDecision`, a deterministic post-capture coverage
  classifier that combines native framing diagnostics with image quality.
- The classifier marks likely cut-off photos when native CameraX/AVFoundation
  reports `possibly_cut_off` or `perspective_skipped_cut_off_risk`.
- It also catches poor framing, tiny-text/too-far captures, weak printed-line
  bands, readable complete frames, and unknown receipt-edge states.
- The receipt photo review tray now uses the coverage decision to explain when
  another photo may be needed instead of showing generic quality copy.
- `Add Another` is emphasized when the app believes the receipt may be cut off.
- Added tests proving cut-off photos prompt for another section and well-framed
  readable photos are allowed to continue.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with ghost-guide prompt and next-section continuity: when Add Another
  is chosen after a possible partial receipt, make the UI explicitly carry the
  bottom-slice guide into the next capture and make the user understand what to
  line up.

### Receipt Camera Reopen Pass 260 / Total Pass 340: Ghost Guide Prompt And Next-Section Continuity Batch

Status: complete.

What changed:
- Routed the selected photo's `ReceiptPhotoCoverageDecision` into the
  Add Another / long-receipt alignment guide.
- The guide sheet now changes its title to `Finish This Receipt Photo` when the
  previous photo was flagged as cut off or likely continuing.
- The guide copy now includes the concrete coverage reason and tells the user
  to repeat 3-5 readable lines in the next photo.
- Preserved the existing bottom-slice preview and native
  `previousSectionGuidePhotoPath` handoff.
- Added a source guard proving the partial-receipt reason flows into the ghost
  guide instead of being dropped at the review tray.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with coverage diagnostics save-handoff: include the coverage decision
  in saved review metadata so OCR/review/telemetry can tell whether a photo was
  accepted as complete, possibly partial, or cut off.

### Receipt Camera Reopen Pass 261 / Total Pass 341: Coverage Diagnostics Save-Handoff Batch

Status: complete.

What changed:
- Added privacy-safe coverage diagnostics to saved receipt proof metadata:
  `photoCoverageStatus`, `photoCoverageReason`, and
  `photoCoverageNeedsMorePhotos`.
- Saved coverage diagnostics are produced even when native diagnostics are
  missing, using the prepared photo quality as a fallback.
- Added `photoCoverageStatuses`, `photoCoverageStatusCounts`, and
  `hasPossiblePartialReceiptPhotos` to `ReceiptPhotoReviewResult`.
- Added tests proving complete photos and possible partial/cut-off photos are
  summarized correctly.
- Added a source guard so the save loop keeps attaching coverage metadata to
  accepted receipt photos.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with coverage-aware OCR review warning: when the user accepts a photo
  that may be partial, the filled receipt review should carry a clear warning
  before final save.

### Receipt Camera Reopen Pass 262 / Total Pass 342: Coverage-Aware OCR Review Warning Batch

Status: complete.

What changed:
- Passed possible partial/cut-off coverage state from the receipt photo review
  result into the expense receipt read handoff.
- The filled receipt review handoff now shows a warning chip when an accepted
  photo may be incomplete, so the user checks the saved proof before final save.
- Added privacy-safe coverage status, reason, needs-more count, and
  possible-partial summary fields to camera-prep telemetry.
- Updated source guards so the OCR handoff keeps reading original/source photos
  before saved proof copies and preserves the coverage warning contract.

Validation:
- `dart format test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_help_flow_test.dart`

Next camera-only focus:
- Continue with native coverage diagnostic parity: make sure the CameraX and
  AVFoundation bridge contracts expose the same privacy-safe coverage reasons
  the Flutter review layer now expects, without collecting receipt content.

### Receipt Camera Reopen Pass 263 / Total Pass 343: Native Coverage Diagnostic Parity Batch

Status: complete.

What changed:
- Added a shared receipt capture diagnostic vocabulary for native coverage,
  framing, perspective, motion, readability, and derived photo-coverage fields.
- Replaced hard-coded coverage/framing strings in the review classifier with
  shared constants so CameraX, AVFoundation, staging, and review stay aligned.
- Allowed the derived coverage status/reason/needs-more fields through the
  privacy-safe native staging diagnostics filter.
- Updated expense receipt camera-prep telemetry and saved proof diagnostics to
  use the shared coverage keys.
- Added a native contract test proving the exact coverage key/value names and
  the likely-cut-off decision path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart test/receipt_camera_help_flow_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_native_camera_contract_test.dart`

Next camera-only focus:
- Continue with coverage signal telemetry reason budgeting: keep the coverage
  health data useful for Command One while proving it remains bounded,
  privacy-safe, and independent of raw receipt text or images.

### Receipt Camera Reopen Pass 264 / Total Pass 344: Coverage Signal Telemetry Reason Budget Batch

Status: complete.

What changed:
- Added bounded receipt photo coverage health to the expense telemetry snapshot:
  status counts, reason counts, needs-more count/rate, top status, and top
  reason.
- Coverage health is aggregated from local `ocrStarted` metadata and remains
  summary-only; it does not upload raw receipt text, receipt images, paths,
  merchant names, customer data, or item descriptions.
- Added risk-priority top selectors so tied coverage health surfaces cut-off
  and other problem states before complete/readable states.
- Preserved the Firestore single-summary-document shape and added the new
  fields to the Command Center schema guard, Firestore sanitizer, and contract
  documentation.
- Strengthened redaction expectations so receipt numbers and terminal/auth
  references stay as `private_reference` in Firestore-safe drill-downs.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with device-tier capture workload audit: prove older phones get
  lower live-analysis load and safer capture limits while newer phones retain
  stronger guidance, cleanup, and multi-photo support.

### Receipt Camera Reopen Pass 265 / Total Pass 345: Device-Tier Capture Workload Audit Batch

Status: complete.

What changed:
- Added explicit receipt camera workload tiers for older-phone, balanced, and
  flagship capture paths.
- The native CameraX/AVFoundation session contract now carries hard workload
  budgets: max live-analysis pixels, max cleanup pixels, max stitch output
  pixels, and max stitch output height.
- Older phones disable heavy live frame analysis and receive the smallest
  cleanup/stitch budgets; high-capacity phones retain stronger live analysis and
  larger long-receipt stitching budgets.
- Storage pressure now forces the native session down to the light workload
  budget even when the physical device is high-capacity.
- Added tests proving the tiered workload defaults and the native channel
  arguments sent to the platform camera layer.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`

Next camera-only focus:
- Continue with native capability-to-workload session handoff: make the
  capability service include the platform camera limits needed by CameraX and
  AVFoundation so the app can pick safe defaults without exposing raw device
  details to the user.

### Receipt Camera Reopen Pass 266 / Total Pass 346: Native Capability-to-Workload Handoff Batch

Status: complete.

What changed:
- Extended the internal hardware profile with native camera controls that matter
  for receipt capture: tap focus, brightness adjustment, zoom, YUV live frames,
  and native edge signals.
- The device capability service now preserves those CameraX/AVFoundation
  signals from the native camera capability reader instead of flattening them
  down to camera count and still-photo dimensions only.
- Automatic device tiering can now reward phones that provide the native
  receipt-camera controls needed for stronger guidance, without showing raw
  device details to the user.
- Added a compact internal control label for diagnostics/settings logic while
  keeping the user-facing UI away from manufacturer/model-style hardware lists.
- Added tests proving native camera controls influence capability tiering and
  source guards proving the service does not drop those controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_device_capability_service.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_device_capability_service.dart test/receipt_assistance_policy_test.dart test/receipt_native_camera_contract_test.dart`

Next camera-only focus:
- Continue with native exposure/readability session controls: make the session
  contract send bounded exposure adjustment, focus locking, zoom range, and
  readability timing defaults so native capture can avoid dark previews and
  sluggish back/cancel behavior.

### Receipt Camera Reopen Pass 267 / Total Pass 347: Native Control Capability Guard Batch

Status: complete.

What changed:
- Converted tap focus, pinch zoom, brightness slider, exposure reset, auto
  brightness assist, focus lock, and exposure lock from raw settings into
  effective session controls based on the native CameraX/AVFoundation
  capability report.
- Added bounded zoom and exposure ranges to the native session contract so the
  platform layer knows the safe limits before showing controls or applying
  adjustments.
- Prevented the Flutter bridge from sending fake camera controls when native
  support is absent, which protects older or limited devices from broken UI and
  unstable camera behavior.
- Verified capable devices still receive the expected focus, zoom, exposure,
  and lock controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`

Next camera-only focus:
- Continue with native back/cancel and interrupted-capture hardening: make sure
  camera exit, section review, and accepted-photo queue behavior cannot strand
  the user or lose a captured receipt image.

### Receipt Camera Reopen Pass 268 / Total Pass 348: Native Cancel Flow Separation Batch

Status: complete.

What changed:
- Separated Maintainiac native camera outcomes into added, unavailable, and
  canceled states for the first receipt-photo entry point.
- Back/cancel from the native receipt camera now stops the camera flow and
  returns to receipt import options instead of falling through into document
  scanner or backup camera behavior.
- Added a canceled state to review-screen photo picking so add-photo/retake
  flows also stop cleanly when the user backs out of native capture.
- Preserved fallback behavior only for real native unavailability; user cancel
  is no longer treated as a reason to open another camera path.
- Added source guards covering both initial capture and review add-photo paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with post-capture review flow polish: ensure accepted photos proceed
  toward receipt read/review, preserve staged captures through navigation, and
  keep add-another-photo language explicit for long receipts.

### Receipt Camera Reopen Pass 269 / Total Pass 349: Post-Capture Recovery Copy and Cleanup Batch

Status: complete.

What changed:
- Updated the leave-review dialog so it no longer tells the user captured
  receipt photos are simply "not saved" when they are already staged locally for
  recovery.
- The dialog now clearly says staged photos are saved locally for recovery but
  not yet attached to the expense, then routes the user toward Next, continued
  review, or discard.
- Added a staged-review-photo helper and used it for cleanup so abandon cleanup
  targets app-created/staged review photos instead of blindly treating every
  review path the same.
- Strengthened receipt camera layout guards so the recovery language and staged
  cleanup helper remain in place.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with post-capture flow correctness: verify the accepted-photo result
  preserves staged-path diagnostics, stitch fallback state, and next-screen
  handoff data so receipt read/review can explain exactly what it is reviewing.

### Receipt Camera Reopen Pass 270 / Total Pass 350: Accepted Photo Handoff Summary Batch

Status: complete.

What changed:
- Added result-level handoff fields to `ReceiptPhotoReviewResult` so downstream
  screens can tell whether Next is reviewing one combined receipt image, ordered
  receipt sections, or a single photo without reinterpreting stitch internals.
- Added a compact diagnostic handoff label that combines stitch status,
  fallback reason, coverage warning state, and OCR source count.
- Updated the expense receipt handoff panel and receipt attachment status copy
  to use the accepted-photo handoff label instead of only the low-level stitch
  decision label.
- Added tests for stitched-image handoff, safe fallback ordered-section
  handoff, and possible partial-receipt handoff.
- Updated source guards so the app-assisted receipt review path keeps using the
  higher-level handoff label.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Continue with native capture diagnostics completeness: ensure CameraX and
  AVFoundation return enough safe diagnostics for exposure brightness, focus,
  zoom, edge/readability, close/back, and device-tier workload decisions without
  exposing receipt content.

### Receipt Camera Reopen Pass 271 / Total Pass 351: Native Diagnostics Completeness Batch

Status: complete.

What changed:
- Mirrored Flutter's native receipt-camera session policy into Android
  CameraX so the activity now reads device tier, policy label, ready hold time,
  assisted-shot limits, camera resolution tier, workload tier, pixel budgets,
  stitch output limits, and session control bounds.
- Mirrored the same policy fields into the iOS AVFoundation controller so both
  native camera engines receive the same device-safe workload contract.
- Added those policy fields to Android and iOS capture diagnostics, alongside
  the existing brightness, focus, zoom, edge, readability, close/back, and
  captured-photo quality evidence.
- Preserved the diagnostics as privacy-safe operational metadata only; no
  receipt image, receipt text, merchant, customer, address, phone, or note
  content is exposed by this pass.
- Strengthened Android and iOS bridge guard tests so future native camera work
  cannot drop the workload/session-policy diagnostics silently.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_camera_contract_test.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart`

Next camera-only focus:
- Continue with native capture interruption recovery: verify staged native
  captures, diagnostics, and temporary IDs survive app pause/resume, phone
  calls, and back navigation without losing accepted receipt sections.
