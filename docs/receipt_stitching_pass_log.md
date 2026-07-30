# Receipt Stitching Hardening Pass Log

This log records completed responsibility bundles. A pass is not closed until
its scoped implementation, QA, and regression checks are complete.

## Pass 1 — Matching, composition, and fallback reliability

Status: **Closed — focused QA passed**

Scope:

- `lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_*`
- Focused stitching regression suite for delayed overlap, horizontal drift,
  long multi-photo stacks, and weak-overlap fallback.

Objective:

- Preserve the original, clear receipt image for saved proof and initial
  reading.
- Use a private, small contrast-normalized image only for overlap matching.
- Restore delayed-overlap and multi-photo stitching reliability without
  re-enabling automatic straightening.
- Retain the safe fallback when a pair cannot be matched confidently.

QA evidence:

- Baseline audit: delayed-overlap regression cases and the supplied two-photo
  S24 stress receipt failed automatic stitching.
- `receipt_stitching_variants_test.dart`: delayed overlap, three-section
  continuation, and faded thermal overlap passed.
- `receipt_stitching_horizontal_drift_test.dart`: handheld horizontal drift
  passed.
- `receipt_stitching_long_stack_test.dart`: five ordered sections passed.
- `receipt_stitching_weak_overlap_safety_test.dart`: missing-middle weak
  overlap stayed in the review-required lane.
- `receipt_stitching_real_fixture_probe_test.dart`: the two locally supplied
  S24 photos completed safely; a difficult pair may preserve ordered source
  photos instead of creating an untrustworthy combined image.
- `dart analyze` passed for the four stitching implementation files.

Residual risk:

- The supplied Kroger pair remains a deliberately difficult stress case; it
  is not yet evidence that automatic stitching succeeds on worst-case photos.
- Pass 2 must validate the capture, review, retake, selected-photo, and
  Continue behavior on the S24 before the long-receipt flow can be called
  ready.

## Pass 2 — Capture, review, retake, and continuation flow

Status: **Implementation and bounded regression complete; device validation pending explicit request**

Scope:

- Android native receipt camera guide wiring.
- Flutter photo-review add, retake, selected-photo, continuation, and safe
  stitch-review actions.

QA evidence:

- Neighbor-aware retake plans passed: middle retakes receive both guides;
  first and final retakes receive only their existing neighbor guide.
- The native channel passed all previous/next guide argument checks.
- The capture-layout contract passed with separate 152dp top and bottom guide
  bands and no text-card container over the live center view.
- Continuation wording and automatic-stitch safety contracts passed.
- Pinch zoom contracts passed: the native activity receives the gesture before
  child views, capture stores each photo's shutter zoom, and review receives
  that exact framing context.
- A full bounded regression gate passed **71 checks** in 6 minutes 12 seconds:
  capture guidance, previous/next guide wiring, pinch zoom, per-photo zoom
  handoff, retake ordering, Continue and Back behavior, asynchronous review
  cleanup, safe stitch review, delayed/faded/wrinkled/clipped overlap,
  horizontal drift, 5–6 photo stacks, and all weak/missing/reversed-section
  fallbacks.
- The gate exposed and then verified two defects fixed in this pass:
  background photo-quality feedback had been removed from review, and a blank
  or nearly uniform photo could receive a false-positive overlap score. The
  review now restores non-blocking quality feedback, while the stitcher keeps
  insufficient-detail sections in the safe ordered fallback path.
- Focused static analysis completed with no findings for the review lifecycle
  and stitch matching files.

Remaining before the device portion can close:

- User-authorized S24 validation of pinch zoom, guide readability, Add Photo
  responsiveness, thumbnail selection, Continue, and in-flow Back behavior.

## Pass 3 — Accuracy benchmark gate

Status: **Implementation and bounded regression complete; real-photo evidence intentionally pending**

Scope:

- Receipt OCR benchmark scoring and release-gate behavior.

QA evidence:

- The benchmark keeps text, numeric, merchant, date, subtotal, tax, total,
  line reconstruction, and routing scores separate.
- A new regression proves a failing opt-in camera scenario is reported
  separately from synthetic fixtures and cannot be masked by their score.
- The release gate rejects the current synthetic-only sample as intended.
- Five focused benchmark and dataset-safeguard regression checks pass, and
  static analysis is clean for the runner and its regression file.
- The deliberately synthetic-only release run was verified to fail for the
  right reason: it has no opt-in real-photo evidence and is missing required
  real-world scenarios. It does not report a false accuracy pass.

Remaining before close:

- Add at least three opt-in local photo cases for every required real-world
  scenario before using the benchmark to make an accuracy claim.
- Do not begin OCR accuracy tuning until a real-photo failure is measured.

## Pass 4 — Real-receipt benchmark intake integrity

Status: **Closed — implementation and bounded regression complete**

Scope:

- `tool/receipt_ocr_benchmark_runner.dart`
- `test/receipt_ocr_benchmark_runner_test.dart`
- `docs/receipt_ocr_real_benchmark_intake.md`

Objective:

- Ensure the benchmark counts each physical receipt or long-receipt photo set
  once.
- Ensure one release score measures one OCR engine/version, rather than a
  mixture that can hide a regression.
- Give the user a local-only, privacy-safe way to label evidence when they are
  ready to supply it.

QA evidence:

- Duplicate anonymous real receipt source IDs are rejected.
- A release gate with mixed real OCR versions is rejected and reports the
  conflicting run identities.
- Six focused benchmark/dataset checks pass and static analysis is clean.
- The synthetic-only sample still refuses release status as designed.

Remaining outside this pass:

- Add opt-in local real receipt results using the intake guide. That evidence,
  plus user-authorized S24 flow validation, is required before OCR accuracy
  work or a commercial-readiness claim.
