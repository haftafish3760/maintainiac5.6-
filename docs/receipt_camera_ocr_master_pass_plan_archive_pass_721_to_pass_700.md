# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 721: Recoverable Photo Classification Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 721: Recoverable Photo Classification Batch

Status: complete.

What changed:
- Audited generated review file cleanup versus recoverable staged receipt
  photos.
- Tightened the “recoverable review photo” check so it now means an initial
  review photo, a staged native receipt photo, or a phone-camera backup photo.
- Removed the broad rule that treated any non-initial path as a generated
  review file. That was too loose because added native/staged receipt photos
  can also be non-initial and must not be treated like disposable preview junk.
- Kept generated cleanup limited to the existing app-owned generated sets:
  manual crop/rotate edits, data-saver previews, and stitch previews.
- Added regression coverage so the broad non-initial generated-file rule does
  not come back.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing OCR-source cleanup after
  successful reading so temporary OCR images are deleted only after the parser
  has consumed them, while accepted proof attachments remain attached and
  recoverable.

### Receipt Camera Reopen Pass 722: OCR Source Cleanup Timing Batch

Status: complete.

What changed:
- Audited the reviewed-photo OCR handoff and temporary OCR-source cleanup path.
- Confirmed OCR source cleanup happens only after
  `_readReviewedPhotosForReceiptForm(result)` returns, which means OCR has run
  and `onImportedText(result.appFillText)` has been awaited when text was read.
- Changed cleanup to use `keptReceiptPhotoPaths: result.photoPaths` instead of
  reading `_photoPaths` after the async OCR/parser handoff. This keeps saved
  proof protection deterministic even if the widget closes immediately after
  reading.
- Kept storage protections for `/receipt_proofs/`,
  `/receipt_proofs_staging/`, and `/native_capture_recovery/`.
- Updated tests to guard the stronger cleanup contract and current user-facing
  Next/filled-review copy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening the photo review
  loading/performance path so after capture the review surface opens quickly and
  background quality/preview work cannot block the visible photo.

### Receipt Camera Reopen Pass 723: Review First-Paint Priority Batch

Status: complete.

What changed:
- Audited the post-capture photo review first-paint path.
- Confirmed the visible review surface uses `Image.file` directly with
  constrained `cacheWidth`, medium filter quality, and `gaplessPlayback`.
- Kept storage-preview generation out of the first frame.
- Added a short deferred quality-check handoff so photo quality scoring starts
  after the review image has had a chance to paint, instead of immediately
  competing with the first visible preview.
- Added regression coverage that the review screen uses `_deferQualityCheck`
  and does not call `_ensureQualityCheck` directly from post-frame setup.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is device-tier/capability review for
  native capture settings so older phones keep lighter live work while newer
  phones can use stronger guidance safely.

### Receipt Camera Pass 710: Attachment Reading CTA Freeze/Clarity Batch

Status: complete.

What changed:
- While app-assisted receipt reading is preparing the filled review, the shared
  attachment panel now changes the main Add Receipt action to Reading Receipt.
- Disabled Add Receipt/Add Receipt Photo while `_readingForReview` is active so
  the user is not invited to start another capture while OCR handoff is already
  moving to review.
- Kept the accepted recovered-photo path aimed at the filled review/proof
  handoff and aligned the guard test with the current
  `open_filled_review_or_save_proof` diagnostic action.
- Preserved long-receipt guidance copy but made the add-more-photo command say
  Add Receipt Photo instead of generic proof language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart test/receipt_attachment_panel_actions_test.dart`
- `flutter test test/receipt_attachment_panel_actions_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the accepted receipt handoff
  visibly land on parsed receipt review and tightening the post-capture copy so
  the next action is clearly Next/Review Details instead of another add-receipt
  loop.

### Receipt Camera Pass 711: Filled Review Handoff Action Batch

Status: complete.

What changed:
- Added an explicit Review Details / Go To Review action to the filled receipt
  handoff panel after a receipt photo is accepted.
- Wired that action to `_scrollToReceiptReview()` so the user has a clear
  forward path into the parsed receipt details even if the page position lands
  near the attachment area.
- Kept the panel copy centered on the correct workflow: receipt proof saved,
  OCR source used before storage-saving proof compression, then review store,
  date, total, tax, item prices, and Business/Personal/Mixed choices.
- Added guard coverage so the handoff panel keeps a real review action instead
  of becoming passive helper text again.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reducing any remaining confusing
  post-capture attachment language and tightening recovery/back behavior around
  accepted photos so the user cannot accidentally lose the captured receipt.

### Receipt Camera Pass 712: Safe Leave Copy Batch

Status: complete.

What changed:
- Reworded the photo-review exit choice from Leave Without Attaching to
  Keep Photo Saved For Later / Keep Photos Saved For Later.
- Made the exit explanation explicitly say staged receipt photos are saved
  locally for recovery and will not be deleted.
- Kept the preferred forward action as Next: Attach + Review Details so the
  user still knows the normal path is to attach the photo and open the filled
  receipt details.
- Updated guard coverage so future copy cannot drift back toward silent-delete
  or confusing discard language.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the native capture/review
  settings surface and making sure the visible camera UI exposes Maintainiac
  receipt settings instead of relying on any stock camera-style ambiguity.

### Receipt Camera Pass 713: Maintainiac Native Camera Identity Batch

Status: complete.

What changed:
- Added a compact top-bar title pill that says Maintainiac Receipt Camera with
  Native receipt mode underneath.
- Kept Back on the top-left and Receipt camera settings / light on the top-right
  so controls do not drift into the middle of the preview.
- Preserved the full-height receipt preview, manual shutter, tap-focus,
  pinch-zoom, and exposure controls.
- Added widget coverage proving the Maintainiac title is visible and remains
  in the top bar while settings stays high on the screen.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening native camera settings
  entry and the review/detail handoff so the flow stays unmistakably
  receipt-first from shutter to parsed receipt review.

### Receipt Camera Pass 714: Visible Native Settings Label Batch

Status: complete.

What changed:
- Made the native receipt-camera gear show a visible Settings label while
  keeping the button in the top-right control group.
- Preserved the tooltip/tap target as Receipt camera settings, so the control
  still opens the Maintainiac receipt settings screen rather than a stock camera
  preference surface.
- Kept the camera preview full height and the shutter in the bottom capture
  zone.
- Added widget coverage for the visible Settings label plus the existing
  Maintainiac Receipt Camera / Native receipt mode identity.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening the photo-review and
  attachment handoff so accepted receipt photos are always queued locally and
  read before any storage-saving copy becomes the only proof.

### Receipt Camera Pass 715: OCR Source Before Saved Proof Copy Batch

Status: complete.

What changed:
- Reworded the accepted-photo reading status from Backup image saved to Saved
  proof ready so users do not think OCR is reading only the compressed backup
  image.
- Made the status explicitly say Maintainiac reads the clear OCR source before
  the smaller backup copy is used for storage.
- Added the privacy-safe diagnostic signal
  `ocr_reads_clear_source_before_saved_proof` to OCR-source document signals.
- Kept the existing saved proof count, OCR source count, quality summary,
  decision, next check, and evidence labels in the handoff status.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening capture interruption
  recovery and local queue evidence so phone calls, app backgrounding, or
  camera-close events do not silently lose receipt work.

### Receipt Camera Pass 716: Interruption Recovery Evidence Batch

Status: complete.

What changed:
- Added privacy-safe covered interruption codes to staged native-capture
  diagnostics:
  `app_backgrounded_after_capture`, `phone_call_after_capture`,
  `camera_closed_before_review`, and `review_closed_before_attach`.
- Added the same covered interruption list to the recovery safety manifest and
  Hive recovery index payload.
- Kept the recovery payload content-free: no receipt text, customer content, or
  image content is recorded in diagnostics.
- Strengthened tests so recovery evidence proves which interruption class the
  local recovery system is designed to survive.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native bridge parity for the visible
  settings/control contract: settings, back, torch, focus, zoom, exposure, and
  manual shutter must stay wired on Android and iOS.

### Receipt Camera Pass 705: Photo Review Lifecycle Guard Batch

Status: complete.

What changed:
- Hardened the receipt photo review screen against disposed-widget async work:
  pending post-frame, storage-preview, quality-check, and data-saver keys are
  cleared during dispose.
- Added a shared interactive-control guard so scroll/zoom/crop controller work
  stops once the review is closing or disposed.
- Replaced loose `mounted` checks in crop, rotate, native-pick, save, dialog,
  and exit paths with the stricter review-active guard where the UI must no
  longer be touched.
- Fixed the async `BuildContext` lint by reading settings/navigator before the
  relevant awaited work and keeping post-await UI use guarded.
- Updated receipt camera source guards to lock in the stronger lifecycle checks
  and the current light-device CameraX capture policy.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening add/retake review actions
  so returned native photos use `_reviewWorkActive` before mutating review
  state and the flow remains safe if the camera is canceled, interrupted, or
  resumed slowly.

### Receipt Camera Pass 706: Add/Retake Review State Safety Batch

Status: complete.

What changed:
- Hardened Add Receipt Photo and Retake Receipt Photo so returned native or
  fallback photos cannot mutate the review screen after it is closing or
  disposed.
- Tightened fallback-camera exception paths to use the review-active guard
  before showing snackbars, staging fallback images, or clearing opening state.
- Preserved the phone-camera backup path as fallback-only, while keeping
  Maintainiac native receipt camera first.
- Added regression guards so add/retake photo state changes stay protected by
  `_reviewWorkActive`.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making native preview/capture
  readiness less confusing by separating advisory guidance from hard blockers
  and ensuring manual shutter remains usable even when quality warnings are
  active.

### Receipt Camera Pass 707: Manual Shutter Advisory Guard Batch

Status: complete.

What changed:
- Updated the Flutter native camera shell bottom-bar copy from “Review before
  saving” to “Tap shutter anytime” so assisted receipt mode does not imply the
  app is blocking capture while guidance is active.
- Added Android CameraX guard coverage proving manual capture only checks
  capture/session state, not auto-capture readiness or guidance quality gates.
- Added iOS AVFoundation guard coverage with the same promise: manual shutter
  is not tied to automatic-capture readiness.
- Kept automatic capture optional and advisory; manual shutter remains the
  user-controlled path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing native photo preview/open
  latency and ensuring the review handoff does not spend visible time on work
  that can be deferred until after the screen is shown.

### Receipt Camera Pass 708: Native Photo Review Handoff Latency Batch

Status: complete.

What changed:
- Removed pre-review `qualityCheckFile` work from native and phone-camera
  fallback photo handoff.
- Native/fallback photo paths now return immediately with empty quality badges;
  the existing review-screen post-frame quality check fills badges in after the
  review surface is already visible.
- Kept existing quality handoff for results that already carry quality data.
- Added regression coverage so native/fallback handoff does not reintroduce a
  blocking `qualityCheckFile(path)` call before the review screen opens.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening native review result
  handoff so the app-assisted receipt reader opens the parsed receipt details
  consistently after accepted photos, without silently dropping back to the
  receipt entry surface.

### Receipt Camera Pass 709: Accepted Photo Handoff Visibility Batch

Status: complete.

What changed:
- Moved the “Opening filled receipt review” handoff panel above the receipt
  attachment controls on the expense receipt entry screen.
- This makes the immediate post-photo state show the app-assisted review
  transition first instead of making the user feel dumped back onto the receipt
  attachment area.
- Added source-order coverage proving `_ReceiptReadHandoffPanel` renders before
  `SharedReceiptAttachmentPanel` inside the receipt handoff section.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --reporter compact`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is checking whether attachment OCR/read
  completion still leaves confusing “Add Receipt” calls to action visible while
  the filled receipt review is already being prepared.

### Receipt Camera Pass 700: Native Surface Contract Enforcement Batch

Status: complete.

What changed:
- Added a Dart-side native surface contract to the receipt camera service so
  every accepted capture says it came from Maintainiac's in-app receipt camera
  surface, not a stock phone camera UI.
- Added a service guard that rejects native capture results when native
  diagnostics explicitly report `stockCameraUiUsed: true`.
- Carried the native surface contract through privacy-safe staging diagnostics:
  surface contract version, expected capture surface, camera identity, custom UI
  contract, preview ownership, and stock-camera allowance/usage.
- Extended focused tests so the method-channel arguments, returned capture
  diagnostics, manifest, and Hive recovery index all preserve those fields
  without receipt text, merchant names, customer content, or line items.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart --reporter compact`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native review-screen layout/action
  diagnostics: prove the accepted photo review has a clear Next path, add-photo
  affordance, long-receipt section visibility, and no hidden stock-camera
  dependency before moving deeper into OCR parsing.
