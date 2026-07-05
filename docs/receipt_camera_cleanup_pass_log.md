# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 895 - 06:28:00 EDT to active cleanup

Scope:
- Split the receipt camera diagnostic publish boundary into a small testable
  policy object.
- Added direct regressions proving opt-out blocks diagnostic publication and
  opt-in envelopes carry machine-only privacy flags.
- Kept the shared attachment panel routed through the policy.
- Recorded `BUG-RECEIPT-0344` under `qa_harness`.
- Archived Pass 855 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused diagnostic policy/settings
  regressions, cleanup/doc/ledger/source gates, and diff whitespace gate.

## Pass 894 - 06:10:00 EDT to active cleanup

Scope:
- Routed shared receipt capture diagnostics through a single opt-in publisher
  so Help Improve Receipt Camera must be enabled before the callback fires.
- Stamped allowed diagnostics with privacy metadata proving owner receipt image
  preview stays disabled.
- Added telemetry policy coverage for the new opt-in and owner-preview flags.
- Recorded `BUG-RECEIPT-0343` under `privacy_redaction`.
- Archived Pass 847 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused receipt settings/admin
  diagnostic regressions, cleanup/doc/ledger/source gates, and diff whitespace
  gate.

## Pass 893 - 05:58:00 EDT to active cleanup

Scope:
- Added a default-off Help Improve Receipt Camera setting to the shared receipt
  camera settings store.
- Exposed the setting in the scanner behavior panel with privacy copy that
  keeps receipt images and receipt text out of owner-visible diagnostics.
- Reset the opt-in to off with receipt photo defaults.
- Recorded `BUG-RECEIPT-0342` under `privacy_redaction`.
- Archived Pass 841 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused receipt settings store
  regressions, cleanup/doc/ledger/source gates, and diff whitespace gate.

## Pass 892 - 05:55:00 EDT to active cleanup

Scope:
- Hardened the admin OCR-quality diagnostic artifact contract so receipt-image
  previews are machine-quality-review-only by default.
- Added telemetry metadata proving owner image preview is not allowed for
  diagnostic artifacts and blocked upload eligibility if that flag is enabled.
- Recorded `BUG-RECEIPT-0341` under `privacy_redaction`.

Verification:
- Passed targeted Dart format/analyzer, focused admin diagnostic contract
  regressions, and diff whitespace gate.

## Pass 891 - 05:30:00 EDT to active cleanup

Scope:
- Added privacy-safe native capture-readiness code counts and top reason to the
  Command1/Command Center camera health summary.
- Wired capture-readiness reason buckets through telemetry snapshots,
  Firestore sanitizer/parity, and command-summary fixtures.
- Preserved the no-private-receipt-content contract while improving camera
  failure visibility for manual-only, waiting, and ready capture states.
- Recorded `BUG-RECEIPT-0340` under `qa_harness`.
- Archived Pass 834 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused camera admin telemetry
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 890 - 17:17:00 EDT to active cleanup

Scope:
- Fixed the failing work-supply barcode bridge regression so malformed private
  QR value types stay blocked from inventory lookup suggestions.
- Pinned the scanner privacy contract to require the `sensitiveOther` bucket,
  zero bridge suggestions, and no raw QR payload in summaries.
- Recorded `BUG-RECEIPT-0339` under `barcode_qr_scanning`.
- Archived Pass 827 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused work-supply barcode bridge
  regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 889 - active cleanup

Scope:
- Added a permanent real-device receipt camera matrix gate for device tiers,
  lighting, receipt conditions, interruptions, OCR-source policy, and retired
  tap/original-source wording.
- Expanded the real-device script with the concrete matrix expected before
  broader receipt testing.
- Wired the matrix gate into the fast guard and added focused gate coverage.
- Recorded `BUG-RECEIPT-0338` under `qa_harness`.
- Archived Pass 826 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused real-device matrix/doc
  regressions, doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and
  diff whitespace gates.

## Pass 888 - active cleanup

Scope:
- Removed stale original-photo wording from native capture recovery OCR-source
  policy diagnostics.
- Renamed recovery manifest, staged-photo, and recovery-index tokens to
  temporary full-quality staged source before saved proof copy.
- Updated recovery fixture expectations to keep source-preservation wording
  aligned with the current storage contract.
- Recorded `BUG-RECEIPT-0337` under `source_preservation`.
- Archived Pass 825 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused native capture recovery/staging
  regressions, doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and
  diff whitespace gates.

## Pass 887 - active cleanup

Scope:
- Hardened native Android/iOS source contracts so retired tap-focus/focus-lock
  style controls stay forced off at session reader and actual-status helper
  boundaries.
- Added source regressions proving platform arguments cannot revive retired
  receipt focus controls behind Dart's continuous-focus product policy.
- Recorded `BUG-RECEIPT-0336` under `native_bridge`.
- Archived Pass 824 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused Android/iOS native bridge source
  regressions, doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and
  diff whitespace gates.

## Pass 886 - active cleanup

Scope:
- Hardened focus/readability diagnostics so continuous-focus expectation and
  native focus status must agree.
- Added mismatch outcomes for expected-but-unavailable focus and
  configured-when-not-expected focus states.
- Added focused regression coverage for the focus expectation/status invariant.
- Recorded `BUG-RECEIPT-0335` under `native_bridge`.
- Archived Pass 821 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused focus-contract/native-ui
  regressions, doc-size, bug-ledger, cleanup-log, source-audit, test-audit, and
  diff whitespace gates.

## Pass 885 - active cleanup

Scope:
- Hardened auto-capture waiting diagnostics so waiting-for-stability requires
  explicit auto-capture opt-in and stable-frame evidence.
- Added native UI risk outcomes for waiting without request and waiting without
  stable-frame diagnostics.
- Added focused regression coverage for the waiting-state invariant class.
- Recorded `BUG-RECEIPT-0334` under `native_bridge`.
- Archived Pass 820 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused auto-capture/native-quality
  regressions, and test source audit.

## Pass 884 - active cleanup

Scope:
- Hardened auto-capture waiting diagnostics so `auto_capture_waiting_for_stability`
  cannot remain the health state after the stable-frame target is already met.
- Added `auto_capture_waiting_after_stable_regressed` as a native UI risk
  outcome for stale waiting-state diagnostics.
- Added focused regression coverage for the waiting-after-stable mismatch.
- Recorded `BUG-RECEIPT-0333` under `native_bridge`.
- Archived Pass 819 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused auto-capture/native-quality
  regressions, and test source audit.

## Pass 883 - active cleanup

Scope:
- Hardened auto-capture readiness diagnostics so `auto_capture_ready` must
  include stable-frame evidence, not only an optimistic readiness code.
- Added `auto_capture_ready_missing_stability_evidence` as a native UI risk
  outcome when stable-frame or required-frame counts are absent.
- Added focused regression coverage for the missing-stability-evidence path.
- Recorded `BUG-RECEIPT-0332` under `native_bridge`.
- Archived Pass 818 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused auto-capture/native-quality
  regressions, and test source audit.

## Pass 882 - active cleanup

Scope:
- Hardened auto-capture readiness diagnostics so `auto_capture_ready` must match
  the required stable-frame count.
- Added a native UI risk outcome for `auto_capture_ready_before_stable_regressed`
  so early auto-capture cannot look safe in review/admin handoff.
- Added focused regression coverage for the stable-frame mismatch.
- Recorded `BUG-RECEIPT-0331` under `native_bridge`.
- Archived Pass 817 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused auto-capture/native-quality
  regressions, and test source audit.

## Pass 881 - active cleanup

Scope:
- Hardened optional auto-capture diagnostics so auto capture cannot appear ready
  without manual shutter fallback.
- Added consistency checks for auto-ready-while-blocked and auto-allowed without
  an explicit opt-in request.
- Surfaced those impossible states as native camera UI risk outcomes and
  attachment risk flags.
- Added focused auto-capture contract regressions.
- Recorded `BUG-RECEIPT-0330` under `native_bridge`.
- Archived Pass 816 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused auto-capture/native-quality
  regressions, and test source audit.

## Pass 880 - active cleanup

Scope:
- Hardened focus/readability contract checks so continuous-autofocus readiness
  must carry a matching `continuous_focus` native UI contract tag.
- Added fallback-review contract checks so devices without continuous focus must
  expose the `focus_readability_review` tag when review is required.
- Corrected the native UI ready regression fixture so retired lock controls stay
  disabled while continuous focus is explicitly present.
- Added focused regression coverage for continuous-focus and fallback-review
  contract tag drift.
- Recorded `BUG-RECEIPT-0329` under `native_bridge`.
- Archived Pass 807 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused native UI/focus contract
  regressions, and test source audit.

## Pass 879 - active cleanup

Scope:
- Hardened native UI health outcome priority so any retired-control regression
  becomes the primary camera health outcome before normal ready summaries.
- Covered the lock-only path where focus-lock, exposure-lock, or white-balance
  lock regressions could otherwise stay behind a ready native-control summary.
- Added regression coverage proving lock-only retirement failures become
  attachment risk flags and the main native UI outcome.
- Recorded `BUG-RECEIPT-0328` under `native_bridge`.
- Archived Pass 806 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused retired-control regression, and
  test source audit.

## Pass 878 - active cleanup

Scope:
- Closed the follow-on retired-control gap where native diagnostics could mark
  tap focus or lock controls active without stale contract tags.
- Added active-retired-control regression buckets for tap focus, focus lock,
  exposure lock, and white-balance lock.
- Kept active retired controls out of normal ready/missing control counts while
  still surfacing attachment risk flags.
- Added focused regression coverage for the no-contract-tag path.
- Recorded `BUG-RECEIPT-0327` under `native_bridge`.
- Archived Pass 805 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused native UI health regressions,
  and test source audit.

## Pass 877 - active cleanup

Scope:
- Hardened retired native camera controls so stale tap-focus or lock contract
  tags are treated as product-policy regressions, not missing controls the UI
  should restore.
- Covered the whole retired-control class: tap focus, focus lock, exposure
  lock, and white-balance lock.
- Kept regression signals flowing into native camera UI health outcomes and
  receipt attachment risk flags.
- Added focused native UI contract regression coverage.
- Recorded `BUG-RECEIPT-0326` under `native_bridge`.
- Archived Pass 804 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused native UI health regressions,
  and test source audit.

## Pass 876 - active cleanup

Scope:
- Classified OCR-source section-order handoff signals as their own typed
  evidence family instead of leaving them mixed into generic source signals.
- Exposed section-order signal counts through privacy-safe OCR handoff
  diagnostics so admin/failure reports can see why ordering review is needed.
- Made section-order review-required evidence drive
  `section_order_review_required` and `review_receipt_section_order` handoff
  actions before OCR/parser trust.
- Added a focused OCR-service regression that keeps section-order flags out of
  generic photo-quality risk counts.
- Recorded `BUG-RECEIPT-0325` under `ocr_handoff_contract`.
- Archived Pass 803 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused OCR/capture-flow/section-
  order regressions.

## Pass 875 - 16:32:00 EDT to active cleanup

Scope:
- Carried section-order review evidence into OCR-source attachment contracts
  from both the shared capture flow and attachment-panel paths.
- Added section-order outcome/action document signals and OCR risk flags so
  downstream OCR/admin diagnostics can see exactly why order review is needed.
- Added source-contract and result-level regressions for the new handoff
  signals and risk flags.
- Recorded `BUG-RECEIPT-0324` under `ocr_handoff_contract`.
- Archived Pass 802 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused capture-flow/section-order
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 874 - 16:36:00 EDT to active cleanup

Scope:
- Hardened malformed retake and insert diagnostics that omit required section
  numbers while still carrying operation metadata.
- Added missing-original/final retake buckets and missing-anchor/final insert
  buckets so OCR cannot trust incomplete section-order metadata.
- Added regression coverage for missing retake and insert section numbers.
- Recorded `BUG-RECEIPT-0323` under `multi_photo_ordering`.
- Archived Pass 801 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused section-order/stitch-scanner
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 873 - 16:31:00 EDT to active cleanup

Scope:
- Closed the follow-on section-order handoff gap where invalid order metadata
  could still report a details-ready route.
- Made invalid section ordering return `needs_review_before_ocr`, pause receipt
  details/OCR handoff, and require section-order review before continuing.
- Added regression coverage for route blocking and attachment document signals
  so downstream OCR handoff sees the review-needed state.
- Recorded `BUG-RECEIPT-0322` under `multi_photo_ordering`.
- Archived Pass 800 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused section-order/stitch-scanner
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 872 - 16:26:00 EDT to active cleanup

Scope:
- Hardened receipt section-order diagnostics for long-receipt retakes,
  inserted sections, manual reorder, and normal ghost-guided continuation.
- Added invalid families for retake offsets, context flag mismatches,
  previous/next context gaps, top-retake ghost mismatches, and insert offsets.
- Surfaced privacy-safe section-order review action codes, labels, metadata,
  and handoff counts so OCR cannot silently trust malformed ordering metadata.
- Added regression coverage for invalid retake context, top ghost mismatch,
  insert offset mismatch, and normal long-receipt ghost continuation.
- Recorded `BUG-RECEIPT-0321` under `multi_photo_ordering`.
- Archived Pass 799 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused section-order/stitch-scanner
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 871 - 16:12:00 EDT to active cleanup

Scope:
- Stopped top-section retakes from feeding the next receipt section into the
  native previous-section ghost overlay field.
- Added a previous-section-only retake guide handoff so native top ghost
  overlays are used only when the retake has true previous-section context.
- Kept top-section next-context guidance as review guidance until a real
  next-section overlay exists.
- Added focused retake-order and long-receipt guidance regressions.
- Recorded `BUG-RECEIPT-0320` under `ghost_overlap_stitching`.
- Archived Pass 798 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused retake-order/long-receipt
  guidance regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 870 - 16:09:00 EDT to active cleanup

Scope:
- Forwarded long-receipt retake alignment reason and guidance into the native
  camera session when a user retakes a top, middle, or bottom receipt segment.
- Kept generic coverage guidance as the fallback only when no retake alignment
  context exists.
- Added retake guidance text regressions for top, middle, and bottom segment
  replacement.
- Added long-receipt handoff regressions proving the retake context is wired
  through to native previous-section reason/guidance fields.
- Recorded `BUG-RECEIPT-0319` under `ghost_overlap_stitching`.
- Archived Pass 797 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused retake-order/long-receipt
  guidance regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 868 - 16:04:00 EDT to active cleanup

Scope:
- Classified native camera `lastFocusStatus` diagnostics into health counts for
  configured, unavailable, not-requested, configuration-failed, and stale
  not-used focus states.
- Promoted focus configuration failure and stale `not_used` diagnostics into
  native UI health outcomes so review/admin surfaces cannot silently treat them
  as ready.
- Routed focus configuration failure and stale `not_used` outcomes into
  attachment risk flags for OCR/review handoff.
- Recorded `BUG-RECEIPT-0318` under `native_bridge`.
- Archived Pass 823 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused native UI health/ready
  regressions.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 865 - 12:29:00 EDT to active cleanup

Scope:
- Added an explicit iOS `continuous_focus_not_requested` diagnostic for
  non-continuous focus sessions instead of leaving `lastFocusStatus` as
  `not_used`.
- Pinned the iOS native bridge source regression for configured, unavailable,
  and not-requested focus-status families.
- Recorded `BUG-RECEIPT-0317` under `native_bridge`.
- Archived Pass 822 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused iOS native bridge regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.

## Pass 860 - 12:23:00 EDT to active cleanup

Scope:
- Added focused barcode/QR QA for repeated invalid input paths so warning
  results stay capped while valid receipt images still scan.
- Pinned `skippedInvalidImageCount` and privacy-safe invalid-path warning
  buckets without exposing raw bad path strings.
- Archived Pass 794 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer and focused barcode scanner regression.
- Passed cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
