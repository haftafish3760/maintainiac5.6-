# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Pass 701: Photo Review Count Clarity Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Pass 701: Photo Review Count Clarity Batch

Status: complete.

What changed:
- Tightened the receipt photo review tray so the selected-photo badge reads
  `Photo 1 of 1` / `Photo 2 of 3` style text instead of terse fraction-only
  `1/1` wording.
- Kept the primary action language on the professional flow: `Next: Attach +
  Review Details` still renders as a clear `Next` button with secondary
  `Attach + Review` copy.
- Added a source regression guard so the shorthand fraction label does not come
  back into the receipt review controls.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the post-capture review affordance
  around adding another receipt photo versus continuing into filled receipt
  review, especially for possible long receipts and partial-bottom warnings.

### Receipt Camera Pass 702: Partial Receipt Next Prompt Clarity Batch

Status: complete.

What changed:
- Reworded the single-photo completion prompt for possible partial receipts from
  a vague whole-receipt question to `Need another receipt photo?`.
- Changed the continue action to `Next: Review Details` so the user knows the
  app is moving into the filled receipt review, not throwing them back to the
  previous screen.
- Kept `Add Receipt Photo` as the explicit action when the receipt continues
  below the current image, while still allowing Next when the user knows the
  photo is complete.
- Updated the focused layout guard so this language cannot drift back to the old
  vague copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture brightness/exposure
  parity and saved-photo quality diagnostics, especially why a native capture may
  appear darker or softer than the phone's stock camera image.

### Receipt Camera Pass 703: Device-Tier Still Capture Policy Batch

Status: complete.

What changed:
- Audited Android CameraX and iOS AVFoundation exposure/capture paths for the
  darker-or-softer saved-photo complaint.
- Changed Android light-device still capture from always using
  `CAPTURE_MODE_MAXIMIZE_QUALITY` to `CAPTURE_MODE_MINIMIZE_LATENCY`, with a
  diagnostic label of `receipt_latency_light_device`. This favors faster,
  steadier receipt capture on older phones where max-quality capture can be more
  likely to blur or drift from the live preview.
- Kept Android balanced/flagship capture on `CAPTURE_MODE_MAXIMIZE_QUALITY`.
- Added source guards proving Android is now tier-aware and iOS keeps its
  existing tier-aware `photoQualityPrioritization` policy: `.quality` for
  flagship, `.balanced` otherwise.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is saved-photo warning calibration and
  review copy for dark/dim/bottom-dark captures so users know whether to retake,
  add light, raise brightness, crop, or continue.

### Receipt Camera Pass 704: Bottom Readability Warning Calibration Batch

Status: complete.

What changed:
- Calibrated saved-photo bottom-dark warnings so a top-to-bottom brightness
  difference does not automatically warn when the bottom of the receipt is still
  bright enough and edge detail is strong.
- Added `latestCapturedBottomLuma` into the saved-photo warning decision so
  bottom-specific readability can suppress false bottom-dark warnings.
- Kept real bottom-dark/bottom-soft warnings active when bottom lines, totals,
  barcode, or final receipt lines are likely risky for OCR.
- Added a regression proving a bottom section that is darker than the top but
  still readable does not surface a warning.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_result_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture/review performance:
  reduce delay when opening the just-captured photo review and make sure async
  preview/quality work cannot freeze or call into disposed review widgets.

### Receipt Camera Pass 695: Native Capture Recovery Guarantee Batch

Status: complete.

What changed:
- Hardened the native receipt capture staging/recovery metadata so every staged
  photo now carries explicit recovery guarantees:
  - resume checkpoint is after native capture and before OCR
  - OCR source policy uses the original staged photo before any data-saving copy
  - cleanup only happens after accept, user discard, or old abandoned cleanup
  - write order is copy photo, then manifest, then Hive index
- Added the same guarantees to the recovery manifest and Hive recovery index so
  interrupted work can be diagnosed even if the app closes before review.
- Expanded privacy-safe recovery evidence labels with checkpoint, OCR-source,
  and cleanup tokens while continuing to exclude receipt text, customer content,
  merchant names, item descriptions, prices, and addresses.
- Added regression coverage proving the manifest, Hive index, per-photo
  diagnostics, and Hive-only recovery path all preserve those guarantees.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-flow recovery routing:
  make sure restored native captures reopen into photo review/OCR handoff with
  the same Next semantics, add-photo path, and privacy-safe diagnostics instead
  of falling back to the generic expense entry surface.

### Receipt Camera Pass 696: Recovered Capture Review Routing Batch

Status: complete.

What changed:
- Hardened the recovered native capture route so resumed photos explicitly open
  the receipt photo review before the reader/fill step.
- Added recovery-stage breadcrumbs for recovered captures:
  - `recovery_review_opening`
  - `recovery_review_interrupted`
  - `recovery_review_closed`
  - `recovery_review_accepted`
- Preserved the user promise that recovered photos stay locally recoverable if
  the review is closed or interrupted before accept.
- Changed accepted recovery diagnostics to point at
  `open_filled_review_or_save_proof`, matching the actual user flow after Next.
- Added safe-listed metadata for recovery route/source, recovered/kept/accepted
  photo counts, and multiple-section state.
- Updated shareability guards so the reusable camera/OCR flow keeps current
  Next/Attach/Review wording instead of stale receipt-reader labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the photo-review Next handoff itself:
  verify the accepted photo result always carries OCR source photos, proof
  photos, stitch status, data-saving choice, and route metadata needed to open
  the filled receipt review immediately after photo acceptance.

### Receipt Camera Pass 697: Accepted Photo Handoff Route Contract Batch

Status: complete.

What changed:
- Added explicit route metadata to `ReceiptPhotoReviewResult` for the accepted
  photo handoff:
  - `photo_review_accepted_to_filled_receipt_review`
  - `filled_receipt_review_store_date_total_tax_items`
  - `tap_next_after_photo_review`
- Carried those values through privacy-safe receipt-reader handoff metadata so
  expenses, materials, and maintenance can share the same camera/OCR result
  without guessing the next screen from UI copy.
- Updated result coverage to prove saved proof photos, OCR source photos,
  stitch status, data-saving choice, and route metadata survive result freezing.
- Kept the OCR rule explicit: OCR reads the clear source first; saved proof/data
  saver copies are for review/storage.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the receipt reader handoff
  diagnostics in `ReceiptCaptureFlow` surface the new route contract everywhere
  a reviewed camera photo is accepted or resumed.

### Receipt Camera Pass 698: Flow Handoff Route Diagnostics Batch

Status: complete.

What changed:
- Surfaced accepted-photo route metadata at the top level of
  `ReceiptCaptureFlow` diagnostics:
  - `receiptReaderHandoffRoute`
  - `receiptReaderHandoffNextScreen`
  - `receiptReaderHandoffUserAction`
- Kept the same values inside `receiptReaderHandoffMetadata` for structured
  consumers, but made Command One / expense telemetry easier to read without
  digging into nested maps.
- Added shareability guards so the shared camera/OCR flow keeps these route
  fields visible across expense, materials, and maintenance callers.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is verifying the expense receipt entry
  consumes these handoff fields and immediately presents the filled receipt
  review state after accepted photos instead of returning the user to a generic
  receipt attachment surface.

### Receipt Camera Pass 699: Expense Filled-Review Consumption Guard Batch

Status: complete.

What changed:
- Audited the expense receipt entry handoff path after accepted camera photos.
- Confirmed the entry screen already does the correct visible flow:
  - accepted photo review marks the receipt flow as started
  - stage becomes `Opening filled receipt review`
  - the screen scrolls to the filled receipt review area
  - the waiting panel tells the user store, date, total, tax, and item prices
    will appear there as soon as the filled review is ready
- Added guard coverage proving the shared result model owns the handoff route
  fields while the expense entry screen consumes the structured metadata spread.
- No production code change was needed in the expense entry screen for this
  pass; the pass locked the current correct ownership boundary.

Validation:
- `dart format test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native-camera capture surface
  again: verify preview/control diagnostics and tests still prove back, settings,
  torch, tap focus, pinch zoom, and exposure controls are present without
  depending on the stock Samsung camera UI.

### Receipt Camera Pass 687: Quality Warning Action Priority Batch

Status: complete.

What changed:
- Tightened the post-capture quality recovery strip so bottom-of-receipt
  warnings lead with `Add Receipt Photo` instead of making the user hunt for the
  long-receipt fix.
- Kept full-frame critical quality warnings leading with `Retake`, while bottom
  soft/dark warnings now emphasize adding the missing/weak lower receipt
  section before crop or retake.
- Preserved the separate `Next` continuation path so readable receipts are not
  blocked by advisory quality warnings.
- Added layout guard coverage proving the add/crop/retake ordering remains
  intentional and does not drift back into generic quality recovery behavior.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_quality_guidance_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture review speed and
  lifecycle hardening so accepted photos, back/close actions, and async preview
  work do not freeze, silently discard images, or leave the user trapped.

### Receipt Camera Pass 688: Review Close Lifecycle Hardening Batch

Status: complete.

What changed:
- Fixed the receipt photo review close transition so it no longer sets
  `_closingReview` and then tries to update through the normal review-work
  helper that refuses to run after closing starts.
- Added a State-owned close helper that enters closing mode and clears save,
  camera, crop, and confirmation flags in one legal state update.
- Cancelled/cleared stitch preview, storage preview, quality check, and
  data-saver preview in-flight work before leaving the review surface so
  background image work cannot keep the screen half alive.
- Applied the same close transition before popping a successful
  `ReceiptPhotoReviewResult`, reducing the chance of async preview callbacks
  racing the final `Next: Attach + Review Details` handoff.
- Strengthened the layout/lifecycle guard so this close behavior stays
  intentional.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture UI parity around
  back/settings/torch placement and ensuring the live camera path exposes
  receipt-specific controls without falling back to stock camera UI.

### Receipt Camera Pass 689: Native Capture UI Contract Diagnostics Batch

Status: complete.

What changed:
- Added privacy-safe native diagnostics proving the Android and iOS capture
  surfaces are Maintainiac custom receipt-camera UIs, not stock phone-camera
  UIs.
- Added shared diagnostic keys for the native UI contract, stock camera usage,
  settings/back/torch/shutter placement, and the after-capture Next placement.
- Kept the diagnostics content-free: they describe the capture surface and
  visible controls, not receipt text, merchant data, user data, or device
  identity.
- Strengthened Android CameraX and iOS AVFoundation bridge tests so both native
  sides stay aligned on custom receipt UI expectations.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is capture-to-review speed and image
  preview responsiveness so tapping the captured photo/review path does not
  hesitate longer than a professional camera flow should.

### Receipt Camera Pass 690: Review Preview Decode Responsiveness Batch

Status: complete.

What changed:
- Kept OCR-first behavior untouched: OCR still uses the clear/original source
  before storage-saving backup work.
- Optimized the post-capture review image display so the UI preview decodes at
  an on-screen receipt-review size instead of decoding a full camera-resolution
  image just to show it on the phone.
- Added gapless preview rendering and medium display filtering for the main
  receipt review image so the review surface feels more immediate when users
  enter photo review.
- Added thumbnail decode caps for the photo strip so small receipt thumbnails
  do not waste full-size image decode work.
- Added layout/performance guard coverage so this display-only optimization
  does not regress into full-resolution UI decode.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture exposure/brightness
  parity, especially proving capture guidance and diagnostics explain when a
  saved photo is darker than the live preview.

### Receipt Camera Pass 691: Native Exposure Rescue Parity Batch

Status: complete.

What changed:
- Strengthened the last-second pre-capture exposure rescue for dim receipts on
  Android CameraX and iOS AVFoundation. Very dark receipts now get a stronger
  brightness nudge before capture, dim receipts get a moderate nudge, and
  borderline-dim receipts get a light nudge.
- Kept bright receipts predictable: pre-capture still avoids dimming readable
  bright receipts right before the user taps the manual shutter, leaving glare
  handling to live assist, guidance, and user review.
- Added a shared privacy-safe `preCaptureExposurePolicy` diagnostic so QA and
  Command One can tell which native brightness policy was active without seeing
  receipt content.
- Aligned iOS auto-capture light readiness with Android so automatic capture
  waits for a safer receipt brightness range on both platforms.
- Strengthened native bridge tests so the exposure rescue thresholds and policy
  diagnostics stay aligned across CameraX and AVFoundation.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is post-capture dark/blur review copy
  and action routing so the user gets a clear retake/add-photo/continue choice
  when saved-photo evidence says the image changed from the live preview.

### Receipt Camera Pass 692: Saved-Photo Warning Primary Action Batch

Status: complete.

What changed:
- Added `primaryActionLabel` to native saved-photo warning models so each
  post-capture evidence bucket has a plain recommended action.
- Updated the receipt photo review status copy so native warnings say the
  recommended action directly instead of only appending a generic
  "tap Next if readable" message.
- Kept the professional no-block behavior: `Next` remains available for
  readable receipts, but the user now sees whether the preferred action is
  retake, add another receipt photo, raise brightness, reduce glare, or review
  readability.
- Added model and layout guards so darker-than-preview, brightness-assist,
  dimmer-than-preview, and bottom-section warnings keep clear action labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native live preview focus/zoom
  diagnostics and touch-path parity, especially proving pinch zoom and tap focus
  are active on the custom Maintainiac receipt camera surfaces.
