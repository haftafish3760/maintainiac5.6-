# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 834: OCR Source Fallback Visibility Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 834: OCR Source Fallback Visibility Batch

Status: complete.

What changed:
- Made the saved-proof OCR fallback explicit in `ReceiptPhotoReviewResult`
  through `usedSavedProofAsOcrSourceFallback`.
- Added privacy-safe handoff counts and evidence wording when OCR source paths
  are missing and saved proof paths are used as a fallback.
- Added shared-flow and expense attachment document signals:
  `receipt_handoff_ocr_source_fallback_saved_proof`.
- Added shared-flow and expense attachment risk flags:
  `ocr_source_fallback_saved_proof_review_required`.
- Kept the fallback available as a user-safety net, but no longer lets it look
  like the ideal prepared-source OCR path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result falls back to saved proof paths if OCR paths are missing"`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "accepted shared flow clears interrupted native recovery after attach"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is source/proof diagnostics through
  expense telemetry and review copy so users and Command One can distinguish
  ideal OCR sources from fallback proof reads.

### Receipt Camera Reopen Pass 835: Accepted Photo OCR-Start Health Bridge Batch

Status: complete.

What changed:
- Bridged accepted photo-review telemetry into the OCR source health rollup by
  emitting `ocrSourceHandoffStatus` and `ocrSourceHandoffSignalCounts` when
  receipt photo review is accepted.
- The accepted-photo event now marks `saved_proof_fallback` when OCR source
  paths are missing and otherwise reports the next-review match readiness
  outcome.
- Updated the health snapshot aggregator so `ocrStarted` events merge OCR
  source handoff status/signals, not only `ocrCompleted`, `ocrFailed`, and
  parser events.
- Added Command One-style regression coverage for
  `ocr_source_fallback_saved_proof` and
  `ocr_source_fallback_saved_proof_review_required`.
- Kept the telemetry content-free: only status/count buckets are emitted, not
  receipt images, receipt text, merchant names, addresses, prices, or line
  descriptions.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is post-capture review copy and action
  routing so fallback proof reads tell the user to review/retake/add clearer
  photo without blocking them from continuing.

### Receipt Camera Reopen Pass 836: Saved-Proof OCR Fallback Review Warning Batch

Status: complete.

What changed:
- Added a user-facing receipt detail warning when OCR has to use the saved proof
  copy because a clearer OCR source was not available.
- Reused the existing handoff warning area instead of adding another block to
  the receipt detail UI.
- Preserved the partial-receipt warning and combines it with the fallback
  warning when both risks exist.
- Added source coverage tying `usedSavedProofAsOcrSourceFallback` to the warning
  copy.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native camera result diagnostics and
  bridge-source tests around manual shutter, close/back, tap focus, pinch zoom,
  and exposure so real-device failures point to exact causes.

### Pass 826: Flutter Native Close Outcome Consumption Batch

Status: complete.

What changed:
- Added Flutter-side close outcome counting for native camera diagnostics using
  `closeCapturedPhotoOutcome`.
- Added a privacy-safe native close health outcome so the receipt flow can
  distinguish healthy protected exits (`back_returned_captured_sections` and
  `next_returned_captured_sections`) from real close failures.
- Added native close outcome metadata and evidence labels to the receipt reader
  handoff so Command One can see whether a back/close event preserved or lost a
  captured photo without seeing private receipt content.
- Wired native close outcome document signals and risk flags into both the
  widget import path and the shared `ReceiptCaptureFlow` path.
- Added focused tests proving protected back-returned captured sections are not
  treated as a risk, while `capture_failed_after_close` is treated as a camera
  risk.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result summarizes native camera close health"`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result flags failed native close after capture"`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "shared camera OCR flow stays module neutral"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the native close/back
  overlay UI contract so the user never gets trapped in the camera, never loses
  a captured photo by backing out, and always has an obvious Next/Add photo path
  from photo review to receipt details.

### Pass 827: Native Add Photo Control Contract Batch

Status: complete.

What changed:
- Added an explicit native `Add Photo` control on Android CameraX after the
  first captured receipt section so users are not expected to guess that the
  shutter icon means "add another receipt photo."
- Added the same visible `Add Photo` control on iOS AVFoundation.
- Kept the manual shutter working normally, including after a captured section.
- Kept `Next` as the clear path from captured photos to receipt photo review and
  receipt details.
- Added `add_photo` to native visible-control diagnostics when the control is
  available, so Command One can verify the UI contract without receipt content.
- Updated native Android/iOS bridge and cross-platform layout guard tests to
  protect the visible Add Photo/Next contract.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "native bridge source rejects stock camera controllers"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the photo review screen less
  confusing after capture by tightening visible action hierarchy, reducing stale
  "review receipt photo" wording, and keeping Next/Add Photo/Crop/Retake
  discoverable without hiding the receipt image.

### Pass 828: Photo Review Wording Clarity Batch

Status: complete.

What changed:
- Renamed the post-capture image review title from `Review receipt photo` to
  `Review Photo` so it does not sound like the parsed receipt-details screen.
- Changed the single-photo badge from generic `Receipt Photo` to `Photo 1 of 1`,
  matching the multi-photo `Photo X of Y` pattern.
- Removed a premature "filled receipt details" phrase from the single-photo
  completion prompt; it now promises receipt details, not that OCR has already
  filled the form.
- Updated review/top-bar/layout guard tests so future changes preserve the
  clearer photo-review versus receipt-details language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is layout hardening for the photo review
  bottom controls so the receipt image remains dominant and the controls stay
  compact across short/tall phones.

### Pass 829: Photo Review Primary Add/Next Action Batch

Status: complete.

What changed:
- Promoted a compact `Add` button into the primary photo-review row so the two
  core choices are always visible after capture: add another receipt photo or
  go Next to receipt details.
- Kept the larger Add Another Photo/Retake/Crop/Proof tools available in the
  lower tool area, but removed dependence on scrolling to discover Add Another
  Photo.
- Preserved the capped bottom-control height so the receipt image remains the
  dominant part of the screen.
- Added guard tests for the always-visible Add control, semantic label, and
  explicit long-receipt wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review bottom controls stay capped by mode"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is photo-review resilience: make sure
  close/back dialogs, async preview work, and saved local recovery do not call
  disposed contexts or lose staged photos.

### Receipt Camera Reopen Pass 822: Native Receipt Details Settings Copy Batch

Status: complete.

What changed:
- Updated Android CameraX receipt camera settings so assisted fill says it opens
  receipt details instead of a filled receipt review.
- Renamed Android Receipt review style to Receipt details style.
- Updated iOS AVFoundation receipt camera settings actions to Receipt details
  style: prices only and Receipt details style: detailed lines.
- Updated iOS guidance after selecting price-only or detailed line mode so it
  says receipt details instead of receipt review.
- Kept the native bridge contract intact: Maintainiac-owned preview, no stock
  camera UI as the primary surface, tap-focus, pinch-zoom, brightness controls,
  settings, and back controls remain covered by bridge tests.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a source-readiness sweep for the
  capture handoff so OCR source photos, saved proof photos, and receipt details
  status all stay separate and diagnostic-safe.

### Receipt Camera Reopen Pass 823: OCR Source And Receipt Details Handoff Batch

Status: complete.

What changed:
- Updated the accepted-photo handoff route from
  `photo_review_accepted_to_filled_receipt_review` to
  `photo_review_accepted_to_receipt_details`.
- Updated the handoff next-screen token from
  `filled_receipt_review_store_date_total_tax_items` to
  `receipt_details_store_date_total_tax_items`.
- Added the new privacy-safe
  `receiptReaderHandoffMustOpenReceiptDetails` metadata key while preserving
  the old `receiptReaderHandoffMustOpenFilledReview` key for compatibility.
- Renamed remaining user-facing waiting panels from filled receipt review to
  receipt details, including shared attachment status, expense entry fallback
  panel, parsed handoff panel, and stitch-readiness guidance.
- Kept OCR/source/proof separation explicit: OCR reads the clear source first,
  saved proof copies remain storage/recovery artifacts, and receipt details are
  the screen where the user checks store/date/total/tax/items and
  Business/Personal/Mixed choices.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_controls.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_result_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "reviewed receipt photos announce app fill handoff safely"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "accepted camera photo starts receipt details before OCR work finishes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the native capture
  settings contract so the Dart service, Android CameraX activity, and iOS
  AVFoundation controller agree on every exposed receipt-camera control and
  every privacy-safe diagnostic key.

### Receipt Camera Reopen Pass 824: Native Source-Proof Safety Parity Batch

Status: complete.

What changed:
- Wired `saveOriginalTemporarily`, `queueAcceptedCaptureLocally`, and
  `ocrUsesOriginalFirst` through Android CameraX session parsing.
- Wired the same three source/proof safety flags through the iOS AVFoundation
  session argument parsing.
- Added those flags to native privacy-safe capture diagnostics so Command One
  and receipt health checks can tell whether accepted-photo recovery and
  clear-source-first OCR were actually enabled for a capture.
- Kept the diagnostics content-free: these are boolean/session-policy flags,
  not receipt text, merchant names, item lines, or prices.
- Added Android/iOS bridge-test guards proving the flags are read from Dart and
  emitted in native diagnostics.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening receipt-camera
  interruption/back/close diagnostics around accepted photos so a captured
  receipt section is never silently discarded or mislabeled.

### Receipt Camera Reopen Pass 825: Native Close Protection Outcome Batch

Status: complete.

What changed:
- Added Android CameraX `closeCapturedPhotoOutcome()` with privacy-safe buckets:
  back returned captured sections, Next returned captured sections, capture
  failed after close, closed without photo, waiting for in-flight capture, close
  already delivered, and open/not closed.
- Added matching iOS AVFoundation `closeCapturedPhotoOutcome()` buckets.
- Added `closeCapturedPhotoPolicy` and `closeCapturedPhotoOutcome` to native
  capture diagnostics so Command One can explain back/close failures without
  seeing receipt content.
- Kept the policy explicit: back returns captured sections before canceling, and
  in-flight capture close requests wait for the capture result instead of
  silently discarding the photo.
- Added Android/iOS bridge-test guards for the new close policy and outcome
  diagnostics.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt ios/Runner/ReceiptCameraViewController.swift test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making Flutter-side receipt capture
  diagnostics consume the new native close outcome so review warnings and
  telemetry can separate back-returned sections from close/cancel failures.

### Receipt Camera Reopen Pass 821: Photo Review To Receipt Details Copy Batch

Status: complete.

What changed:
- Cleaned up the capture handoff wording so the captured-image screen is called
  photo review and the parsed/OCR form screen is called receipt details.
- Updated photo-review buttons, status messages, stitch guidance, saved-proof
  recovery copy, OCR handoff messages, and expense receipt entry statuses to
  say that Next opens receipt details instead of a vague filled receipt review.
- Renamed close/back labels on the photo review screen to Leave photo review so
  the user is not told they are leaving the parsed receipt details screen.
- Kept the explicit primary button label Next: Review Receipt Details, because
  it tells the user exactly where the flow is going after accepting the photo.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "accepted camera photo starts receipt details before OCR work finishes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is bridge parity and focused tests for
  native tap-focus, pinch-zoom, exposure/reset, settings, and back/close
  diagnostics.

### Receipt Camera Reopen Pass 813: Saved-Proof Preview Language Batch

Status: complete.

What changed:
- Tightened the saved-proof preview panel so it plainly says receipt reading
  uses the clear OCR source first.
- Renamed the misleading cloud row from "Cloud backup copy" to "Proof kept
  after reading" so the UI does not imply a cloud upload happened.
- Renamed "Cloud backup" to "Backup status" so connected/offline cloud state is
  shown as status only.
- Kept saved-proof sizing visible for the user without mixing it up with OCR
  quality or cloud backup.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart test/receipt_camera_help_flow_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt review continuation copy explains the next screen"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the review panel save/next
  wording so a single accepted photo always presents "Next: Review Receipt
  Details" and never feels like it silently returns to the entry form.

### Receipt Camera Reopen Pass 814: Single-Photo Add-Another Clarity Batch

Status: complete.

What changed:
- Replaced the vague single-photo review action label "Add Photo" with
  "Add Another Photo" after a receipt photo has already been captured.
- Tightened the tooltip to say the action is for adding another receipt photo
  only when the receipt continues.
- Kept "Next: Review Receipt Details" as the primary action so the next step
  stays explicit: open the filled receipt details, not return to the entry
  page.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review tray uses explicit long-receipt language"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking the actual review exit/back
  copy and lifecycle guards so a captured receipt photo cannot be lost or
  silently abandoned when the user backs out.

### Receipt Camera Reopen Pass 815: Review Back Lifecycle Guard Batch

Status: complete.

What changed:
- Tightened the receipt photo review back/exit path so it only pops the review
  screen after the review successfully enters its closing state.
- Converted the review-close helper to return a boolean result, preventing a
  second pop if the review is already closing or disposed.
- Fixed the async BuildContext warning in the back path by capturing
  `NavigatorState` before awaiting the exit confirmation dialog.
- Extended the back-protection guard test so captured receipt photos continue
  to be protected from silent discard.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "receipt photo back protects captured images from silent discard"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture brightness/exposure
  diagnostics and guard wording for darker-than-stock camera captures.
