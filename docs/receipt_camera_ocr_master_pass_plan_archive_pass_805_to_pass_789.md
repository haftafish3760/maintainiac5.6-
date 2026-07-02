# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 805: Saved-Proof Size Choice Explanation Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 805: Saved-Proof Size Choice Explanation Batch

Status: complete.

What changed:
- Added plain-language tooltips and semantics to each saved-proof size choice in
  the receipt photo settings sheet.
- Kept the main settings explanation focused on phone space, cloud backup
  storage, and the fact that OCR still uses the clearest receipt source first.
- Explained each saved-proof tier without developer-facing compression jargon:
  original/local-only, high quality, normal, low storage, and tiny proof.
- Added guard coverage for the size-choice tooltip helper and key user-facing
  tradeoff wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart --name "receipt capture exposes camera help and long receipt guidance"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making camera/review settings visible
  and useful without crowding the capture or review surfaces.

### Receipt Camera Reopen Pass 806: User-Facing Native Shell Labels Batch

Status: complete.

What changed:
- Removed user-facing CameraX/AVFoundation API names from the native receipt
  camera shell.
- Kept the native engine concepts available for diagnostics/contract tests, but
  changed the visible title to `Native receipt controls`.
- Changed the visible next-step badge from `CameraX`/`AVFoundation` to `Ready`
  so users see capture state instead of platform plumbing.
- Changed the bottom storage pill from `Backup size`/backup details to
  `Saved proof` with `Sharp proof`, `Normal proof`, `Smaller proof`, and
  `Tiny proof`.
- Updated native shell tests to protect the cleaner user-facing labels while
  keeping the visible settings button at the top of the camera.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening live capture guidance so
  it helps without blocking manual shutter or covering too much of the preview.

### Receipt Camera Reopen Pass 798: Manual Shutter Never-Blocked Native Contract Batch

Status: complete.

What changed:
- Added privacy-safe native diagnostics for manual shutter taps, manual capture
  starts, auto-capture attempts, auto-capture starts, and concrete capture block
  reasons on Android CameraX and iOS AVFoundation.
- Made the capture contract explicit: receipt quality guidance, framing
  guidance, readability warnings, and auto-capture readiness are advisory and
  must not block manual shutter capture.
- Limited manual capture blocks to concrete camera lifecycle states: no camera,
  capture already in flight, camera closing, or inactive camera surface.
- Passed the same `guidanceBlockingPolicy` and `manualCaptureBlockPolicy`
  through the Flutter native-camera bridge so app review and diagnostics can
  explain why a capture did or did not start without receipt content.
- Guarded the native source so future changes do not add hidden
  `latestReadabilitySignal` or `latestFramingSignal` gates to manual capture.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native service sends previous section guide through channel"`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native camera screens report control diagnostics without content"`
- `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is turning the manual-capture policy
  into user-facing review behavior: captured images should land in a clear
  image-review step with obvious Next/Add Photo/Retake actions before OCR
  parse review.

### Receipt Camera Reopen Pass 799: Receipt Photo Review Primary-Action UX Batch

Status: complete.

What changed:
- Added a visible top-bar `Next` action on the receipt photo review screen so
  the user can always see the way forward after taking a photo.
- Kept the bottom tray available for Add Another Photo, Retake, Crop, Save
  Space, order, and stitch tools without making the bottom tray the only path
  forward.
- Reworded the review flow from vague/internal "attach" language to clearer
  receipt workflow language: `Next` opens receipt details/item prices/totals and
  business/personal review.
- Updated the stacked button copy to `Next / Review Receipt`, which matches the
  actual next screen the user expects after accepting receipt photos.
- Updated source guards so future changes keep the clearer review-path wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reducing hidden/scroll-only review
  controls by making Add Photo, Retake, Crop, Match, and Save Space
  mode-specific but obvious, while keeping the receipt image dominant.

### Receipt Camera Reopen Pass 800: Photo Quality Guidance Copy Batch

Status: complete.

What changed:
- Kept receipt photo quality scoring available for diagnostics, ranking, and
  Command One health, but softened the user-facing language so a usable photo
  does not feel rejected by a noisy percentage.
- Changed score explanations from "This score..." to "Photo check..." or direct
  retake/readability guidance.
- Kept `Next` explicitly available even when retake is safer, as long as the
  user can read the receipt text.
- Updated quality evidence copy so the percentage reads as supporting evidence,
  not a blocking grade.
- Added regression coverage around the new guidance wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_quality_guidance_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `flutter test test/receipt_camera_result_test.dart --name "photo quality"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the receipt-photo review
  controls easier to scan without growing the bottom tray, especially for
  single-photo Add Photo/Retake/Crop/Save Space actions.

### Receipt Camera Reopen Pass 791: Preview/Saved Brightness Parity Review Warning Batch

Status: complete.

What changed:
- Wired the native `latestCapturedPreviewParitySignal` diagnostic into the
  saved-photo review warning model so a photo that saves darker than the live
  preview is surfaced through the existing review controls.
- Added the matching brighter-than-preview warning path for washed-out/glare
  saves instead of collapsing those cases into a generic brightness issue.
- Added action and parser-risk buckets for brighter-than-preview review:
  `reduce_brightness_or_glare` and `ocr_washed_out_text_may_fail`.
- Kept the warning content-free: it uses brightness/parity buckets only, never
  receipt text, merchant names, line items, totals, addresses, or notes.
- Tightened the review-flow guard test so both parity review signals remain
  present without relying on fragile formatter-specific source line wrapping.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review surfaces native saved-photo quality warnings"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture preview/photo parity
  handoff in UI health counts so Command One and the receipt review flow can
  distinguish darker-than-preview, brighter-than-preview, bottom-dark, glare,
  and blur problems without exposing receipt content.

### Receipt Camera Reopen Pass 792: Preview/Saved Parity Health Count Batch

Status: complete.

What changed:
- Added privacy-safe native camera health buckets for preview-to-saved-photo
  parity:
  - `preview_saved_darker_than_live`
  - `preview_saved_brighter_than_live`
  - `preview_saved_parity_ok`
  - `preview_saved_parity_review`
- Counted those buckets from the captured preview parity diagnostics even when
  the settings/control telemetry is absent, so brightness problems still show
  up when UI diagnostics are incomplete.
- Added the darker/brighter parity buckets to `nativeCameraUiHealthOutcome`
  after hard UI contract failures but before the generic ready state.
- Extended receipt review guard coverage so the parity health helper and
  buckets stay wired into the same privacy-safe native camera health path.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review surfaces native saved-photo quality warnings"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is turning saved-photo warning counts
  into clearer receipt-review handoff action evidence so the next screen knows
  whether the user accepted a darker preview, brighter preview, bottom-risk,
  blur-risk, or clean photo.

### Receipt Camera Reopen Pass 793: Accepted Photo Warning Profile Handoff Batch

Status: complete.

What changed:
- Added `acceptedPhotoWarningProfile` to the receipt photo review result model
  so accepted photos carry a precise warning family forward without changing
  the existing broad handoff outcome route.
- Made `acceptedPhotoHandoffActionLabel` prefer warning-specific guidance for
  dark, bright/glare, blur, and bottom-section risks before falling back to the
  broad quality outcome.
- Added the warning profile to privacy-safe handoff evidence and metadata so
  later receipt-review/Command One consumers can distinguish dark-preview,
  bright-preview, glare, blur, bottom-dark, and bottom-soft paths.
- Kept all evidence content-free: only bucket/profile tokens are emitted, never
  receipt text, merchant names, item details, totals, addresses, or notes.
- Added focused tests for dim, critical-dark, soft, glare, and brighter-than-
  preview warning profiles and parser-risk handoff.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "saved-photo"`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result flags bridged dim and glare capture wording"`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review surfaces native saved-photo quality warnings"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using the warning profile in the
  app-assisted receipt review entry path so the filled receipt review can show
  a non-private “check totals/prices first” cue when OCR starts from a risky
  accepted photo.

### Receipt Camera Reopen Pass 794: OCR Source Warning Profile Handoff Batch

Status: complete.

What changed:
- Added `receipt_handoff_warning_${acceptedPhotoWarningProfile}` document
  signals to both reusable receipt capture flow paths:
  `receipt_capture_flow.dart` and `receipt_attachment_import_actions.dart`.
- Added `acceptedPhotoWarningProfile` to the reusable receipt-reader handoff
  diagnostics map.
- Extended `ReceiptOcrSourceHandoffSummary` with
  `handoffWarningProfileCounts`, `warningProfileStatus`, and `reviewCueStatus`
  so OCR can preserve “accepted from dim/glare/blur/bottom-risk photo” context.
- Added `ocrSourceHandoffWarningProfileCounts` to `ReceiptOcrDiagnostics`.
- Kept the handoff content-free and privacy-safe: warning profile tokens carry
  no receipt text, merchant names, line descriptions, prices, totals, addresses,
  or notes.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_ocr_service_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_ocr_service.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_capture_flow_shareability_test.dart test/receipt_ocr_service_test.dart`
- `flutter test test/receipt_ocr_service_test.dart --name "ocr result carries accepted photo handoff signals without receipt content"`
- `flutter test test/receipt_capture_flow_shareability_test.dart --name "app assisted OCR reads prepared OCR sources instead of saved backup proof"`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is surfacing the OCR warning cue in the
  filled receipt review panel so risky accepted-photo reads prompt the user to
  check totals/prices first without blocking the flow.

### Receipt Camera Reopen Pass 795: Filled Review Accepted-Photo Cue Batch

Status: complete.

What changed:
- Added accepted-photo warning cues to the filled receipt review OCR panel using
  the privacy-safe OCR source handoff `reviewCueStatus`.
- Added focused action labels for risky accepted photos:
  - check totals before save
  - check washed-out prices
  - check item prices
  - check bottom totals
  - retake/add another bottom photo when needed
- Kept the cue non-blocking: users still reach the filled receipt review, but
  the panel now tells them what to verify first when OCR started from a dim,
  dark, bright/glare, soft, or bottom-risk accepted photo.
- Added fallback cue lookup from `ocrSourceHandoffWarningProfileCounts` if the
  generic handoff contract does not include `reviewCueStatus`.
- Added assisted-review guard coverage for the cue helper, action labels, and
  content-free diagnostics fields.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening the native capture back/close
  and lifecycle path so camera preview disposal cannot strand the user or call
  preview-building code after the native/Flutter review surface is gone.

### Receipt Camera Reopen Pass 796: Native Close/Lifecycle Diagnostics Batch

Status: complete.

What changed:
- Added native close counters on Android CameraX and iOS AVFoundation:
  - `closeRequestCount`
  - `closeDuringCaptureCount`
  - `closeNoPhotoCancelCount`
  - `closeReturnedSectionsCount`
- Preserved the existing safe behavior where a back/close request during an
  in-flight capture defers closing until the photo has saved, then returns the
  captured sections instead of silently losing the image.
- Added the close counters to native capture diagnostics on both platforms.
- Added native camera UI health buckets for close behavior:
  - `native_close_deferred_during_capture`
  - `native_close_retry_after_result`
  - `native_close_no_photo_cancel`
  - `native_close_returned_captured_sections`
  - `native_close_action_*`
- Marked close-deferred and close-retry buckets as reviewable camera UI risks
  in both reusable receipt capture and expense import paths.
- Added regression coverage proving close-deferred diagnostics flow into
  receipt reader counts, document signals, and risk flags without exposing
  receipt content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_result_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result summarizes native camera close health"`
- `flutter test test/receipt_native_camera_contract_test.dart --name "native camera screens report control diagnostics without content"`
- `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is review-screen lifecycle hardening for
  async preview/storage/quality/stitch work so delayed work cannot update after
  the review surface has started closing.

### Receipt Camera Reopen Pass 797: Review Async Work Generation Guard Batch

Status: complete.

What changed:
- Added `_reviewWorkGeneration` to the receipt photo review screen.
- Invalidated async review work when the review screen is disposed or begins
  closing.
- Added `_reviewWorkTokenActive(...)` so delayed quality, storage preview, data
  saver preview, and stitch preview work can verify it still belongs to the
  active review surface before updating state.
- Threaded the generation token through post-frame work, delayed quality checks,
  delayed storage previews, data-saver preview generation, and stitch preview
  completion/error paths.
- Kept generated preview cleanup intact when stale work finishes after the
  screen has changed or closed.
- Tightened the lifecycle guard test so the review screen must keep the
  tokenized async-work contract.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "photo review async preview work cleans up after lifecycle changes"`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native/manual shutter and zoom
  interaction contract: prove pinch zoom, tap focus, and manual shutter remain
  available even when guidance/autocapture/readability checks are active.

### Receipt Camera Pass 790: Live Preview To Saved Photo Brightness Parity Batch

Status: complete.

What changed:
- Android CameraX now snapshots live preview brightness at shutter time, then
  compares that value against the saved receipt photo brightness.
- iOS AVFoundation now captures the same live-at-shutter brightness snapshot
  and computes the same saved-photo parity diagnostics.
- Added platform-neutral diagnostics for live-to-saved luma delta, delta
  bucket, and preview parity signal so a dark saved photo can be traced instead
  of guessed at.
- Added the parity fields to the Flutter receipt capture diagnostic constants
  and fallback bridge diagnostics so native and fallback capture paths preserve
  the same evidence.
- Added regression guards requiring the new parity fields on native Android,
  native iOS, and the receipt review/handoff model expectations.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart --name "reviewed receipt photos announce app fill handoff safely"`
- `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin` from `android/`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Remaining working estimate is about 110 serious
  passes from this point. Next target is using the new preview parity signal in
  review warnings so users get clear retake/continue guidance when the saved
  image is darker than the live preview.

### Receipt Camera Pass 789: Native Platform Exposure Policy Consumption Batch

Status: complete.

What changed:
- Android CameraX receipt camera now reads the session's preview exposure,
  brightness guard, shutter speed, tap focus, pinch zoom, and auto-capture
  policy tokens instead of using stale hardcoded preview policy text.
- iOS AVFoundation receipt camera now reads the same policy tokens from the
  session arguments so both native platforms follow the same Maintainiac receipt
  camera contract.
- Native diagnostics on both platforms now report those exact policy values
  back without receipt content, so dark-preview or control-behavior issues can
  be traced by policy instead of guessing.
- The native settings/status strip now includes brightness mode so users can see
  whether auto brightness assist or manual brightness is active.
- Added regression guards proving both native sources consume/report these
  policy keys and no longer contain the stale dim-receipt policy token.

Validation:
- `dart format test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:compileDebugKotlin` from `android/`
- `git diff --check`

Note:
- Android native Kotlin compile passed. iOS native source was guarded by the
  Dart source-contract test in this pass; a full Xcode/iOS build was not run.

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the live preview/capture
  exposure loop so the saved photo brightness tracks the preview and the app can
  explain when a saved photo is darker than expected.
