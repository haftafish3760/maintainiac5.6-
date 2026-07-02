# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 353 / Total Pass 433: Native Capture Lifecycle Guard Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 353 / Total Pass 433: Native Capture Lifecycle Guard Batch

Status: complete.

What changed:
- Audited native capture and add-another-photo lifecycle paths after earlier
  real-device disposed camera/review failures.
- Split "context disappeared after native camera returned" from "camera
  returned no photo" so stale review contexts cancel cleanly instead of being
  recorded as camera failures.
- Added a staged-photo cancellation path that preserves native capture recovery
  if the review context closes after staging.
- Added mounted checks after native add-another capture and after native
  staging inside the review screen so stale async work does not continue into
  review state.
- Extended source guards for shared camera capture and review add-photo flow.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_capture_flow_shareability_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is low-storage cloud-assist wording and
  local/cloud OCR capability split.

### Receipt Camera Reopen Pass 354 / Total Pass 434: Low-Storage Cloud Assist Boundary Batch

Status: complete.

What changed:
- Audited low-storage receipt OCR capability behavior against the product rule
  that local OCR must remain available while cloud OCR remains optional.
- Added a separate optional cloud inventory/catalog assist contract so large
  material/inventory matching can be cloud-assisted without making receipt
  capture or basic OCR cloud-only.
- Added combined cloud-assist planning copy on the device capability model.
- Updated first-use camera help to state that cloud OCR or inventory matching
  must be optional and clearly chosen.
- Clarified receipt backup image size settings so saved-proof compression is
  not confused with the OCR source.
- Added tests covering low-storage and high-capacity devices.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_assistance_policy_test.dart test/receipt_camera_help_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture/settings bridge
  parity for user-facing camera controls.

### Receipt Camera Reopen Pass 355 / Total Pass 435: Native Settings Contract Version Batch

Status: complete.

What changed:
- Audited the native CameraX/AVFoundation settings bridge.
- Added `settingsContractVersion` to the Flutter native camera payload.
- Wired Android CameraX to read the contract version and include it in capture
  diagnostics.
- Wired iOS AVFoundation to read the contract version and include it in capture
  diagnostics.
- Added Flutter, Android, and iOS bridge guards so future native-camera
  settings payload changes remain identifiable in diagnostics.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture diagnostics allowlist
  and Command One-safe camera health keys.

### Receipt Camera Reopen Pass 356 / Total Pass 436: Camera Settings Contract Telemetry Allowlist Batch

Status: complete.

What changed:
- Audited expense telemetry metadata allowlists for native camera diagnostics.
- Added `settingsContractVersion` as a content-free, Command One-safe metadata
  key.
- Extended telemetry tests so the native camera settings contract version
  survives sanitization with other camera health metadata.
- Kept private receipt content blocked: no receipt text, image path, customer
  content, merchant content, account id, or user id is exposed by this key.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is camera/OCR gap audit before another
  visible UI/device build batch.

### Receipt Camera Reopen Pass 357 / Total Pass 437: Native Settings Contract Health Summary Batch

Status: complete.

What changed:
- Audited the camera/OCR telemetry path from native capture metadata into the
  Command One health snapshot.
- Added `settingsContractVersionBuckets` to the privacy-safe metadata allowlist
  so native settings contract versions can be summarized without receipt
  content.
- Added `nativeSettingsContractVersionCounts` and
  `topNativeSettingsContractVersion` to the expense telemetry health snapshot.
- Aggregated the raw native `settingsContractVersion` emitted by CameraX and
  AVFoundation into Command One-safe counts.
- Extended telemetry tests so settings-contract drift is visible in Command One
  health while merchant, receipt text, customer, and price content remain
  blocked.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a focused camera/OCR gap audit for
  the next native-camera UI/device build batch.

### Receipt Camera Reopen Pass 358 / Total Pass 438: Local OCR And Optional Cloud Assist Contract Batch

Status: complete.

What changed:
- Audited the device capability policy for low-storage receipt behavior.
- Added `ReceiptCloudAssistPlan` as a shared contract for receipt settings,
  camera flow, OCR handoff, telemetry, and later Command One views.
- Made the local/cloud boundary explicit: local OCR remains available, cloud
  OCR is optional, cloud inventory matching is optional, and cloud assist
  requires explicit user choice plus internet.
- Added privacy-safe diagnostics for the plan without receipt text, image
  paths, merchant names, customer content, or user identity.
- Preserved existing user-facing local-first copy for high-capacity devices.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring the cloud-assist plan into
  receipt OCR/camera metadata so Command One can report local-only versus
  optional-cloud receipt behavior without private content.

### Receipt Camera Reopen Pass 359 / Total Pass 439: OCR Cloud Assist Telemetry Wiring Batch

Status: complete.

What changed:
- Wired the receipt cloud-assist plan into expense receipt OCR-started
  telemetry after the device capability and policy are known.
- Carried the same privacy-safe plan metadata into OCR completion/failure
  telemetry so blocked and failed reads remain explainable.
- Added content-free telemetry allowlist keys for local OCR mode, optional cloud
  OCR, optional cloud inventory matching, local catalog limits, local inventory
  cache limits, and data-saver level.
- Added Command One health summary counts for receipt cloud-assist plans and
  local OCR modes.
- Added optional-cloud OCR and optional-cloud inventory counts so Command One
  can separate low-storage/cloud-assisted behavior from full local device runs.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/expense_screen_telemetry_test.dart test/receipt_assistance_policy_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the visible native receipt-camera
  review/capture UI flow gap list before the next phone build batch.

### Receipt Camera Reopen Pass 360 / Total Pass 440: Receipt Review First-Tray Copy Cleanup Batch

Status: complete.

What changed:
- Audited the visible receipt photo review tray shown immediately after
  capture.
- Kept the receipt preview dominant while preserving the explicit
  `Next: Review Receipt Details` handoff.
- Removed raw score/evidence copy from the first warning strip so the user sees
  action guidance first instead of noisy quality-score language.
- Preserved underlying quality evidence in the model and diagnostics for OCR,
  tests, and Command One.
- Added a layout/copy guard so future review-tray changes do not reintroduce
  raw quality evidence into the first visible action strip.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native camera live-preview controls:
  pinch zoom, tap focus, brightness/exposure control, settings access, and
  back/close behavior.

### Receipt Camera Reopen Pass 361 / Total Pass 441: Native Live Control Hint Batch

Status: complete.

What changed:
- Audited the Maintainiac native receipt camera shell, not the stock Samsung
  camera UI.
- Added compact live-control chips inside the guidance panel for native
  capabilities that are actually available.
- Shows `Tap text to focus` only when the backend reports tap focus support.
- Shows `Pinch to zoom` only when the backend reports zoom support.
- Shows `Brightness assist` only when the backend reports exposure
  compensation support.
- Kept the back button, settings button, and torch button in the top bar and
  verified they remain away from the middle of the screen.
- Added widget coverage proving unsupported devices do not show unavailable
  control promises.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`
- `flutter test test/receipt_native_camera_shell_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart test/receipt_native_camera_shell_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native Android/iOS bridge parity for
  those visible controls: tap focus, pinch zoom, exposure assist/reset, and
  close/back diagnostics.

### Receipt Camera Reopen Pass 362 / Total Pass 442: Command One Firestore Schema Parity Batch

Status: complete.

What changed:
- Audited the Command One expense telemetry schema guards after adding native
  settings contract and local/cloud OCR assist summaries.
- Added native settings contract, local/cloud assist plan, local OCR mode, and
  optional cloud assist count keys to the expected Command One schema.
- Added bottom-brightness, bottom-edge, and vertical-quality camera fields to
  the Firestore telemetry sanitizer so saved-photo darkness/blur issues are not
  dropped before Command One sees them.
- Updated Firestore redaction map fields so camera quality bucket keys remain
  tokenized and privacy-safe.
- Updated the rich Firestore telemetry fixture so new conditional camera/OCR
  keys are exercised and protected.
- Fixed the manual telemetry snapshot fixture so it includes the newer
  bottom-quality and native/cloud assist fields.

Validation:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/helpers/expense_telemetry_schema_expectations.dart test/maintainiac_firestore_documents_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is bridge parity and focused tests for
  native tap-focus, pinch-zoom, exposure/reset, settings, and back/close
  diagnostics.

### Receipt Camera Reopen Pass 876: Totals-Only Line Recovery Diagnostics Batch

Status: complete.

What changed:
- Split the local parser's "no line items" path into a sharper recovery signal:
  receipt totals found, but no safe item-price lines detected.
- Added privacy-safe downstream readiness count
  `totals_found_no_safe_lines` so Command One can report the exact parser
  failure point without storing receipt text, store names, prices, addresses, or
  image paths.
- Updated receipt review wording to tell the user they can continue with the
  detected total or add item lines manually, instead of making the receipt look
  empty.
- Added diagnostic cause `receipt_parser_totals_found_no_safe_lines` with
  failed-at stage `receipt_line_detection_after_total_detection`.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_receipt_parser_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_receipt_parser_test.dart test/expense_parser_failure_diagnostics_test.dart`
- `flutter test test/expense_receipt_parser_test.dart -r compact`
- `flutter test test/expense_parser_failure_diagnostics_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart lib/screens/expenses/data/expense_receipt_parse_models.dart lib/screens/expenses/data/expense_parser_failure_diagnostics.dart lib/screens/expenses/data/expense_screen_telemetry.dart lib/screens/expenses/data/expense_receipt_privacy_event.dart test/expense_receipt_parser_test.dart test/expense_parser_failure_diagnostics_test.dart`

### Receipt Camera Reopen Pass 877: Base Receipt Footprint Policy Batch

Status: complete.

What changed:
- Added `ReceiptFeatureFootprintPlan` to make the base receipt feature budget,
  included local pack size, optional local pack size, cloud fallback pack codes,
  and low-storage safety explicit.
- Wired footprint diagnostics into `ReceiptCloudAssistPlan` and native capture
  staging's privacy-safe diagnostic whitelist.
- Proved low-storage phones keep local OCR available without forcing optional
  local parser pack downloads.
- Proved high-capacity materials/inventory intelligence remains an explicit
  optional local download instead of being silently treated as base app weight.
- Kept the actual APK/AAB size question separate: this is a policy guard, while
  release build size still must be measured from Android and iOS build outputs.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_assistance_policy_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native capture handoff enforcement:
  make sure the custom Maintainiac camera path is the primary receipt capture
  path, fallback capture is explicitly labeled as backup, and accepted photos
  hand into OCR/review without dropping the user back to the receipt home panel.

### Receipt Camera Reopen Pass 873: Critical Storage Receipt Workload Batch

Status: complete.

What changed:
- Made critical and low storage capability profiles real instead of only
  changing the recommended space-saving label.
- Critical storage now forces the light receipt workload, proof/totals-first
  local parser scope, smaller staged-photo and PDF budgets, slower live analysis,
  one assisted shot, no SKU detection, no trade classification, no advanced
  confidence scoring, and tiny local catalog/cache limits.
- Low storage now avoids heavyweight inventory matching, trims photo/PDF
  staging limits, reduces catalog/cache limits, and keeps OCR/local review
  usable without forcing cloud.
- Preserved the important rule: capture and local OCR are still available on
  low-space phones; cloud OCR/inventory help remains optional, explicit, and
  never required for camera capture or receipt review.
- Added regression coverage for a flagship-class device with critical storage
  proving it does not pull heavy parser packs or enable auto-capture, and that
  privacy-safe diagnostics still show no cloud requirement.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "critical storage" -r compact`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the capture/review flow
  around accepted-photo preservation, clear "Next" routing into parsed receipt
  review, and keeping the UI adjustable without disturbing the native camera
  service and low-storage workload rules.

### Receipt Camera Reopen Pass 874: Accepted Photo To Receipt Details Route Batch

Status: complete.

What changed:
- Hardened the app-assisted receipt handoff after a user taps Next on an
  accepted receipt photo.
- Added explicit route-result labels for the three real post-photo outcomes:
  parsed receipt fields opened, manual receipt-line review opened, and saved
  proof opened with no readable text.
- Wired those route-result labels into OCR completion, parser success,
  parser fallback/manual review, and no-readable-text paths so telemetry and
  UI can answer exactly what happened after photo acceptance.
- Kept the receipt review flow open and review-scrolled after parser completion;
  the attachment panel remains below the receipt-details review after the
  app-assisted flow starts.
- Updated the camera help guard to match the current native-camera-first
  fallback copy: backup phone camera capture is fallback only and still returns
  to Maintainiac review.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart --name "assisted expense receipt review exposes whole receipt choices" -r compact`
- `flutter test test/receipt_camera_capture_layout_test.dart -r compact`
- `flutter test test/receipt_camera_help_flow_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_entry_screen.dart lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart test/expense_receipt_assisted_review_flow_test.dart test/receipt_camera_help_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local OCR/parser accuracy for clean
  fuel/simple retail receipts: improve field/line extraction confidence,
  no-line recovery, and privacy-safe failure buckets without adding cloud work
  or forced heavyweight local packs.

### Receipt Camera Reopen Pass 875: Compact Identifier Total Guard Batch

Status: complete.

What changed:
- Hardened the local parser against a real OCR failure mode where an identifier
  on an ID-heavy total row could be misread as compact cents.
- Added a guard so lines like `INVOICE TOTAL 18934` do not become `$189.34`
  when OCR drops the actual receipt total amount.
- Preserved valid compact receipt totals such as `TOTAL 324`, which still parse
  as `$3.24`.
- Added safe total inference from subtotal plus tax when the explicit total is
  missing after rejecting an ID-looking compact amount. The inferred total is
  marked for review, not treated as directly read from the receipt.
- Added Lowe's regression coverage for rejecting invoice identifiers, avoiding
  ZIP-code totals, keeping the real item line, and inferring the 3.24 total from
  2.99 subtotal plus 0.25 tax.

Validation:
- `dart format lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`
- `flutter test test/expense_receipt_parser_test.dart --name "Lowe invoice identifiers" -r compact`
- `flutter test test/expense_receipt_parser_test.dart --name "compact cents" -r compact`
- `flutter test test/expense_receipt_parser_test.dart -r compact`
- `git diff --check -- lib/screens/expenses/data/expense_receipt_parser_logic.dart test/expense_receipt_parser_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is local OCR/parser no-line recovery:
  when OCR finds text and totals but no safe line items, improve the review
  bucket and recovery actions without pretending the parser succeeded.

### Receipt Camera Reopen Pass 871: Saved-Photo Exact Cause Telemetry Batch

Status: complete.

What changed:
- Added privacy-safe saved-photo warning cause counts to receipt photo review
  results so dim saved photos, preview-to-saved brightness mismatch, glare,
  blur, bottom-dark, and bottom-soft cases are separated from the broader user
  warning labels.
- Carried `savedPhotoWarningCauseCounts` through receipt-reader handoff
  metadata so OCR/parser review can explain why a captured receipt image needs
  review without exposing receipt content.
- Added `savedPhotoWarningCauseCounts` and `topSavedPhotoWarningCause` to the
  expense telemetry health snapshot and Command One map.
- Extended telemetry schema expectations and regression fixtures so Command
  One can distinguish, for example, `saved_photo_dim_or_live_to_saved_mismatch`
  from `saved_photo_darker_than_live_preview` and `saved_photo_soft_blur_risk`.
- Kept the new diagnostics content-free: no merchant names, receipt lines,
  item descriptions, prices, addresses, phone numbers, notes, or image paths are
  surfaced.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result summarizes saved-photo camera warnings" -r compact`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result flags bridged dim and glare capture wording" -r compact`
- `flutter test test/receipt_camera_result_test.dart --name "photo review result tracks preview parity watch without blocking" -r compact`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/helpers/expense_telemetry_schema_expectations.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening local OCR/parser
  readiness for long Walmart-style receipts by separating unreadable-line,
  missing-total, duplicate-overlap, and tiny-text failure causes before the
  receipt review screen.
