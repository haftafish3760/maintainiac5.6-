# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 141: Real Receipt Line Review Entry Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 141: Real Receipt Line Review Entry Batch

Status: completed.

Goal:
- Make the app-filled receipt review guide the user clearly into Business /
  Personal / Mixed classification and surface the strongest privacy-safe warning
  when OCR or parsing needs attention.

Completed:
- Changed attached receipt OCR no-text handling to show the OCR result's
  strongest action message instead of whichever warning happened to come first.
- Added primary parsed-warning selection that prioritizes missing, could-not,
  failed, low-confidence, and mismatch warnings.
- Updated successful parse handoff copy to explicitly tell the user to classify
  the receipt as Business, Personal, or Mixed and review the lines before
  saving.
- Updated parse-warning handoff copy to keep the warning but still direct the
  user into classification and line review.
- Added assisted-review source guards for the stronger warning selection and
  classification handoff copy.

Verification:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture lib/screens/expenses/entry`
- `git diff --check`

### Receipt Camera Reopen Pass 140: Receipt Review Failure Detail Batch

Status: completed.

Goal:
- Make app-assisted receipt-read failures explain the strongest confirmed issue
  and a concrete next action instead of flattening every failure into vague
  retry copy.

Completed:
- Added `primaryWarning` to OCR results so blocking warnings outrank partial
  and review warnings.
- Added `strongestActionMessage` to OCR results for privacy-safe user guidance.
- Updated OCR review messages to use the strongest structured warning instead
  of the first raw warning string.
- Updated no-text receipt-photo failure copy to keep the proof attached and
  give concrete options: add another receipt photo, retake, or enter manually.
- Added tests proving no-readable-text outranks duplicate/overlap warnings in
  user-facing action copy.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 139: Review-To-App-Filled Receipt Handoff Batch

Status: completed.

Goal:
- Make the transition from approved receipt photos into app-assisted receipt
  filling visible, deterministic, and lifecycle-safe.

Completed:
- Added a reviewed-photo handoff status before OCR begins so the user sees that
  receipt photos were saved and are being read into the receipt form.
- Tailored the handoff copy for single photos, multi-section receipts, and
  stitched receipt images.
- Reused the existing app-assisted settings gate so proof-only mode stays
  proof-only.
- Added mounted checks after reviewed-photo OCR before updating photo read
  states.
- Added a mounted guard after the receipt text is handed to the form and before
  the attachment panel updates its own state.
- Added source guards proving the review-to-form handoff is announced before
  OCR and that the async form-fill callback is lifecycle-safe.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 138: Camera Capture Flow Real-Device Polish Batch

Status: completed.

Goal:
- Make the first photo review surface clearer and more professional on real
  phones without hiding critical receipt actions in a tiny horizontal drawer.

Completed:
- Added a compact `current/total` receipt photo badge to the preview tray.
- Changed single-photo and multi-photo copy to explain that `Next` opens the
  filled receipt review, while additional photos are for continuing long
  receipts.
- Reworded the add-photo actions to `Add Another Receipt Photo` and `Add Next
  Receipt Photo`.
- Reworded crop and data-saver actions to `Crop / Straighten` and `Save Space
  Preview`.
- Replaced the preview action rail's horizontal scroller with a wrapped action
  layout so key controls stay visible without a hidden control drawer.
- Raised preview-mode bottom control caps enough to fit the wrapped scanner
  controls while keeping the receipt image dominant.
- Added source guards proving the preview tray uses explicit receipt language
  and a wrapped action panel.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 137: Exposure Retry Failure Recovery Batch

Status: completed.

Goal:
- Keep the camera lifecycle safe when exposure retries cross async gaps or when
  capture exits early.

Completed:
- Added mounted/closing guards immediately after async exposure adjustment in
  manual capture before widget state is touched.
- Added mounted/closing guards immediately after async exposure adjustment in
  assisted capture before widget state is touched.
- Moved manual capture exposure restoration into a `finally` block so native
  baseline recovery still runs after early returns or capture errors.
- Moved assisted capture exposure restoration into a `finally` block so guided
  capture cannot leave the camera in a nudged exposure state.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_screen.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 136: Capture Exposure Retry Strategy Batch

Status: completed.

Goal:
- Give dark/glare capture sessions a bounded second chance without abandoning
  native auto exposure as the default camera behavior.

Completed:
- Added per-candidate exposure offset tracking to camera candidates.
- Added selected/candidate exposure offsets to privacy-safe camera capture
  evidence.
- Kept the first receipt photo at the native auto-exposure baseline.
- Added a bounded exposure nudge only for later candidates when live guidance
  says the frame is too dark or too bright.
- Clamped every exposure retry to the camera-reported min/max exposure range.
- Restored the native exposure baseline after the candidate burst.
- Added model and source guards proving exposure retries are bounded,
  evidence-backed, and not a blind always-on exposure change.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 135: Review Continue Safety For Critical Photos Batch

Status: completed.

Goal:
- Keep users from mistaking a critical dark/glare/blurry photo for a normal
  review-ready receipt while still allowing them to continue when they decide
  the receipt is readable.

Completed:
- Changed the preview-mode continue label to `Review Anyway` when the selected
  photo has a critical quality issue.
- Kept normal `Next` behavior for readable or non-critical photos.
- Added a source guard proving critical photo quality changes the preview
  continue copy before the normal `Next` branch.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 134: Brightness Review Feedback And Retake Guidance Batch

Status: completed.

Goal:
- Make dark/glare receipt photo problems obvious in the photo review surface so
  users know whether to retake, add light, turn on the torch, or reduce glare.

Completed:
- Added quality-aware status icons in the photo review tray.
- Added warning color treatment for critical photo quality issues.
- Changed critical-quality review copy to include `Retake Recommended` and the
  concrete dark/glare guidance from the photo quality model.
- Made `Retake Now` the emphasized preview action for critical photo issues.
- Kept normal/add-photo emphasis when the selected photo does not have a
  critical quality issue.
- Added source and model guards for dark/glare guidance and critical retake
  emphasis.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 133: Brightness-Aware Capture Candidate Selection Batch

Status: completed.

Goal:
- Make best-shot selection explicitly prefer readable, properly lit receipt
  images before falling back to generic score or pixel count.

Completed:
- Added `brightnessDistanceFromReceiptIdeal` to receipt photo quality checks.
- Updated best-shot candidate ranking to reject critical quality issues before
  normal readability scoring.
- Added explicit dark/glare ordering so a large but poorly lit photo does not
  beat a cleaner receipt image.
- Added brightness-distance, contrast, and text-band tie breakers before final
  pixel-count tie breaking.
- Added tests/source guards proving brightness-aware ranking happens before
  resolution tie breaking.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_capture.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 132: Review Image Brightness And Native Capture Evidence Batch

Status: completed.

Goal:
- Add privacy-safe evidence for dark/bright receipt captures so the app can
  tell whether capture quality problems came from native camera state, lighting,
  preview analysis, or later image processing.

Completed:
- Added `ReceiptCameraCaptureEvidence` to `ReceiptCameraResult`.
- Tracked capture surface, capture flow, resolution tier, actual resolution
  preset, flash mode, exposure mode, focus mode, focus/exposure point support,
  applied exposure offset, exposure range, zoom range, preview size, live
  brightness, live contrast, live focus score, readiness, and stream state.
- Populated capture evidence for both manual and assisted custom-camera
  captures.
- Recorded the actual resolution preset that initialized successfully after
  fallback.
- Stored the actual exposure offset returned by the native camera plugin when
  the app resets exposure to the native auto-exposure baseline.
- Added model and source guards proving brightness/exposure evidence stays
  attached to camera results without collecting receipt content.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_setup.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_camera_screen.dart lib/shared/widgets/receipt_capture/receipt_camera_setup.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_result_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 131: Crop Failure And Storage Recovery Copy Batch

Status: completed.

Goal:
- Prevent crop mode from leaving the review screen in a stuck processing state
  when async storage validation returns after crop mode has already been exited.

Completed:
- Split the crop apply post-storage guard into explicit mounted and mode checks.
- Cleared `_cropProcessing` before returning when the crop session is no longer
  active.
- Added a source guard proving the interrupted crop path clears processing
  before any storage failure handling continues.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 130: Crop Apply And Preview Recovery Batch

Status: completed.

Goal:
- Make crop apply/cancel behavior recover predictably, avoid stale crop state,
  and keep async crop work tied to the crop that the user actually accepted.

Completed:
- Added a dedicated crop cancel path that clears crop processing, source bytes,
  decoded image size, crop rectangle, and display rectangle.
- Routed both the crop top-bar close action and bottom `Cancel` action through
  that shared cleanup path.
- Made `Apply Crop` snapshot the current crop bytes, display rectangle, and crop
  rectangle before async storage/image work starts.
- Added a user-facing recovery message when Apply Crop is tapped before crop
  data is ready.
- Routed successful crop completion through the shared review-mode transition so
  preview controls reset cleanly.
- Added source guards proving crop apply/cancel cannot leave stale crop state.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 129: Crop Mode Readability And Edge Controls Batch

Status: completed.

Goal:
- Make receipt crop mode easier to understand and easier to operate on a phone
  without covering the receipt image.

Completed:
- Increased crop handle hit targets and visible edge/corner sizes so users can
  grab receipt edges more reliably.
- Added high-contrast corner handle centers and stronger handle outlines.
- Added accessibility labels for each crop edge and corner.
- Replaced the icon-only crop cancel affordance with a labeled `Cancel` action.
- Renamed the crop confirmation action to `Apply Crop`.
- Added compact crop instructions inside the bottom tool controls instead of
  over the receipt image.
- Added source guards proving crop handles stay touchable and crop controls
  remain plainly labeled.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 128: Receipt Review Mode Transition Polish Batch

Status: completed.

Goal:
- Keep receipt-review mode switches predictable by preventing stale scroll
  positions from carrying between Review, Crop, Order, Match, and Save Space.

Completed:
- Added a mode-transition scroll reset so each tool mode starts at the top of
  its controls.
- Guarded the scroll reset so it only touches the controller when attached.
- Routed crop top-bar close through the shared review-mode switch.
- Routed crop cancel through the shared review-mode switch.
- Added source guards proving mode changes reset the tool scroll position and
  crop exits use the shared transition path.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 127: Review Continue Button Persistence Batch

Status: completed.

Goal:
- Keep the `Next` / receipt-review handoff action visible in tool modes even
  when the crop/order/match/save-space details need to scroll.

Completed:
- Passed the receipt-review tool scroll controller into the bottom-controls
  widget instead of wrapping the whole tray from the screen.
- Moved the visible scrollbar and scroll view inside the non-preview tool
  content area only.
- Added a persistent continue button below the scrollable tool details so the
  user does not have to hunt for `Next`.
- Preserved the waiting-for-stitch disable behavior and the saving spinner/copy
  on the persistent action.
- Added source guards proving the scrollbar appears before the persistent
  continue button and that the screen wires the scroll controller into the
  controls.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 126: Review Tool Mode Height And Scroll Batch

Status: completed.

Goal:
- Make capped tool trays usable on phone screens when crop/order/match/save-space
  controls are taller than the available review tray height.

Completed:
- Added a dedicated scroll controller for receipt-review tool controls.
- Wrapped non-preview review tool trays in a visible `Scrollbar` so scrollable
  controls are discoverable instead of silently clipped.
- Kept preview mode unwrapped so the primary review tray remains direct and
  compact.
- Disposed the tool-control scroll controller with the review screen lifecycle.
- Added source guards for the controller, disposal, and visible scrollbar
  contract.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

### Receipt Camera Reopen Pass 125: Review Surface Tool Affordance Batch

Status: completed.

Goal:
- Make secondary receipt-review tools understandable on a phone without relying
  on tooltip-only icon buttons.

Completed:
- Reworked the non-preview tool context row into a compact labeled action card.
- Replaced the icon-only Add/Retake/Remove controls in tool modes with labeled
  mini action buttons.
- The Add action now says Add Next Photo when multiple receipt sections exist
  and Add Another Photo for a single receipt section.
- Kept the action strip horizontally scrollable and compact so crop/order/match
  tools remain usable without taking over the receipt preview.
- Added guards that the tool-mode action row uses visible labels instead of
  tooltip-only icons.

Verification:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`
