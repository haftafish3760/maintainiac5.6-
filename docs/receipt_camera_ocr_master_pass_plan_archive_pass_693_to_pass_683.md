# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Pass 693: Native Touch Focus And Zoom Parity Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Pass 693: Native Touch Focus And Zoom Parity Batch

Status: complete.

What changed:
- Added privacy-safe native diagnostics proving the custom receipt preview
  supports tap focus and pinch zoom on both CameraX and AVFoundation.
- Documented the native touch coordinate policy in diagnostics: Android uses
  the CameraX preview metering-point factory, and iOS uses the AVFoundation
  preview-layer device point.
- Documented the native zoom clamp policy in diagnostics so Command One/QA can
  tell that zoom is bounded by device capability instead of being an arbitrary
  app-side scale.
- Fixed Android touch release behavior so the preview releases parent touch
  interception on normal finger-up, not only on cancel. This reduces the chance
  of touch/back gestures feeling trapped after interacting with the camera.
- Strengthened Android and iOS bridge tests for tap-focus/pinch-zoom policy,
  zoom counts, focus counts, suppression-after-zoom, and native control parity.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is receipt edge/framing guidance,
  including safer long-receipt prompts when the captured frame likely missed the
  bottom or squeezed text too small for reliable OCR.

### Receipt Camera Pass 694: Native Framing Ratio Coverage Batch

Status: complete.

What changed:
- Added privacy-safe native framing width/height ratio diagnostics on Android
  CameraX and iOS AVFoundation.
- Fed those native ratios into the Dart receipt coverage decision so the app can
  warn when the receipt text is likely too tiny because the user tried to fit a
  long receipt into one photo.
- Kept manual capture non-blocking: tiny-text evidence prompts for closer
  top-to-bottom photos, but it does not prevent the user from continuing when
  the receipt is readable.
- Added coverage tests proving native ratio evidence triggers the long-receipt
  "closer photos from top to bottom" guidance.
- Added bridge and layout guards so ratio diagnostics continue to flow from the
  native camera surfaces into the review decision layer.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture recovery/Hive staging
  resilience for app interruption, phone calls, backgrounding, and repeated
  capture/review transitions.

### Receipt Camera Pass 670: Camera Flow Regression Guard Batch

Status: complete.

What changed:
- Updated stale receipt-camera layout assertions so the tests match the current
  post-capture copy: Next opens the filled receipt review, and Add Receipt Photo
  is only for a continuing receipt.
- Re-ran the capture layout and result regressions together after the native
  preview lifecycle, bottom review button, wording, and phone-camera backup
  clarity batches.
- Confirmed the camera/result tests still protect the native-camera-first path,
  capped bottom controls, saved-photo warnings, back protection, long-receipt
  stitching handoff, OCR source handoff, native UI health diagnostics, quality
  warning priority, and receipt review result summaries.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native camera capture shell
  controls and diagnostics: make the settings/flash/back/close path explicit,
  keep the preview from looking like the stock camera flow, and keep native
  exposure/focus/zoom evidence wired into the privacy-safe result.

### Receipt Camera Pass 671: Native Camera Identity Contract Batch

Status: complete.

What changed:
- Made the live Android CameraX status strip start with
  `Maintainiac receipt camera` so the in-app scanner is plainly identified
  while the user is taking a receipt photo.
- Made the live iOS AVFoundation status strip use the same Maintainiac receipt
  camera identity.
- Added a privacy-safe `nativeCameraIdentity` diagnostic on Android and iOS so
  Command One/tests can distinguish the Maintainiac in-app native camera from
  any fallback phone-camera path without collecting receipt content.
- Added Android/iOS bridge guards proving the visible identity and diagnostic
  identity stay wired.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native settings parity and review
  handoff clarity: make sure every user-facing capture setting has plain
  receipt wording, reset/default behavior, and matching Android/iOS diagnostic
  evidence before moving deeper into OCR/parser hardening.

### Receipt Camera Pass 672: Native Receipt Settings Reset Batch

Status: complete.

What changed:
- Added `Reset receipt camera defaults` to Android CameraX receipt settings.
- Added the matching reset action to iOS AVFoundation receipt settings.
- Reset restores receipt-specific defaults: assisted receipt fill on,
  long-receipt mode where supported, automatic capture off, price-only review,
  normal backup proof, guidance warnings on, edge guidance on, cleanup settings
  on, and manual shutter ready.
- Added a privacy-safe `settingsResetCount` diagnostic on Android and iOS so
  Command One can see settings recovery behavior without receipt content.
- Added bridge tests proving the reset action, user-facing recovery message,
  reset function, and diagnostic counter exist on both native engines.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native settings wording and result
  handoff polish: make the next-step labels say `Next`/receipt review plainly,
  avoid stock-camera wording, and preserve OCR-source-first plus data-saver
  backup clarity across Android, iOS, and Flutter review screens.

### Receipt Camera Pass 673: Native Next Handoff Wording Batch

Status: complete.

What changed:
- Replaced Android native `Review Photo` / `Review Photos` handoff buttons with
  `Next` and `Next (n photos)` so captured receipt photos move forward with the
  same language the receipt flow uses.
- Replaced iOS native `Review Photo` / `Review Photos` handoff buttons with the
  same `Next` wording.
- Changed long-receipt guidance from `tap Review Photos` to
  `tap Next to review the receipt`.
- Updated Android/iOS accessibility labels to say
  `Next: review captured receipt photos in Maintainiac`.
- Updated bridge tests to reject the old wording and protect the clearer
  captured-photo handoff.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is compile verification for the native
  Android camera changes, then another receipt-flow pass focused on saving the
  accepted photo and moving into the filled receipt review without dropping the
  user back to the blank receipt start.

### Receipt Camera Pass 674: Accepted Photo Handoff Regression Batch

Status: complete.

What changed:
- Built the debug APK after native CameraX label/settings changes to prove the
  Android native camera code still compiles.
- Strengthened the assisted receipt review test so accepting receipt photos
  cannot silently route back to the capture/blank-start area.
- Added guards proving `_markReceiptPhotoReviewAccepted` keeps
  `_receiptReviewFlowStarted` true, sets the handoff stage to
  `Opening filled receipt review`, saves the draft, records preparation
  telemetry, and scrolls to the receipt review area.
- Added import-flow ordering guards proving the accepted-photo callback happens
  before reviewed-photo read status starts, and before OCR reads the accepted
  photos for the receipt form.

Validation:
- `flutter build apk --debug`
- `dart format test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a combined camera regression sweep
  over native bridge, receipt capture layout, camera result, and assisted
  review tests before the next functional camera pass.

### Receipt Camera Pass 675: Combined Camera Regression Sweep Batch

Status: complete.

What changed:
- Updated the remaining capture-layout bridge expectations from old
  `Review Photo` / `Review Photos` wording to the new native `Next` handoff
  wording.
- Ran the native bridge, capture layout, camera result, and assisted receipt
  review tests together so recent native settings, identity, handoff wording,
  and accepted-photo flow changes are verified as one camera stack.
- Confirmed the combined suite passes with the native CameraX/AVFoundation
  controls, captured-photo handoff, saved-photo diagnostics, OCR source handoff,
  stitching/fallback summaries, and filled receipt review handoff guards all in
  the same regression run.

Validation:
- `dart format test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native settings coverage beyond the
  reset path: add/verify plain receipt wording for capture quality, data-saving
  proof size, OCR-original-first, long receipt mode, and optional automatic
  capture without making automatic capture block manual shutter.

### Receipt Camera Pass 676: OCR-First Capture Quality Settings Copy Batch

Status: complete.

What changed:
- Added Android native receipt settings copy explaining that Maintainiac takes
  the clearest native photo for OCR first, then applies save-space proof size
  after receipt reading.
- Added the matching iOS AVFoundation settings summary line.
- Added Android/iOS bridge tests so OCR-first capture quality and post-read
  proof sizing stay visible in native settings.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is long-receipt capture guidance and
  ghost-guide handoff: make sure Android/iOS settings and diagnostics explain
  section order, overlap guidance, and manual continuation without blocking OCR.

### Receipt Camera Pass 677: Long Receipt Section Guidance Batch

Status: complete.

What changed:
- Updated Android native long-receipt settings copy to explain the real
  workflow: start at the top, add sections in order, and repeat readable lines
  so Maintainiac can match receipt pieces.
- Added matching iOS AVFoundation settings summary wording.
- Added privacy-safe `longReceiptSectionGuidance` diagnostics on Android and
  iOS with `top_to_bottom_with_readable_overlap`.
- Added bridge tests to keep the long-receipt/ghost-guide guidance visible and
  diagnostics available without storing receipt content.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture/result diagnostics for
  automatic capture as optional: make sure auto-capture cannot block manual
  shutter, and its diagnostics distinguish disabled, blocked, waiting, and
  triggered states.

### Receipt Camera Pass 678: Optional Auto-Capture Safety Contract Batch

Status: complete.

What changed:
- Added Android native diagnostic `autoCaptureSafetyPolicy` with
  `optional_manual_shutter_always_available`.
- Added the matching iOS AVFoundation diagnostic.
- Aligned iOS auto-capture settings copy with Android so it says automatic
  capture is off by default and manual shutter always works.
- Added Android/iOS bridge tests proving automatic capture remains optional and
  manual shutter availability is part of the native diagnostics contract.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is broader regression/build verification
  after the latest native settings batches, then move into captured-photo
  recovery/safe-save hardening.

### Receipt Camera Pass 679: Native Settings Compile Proof Batch

Status: complete.

What changed:
- Built the Android debug APK after native settings/diagnostics changes for
  camera identity, reset defaults, Next handoff wording, OCR-first capture
  quality, long-receipt guidance, and optional auto-capture safety.
- Confirmed the CameraX native source still compiles into a debug build.

Validation:
- `flutter build apk --debug`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is captured-photo recovery/safe-save
  hardening: prove accepted photos are staged, recovery metadata is safe, and
  leaving the review cannot silently discard a captured receipt.

### Receipt Camera Pass 680: Recovery Copy Matches Next Handoff Batch

Status: complete.

What changed:
- Updated native capture recovery copy so internal `done_*` close-action tokens
  display to the user as `Next was pressed...`, matching the current native
  camera button wording.
- Kept the existing diagnostic tokens stable so historical recovery analytics
  and tests do not lose continuity.
- Added a capture-layout guard proving recovery copy no longer says
  `Done was pressed`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is safe-save/recovery metadata depth:
  verify staged native captures carry enough privacy-safe detail for Command One
  and for the receipt flow to resume without showing private receipt content.

### Receipt Camera Pass 681: Native Recovery Privacy Metadata Batch

Status: complete.

What changed:
- Added explicit staged-photo recovery diagnostics for native captures so the
  app can tell the difference between a photo safely copied for review and a
  photo that has already been attached to an expense.
- Added recovery resume/action metadata: resume opens review before receipt
  reading, safe exits keep local recovery until accept/discard, and recovery
  evidence is summary-only.
- Added content-policy metadata to both the recovery manifest and Hive recovery
  index: no receipt text and no customer content.
- Strengthened tests that inject private-looking receipt text and prove it does
  not appear in staged diagnostics, recovery manifests, or the recovery index.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the visible post-capture review
  handoff: make the review surface harder to confuse, keep the captured photo
  visible, and ensure the next action points toward receipt-item review instead
  of falling back to the expense entry start.

### Receipt Camera Pass 682: Post-Capture Next Handoff Copy Batch

Status: complete.

What changed:
- Changed the primary post-capture action from `Next: Review Receipt Details`
  to `Next: Attach + Review Details` so the button explains that the captured
  photo is attached before opening the filled receipt review.
- Updated single-photo and multi-section status copy to say photos are saved
  locally and that Next attaches them before showing item prices, totals, and
  business/personal use.
- Kept the review controls compact while removing ambiguity about whether the
  photo was saved, attached, or discarded.
- Updated the camera layout and assisted-review guards so the old vague wording
  cannot silently come back.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/expense_receipt_assisted_review_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reducing post-capture review friction:
  verify the preview tray remains compact, the active receipt image stays the
  dominant surface, and no hidden/scroll-only action is required to continue.

### Receipt Camera Pass 683: Pinned Next Compact Review Tray Batch

Status: complete.

What changed:
- Kept the post-capture primary row pinned in preview mode so the `Next` action
  stays visible even when helper controls need to scroll on a short screen.
- Moved only the lower helper controls, long-receipt actions, quality warning
  actions, and thumbnails into a loose scroll area inside the capped tray.
- Preserved the existing 75-80% receipt-preview target while preventing the
  preview tray from overflowing on tighter phone heights.
- Added a layout guard proving the preview tray uses a loose scroll region
  instead of allowing secondary controls to push the primary action out.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is live-camera capture behavior:
  re-check pinch/tap/focus/exposure contracts and make sure manual shutter is
  never blocked by assistant guidance.
