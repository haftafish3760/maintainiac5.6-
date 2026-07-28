# Receipt Camera Cleanup Pass Log

This log tracks each cleanup/QA pass during the receipt camera, OCR, and shared
receipt pipeline repair work. Times are local to the development machine.

## Pass 904 - 12:46:52 EDT

Scope:
- Completed the Expenses manual receipt-form structure: Simple receipt with an
  optional whole-receipt category, Basic category-and-price lines, and full
  Detailed receipt lines.
- Kept receipt photo attachment on the same editable receipt form for every
  detail level and persisted the selected detail level and category in drafts.
- Added the focused manual-receipt QA runner and preserved the shared Work
  Supplies receipt-memory integration test without changing parser code.

Verification:
- Manual receipt QA passed: formatter, changed-source analysis, draft storage,
  receipt level, attachment, save guardrail, split, category, and custom
  category regressions.
- Shared Work Supplies receipt-memory integration test passed unchanged.
- Every touched production source file is below 500 lines.

## Pass 903 - 07:52:00 EDT to active cleanup

Scope:
- Made the active camera documentation explicit that preview tap focus is
  forbidden, not merely disabled.
- Preserved the allowed future path for explicit reversible manual focus
  controls such as plus/minus fine-focus buttons or a slider.
- Added doc-regression coverage so active camera docs must carry the preview
  tap focus ban.
- Recorded `BUG-RECEIPT-0351` under `native_bridge`.

Verification:
- Passed focused active camera docs focus-policy regression, doc-size,
  source-audit, test-audit, and diff whitespace gates.
- Archived Pass 872 from the active cleanup log to keep the doc under cap.

## Pass 901 - 07:37:00 EDT to active cleanup

Scope:
- Hardened the native session focus contract so stale manual/tap-focus settings
  cannot demote a continuous-focus-capable device into fallback review mode.
- Added regression coverage proving legacy manual/tap settings still produce
  continuous-focus, no-tap, live-readability session contracts.
- Recorded `BUG-RECEIPT-0350` under `native_bridge`.

Verification:
- Passed targeted Dart format/analyzer and focused native session focus
  contract regression.
- Passed cleanup log, bug-ledger, source-audit, test-audit, and diff whitespace
  gates.
- Archived Pass 871 from the active cleanup log to keep the doc under cap.

## Pass 900 - 07:25:00 EDT to active cleanup

Scope:
- Hardened the opted-in camera diagnostic publish denylist for tokenized device
  model and device name keys.
- Added regression coverage for safe-token-looking model/name values so they
  cannot bypass the privacy filter.
- Recorded `BUG-RECEIPT-0349` under `privacy_redaction`.

Verification:
- Passed targeted Dart format/analyzer, focused diagnostic policy regression,
  cleanup log, doc-size, bug-ledger, source-audit, test-audit, and diff
  whitespace gates.
- Archived Pass 870 from the active cleanup log to keep the doc under cap.

## Pass 899 - 07:23:00 EDT to active cleanup

Scope:
- Hardened the native camera diagnostics sanitizer before review handoff.
- Dropped private-looking diagnostic keys and path/receipt-text/device evidence
  returned by Android or iOS native capture.
- Added a native service regression proving raw receipt text, paths, device IDs,
  and device models do not reach review diagnostics.
- Recorded `BUG-RECEIPT-0348` under `privacy_redaction`.

Verification:
- Passed targeted Dart format/analyzer, focused native camera result rejection
  regression, and diff whitespace gate.

## Pass 898 - 07:08:00 EDT to active cleanup

Scope:
- Reworded the production operating directive away from default full-original
  receipt retention.
- Updated the active camera handoff to require temporary full-quality OCR source
  handling before saved-proof compression and explicit original-proof opt-in.
- Added regressions rejecting stale original-retention language in active docs.
- Recorded `BUG-RECEIPT-0347` under `source_preservation`.
- Archived Pass 868 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused production directive and active
  camera doc regressions, cleanup/doc/ledger/source gates, and diff whitespace
  gate.

## Pass 897 - 06:57:00 EDT to active cleanup

Scope:
- Hardened the receipt camera diagnostic publish policy with local payload
  sanitizing before any opted-in diagnostic reaches the expense callback.
- Dropped unsafe diagnostic keys for paths, receipt text, raw OCR text, device
  identifiers, and raw device model evidence while preserving safe tokens and
  counts.
- Recorded `BUG-RECEIPT-0346` under `privacy_redaction`.
- Archived Pass 865 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused diagnostic policy regression,
  cleanup/doc/ledger/source gates, and diff whitespace gate.

## Pass 896 - 06:42:00 EDT to active cleanup

Scope:
- Added real-device QA privacy checkpoints for Help Improve Receipt Camera.
- Required the real-device matrix gate to prove diagnostics default off,
  owner-visible diagnostics stay metadata-only, and receipt images/text are not
  owner-visible.
- Recorded `BUG-RECEIPT-0345` under `qa_harness`.
- Archived Pass 860 from the active cleanup log to keep the doc under cap.

Verification:
- Passed targeted Dart format/analyzer, focused real-device matrix regression,
  direct matrix gate run, cleanup/doc/ledger/source gates, and diff whitespace
  gate.

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
