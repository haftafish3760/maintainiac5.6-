# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 654: Preview Tray Long-Receipt Decision Copy Batch

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 654: Preview Tray Long-Receipt Decision Copy Batch

Status: complete.

What changed:
- Tightened the post-capture preview tray copy so a single accepted photo tells
  the user the actual decision: if this is the whole receipt, tap Next; if the
  receipt continues, use Add Receipt Photo.
- Kept the bottom tray compact; no new panel was added and the existing
  capped preview-control heights remain in place.
- Preserved the "Next: Review Receipt Details" primary action and the
  explicit Add Receipt Photo button so long receipts do not depend on a camera
  icon alone.
- Updated layout guards to expect the clearer long-receipt decision copy
  instead of the older generic item-price wording.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening add-photo capture
  recovery from the review screen, including previous-section ghost guide
  diagnostics and fallback wording.

### Receipt Camera Reopen Pass 655: Add-Photo Fallback Metadata Batch

Status: complete.

What changed:
- Added explicit fallback metadata when Add Receipt Photo has to use the phone
  camera backup from the review screen.
- Phone-camera backup sections now report the primary flow as
  `maintainiac_native_receipt_camera`, the backup role as `fallback_only`, and
  whether the user was adding a section with a previous-section guide.
- Preserved the native CameraX/AVFoundation path as the first choice for
  additional receipt sections; the phone camera remains emergency backup only.
- Added layout-test guards so long-receipt add-photo diagnostics keep the
  native-primary/fallback-only boundary visible.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart test/receipt_camera_capture_layout_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is strengthening native capture result
  diagnostics around exposure/brightness and accepted-photo quality so dark or
  blurry lower-receipt problems are easier to explain and fix.

### Receipt Camera Reopen Pass 656: Native Bottom Brightness Delta Batch

Status: complete.

What changed:
- Added Android CameraX and iOS AVFoundation diagnostics for the brightness
  difference between the top and bottom of the captured receipt photo.
- Added `latestCapturedBottomTopLumaDelta` and
  `latestCapturedBottomTopLumaDeltaBucket` so dark-bottom, bright-bottom, and
  even-brightness captures can be separated without storing receipt content.
- Kept the diagnostics privacy-safe: numeric/bucketed image-quality evidence
  only, no text, prices, store names, addresses, or line items.
- Added bridge/layout guards for the new native diagnostic keys on both
  platforms.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is routing the new bottom/top
  brightness buckets into saved-photo review warnings and OCR recovery advice.

### Receipt Camera Reopen Pass 657: Bottom Brightness Warning Routing Batch

Status: complete.

What changed:
- Added the new bottom/top luma delta keys to the shared diagnostic contract and
  native capture staging allow-list.
- Routed `bottom_darker_than_top` and `bottom_much_darker_than_top` into the
  existing bottom-too-dark saved-photo warning family.
- Kept the advice tied to OCR risk: if the total, tax, barcode, or final lines
  are hard to read, use Add Receipt Photo for a clearer bottom section before
  OCR review.
- Added guards proving the model, staging layer, and photo review layout all
  recognize the new brightness delta diagnostics without exposing receipt
  content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart`
- `flutter test test/receipt_camera_capture_layout_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_capture_staging_test.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding a focused unit test for the
  bottom/top brightness warning decision itself instead of relying only on
  source guards.

### Receipt Camera Reopen Pass 658: Bottom Brightness Warning Unit Coverage Batch

Status: complete.

What changed:
- Added direct unit coverage for bottom/top brightness warning decisions.
- Verified both `bottom_darker_than_top` and
  `bottom_much_darker_than_top` route to `saved_photo_bottom_too_dark`.
- Verified the warning carries the bottom-total OCR risk and prefers Add
  Receipt Photo when the bottom of the receipt is the weak section.
- Kept the behavior in the existing receipt quality guidance test so the
  decision is exercised as a model behavior, not only a source-code guard.

Validation:
- `dart format test/receipt_camera_quality_guidance_test.dart`
- `flutter test test/receipt_camera_quality_guidance_test.dart`
- `flutter analyze test/receipt_camera_quality_guidance_test.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing the native exposure
  pre-capture adjustment thresholds and diagnostics so manual shutter remains
  immediate while brightness assist avoids making good scenes darker.

### Receipt Camera Reopen Pass 649: Filled Review Recovery Action And Add Photo Wording Batch

Status: complete.

What changed:
- Replaced the remaining active native recovery action token
  `read_receipt_or_save_proof` with `open_filled_review_or_save_proof` so
  accepted receipt photos point at the filled receipt review/proof-save path.
- Standardized active long-receipt recovery wording from `Add Next Section` /
  `Add More Proof` to `Add Receipt Photo` or `add another receipt photo`.
- Added source guard coverage so the active capture flow keeps the filled-review
  action token and does not reintroduce the old read-receipt recovery token.
- Kept this pass scoped to camera/receipt wording and diagnostics; no camera
  backend, OCR engine, parser, PDF, Firebase, or inventory behavior changed.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_flow.dart lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart lib/screens/expenses/entry/expense_receipt_entry_screen.dart test/receipt_camera_help_flow_test.dart test/receipt_attachment_panel_actions_test.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the active post-capture
  review flow so a confirmed receipt photo clearly proceeds to the filled
  receipt review, with obvious add-photo/retake/crop choices and no ambiguous
  read/save labels.

### Receipt Camera Reopen Pass 650: Native Primary Capture Boundary Batch

Status: complete.

What changed:
- Added fallback diagnostics that explicitly distinguish the primary
  `maintainiac_native_receipt_camera` flow from the phone camera backup path.
- Marked phone-camera backup diagnostics as `fallback_only` so Command
  One/debugging can tell when the stock camera/image picker was used because
  the native receipt camera was unavailable.
- Added regression coverage proving Android capture opens the Maintainiac
  CameraX receipt activity before any phone-camera backup and that the
  `image_picker` camera path remains documented as backup/import only.
- Tightened receipt review layout guard coverage around the explicit
  `Add Receipt Photo` action label.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_camera_capture_layout_test.dart test/receipt_native_android_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_camera_capture_layout_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart test/receipt_native_android_bridge_test.dart test/receipt_camera_capture_layout_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing the Android/iOS native
  capture UI settings surface so the camera screen itself exposes Maintainiac
  receipt controls clearly without becoming a generic system camera.

### Receipt Camera Reopen Pass 651: Native Receipt Settings Clarity Batch

Status: complete.

What changed:
- Tightened Android CameraX in-camera settings copy to say the settings control
  the Maintainiac receipt scanner, not the phone's regular camera app.
- Tightened iOS AVFoundation in-camera settings summary with the same boundary.
- Clarified that accepted photos open Maintainiac's filled receipt review when
  app-assisted fill is on.
- Clarified that save-space proof size affects the smaller proof/cloud-backup
  copy after OCR reads the clear source first.
- Clarified that the manual shutter works immediately and automatic capture is
  optional.
- Added Android/iOS bridge guards for those receipt-specific settings promises.

Validation:
- `dart format test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`
- `flutter analyze test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing the active native capture
  screen controls/back/close and post-capture transition so taking a receipt
  photo reliably lands in the review/filled-details path.

### Receipt Camera Reopen Pass 643: OCR Pack Disclosure Telemetry Batch

Status: complete.

What changed:
- Allowed the receipt OCR/parser pack disclosure label through expense telemetry
  as bounded readable setup text, not as receipt content.
- Added Command One visibility for the top parser-pack disclosure label so the
  admin health view can explain local download size, cloud fallback, internet
  requirement, and accuracy-band honesty without exposing user receipts.
- Kept parser pack code counts, accuracy-band counts, optional local bytes, and
  cloud fallback counts as tokenized operational telemetry.
- Updated the Firestore summary allowlist and contract tests so this disclosure
  survives backup safely.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "allows only content-free receipt camera health metadata"`
- `flutter test test/expense_screen_telemetry_test.dart --name "builds command center summary without private receipt details"`
- `flutter test test/maintainiac_firestore_documents_test.dart --name "keeps every Command Center telemetry field in Firestore summary"`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart lib/shared/firebase/maintainiac_firestore_documents.dart test/expense_screen_telemetry_test.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is the native receipt-camera settings
  contract and capture/review flow, keeping local/cloud OCR choices visible
  without making capture depend on network access.

### Receipt Camera Reopen Pass 644: Parser Pack Install Choice Contract Batch

Status: complete.

What changed:
- Added `ReceiptParserPackInstallChoice` as a reusable local/cloud OCR parser
  pack contract.
- Separated included local packs, optional local downloads, and cloud fallback
  packs so the expense camera flow and later materials flow can share the same
  decision model.
- Added explicit optional-download byte totals, cloud fallback internet
  requirement, offline capability, user-facing download copy, and privacy-safe
  diagnostics.
- Kept the contract pack-code based; it does not include store names, item
  names, receipt text, prices, customer content, or inventory content.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart --name "parser pack install choice separates local downloads from cloud fallback"`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring this shared install-choice
  contract into receipt setup/review UI copy without changing the camera backend
  or touching inventory-owned screens.

### Receipt Camera Reopen Pass 645: Settings Pack Choice Copy Batch

Status: complete.

What changed:
- Wired the receipt settings data-saver section to
  `ReceiptParserPackInstallChoice.userFacingDownloadChoiceLabel`.
- Removed hard-coded cloud OCR/inventory wording from that settings block so
  optional local download size and cloud fallback requirements come from the
  shared pack contract.
- Updated camera help/source guards to match the current explicit
  `Receipt Photo` wording instead of older section/photo labels.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is wiring the same install-choice
  contract into first-use receipt setup/review copy while keeping capture usable
  with no network and no optional packs installed.

### Receipt Camera Reopen Pass 646: First-Use Pack Choice Copy Batch

Status: complete.

What changed:
- Passed the active `ReceiptParserPackInstallChoice` into the first-use receipt
  camera intro sheet.
- Replaced first-use hard-coded cloud wording with the shared install-choice
  label so local download size and cloud fallback internet requirements match
  the settings screen.
- Kept the first-use flow capture-first: it still explains OCR uses the clearest
  photo first and that smaller saved proofs are for review/backup.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a focused source guard that prevents
  future receipt setup copy from claiming cloud OCR, parser, or inventory
  matching is required for basic capture/local review.

### Receipt Camera Reopen Pass 647: Cloud-Required Copy Guard Batch

Status: complete.

What changed:
- Added a receipt camera/help source guard that rejects setup copy implying
  cloud OCR, cloud parser, cloud inventory, or internet is required for basic
  receipt capture/local review.
- Guarded the settings sheet, first-use intro sheet, and receipt camera import
  actions against phrases such as `cloud required`, `requires cloud`,
  `must use cloud`, `cloud-only`, `cloud only`, and `internet required`.
- Kept optional cloud wording allowed through the shared install-choice label.

Validation:
- `dart format test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is a similar guard around OCR source
  ordering: original/clear source first, saved backup proof second.

### Receipt Camera Reopen Pass 648: OCR Source Ordering Copy Guard Batch

Status: complete.

What changed:
- Strengthened receipt camera source guards so review/data-saver copy continues
  to state the correct processing order: OCR uses the clear/prepared source
  first, then the smaller saved proof is used for review/backup.
- Added an exact guard for the data-saver preview panel copy explaining that the
  image behind the panel is the backup preview and not the first OCR source.
- Kept this as a source/test hardening pass only; no camera backend behavior was
  changed.

Validation:
- `dart format test/receipt_camera_help_flow_test.dart`
- `flutter test test/receipt_camera_help_flow_test.dart`
- `flutter analyze test/receipt_camera_help_flow_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is reviewing receipt result handoff
  messages for the same source-order clarity and no confusing `read receipt`
  language.

### Receipt Camera Reopen Pass 637: Native Recovery Command One Action Batch

Status: complete.

What changed:
- Added `topNativeRecoveryAction` to the expense telemetry health snapshot and
  Command One map so interrupted native receipt captures have a direct next
  step instead of only raw freshness/storage buckets.
- Prioritized recovery actions by operational risk: missing saved photos,
  partial saved sections, very stale recovery records, then stale recovery
  records.
- Kept the action content-free. It reports only recovery age/status and asks for
  recover, discard, retake, or manual confirmation without exposing receipt
  text, merchant names, prices, addresses, or line items.
- Added regression coverage for stale/partial recovery and missing-photo
  priority, plus updated the Command One schema expectation.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart --name "gives Command 1 a recovery action"`
- `flutter test test/expense_screen_telemetry_test.dart`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is native recovery action visibility in
  any Command One/admin widgets that render health summaries, then continue
  hardening receipt capture/review routing without touching PDF or inventory.

### Receipt Camera Reopen Pass 638: Native Recovery Firestore Visibility Batch

Status: complete.

What changed:
- Carried native recovery freshness counts, storage-status counts, and
  `topNativeRecoveryAction` through the Firestore expense telemetry summary
  sanitizer so Command One can read the same action that local telemetry
  computes.
- Closed related Command One sanitizer drift for OCR source handoff,
  client-proof redaction, parser downstream readiness, and parser-pack fields
  that already existed in the local health snapshot.
- Updated the Command One OCR contract doc to list the recovery freshness,
  storage, action, parser-pack, OCR handoff, and client-proof fields explicitly.
- Added hosted-summary assertions proving the Firestore document keeps the
  recovery action and supporting buckets without exposing private receipt
  content.
- Kept this pass limited to camera/OCR diagnostics and admin visibility. No PDF,
  inventory, or app-camera UI was changed.

Validation:
- `dart format lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/maintainiac_firestore_documents_test.dart --name "keeps every Command Center telemetry field in Firestore summary"`
- `flutter test test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter analyze lib/shared/firebase/maintainiac_firestore_documents.dart test/maintainiac_firestore_documents_test.dart test/expense_command_center_ocr_contract_doc_test.dart`
- `flutter build apk --debug`
- `git diff --check`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is returning to capture/review routing:
  accepted native receipt photos should reliably preserve the original OCR
  source image, keep recoverable staged photos visible, and route Next into the
  assisted receipt review instead of the expense entry start screen.
