# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 738 - 03:33:00 EDT to active cleanup

Scope:
- Added a shared `ReceiptCaptureFlow.scanBarcodesFromReviewResult` handoff
  helper for expense, inventory, and maintenance consumers.
- Routed barcode scanning through OCR-source photos first, with saved proof
  fallback only when the review result already fell back.
- Added focused regressions for OCR-source preference and saved-proof fallback.
- Archived Pass 713 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for capture flow barcode handoff.
- Passed focused Flutter barcode handoff and barcode scanner regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 737 - 03:30:19 EDT to active cleanup

Scope:
- Audited the existing ML Kit barcode/QR service and confirmed the dependency
  and single-image scanner already exist.
- Added a bounded multi-image barcode scan result for long receipts and shared
  camera handoff consumers.
- Added privacy-safe batch summaries and deduped inventory lookup values across
  receipt segments without exposing raw barcode or QR payloads.
- Added focused batch scanner regressions for cross-segment dedupe and segment
  count bounding.
- Archived Pass 712 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for barcode scanner service and focused
  barcode scanner regression.
- Passed focused Flutter barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 736 - 03:28:54 EDT to active cleanup

Scope:
- Audited native capture staging fixtures for retired lock diagnostics.
- Replaced stale locked focus/exposure/white-balance fixture state with
  continuous/auto/not-requested diagnostics.
- Updated manifest and recovery-index expectations so staged diagnostics keep
  retired lock attempts at zero.
- Recorded `BUG-RECEIPT-0227` under `qa_harness`.
- Archived Pass 711 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for native capture staging fixtures,
  manifest expectations, index expectations, and staging regression.
- Passed focused Flutter native capture staging regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 735 - 03:27:16 EDT to active cleanup

Scope:
- Audited remaining native lock diagnostics after platform argument hardening.
- Hard-coded Android and iOS `whiteBalanceLockEnabled` diagnostics false so
  retired lock state cannot leak through serialized capture diagnostics.
- Updated Android/iOS storage-contract regressions to reject variable-derived
  white-balance lock diagnostics.
- Recorded `BUG-RECEIPT-0226` under `native_bridge`.
- Archived Pass 710 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS native storage bridge
  regressions.
- Passed focused Flutter Android/iOS storage bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 734 - 03:25:54 EDT to active cleanup

Scope:
- Audited native argument readers after the Dart service boundary was hardened.
- Hard-coded Android and iOS `whiteBalanceLockEnabled` false so stale native
  arguments cannot re-enable retired white-balance locking.
- Updated Android/iOS bridge source regressions to reject the stale argument
  trust path.
- Recorded `BUG-RECEIPT-0225` under `native_bridge`.
- Archived Pass 709 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for Android/iOS native bridge exposure
  regressions.
- Passed focused Flutter Android/iOS bridge regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 733 - 03:24:50 EDT to active cleanup

Scope:
- Closed the remaining Dart service payload gap for retired tap focus.
- Hard-coded `tapFocusEnabled` false before native channel handoff instead of
  relying on upstream session policy.
- Extended the service source-contract regression to reject config-derived
  `tapFocusEnabled` payloads.
- Recorded `BUG-RECEIPT-0224` under `native_bridge`.
- Archived Pass 708 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 732 - 03:23:50 EDT to active cleanup

Scope:
- Extended retired-control hardening from tap focus to focus, exposure, and
  white-balance lock enablement at the Dart service boundary.
- Hard-coded retired lock enablement fields false before native channel handoff.
- Added a service source-contract regression rejecting lock enablement derivation
  from session config.
- Recorded `BUG-RECEIPT-0223` under `native_bridge`.
- Archived Pass 707 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 731 - 03:22:11 EDT to active cleanup

Scope:
- Audited remaining tap-focus references after removing retired controls from
  capability policy scoring.
- Hard-coded the Dart service contract payload so `tapFocusControlExpected`
  stays false instead of deriving from `config.tapFocusEnabled`.
- Added a service source-contract regression proving the retired tap-focus
  expected flag cannot be reconnected through the service helper.
- Recorded `BUG-RECEIPT-0222` under `native_bridge`.
- Archived Pass 706 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer for the native camera service contract
  helper and service basics regression.
- Passed focused Flutter native service regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 730 - 03:17:54 EDT to active cleanup

Scope:
- Removed retired lock controls from native capability policy scoring so
  capable devices can still report full camera assist.
- Kept lock enablement false, but stopped treating retired locks as a degraded
  capability or noisy policy code.
- Removed retired tap-focus controls from capability policy scoring after the
  focused test caught capable devices losing their full-assist policy code.
- Added session/channel regressions proving retired-lock policy noise stays out
  while full camera assist remains possible.
- Recorded `BUG-RECEIPT-0220` and `BUG-RECEIPT-0221` under `native_bridge`.
- Archived Pass 705 from the active cleanup log to keep the doc under cap.

Verification:
- Focused test caught `BUG-RECEIPT-0221`; fix added before continuing.
- Passed targeted Dart format/analyzer for native camera capability policy,
  session settings, channel expectations, and focused contract tests.
- Passed focused Flutter native session, settings-contract, and channel
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 729 - 03:15:57 EDT to active cleanup

Scope:
- Removed remaining active native service spec wording that listed
  focus/exposure/white-balance lock controls after the receipt camera moved to
  continuous autofocus/readability guidance.
- Removed dormant lock-tag builder lines from current Dart session config so a
  future flag flip cannot re-add `focus_lock`, `brightness_lock`, or
  `white_balance_lock` tags.
- Extended active-doc and session-contract regressions for retired lock-control
  wording and tags.
- Recorded `BUG-RECEIPT-0219` under `native_bridge`.
- Archived Pass 704 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused active-doc/session
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

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
