# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Pass 760: Native Settings User-Language Polish Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Pass 760: Native Settings User-Language Polish Batch

Status: complete.

What changed:
- Reworded Android CameraX and iOS AVFoundation receipt camera settings copy
  from `native photo` to `receipt photo` so user-facing settings stay plain.
- Kept native implementation terms in diagnostics/tests where they prove the
  correct CameraX/AVFoundation bridge is used.
- Updated Android and iOS bridge tests to guard the non-technical settings copy.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is verifying the receipt settings sheet
  and native settings affordance describe assisted fill, long receipt capture,
  automatic capture, and backup proof size consistently across Flutter, Android,
  and iOS.

### Receipt Camera Pass 761: Receipt Proof Settings Copy Alignment Batch

Status: complete.

What changed:
- Reworded the Flutter receipt capture settings section from `Receipt Backup
  Image Size` to `Saved Receipt Proof Size`.
- Clarified that smaller saved proof files save phone/cloud storage while OCR
  still uses the clearest receipt source first.
- Updated settings guidance to point users to `Receipt Details And Backup
  Image`, matching the photo review screen label.
- Updated help/settings tests to guard the clearer saved-proof and review-panel
  copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking post-capture review controls
  for any remaining confusing labels around save-space preview, OCR source,
  crop/edit, and Next-to-filled-review behavior.

### Receipt Camera Pass 754: Native Settings Contract Platform Parity Test Batch

Status: complete.

What changed:
- Added iOS AVFoundation bridge coverage for the same receipt camera settings contract already guarded on Android CameraX.
- Guarded settings button placement, settings contract version, settings open/reset counts, settings control expectation, and visible control set on iOS.
- Confirmed iOS settings copy says these are Maintainiac receipt scanner settings, not the phone camera app.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking device-capability policy evidence in the native session so older phones and storage-constrained devices keep lighter camera/OCR workloads.

### Receipt Camera Pass 753: Native Receipt Settings Control Health Batch

Status: complete.

What changed:
- Added shared diagnostics for native receipt camera settings-control health.
- Counted whether the in-camera settings control is visible, uses the expected settings contract, sits in the expected top-right placement, and was opened.
- Added missing-control risk states for absent settings control, missing settings contract, and missing settings placement.
- Kept the diagnostics privacy-safe and summary-only: no receipt text, merchant, customer, or line-item content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_result_test.dart --reporter compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening settings-control parity in native bridge tests so Android CameraX and iOS AVFoundation both keep reporting the same receipt-specific settings contract.

### Receipt Camera Pass 752: First-Use Receipt Camera Controls Copy Batch

Status: complete.

What changed:
- Added first-use guidance that Maintainiac has in-camera receipt controls for help, long receipt guidance, flash, focus, and saved proof size.
- Kept the first-use sheet free of raw device model/RAM details.
- Refreshed stale help-flow source guards to match the current preview tray, generated-edit cleanup, and photo-order wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture settings diagnostics parity so the settings button/control contract stays visible in camera telemetry.

### Receipt Camera Pass 751: Native Cancel/No-Photo Diagnostic Split Batch

Status: complete.

What changed:
- Added explicit native capture outcome metadata for user-canceled, native-open-failed, and no-photo-returned cases.
- Added fallback-policy metadata so diagnostics can distinguish retry/import offers from phone-camera backup paths.
- Kept these diagnostics privacy-safe and free of receipt/customer content.
- Added source guards for the new outcome and fallback policy tokens.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking the first-use camera intro/settings handoff so users can reach receipt-specific settings before capture without being dumped into generic phone-camera behavior.

### Receipt Camera Pass 750: Review-Unavailable Retry Copy Batch

Status: complete.

What changed:
- Added explicit retry/import wording when the receipt photo review screen does not open after native capture.
- Added diagnostics for review-screen-unavailable failures so Command One can see that the camera worked but review did not open.
- Added a recovered-capture review-unavailable path that keeps the saved photos recoverable and tells the user to resume again or retake.
- Guarded the wording and diagnostic reasons in source tests.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the native camera cancel/no-photo diagnostic wording so it distinguishes user cancel, no returned photo, and fallback paths without blocking receipt capture.

### Receipt Camera Pass 749: Filled Review Reading Status Copy Batch

Status: complete.

What changed:
- Reworded the post-photo reading status so it says Next was accepted and the saved proof is attached.
- Made the visible copy clear that Maintainiac reads prepared OCR source photos before the smaller backup copy is saved.
- Kept the user focused on the next filled-review screen: store, date, total, tax, item prices, and Business/Personal/Mixed choices.
- Removed diagnostic evidence codes from the user-facing reading status message.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking the native camera entry/cancel paths for consistent user-facing wording around retry, import existing receipt image, and app-assisted filling.

### Receipt Camera Pass 748: Recovered Photo Filled-Review Handoff Diagnostics Batch

Status: complete.

What changed:
- Added explicit receipt-reader handoff outcome, action label, and evidence to shared camera diagnostics.
- Kept fresh captures and resumed interrupted captures on the same filled-review handoff contract.
- Strengthened source guards so recovered photos must still route toward filled receipt review after Next, not back to a dead-end attachment-only state.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the attach/read status message so the user sees that OCR is reading the prepared source photos while the filled receipt review opens.

### Receipt Camera Pass 747: Recoverable Capture Banner Clarity Batch

Status: complete.

What changed:
- Added compact recovery resume status/action labels for ready, partial, missing, and empty recovery states.
- Split interrupted receipt recovery UI into saved-photo context plus clear next-step detail.
- Changed the primary recovery button from a generic Resume label to the exact action: resume saved review, resume available photos, retake receipt photos, or start a new photo.
- Kept recovery copy local-only and receipt-content-free while making missing-photo states obvious.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --reporter compact`
- `flutter test test/receipt_attachment_panel_actions_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking whether recovered native photos preserve the same filled-review handoff expectations as fresh photos when a user resumes after an interruption.

### Receipt Camera Pass 746: Native Recovery Outcome Diagnostics Batch

Status: complete.

What changed:
- Added recovery resume outcome code/label to interrupted native capture records.
- Added resume outcome to privacy-safe recovery evidence labels.
- Added restore/keep/accepted/discarded outcome and next-step diagnostics for recovered receipt photos.
- Added source/test coverage for missing photos, kept recovery, accepted recovery, and user-discarded recovery telemetry.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --reporter compact`
- `flutter test test/receipt_attachment_panel_actions_test.dart --reporter compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening recoverable-capture UI copy so restore/discard states are visible without crowding the receipt intake panel.

### Receipt Camera Pass 735: Safe Leave Generated Edit Preservation Batch

Status: complete.

What changed:
- Fixed safe-leave cleanup so Keep Photo Saved For Later preserves generated
  crop/rotate/edit photos that are still part of the active receipt review.
- Kept cleanup for generated edit files that are no longer referenced by the
  current review.
- Added guard coverage so the safe-leave cleanup path cannot regress to
  deleting every generated edit artifact blindly.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review/crop save safeguards and
  recovery wording for edited proof photos.

### Receipt Camera Pass 736: Edited Proof Safe Leave Copy Batch

Status: complete.

What changed:
- Added safe-leave awareness for generated crop/rotation review photos.
- Updated the exit dialog copy so Keep Photo Saved For Later explicitly says
  edited crop/rotation copies currently shown in review are preserved too.
- Kept the copy conditional so normal unedited receipt photos do not get extra
  wording.
- Added guard coverage for edited-copy detection and the user-facing promise.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewed-photo edit diagnostics so
  OCR/parser handoff knows a photo was manually cropped or rotated before Next.

### Receipt Camera Pass 745: Native Cancel And No-Photo Recovery Copy Batch

Status: complete.

What changed:
- Replaced silent/ambiguous native camera cancel copy with a clear next step:
  retry receipt photo or choose an existing receipt image.
- Changed no-photo native camera diagnostics from backup-only action to
  retry-or-import action with a privacy-safe user next-step token.
- Updated both shared attachment panel and expense import flow to show non-empty
  canceled-result messages instead of silently returning.
- Added source guards for cancel/no-photo recovery copy and diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening native recovery records so
  staged interrupted photos carry a clear restore/discard outcome and source
  evidence into the same camera diagnostics.

### Receipt Camera Pass 744: Match Readiness Attachment Signal Batch

Status: complete.

What changed:
- Added match-readiness document signals to OCR source attachments.
- Added match-readiness OCR source flags so downstream parsing/diagnostics can
  distinguish combined-image OCR, ordered-section fallback, ordered sections,
  single source, or missing OCR source.
- Kept shared capture flow and expense import flow aligned with the same
  privacy-safe signal names.
- Added focused runtime and source-guard coverage for the new signals.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_result_test.dart --reporter compact`
- `flutter test test/receipt_capture_flow_shareability_test.dart --reporter compact`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening recovery when the
  native camera returns no photos, canceled photos, or staged photos after an
  interruption so the user always has an obvious next step.

### Receipt Camera Pass 743: Match Readiness Handoff Diagnostics Batch

Status: complete.

What changed:
- Added a stable `nextReviewMatchReadinessOutcome` for receipt reader handoff:
  combined image ready, ordered-section fallback ready, ordered sections ready,
  single source ready, or missing OCR source.
- Added a user-readable match readiness label to privacy-safe handoff metadata.
- Added match-readiness outcome counts to receipt reader handoff counts so
  Command One can group camera/OCR health without receipt content.
- Updated result-model regression coverage for single, ordered, stitched, and
  fallback handoff paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is exposing the match-readiness outcome
  in OCR attachment document signals/risk flags so downstream parsers inherit
  the same no-content camera decision.

### Receipt Camera Pass 742: Multi-Photo Match Readiness Preview Batch

Status: complete.

What changed:
- Passed stitch preview state into the lightweight post-capture preview tray.
- Added plain match-readiness copy before Next: match check running, check
  needed, combined receipt image ready, ordered-section fallback ready, or match
  needs review.
- Kept the copy tied to the selected long-receipt section guidance so users know
  both what section they are viewing and what OCR handoff will do next.
- Added regression coverage for combined-image and ordered-section fallback
  preview wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying match-readiness outcome into
  review handoff diagnostics so Command One can distinguish combined-image OCR
  from ordered-section fallback without receipt content.

### Receipt Camera Pass 741: Long-Receipt Review Tray Guidance Batch

Status: complete.

What changed:
- Added reusable selected-section guidance for long receipt review: top,
  middle, and bottom sections now explain what that section should contain.
- Added selected-section next-action copy so the user knows whether to add,
  order, match, or continue.
- Wired the selected-section guidance into both the lightweight post-capture
  preview tray and the deeper tool-mode context row.
- Added regression coverage for the new long-receipt guidance and action copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making multi-photo match readiness
  visible before Next so the user knows whether stitching will use one combined
  receipt image or ordered fallback sections.

### Receipt Camera Pass 740: Edited Photo Review Tray Clarity Batch

Status: complete.

What changed:
- Added selected-photo review tray copy that tells the user when a crop or
  rotation edit is applied.
- Added explicit copy that the edited copy is the one Maintainiac will read
  when the edit replaced the original review photo.
- Kept the signal in the lightweight post-capture review tray so users can see
  it before tapping Next, without opening a deeper tool panel.
- Added regression coverage for the edited-photo copy and manual crop/rotation
  labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the review tray's
  multi-photo section messaging so long-receipt users know when to order, match,
  add, or continue.

### Receipt Camera Pass 739: Edited Review Close Preservation Batch

Status: complete.

What changed:
- Fixed receipt photo review disposal so current edited crop/rotation copies are
  preserved instead of deleted during screen close.
- Kept the existing attach-or-keep confirmation behavior aligned with the
  dispose cleanup path, so leaving review does not silently discard the edited
  receipt section the user is looking at.
- Added a regression guard proving dispose keeps current review edit photos and
  does not call the old unconditional generated-edit cleanup.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the post-capture review
  controls clearer for edited/long-receipt sections while keeping the receipt
  preview dominant and touchable.
