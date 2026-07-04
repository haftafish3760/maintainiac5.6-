# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 728 - 03:11:18 EDT to active cleanup

Scope:
- Retired Dart-side focus/exposure/white-balance lock enablement so current
  receipt camera sessions no longer advertise lock controls or lock tags.
- Removed lock-control descriptors from the current receipt camera settings
  list, keeping continuous focus/readability guidance as the product path.
- Replaced lock-unavailable capability policy noise with a retired-lock policy
  code and updated channel/staging/native UI fixtures.
- Recorded `BUG-RECEIPT-0218` under `native_bridge`.
- Archived Pass 703 from the active cleanup log to keep the doc under cap.

Verification:
- First focused batch exposed stale previous-section capability-policy and
  native UI tag-count expectations; fixed before continuing.
- Passed targeted Dart format/analyzer and focused native contract/channel/
  staging/UI regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 727 - 03:07:12 EDT to active cleanup

Scope:
- Pinned Android, iOS, and Dart bridge diagnostics so retired focus/exposure/
  white-balance lock controls are never reported as expected receipt-camera
  controls.
- Kept legacy lock setting fields available separately for compatibility while
  preventing them from driving expected-control health.
- Updated staging/channel fixtures and Android/iOS bridge regressions for the
  retired lock-control expected values.
- Recorded `BUG-RECEIPT-0217` under `native_bridge`.
- Archived Pass 701 from the active cleanup log to keep the doc under cap.

Verification:
- First focused run included a non-existent staging manifest test path and
  exposed a stale retired-lock health expectation; fixed the expectation and
  reran with the correct staging test.
- Focused staging rerun exposed stale manifest helper assertions for retired
  lock expected controls; fixed before continuing.
- Tests-only source audit initially hit a Dart native-assets codesign race while
  another audit was running; reran it alone and it passed.
- Passed targeted Dart format/analyzer and focused native bridge/staging
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 726 - 03:04:16 EDT to active cleanup

Scope:
- Refined Android and iOS native control readiness summaries into core camera
  readiness signals so optional hardware controls do not make limited devices
  look unhealthy.
- Kept optional pinch zoom, brightness slider/reset, and torch diagnostics
  available as separate actual-status fields for admin/device capability
  review.
- Added Android/iOS bridge regressions that reject optional hardware controls
  as readiness-summary blockers.
- Recorded `BUG-RECEIPT-0216` under `native_bridge`.
- Archived Pass 700 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS native UI
  contract regressions.
- First bug-ledger gate failed because `BUG-RECEIPT-0216` used an unknown
  category; reclassified it under allowed `native_bridge` before continuing.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 725 - 03:01:36 EDT to active cleanup

Scope:
- Fixed Android and iOS native control readiness summaries so retired tap-focus
  and manual focus-lock controls do not make the active receipt camera look
  unhealthy.
- Kept explicit retired-control diagnostics available while limiting readiness
  summary evaluation to active controls such as back, settings, shutter, pinch
  zoom, brightness, reset, and torch.
- Added Android/iOS bridge regressions that inspect the readiness-summary body
  and reject retired tap/manual-lock controls inside it.
- Recorded `BUG-RECEIPT-0215` under `camera_capture_quality`.
- Archived Pass 699 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS native UI
  contract regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 724 - 02:59:50 EDT to active cleanup

Scope:
- Hardened Android and iOS native diagnostics so retired tap focus is never
  reported as an expected control, even if a stale internal flag flips later.
- Added Android/iOS bridge regressions requiring
  `tapFocusControlExpected` to be hard-coded false instead of derived from
  `tapFocusEnabled`.
- Recorded `BUG-RECEIPT-0214` under `camera_capture_quality`.
- Archived Pass 698 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS native UI
  contract regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 723 - 02:54:10 EDT to active cleanup

Scope:
- Retired dormant Android and iOS native tap-to-focus gesture paths so legacy
  flags cannot bring manual tap focus back into the receipt camera.
- Kept pinch zoom, brightness/exposure, continuous focus, and readability
  guidance as the active receipt-camera control model.
- Tightened native control readiness so tap/manual focus lock diagnostics report
  retired controls instead of becoming ready if a stale flag flips.
- Added Android/iOS bridge regressions that reject `FocusMeteringAction`,
  `UITapGestureRecognizer`, tap focus point metering, and tap-suppression
  zoom baggage in active native camera sources.
- Recorded `BUG-RECEIPT-0212` under `camera_capture_quality`.
- Fixed stale Android import-hygiene expectations for the legitimate Camera2
  interop imports used by continuous autofocus and the UUID import used by
  native unique receipt filenames.
- Recorded `BUG-RECEIPT-0213` under `qa_harness`.
- Archived Pass 696 from the active cleanup log to keep the doc under cap.

Verification:
- First focused native bridge run failed because manual focus-lock assertions
  still expected the retired tap-focus path; fixed those assertions before
  continuing.
- Second focused batch failed because Android import hygiene did not include
  legitimate Camera2 continuous-focus interop imports; the follow-up focused
  import-hygiene run also exposed the missing UUID import for native unique
  receipt filenames. Fixed both before continuing.
- Passed targeted Dart format/analyzer and focused native bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 722 - 02:51:00 EDT to active cleanup

Scope:
- Fixed native over-budget capture handling so existing sections are returned
  only when a close-after-capture flow was actually pending.
- Kept add-photo/retake flows on the camera after an over-budget section so the
  user can retry instead of being forced into review with older sections.
- Added Android/iOS bridge source regressions for the
  `shouldReturnExistingSections` guard.
- Recorded `BUG-RECEIPT-0211` under `multi_photo_ordering`.
- Archived Pass 695 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused Android/iOS bridge
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 721 - 02:47:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native capture callbacks so an over-budget receipt
  photo is deleted and rejected before it is appended to captured sections.
- Preserved existing captured sections when a close-after-capture path fails due
  to the byte budget.
- Added Android/iOS bridge source regressions for native over-budget cleanup and
  `native_capture_over_byte_budget` status.
- Recorded `BUG-RECEIPT-0209` under `source_preservation`.
- Fixed stale Android auto-capture QA assertions that still expected raw
  readability-signal equality checks instead of the named readability-review
  policy set.
- Recorded `BUG-RECEIPT-0210` under `qa_harness`.
- Archived Pass 694 from the active cleanup log to keep the doc under cap.

Verification:
- First focused bridge run failed because the Android auto-capture test still
  expected raw `latestReadabilitySignal == ...` checks; fixed the test to
  require the helper/set policy and reject direct equality checks.
- Passed targeted Dart format/analyzer for Android/iOS bridge regressions.
- Passed focused Android/iOS native bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 720 - 02:45:00 EDT to active cleanup

Scope:
- Tightened native byte-budget validation so the service enforces the largest
  positive value from `photoByteSize` and `totalCapturedByteSize`.
- Added a regression where per-photo bytes are small but total captured bytes
  exceed the session budget.
- Recorded `BUG-RECEIPT-0208` under `source_preservation`.
- Archived Pass 693 from the active cleanup log to keep the doc under cap.

Verification:
- Passed Dart format/analyzer for native total-byte validation.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 719 - 02:43:00 EDT to active cleanup

Scope:
- Hardened `ReceiptNativeCameraService` so sanitized native capture diagnostics
  that exceed the session `maxLocalPhotoBytes` budget are rejected before
  OCR/staging handoff.
- Added a focused regression for oversized native receipt photo diagnostics.
- Recorded `BUG-RECEIPT-0207` under `source_preservation`.
- Archived Pass 692 from the active cleanup log to keep the doc under cap.

Verification:
- Passed Dart format/analyzer for native byte-budget validation.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 718 - 02:40:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native receipt capture temp filenames so they include
  a UUID in addition to the timestamp.
- Added native bridge source regressions proving timestamp-only receipt capture
  filenames cannot return.
- Recorded `BUG-RECEIPT-0206` under `multi_photo_ordering`.
- Archived Pass 691 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS bridge regressions.
- Passed focused Android/iOS native bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 717 - 02:39:00 EDT to active cleanup

Scope:
- Hardened `ReceiptNativeCameraService` so native results cannot return more
  receipt photo paths than the session `maxSectionCount` allows.
- Added a focused regression where long-receipt mode is disabled but the native
  bridge returns two receipt paths.
- Recorded `BUG-RECEIPT-0205` under `multi_photo_ordering`.

Verification:
- Passed Dart format/analyzer for native section-count validation.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 716 - 02:37:00 EDT to active cleanup

Scope:
- Added a focused native path-validation regression proving NUL-containing
  receipt photo paths are rejected before OCR/staging handoff.
- Recorded `BUG-RECEIPT-0204` under `source_preservation`.

Verification:
- Passed Dart format/analyzer for native path validation regression.
- Passed focused native path validation regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 715 - 02:32:00 EDT to active cleanup

Scope:
- Split native receipt path validation regressions into
  `test/receipt_native_camera_result_path_validation_test.dart` so the primary
  native result rejection test is no longer one line under the project cap.
- Kept duplicate, non-local, and non-image path regressions intact in the new
  focused test file.
- Recorded `BUG-RECEIPT-0203` under `qa_harness`.
- Archived Pass 690 from the active cleanup log to keep the doc under cap.

Verification:
- Passed Dart format/analyzer for native result and path validation tests.
- Passed focused native result and path validation regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 714 - 02:31:00 EDT to active cleanup

Scope:
- Extended native receipt path validation so local paths must also be image-like
  receipt captures before OCR/staging handoff.
- Added a regression rejecting a local `.txt` path returned from the native
  camera platform channel.
- Recorded `BUG-RECEIPT-0202` under `source_preservation`.
- Archived Pass 689 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native receipt image path
  validation.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 713 - 02:29:00 EDT to active cleanup

Scope:
- Hardened `ReceiptNativeCameraService` so native camera results must return
  local absolute receipt photo paths before OCR/staging handoff.
- Added a regression rejecting URL and relative-path receipt results from the
  platform channel.
- Recorded `BUG-RECEIPT-0201` under `source_preservation`.
- Archived Pass 688 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native receipt path validation.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 712 - 02:27:00 EDT to active cleanup

Scope:
- Tightened native capture ID sanitization so malformed, path-like, spaced, or
  oversized IDs become opaque `native_capture_N` values instead of preserving
  sanitized user-looking words.
- Updated the native result regression to prove path-like names and oversized
  receipt IDs do not survive as staging metadata.
- Recorded `BUG-RECEIPT-0200` under `privacy_redaction`.
- Archived Pass 687 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native capture ID sanitization.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 711 - 02:25:00 EDT to active cleanup

Scope:
- Hardened the shared native camera result boundary so Android/iOS
  `temporaryCaptureIds` are sanitized, bounded, and capped to the returned
  photo count before the result leaves `ReceiptNativeCameraService`.
- Added a regression with path-like, oversized, and extra native capture IDs so
  malformed metadata cannot spread into staging manifests or diagnostics.
- Recorded `BUG-RECEIPT-0199` under `native_bridge`.
- Archived Pass 686 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service boundary
  and result regression.
- Passed focused native camera result regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 710 - 02:23:00 EDT to active cleanup

Scope:
- Tightened shared Flutter receipt help copy so it names continuous
  autofocus/readability guidance instead of generic continuous focus.
- Replaced first-use intro `flash, focus` wording with `flash, readability
  guidance` so the shared camera entry point does not imply a manual focus
  feature.
- Added help-flow source regressions for the updated copy and the retired
  generic focus phrase.
- Recorded `BUG-RECEIPT-0198` under `camera_capture_quality`.
- Archived Pass 652 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the receipt camera help flow.
- Passed focused receipt camera help flow regression.
- First cleanup log gate failed at 501 lines; archived Pass 653 and reran the
  gate before milestone push.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 709 - 02:21:00 EDT to active cleanup

Scope:
- Removed stale Android native settings copy that still told users to use focus
  assist after the receipt camera moved to continuous-autofocus/readability
  guidance.
- Added focused Android bridge source regression coverage so retired focus
  assist copy cannot return through settings/help text.
- Recorded `BUG-RECEIPT-0197` under `camera_capture_quality`.
- Archived Pass 651 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the Android settings bridge test.
- Passed focused Android settings bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 708 - 02:45:00 EDT to active cleanup

Scope:
- Removed stale iOS native settings copy that still told users to use focus
  assist after the receipt camera moved to continuous-autofocus/readability
  guidance.
- Added focused iOS bridge source regression coverage so the retired focus
  assist copy cannot return through settings/help text.
- Fixed stale iOS bridge QA assertions that still expected direct raw
  readability-signal equality checks instead of the named readability-review
  policy set.
- Recorded `BUG-RECEIPT-0195` under `camera_capture_quality`.
- Recorded `BUG-RECEIPT-0196` under `qa_harness`.
- Archived Pass 650 from the active cleanup log to keep the doc under cap.

Verification:
- First focused iOS settings bridge regression failed because the test still
  expected raw `latestReadabilitySignal == ...` checks; fixed the regression to
  require the helper/set policy and reject direct equality checks.
- Passed targeted Dart format/analyzer for the iOS settings bridge test.
- Passed focused iOS settings bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 707 - 02:38:00 EDT to active cleanup

Scope:
- Audited native long-receipt ghost-guide argument parsing after the tap-focus
  boundary hardening.
- Fixed iOS previous-section guide path handling so it stores the trimmed path
  instead of keeping whitespace around the local receipt image path.
- Added focused iOS bridge regression coverage for the trimmed ghost-guide path.
- Recorded `BUG-RECEIPT-0194` under `ghost_overlap_stitching`.

Verification:
- Passed targeted Dart format/analyzer for iOS long-receipt bridge test.
- Passed focused iOS long-receipt bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 649 from the active cleanup log to keep the doc under cap.

## Pass 706 - 02:31:00 EDT to active cleanup

Scope:
- Hardened Android and iOS native session argument readers so stale or malformed
  bridge arguments cannot re-enable tap-focus for receipt capture.
- Forced the native tap-focus policy to
  `continuous_focus_primary_no_tap_focus` at both platform boundaries.
- Updated Android and iOS bridge regressions to reject raw tap-focus argument
  trust.
- Recorded `BUG-RECEIPT-0193` under `native_bridge`.
- Archived Pass 647 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native bridge tests.
- Passed focused Android/iOS bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 648 from the active cleanup log to keep the doc under cap.

## Pass 705 - 02:25:00 EDT to active cleanup

Scope:
- Aligned in-entry draft receipt line numbering with the saved ledger line
  guardrails so malformed OCR line or section numbers cannot show impossible
  proof labels before save.
- Added bounded draft line/section helpers and routed draft proof labels, OCR
  source labels, and redaction anchors through them.
- Expanded the assisted-review source fixture so regression coverage includes
  the shared draft line support and label helpers.
- Recorded `BUG-RECEIPT-0192` under `receipt_line_numbering`.
- Archived Pass 646 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for draft receipt line helpers and
  assisted-review source regression.
- Passed focused Flutter assisted receipt review flow regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 704 - 02:18:00 EDT to active cleanup

Scope:
- Audited the shared Google ML Kit barcode/QR scanner foundation after the
  camera-lane reminder to keep scanner support shared across expenses,
  inventory, and maintenance without touching inventory internals.
- Added corrupted/wrong-file style regression coverage so generic decoder
  failures become safe `barcode_scan_failed` warnings.
- Proved raw exception text from barcode failures does not leak into
  privacy-safe scanner summaries.
- Recorded `BUG-RECEIPT-0191` under `barcode_qr_scanning`.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service tests.
- Passed focused Flutter barcode scanner service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 645 from the active cleanup log to keep the doc under cap.
