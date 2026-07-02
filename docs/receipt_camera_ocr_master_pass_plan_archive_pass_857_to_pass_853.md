# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Pass 857: Native Preview Brightness Evidence Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Pass 857: Native Preview Brightness Evidence Batch

Status: complete.

What changed:
- Added exact native preview/saved-photo brightness evidence buckets to the
  receipt photo review health counts so dark saved captures can be separated
  from normal readable captures without exposing receipt content.
- Added a manual-capture policy health token proving quality guidance remains
  advisory and the user can still take a photo when the app is uncertain.
- Tightened regression coverage for the case where saved-photo brightness is
  darker than the live preview while manual capture stays allowed.

Validation:
- `dart format test/receipt_camera_result_test.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result tracks preview parity watch without blocking" -r compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native bridge parity for actual
  camera controls: back/close reliability, tap focus, pinch zoom, exposure
  reset, flash/settings availability, and photo-review handoff diagnostics.

### Receipt Camera Pass 858: Native Actual Control Parity Batch

Status: complete.

What changed:
- Extended Android CameraX diagnostics with actual status fields for receipt
  light/flash, focus lock, exposure lock, and white-balance lock controls.
- Extended iOS AVFoundation diagnostics with the same actual control status
  fields so Command One can compare expected controls against real native
  availability on both platforms.
- Extended Dart receipt review health counts so missing flash/torch and lock
  controls are counted separately from missing back, settings, shutter, tap
  focus, pinch zoom, and exposure controls.
- Tightened tests for both healthy and incomplete native camera control states.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result summarizes native camera UI health" -r compact`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result flags incomplete native camera controls" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "native camera" -r compact`
- `git diff --check`

Note:
- Native Android Kotlin compilation still needs a Java runtime on this Mac
  before `./gradlew :app:compileDebugKotlin --quiet` can verify the Kotlin
  source directly.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening back/close reliability
  outcomes and interruption-safe capture recovery around in-flight captures and
  saved-but-not-yet-reviewed receipt photos.

### Receipt Camera Pass 859: Native Close Policy Health Batch

Status: complete.

What changed:
- Added privacy-safe close-policy health codes so Command One can distinguish
  the intended policy from the actual close outcome.
- Added close request and result-delivered health codes so a back press during
  capture can be diagnosed as request recorded, save deferred, captured
  sections returned, and result delivered.
- Tightened close success and close-failure regressions so captured receipt
  photos are not treated like silent cancellations.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "native camera close" -r compact`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result flags failed native close after capture" -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-screen recovery wording and
  safe action labels around saved-but-not-yet-read photos so the user can
  resume, add another photo, or continue to receipt details without losing work.

### Receipt Camera Pass 860: Review Exit Wording Safety Batch

Status: complete.

What changed:
- Reworded the receipt photo review exit action from the clunky
  "Keep Photo(s) Saved For Later" language to "Save Photo(s) For Later."
- Kept the safety behavior unchanged: leaving photo review keeps recoverable
  local photos but does not read them into the expense until the user taps
  Next: Review Receipt Details.
- Tightened layout/copy tests so the old confusing wording does not return.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "review" -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is receipt review action clarity for
  single-photo versus multi-photo long receipt flows, especially Add Photo,
  Next, and recovery hints.

### Receipt Camera Pass 861: Native Add-Next Label Clarity Batch

Status: complete.

What changed:
- Changed the native Android CameraX long-receipt add-section button from
  "Add Photo" to "Add Next" while keeping the accessibility label as
  "Add another receipt photo."
- Changed the native iOS AVFoundation long-receipt add-section button to the
  same compact "Add Next" wording.
- Updated native bridge and layout guards so the clearer wording is enforced
  on both platforms.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "native camera" -r compact`
- `flutter test test/receipt_native_android_bridge_test.dart --name "Android receipt camera bridge uses CameraX method channel" -r compact`
- `flutter test test/receipt_native_ios_bridge_test.dart --name "iOS receipt camera bridge uses AVFoundation method channel" -r compact`
- `flutter analyze test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking actual runtime handoff
  plumbing from accepted native photos into receipt details, with OCR source
  first and saved proof second.

### Receipt Camera Pass 862: Receipt Details Handoff Action Clarity Batch

Status: complete.

What changed:
- Tightened accepted-photo handoff copy so the next step explicitly says the
  user will review receipt details and mark Business, Personal, or Mixed.
- Kept the OCR-source-first policy unchanged: OCR reads the prepared/original
  source photos before saved proof compression is treated as backup evidence.
- Updated result and shareability tests so the old vague "continue to receipt
  details" action copy does not return.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result summarizes saved-photo camera warnings" -r compact`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result tracks preview parity watch without blocking" -r compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "shared capture keeps UI labels on next/review language" -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capability detection and
  device-tier reporting around storage, camera controls, and local/cloud assist
  recommendations without exposing device identity in the user-facing UI.

### Receipt Camera Pass 863: Privacy-Safe Capability Summary Batch

Status: complete.

What changed:
- Added a privacy-safe hardware capability label that reports only tier,
  storage bucket, rear-camera availability, and supported camera controls.
- Added privacy-safe capability diagnostics that preserve useful operational
  evidence without exposing device manufacturer, device model, or device name.
- Added regression coverage proving the sanitized summary does not leak device
  identity strings while still reporting camera count, focus/zoom support, and
  still-photo megapixel bucket.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --name "hardware profile exposes privacy-safe capability buckets" -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_native_camera_contract_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring the sanitized capability
  summary into diagnostics/settings copy where useful while keeping model and
  manufacturer details out of the user-facing receipt camera UI.

### Receipt Camera Reopen Pass 854: Native Review Transition Guard Batch

Status: complete.

What changed:
- Added a native review-transition contract to Android CameraX and iOS
  AVFoundation diagnostics:
  - `nativeCaptureReviewTransitionPolicy`
  - `nativeCaptureReviewTransitionTarget`
  - `nativeCaptureReviewDiscardPolicy`
- The contract states that captured photos must move into receipt photo review,
  then receipt details, and that back/close must not silently discard captured
  receipt photos.
- Added Dart health-count routing for the transition contract so Command One and
  receipt diagnostics can distinguish a missing forward-flow contract from normal
  camera latency or close/cancel behavior.
- Added regression guards proving Android, iOS, and Dart all expose the
  transition/discard contract without receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_camera_contract_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "native receipt settings control health"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "native camera review transition"`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native camera screens report control diagnostics without content"`
- `git diff --check`

Note:
- `./gradlew :app:compileDebugKotlin --quiet` could not run because this Mac
  does not currently have a Java runtime available.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening accepted-photo review
  labels and OCR handoff routing so the first clear forward action remains
  `Next`/receipt details instead of ambiguous read/save wording.

### Receipt Camera Reopen Pass 855: Review Next Label Unification Batch

Status: complete.

What changed:
- Replaced the remaining `Next: Details` receipt-photo review top-bar label with
  `Next: Review Receipt Details`.
- Removed the old `Next: Details` special-case from the common review button
  label renderer.
- Updated the shared capture UI-label guard so the old vague label cannot come
  back.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "shared capture keeps UI labels on next/review language"`
- `git diff --check`

Note:
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "receipt photo review"` and
  `flutter test test/receipt_camera_help_flow_test.dart --name "Receipt Details"` matched no test names, so
  they were not counted as validation.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is accepted-photo handoff routing and
  OCR-source diagnostics so `Next: Review Receipt Details` always means the app
  opens receipt details from original/clean OCR sources before saved-proof
  compression.

### Receipt Camera Reopen Pass 856: OCR Source-First Handoff Policy Batch

Status: complete.

What changed:
- Added explicit receipt-reader handoff diagnostics:
  - `receiptReaderHandoffOcrSourcePolicy`
  - `receiptReaderHandoffCompressionPolicy`
- The handoff now states that OCR reads the original/prepared source before the
  smaller saved proof is used for storage or backup.
- Added regression coverage so the shared flow keeps this source-first policy
  next to the existing prepared-source/not-saved-backup guard.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "app assisted OCR reads prepared OCR sources instead of saved backup proof"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native live-preview brightness and
  saved-photo parity guard tightening so dark saved captures get surfaced as
  exact diagnostics without blocking manual capture.

### Receipt Camera Reopen Pass 848: Accepted Photo Exit Handoff Guard Batch

Status: complete.

What changed:
- Hardened kept-for-later receipt photo review results so a captured photo
  saved through the back/exit path cannot look like it was accepted into OCR or
  receipt details.
- Added privacy-safe handoff metadata that now separates accepted receipt
  details handoff from saved-photo review resume-required state.
- Added explicit non-content diagnostics for deferred OCR, reader-not-accepted,
  resume-before-OCR, and back-action kept-for-later outcomes.
- Corrected OCR handoff evidence so missing OCR sources report
  `ocr_source_first=not_ready` instead of sounding like a reader source exists.
- Added regression coverage proving kept-for-later photos stay recoverable but
  do not become app-assisted receipt-reader input until the user resumes review
  and taps Next.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the review screen controls
  clearer and harder to misuse after capture: visible Next language, clear Add
  Another Photo action, and no hidden scroll-only continuation path.

### Receipt Camera Reopen Pass 849: Review Controls Clarity Batch

Status: complete.

What changed:
- Made the post-capture top action read `Next: Details` in preview mode instead
  of a vague `Next`, while preserving the green primary action treatment.
- Reused the stacked Next label component in the top bar so short phones do not
  squeeze the action text into unreadable one-line copy.
- Changed the primary add-section control from `Add` to `Add Photo` so the user
  is not left interpreting a camera-plus icon.
- Increased the preview/action tray budget to keep the core actions visible
  without turning the review screen into a large bottom drawer; the receipt
  image still owns the screen.
- Added source guards that keep the review controls on Next/Details/Add Photo
  language and prevent drift back to `Read receipt`, `Use this photo`, or
  hidden-copy wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native capture/review latency
  path: make sure the captured photo opens review fast, the UI labels that wait
  honestly, and diagnostics separate slow decode from slow review routing.

### Receipt Camera Reopen Pass 850: Review Opening Handoff Diagnostics Batch

Status: complete.

What changed:
- Added per-photo diagnostics at the handoff between native capture staging and
  photo review opening.
- Marked the expected route as fresh native capture to photo review, before OCR
  or the receipt form runs.
- Added the same review-opening route diagnostics for saved native capture
  recovery so interrupted review resumes are visible and separate.
- Added health-count tokens for review-opening route, source, before-OCR policy,
  and visible core-action expectations.
- Added regression coverage so Command One-style privacy-safe metadata can prove
  the captured photo is supposed to open photo review first, with Next/Add Photo
  visible, before the receipt-details screen is filled.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native camera preview/capture parity:
  keep investigating brightness/dark-preview signals and make sure the bridge
  reports whether saved capture was darker than live preview.

### Receipt Camera Reopen Pass 851: Preview-To-Saved Brightness Watch Batch

Status: complete.

What changed:
- Tightened Android CameraX parity reporting so a saved photo that is darker
  than the live preview becomes `saved_photo_darker_than_preview_watch` instead
  of collapsing into preview parity OK.
- Added the matching iOS AVFoundation parity watch signals for darker and
  brighter saved images.
- Updated the shared Dart diagnostics to count darker/brighter preview-watch
  states separately from critical retake states.
- Promoted preview parity watch states into the camera UI-health headline so
  Command One-style diagnostics can say the saved image was darker than preview
  directly.
- Kept the watch state non-blocking: it warns/reviews readability without
  forcing retake when the receipt is still usable.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `git diff --check -- android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture exposure controls:
  make sure the user-facing brightness slider/reset and auto exposure assist
  produce clear, privacy-safe evidence without making shutter behavior sluggish.

### Receipt Camera Reopen Pass 852: Exposure Control Health Rollup Batch

Status: complete.

What changed:
- Added shared health-count tokens for native pre-capture exposure policy and
  outcome.
- Separated auto exposure assist outcomes from manual brightness choices:
  lifted dim receipt, kept native auto, skipped assist, baseline, user raised,
  and user lowered brightness.
- Kept the telemetry privacy-safe: only control/outcome buckets are counted, no
  receipt text, image content, merchant, line items, prices, or user notes.
- Added regression coverage proving exposure assist and manual brightness both
  flow into the receipt reader handoff metadata for Command One-style health.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-screen resilience around
  hiding/showing controls and pinch/double-tap zoom so the user can inspect the
  full receipt without losing the way forward.

### Receipt Camera Reopen Pass 853: Review Zoom And Controls Recovery Batch

Status: complete.

What changed:
- Replaced the hidden-controls restore affordance with a labeled `Controls`
  button so it cannot be mistaken for camera settings.
- Added a review zoom reset helper and wired it into photo selection, review
  mode changes, and photo-set recovery after add/retake/remove/reorder.
- Kept pinch/double-tap receipt inspection intact through `InteractiveViewer`
  while preventing stale zoom/pan state from carrying onto another receipt
  section.
- Updated layout guards for the current review tray sizing and zoom controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is long-receipt add-section guidance:
  make sure ghost-guide context and partial-receipt reasons flow clearly into
  the next capture without blocking manual shutter.
