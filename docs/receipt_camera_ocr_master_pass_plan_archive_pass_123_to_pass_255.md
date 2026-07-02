# Receipt Camera OCR Master Pass Plan Archive - Native Scanner Pass 123: Live-Capture Brightness Mismatch Fix

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Native Scanner Pass 123: Live-Capture Brightness Mismatch Fix

Status: complete.

What changed:
- Fixed the Android CameraX saved-photo exposure mismatch detector so it uses
  the real live brightness bucket names emitted by the camera analyzer:
  `lighting_ok`, `too_dark_warning`, `dark_assisted`, `glare_warning`, and
  `bright_assisted`.
- Fixed the same AVFoundation mismatch detector on iOS.
- This makes the captured-photo diagnostics correctly identify cases where the
  live preview looked acceptable but the saved receipt photo came out too dark
  or dim, so the review warning added in Pass 122 can actually fire.
- Added Android and iOS bridge regression checks so the old dead comparisons to
  `normal`, `dark`, and `bright` cannot sneak back in.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Next camera-only focus:
- Continue with native preview/capture brightness parity, especially whether the
  live analyzer is sampling the same region the user cares about and whether
  the review surface should offer clearer retake/edit guidance for dim captures.

### Native Scanner Pass 124: Conservative Exposure Assist Before Edges

Status: complete.

What changed:
- Added a conservative pre-edge exposure fallback to Android CameraX and iOS
  AVFoundation receipt capture.
- Before receipt edges are found, auto brightness assist can now make a small
  native exposure correction only after four sustained very-dark or glare-heavy
  analysis frames.
- Kept normal receipt-target exposure behavior faster: once receipt framing is
  found, the existing two-frame brightness candidate gate still applies.
- Preserved user control: manual brightness still overrides auto assist, manual
  shutter still works, and automatic capture is not made more aggressive.
- Added Android and iOS bridge regression checks for the four-frame fallback
  candidates so this cannot turn into twitchy instant exposure changes.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Next camera-only focus:
- Continue with physical-device camera review around focus/zoom responsiveness,
  crop/edit clarity, and receipt-section handoff into the app-filled review.

### Native Scanner Pass 125: Pinch Zoom Tap-Focus Guard

Status: complete.

What changed:
- Hardened Android CameraX pinch zoom so the finger lift at the end of a pinch
  cannot accidentally fire tap-to-focus.
- Hardened iOS AVFoundation the same way with a short post-zoom tap-focus
  suppression window.
- Added privacy-safe diagnostics for the suppression count so Command One can
  eventually show camera interaction health without receipt images, receipt
  text, names, addresses, or other private user content.
- Preserved normal tap-to-focus behavior outside the short post-zoom guard.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Command One telemetry requirement:
- Command One must expose receipt/expense health from privacy-safe summarized
  diagnostics, including OCR success/failure, parser success/failure,
  save/abandonment/retry rates, camera capture problems, crop/stitch problems,
  and parser accuracy by expense category such as fuel, materials, groceries,
  maintenance, basic expense, and unknown.
- Command One must show what failed and where it failed, using diagnostic
  reason codes and trace IDs instead of private receipt content.
- Bundle related camera/receipt work whenever safe so passes move the system
  forward in meaningful chunks instead of tiny isolated edits.

Next camera-only focus:
- Continue with camera lifecycle/back behavior, post-capture review layout, and
  the Next handoff into app-filled receipt review before parser/PDF/Firebase
  work resumes.

### Native Scanner Pass 126: Retry-Safe Back/Close

Status: complete.

What changed:
- Hardened Android CameraX back/close so a second back tap is not ignored if
  the native camera screen is still visible after a close result was already
  marked delivered.
- Hardened iOS AVFoundation the same way: if the controller is still presented
  after a delivered close result, another back action attempts dismissal again.
- Added `closeRetryCount` as a privacy-safe diagnostic so Command One can later
  show whether camera close/back behavior is getting sticky on real devices.
- Preserved captured-photo safety: back with saved receipt sections returns
  those photos, while back with no photo still cancels.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_capture_staging_test.dart`
- `JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home' ./gradlew :app:compileDebugKotlin --quiet`
- `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -sdk iphonesimulator -configuration Debug COMPILER_INDEX_STORE_ENABLE=NO build`

Next camera-only focus:
- Continue with the post-capture review layout and the Next handoff into the
  app-filled receipt review, then return to physical-device brightness/quality
  tuning.

### Native Scanner Pass 127: Command One Camera Health Signals

Status: complete.

What changed:
- Added the new native camera interaction diagnostics into the expense receipt
  photo telemetry summary that Command One will consume later.
- `tapFocusSuppressedAfterZoomTotal` lets the admin app show whether pinch zoom
  is being protected from accidental tap-focus conflicts on real devices.
- `closeRetryTotal` lets the admin app show whether camera back/close is sticky
  or requiring repeated attempts.
- Kept the telemetry privacy-safe: no receipt image, receipt text, customer
  names, addresses, phone numbers, notes, or item descriptions are included.
- Preserved the visible handoff language: after photo review, the user is told
  to tap Next to review what Maintainiac read.

Validation:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`

Next camera-only focus:
- Continue with the photo-review layout and the app-filled review handoff,
  especially making the “Next” path feel like a guided receipt flow instead of
  a return to the starting form.

### Native Scanner Pass 128: Receipt-First Review Height Cap

Status: complete.

What changed:
- Tightened the post-capture receipt review bottom-control height limits so the
  receipt image keeps more of the screen.
- Reduced preview, stitch, and backup-size panel caps while preserving access
  to Add Another Photo, Retake, Adjust, Backup Size, and Next.
- Kept crop mode especially low so receipt edges remain reachable.
- Updated layout tests to guard the tighter cap.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with post-capture review clarity: make Add Another Photo, Next, crop,
  and long-receipt stitching feel like one professional receipt workflow.

### Native Scanner Pass 129: Plain Receipt Quality Wording

Status: complete.

What changed:
- Replaced vague photo-score evidence such as `Photo check 78%` with
  action-oriented receipt language such as `Readable receipt photo (78%)`,
  `Check before Next (...)`, or `Retake recommended (...)`.
- Kept the numeric score as supporting evidence for diagnostics and Command One
  trends, but stopped leading the user with an unexplained percentage.
- Preserved the same quality model, warnings, and review decisions.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue tightening the post-capture review flow: clear Add Another Photo,
  crop, backup size, and Next behavior before deeper OCR/parser polish.

### Native Scanner Pass 130: Direct Next Review Language

Status: complete.

What changed:
- Replaced long post-photo continuation labels with plain `Next` or
  `Next Anyway` so the review screen behaves like a normal camera workflow.
- Moved the explanation into the compact status copy: after a photo is accepted,
  Next leads to reviewing the store, date, total, and item prices.
- Renamed vague review tools from `Adjust` to `Crop` and `Backup Size` to
  `Save Space`.
- Kept long-receipt language explicit: add the next receipt section if the
  receipt continues, check the match when multiple photos are present, then tap
  Next.

Validation:
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_camera_help_flow_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera-only focus:
- Tighten the photo-review action tray further, then continue with the
  brightness/focus and native camera quality passes.

### Native Scanner Pass 131: Android Bright Receipt And Back Guard

Status: complete.

What changed:
- Raised the Android CameraX glare/dim thresholds so normal bright white receipt
  paper is treated as readable instead of being dimmed like glare.
- Added a `bright_receipt_ok` diagnostics bucket so Command One can separate
  healthy bright receipt paper from true glare.
- Kept strong dimming only for real over-bright frames, reducing the chance that
  the Maintainiac camera view looks darker than the phone's stock camera.
- Made the Android receipt edge guide follow the detected receipt bounds instead
  of staying as a fixed decorative rectangle.
- Enabled Android's modern back callback on `ReceiptCameraActivity` so system
  back and the in-app back path both route through the receipt-camera close
  logic.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart`
- Native Kotlin compile was attempted with `./gradlew :app:compileDebugKotlin`
  but this Mac session could not locate a Java runtime.

Next camera-only focus:
- Continue Android/iOS native camera hardening: prove back behavior on-device,
  keep tightening pinch zoom/focus behavior, then continue into post-capture
  review and stitched receipt handoff.

### Native Scanner Pass 132: iOS Bright Receipt Parity

Status: complete.

What changed:
- Mirrored the Android bright-paper threshold fix into the iOS AVFoundation
  receipt camera.
- Normal bright white receipt paper now reports `bright_receipt_ok` instead of
  being treated as a dimming target.
- Kept true glare detection at the higher over-bright threshold so both native
  camera backends share the same receipt-first exposure behavior.
- Updated bridge guard tests so Android CameraX and iOS AVFoundation stay in
  sync on brightness buckets.

Validation:
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with on-device behavior risks: pinch zoom/focus, sticky back exits,
  capture-result recovery, and the post-capture review path into parsed receipt
  lines.

### Native Scanner Pass 133: Hive-Only Recovery Cleanup

Status: complete.

What changed:
- Hardened the receipt-native recovery index so stale Hive entries are removed
  when both the recovery manifest and staged receipt photos are gone.
- Wired stale-index cleanup into abandoned native staging cleanup.
- Preserved retained staged photos, so an in-progress receipt review is not
  deleted just because cleanup runs.
- Added a regression test for the edge case where a receipt capture manifest is
  missing, Hive still has the recovery entry, and the old staged photo has been
  cleaned up.

Validation:
- `flutter test test/receipt_native_capture_staging_test.dart`

Next camera-only focus:
- Continue interruption safety from the UI side: resume banners/actions for
  interrupted captures, then return to post-photo review layout and the Next
  handoff into parsed receipt lines.

### Native Scanner Pass 134: Attachment-Backed Resume Paths

Status: complete.

What changed:
- Added `recoverablePhotoPaths` to interrupted native capture records so resume
  can recover from either staged path lists or attachment-backed Hive records.
- Updated the receipt attachment panel resume path to use the safer recovered
  path list instead of raw `stagedPhotoPaths`.
- Preserved capture diagnostics for every recovered photo path when review is
  resumed.
- Added regression coverage for attachment-only recovery records and guarded
  the UI source against reverting to the old raw path loop.

Validation:
- `flutter test test/receipt_native_capture_staging_test.dart test/receipt_attachment_panel_actions_test.dart`

Next camera-only focus:
- Continue with the post-capture review flow: clearer resume/Next language,
  then enforce that accepted assisted receipt photos move into the parsed line
  review instead of feeling like a return to the starting form.

### Receipt Camera Reopen Pass 140: Command One Parser Category Telemetry Batch

Status: complete.

What changed:
- Added privacy-safe parser category health buckets for Command One so the admin
  app can separate receipt/parser performance by `fuel`, `groceries`,
  `materials`, `maintenance`, and other safe category tokens.
- Added parser needs-review and parser-failed category buckets so failure-rate
  drill-downs can answer which expense categories are struggling without
  storing receipt text, store names, addresses, item descriptions, or private
  notes.
- Added parser field confidence buckets such as safe field/status tokens, so
  Command One can distinguish weak totals, tax, date, or merchant parsing.
- Wired the expense receipt parser event path to emit safe category,
  confidence, subtotal reconciliation, tax math, and review-count telemetry.
- Updated telemetry schema guard coverage so these admin-facing fields cannot
  quietly disappear in a later pass.

Validation:
- `flutter test test/expense_screen_telemetry_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart`

Next camera-only focus:
- Continue with the accepted-photo handoff and receipt review surface: make the
  post-capture Next path visibly and reliably land on the filled receipt review,
  then continue hardening native capture brightness/back/zoom behavior.

### Receipt Camera Reopen Pass 252 / Total Pass 332: Accepted Photo Handoff And Admin Health Continuity Batch

Status: complete.

What changed:
- Finished the accepted-photo handoff panel in the expense receipt flow so an
  accepted receipt photo shows `Reading Receipt Details`, saved proof count,
  OCR source count, stitch/review decision, and clear copy that the next step is
  the filled receipt details review.
- Kept the handoff privacy-safe and workflow-specific; it does not show receipt
  text, store names, addresses, item descriptions, or user content.
- Added Command 1 expense health models that consume the sanitized Maintainiac
  expense telemetry summary keys, including parser category counts, parser
  needs-review category counts, parser failed category counts, top parser
  category, top needs-review category, and top failed category.
- Added a Command 1 expense telemetry health panel with OCR readable rate,
  parser success rate, save success, time on screen, abandonment, and category
  breakdowns for fuel, groceries, materials, and maintenance.
- Wired the Command 1 Expenses screen to show the new telemetry panel before the
  broader owner stats, so category health and failure causes are visible without
  exposing private receipt content.

Validation:
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart`
- Command 1: `flutter test test/expense_health_panel_test.dart test/widget_test.dart`
- Command 1: `flutter analyze lib/features/admin_screens/admin_detail_screen.dart lib/features/expense_health/expense_health_models.dart lib/features/expense_health/expense_health_panel.dart test/expense_health_panel_test.dart`

Next camera-only focus:
- Continue with native camera UI settings and review continuity: camera settings
  must be visible inside Maintainiac, accepted photos must not be easy to lose,
  and the flow must keep moving from capture to image review to filled receipt
  review.

### Receipt Camera Reopen Pass 253 / Total Pass 333: Native Camera UI Settings And Review Continuity Batch

Status: complete.

What changed:
- Brought the native iOS AVFoundation camera closer to Android parity by adding
  a visible receipt settings status strip directly on the capture screen.
- Replaced ambiguous iOS `Done` language with receipt-specific `Use Photo` and
  `Use Photos` language, including accessibility copy.
- Updated long-receipt saved-section guidance so the user is told to tap
  `Use Photos` instead of generic `Done`.
- Kept OCR/data-saving language explicit: OCR reads the original photo first,
  and smaller backup copies are made only after receipt reading.
- Updated iOS settings actions so the visible settings strip refreshes when
  assisted fill, long receipt mode, automatic capture, auto brightness assist,
  edge guidance, or receipt warnings are changed.
- Updated the iOS bridge source guard so the old generic copy cannot silently
  come back.

Validation:
- `dart format test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_ios_bridge_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_camera_shell_test.dart`

Next camera-only focus:
- Continue with the native capture review layout and control recovery: the
  post-photo review surface must make Add Photo, retake, crop/edit, and Next
  impossible to miss without covering the receipt image.

### Receipt Camera Reopen Pass 254 / Total Pass 334: Native Capture Review Layout And Control Recovery Batch

Status: complete.

What changed:
- Tightened the receipt photo review bottom tray so the receipt image owns more
  of the screen after capture.
- Reduced preview/order/stitch/data-saver bottom control height caps while
  preserving visible `Next`, `Add Another Photo`, `Retake`, `Crop`, and
  `Save Space` actions.
- Kept the 75-80% image-dominance rule guarded by the layout source test.
- Preserved the existing full-screen tap-to-hide-controls behavior and pinch
  zoom preview behavior.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera-only focus:
- Continue with review action clarity and image-edit recovery: make crop/edit,
  retake, Add Photo, and Next harder to confuse, then continue into actual
  crop/edit recovery behavior and saved-photo persistence.

### Receipt Camera Reopen Pass 255 / Total Pass 335: Review Action Clarity And Image Edit Recovery Batch

Status: complete.

What changed:
- Fixed the native saved-photo blur warning path so it checks the actual
  emitted diagnostic bucket, `captured_soft_blur_risk`, instead of the stale
  `captured_soft` token.
- This keeps soft/blurry native captures from silently losing the retake warning
  on the post-photo review screen.
- Renamed the quality-recovery add button from `Add Photo` to `Add Another` so
  long receipt recovery is clearer after the first section has already been
  captured.
- Added layout source guards so these user-facing review warnings and labels do
  not drift back.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera-only focus:
- Continue with native exposure quality scoring calibration: tighten the gap
  between live brightness, saved-photo brightness, quality score, and user
  warning copy so good photos are not punished and bad photos explain why.
