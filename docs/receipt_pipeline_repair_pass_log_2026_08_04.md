# Receipt Pipeline Repair Pass Log — 2026-08-04

This log tracks the current controlled repair roadmap. A pass closes only after
its bounded implementation, analyzer checks, focused QA, and regression checks
finish without a newly introduced failure. Physical-device proof is recorded
separately from source and host-test proof.

Physical long-receipt fixture rule: pair sections by the color of the number
written on the receipt image (black with black, blue with blue, red with red),
then import `1 of 2` first as the top and `2 of 2` second as the continuation.
Never mix color families or reverse a clearly labeled sequence.

## Pass 0 — Isolated safety checkpoint and failing baseline

Status: **Closed**

- Local branch: `backup/receipt-pipeline-pre-registration-2026-08-04`
- Safety commit: `56fc33ec`
- The unrelated deleted blueprint note remains outside receipt work.
- Source/test baseline reproduced the hard OCR-overlap gate and existing
  coordinate/geometry stitch failures before the new repair work began.

## Pass 1 — Shared post-review receipt-image handoff

Status: **Closed at source and host-test tiers; device verification belongs to
the final Android evidence pass**

Implemented contract:

- A single reviewed photo advances to saved-image review without stitching.
- Multiple reviewed photos must produce one accepted combined receipt image
  before saved-image review can open.
- A failed combine cannot silently advance using whichever original section is
  selected. It remains in retake/manual-alignment recovery.
- Data Saver previews the accepted receipt image.
- For an accepted long receipt, the same combined image owns OCR preparation
  and compressed saved-proof generation; the original sections remain listed
  as temporary source artifacts for recovery/provenance until downstream save
  confirmation.
- Stale/mismatched stitch previews cannot be accepted as the current receipt.

QA evidence:

- New executable pipeline contract: 3/3 tests passed.
- Focused lifecycle, combined-image ownership, OCR handoff, and source-count
  bundle: 11/11 tests passed.
- Camera phase-4 review gate: analyzer clean, source audit clean, 17/17 tests
  passed.
- Camera phase-7 OCR-source handoff gate: analyzer clean, source audit clean,
  55/55 tests passed.
- Scoped analyzer for the new contract and photo-review screen: no issues.

Known failures deliberately carried into the next stitch passes:

- The existing coordinate-space stitch regression still falls back with
  `ocr_overlap_not_proven`.
- Existing synthetic phase-6 overlap cases still expose the hard OCR gate and
  pixel-registration defects. Pass 1 prevents those failures from producing a
  misleading saved receipt; it does not claim to repair registration itself.

## Pass 2 — Production-equivalent isolated stitch harness

Status: **Closed at source and host-test tiers**

Implemented contract:

- The formerly broken plain-Dart command now delegates to a Flutter harness
  that can load the real production stitch implementation.
- The harness selects the existing light, medium, or heavy receipt-device
  workload limits and records every effective pixel, width, and timeout cap.
- Optional local OCR line evidence can be supplied through a sidecar file to
  reproduce the device OCR-assisted path without committing receipt content.
- Output diagnostics exclude paths, receipt text, merchant names, and amounts.
  They include result/fallback status, elapsed time, output dimensions, source
  contract, selected transform evidence, geometry/continuity scores, and the
  exact number of continuation rows removed at the seam.
- Source hashes are verified before and after every opt-in probe run.

QA evidence:

- Scoped analyzer for the real probe and contract checks: no issues.
- Probe/health/source-integrity bundle: 4/4 tests passed; opt-in tests skipped
  normally when no local paths are supplied.
- Both supplied two-photo Walmart sequences ran through the production stitch
  call under the medium limits. Both declined in about 0.86 seconds with
  `ocr_overlap_not_proven`; neither produced a misleading combined image.
- Sequence A also ran under the light-device limits and declined in about 0.80
  seconds with the same reason. The evidence explicitly shows no OCR lines were
  available in the host harness, so this is proof of the current hard OCR gate,
  not yet proof that ML Kit on a physical phone would return no overlap text.

Finding carried into Pass 3:

- The stitcher currently refuses to evaluate visual/document geometry at all
  unless unordered OCR strings first prove a strong overlap. That makes OCR a
  hard blocker instead of one weighted signal and prevents the harness from
  reporting candidate geometry on imperfect, absent, or host-unavailable OCR.

## Pass 3 — Positional OCR and document-structure evidence

Status: **Closed at source and host-test tiers; Android ML Kit coordinate proof
belongs to the final device pass**

Implemented contract:

- Stitch OCR evidence now retains each recognized line's normalized bounding
  box instead of reducing the page immediately to unordered strings.
- Encoded image dimensions are read without decoding a second full bitmap; a
  bounding-box fallback preserves usable relative evidence if metadata fails.
- Positional line evidence survives photo reordering, prepared-path remapping,
  and the background stitch isolate.
- Text overlap matching now records where the shared block starts on the prior
  section and ends on the continuation, rewards bottom-to-top document flow,
  and rejects clearly backward top-to-bottom matches.
- Pair diagnostics expose positional confidence and normalized overlap bounds;
  legacy string-only evidence remains supported.

QA evidence:

- Scoped analyzer across OCR evidence, stitch evidence, processor, review, and
  focused tests: no issues.
- OCR overlap/order/result/source-contract bundle: 32/32 tests passed.
- Focused production-stitch test with OCR evidence: passed and produced one
  combined OCR source.
- New positional cases prove bottom-to-top overlap metadata is retained and a
  backward document match is rejected.
- Source files remain below the 500-line receipt-module cap.

Known baseline carried forward:

- String/position evidence is still a hard prerequisite before visual geometry
  runs. Existing no-OCR synthetic cases therefore still fail early with
  `ocr_overlap_not_proven`. Evidence fusion and graceful no-OCR behavior are
  intentionally repaired in Pass 5 after coordinate registration is fixed.

## Pass 4 — Registration and coordinate-transform contract

Status: **Closed at source and host-test tiers**

Verified and hardened contract:

- EXIF orientation is baked only into private stitch working copies; selected
  source images are never rewritten.
- Receipt-background isolation masks outside the detected paper frame without
  crop-and-stretch, preserving the proof image's X/Y coordinate system.
- Candidate overlap, leading continuation rows, X drift, scale, rotation, and
  perspective are mapped from bounded comparison pixels back to proof pixels
  before composition.
- Pair evidence now records the exact full-proof seam skip separately from the
  matched overlap height, preventing delayed-overlap coordinates from being
  mistaken for a simple top-edge overlap.

QA evidence:

- Off-center 120-pixel receipt movement survives comparison preparation and
  produces the expected expanded proof canvas.
- Delayed overlap maps its leading band into the full-proof seam instead of
  dropping those rows; decoded output dimensions match reported dimensions.
- Coordinate-space regression: 2/2 tests passed.

No new source defect was found in the current mask-versus-crop mapping; the
previous failing guard had been stopping at the OCR hard gate and therefore was
not exercising registration. Supplying controlled text evidence now makes the
guard test the intended coordinate path.

## Pass 5 — Evidence fusion, ordering, and acceptance policy

Status: **Closed at source and host-test tiers; physical ML Kit evidence and
the no-text transform budget remain assigned to the capability/performance
pass**

Implemented contract:

- OCR is no longer a hard prerequisite for registration. Visual continuity,
  two-dimensional document geometry, and positioned receipt text are separate
  signals combined by one acceptance decision.
- A no-text stitch cannot be accepted from brightness or one-dimensional row
  continuity alone. It requires corroborating two-dimensional geometry.
- A lone OCR match or a lone visual match cannot authorize removal of repeated
  rows.
- Distinct matched OCR lines now retain corresponding baseline anchors. Those
  anchors estimate the continuation scale and placement before pixel work;
  continuity/geometry must still verify the proposed join.
- Repetitive identical purchase rows do not enable the text-guided shortcut.
- An upright candidate backed by either continuity or document geometry can
  bypass needless rotation/perspective exploration, while the final fused gate
  remains authoritative.

QA evidence:

- Evidence-policy regressions: 6/6 passed.
- Text overlap/order/position regressions plus policy bundle: 20/20 passed.
- Positioned-anchor production stitch regression produced one combined source
  and mapped the expected overlap into normalized proof coordinates.
- Full focused stitch, coordinate, and opt-in probe bundle: 10 passed, 3
  intentionally skipped without local probe environment variables.
- Valid three-section no-OCR host work dropped from roughly 41 seconds to 5
  seconds after the bounded upright geometry path; the stitch remained green.
- Real Walmart sequence B now rejects its uncorroborated candidate in about
  1.2 seconds with `overlap_confidence_low` instead of creating a false join.
- Scoped analyzer: no issues.

Performance finding carried to Pass 8:

- Real Walmart sequence A without host OCR still exhausts transformed visual
  candidates and reaches the medium-device 12-second timeout. Production runs
  local positional OCR before registration, and the new anchored route is
  covered at source/test tier, but S24 ML Kit runtime proof is still required.
  The no-text/reversed rejection path also remains too expensive and must be
  bounded by capability-derived search budgets rather than longer timeouts.

## Pass 6 — Safe seam composition and full-composite preview ownership

Status: **Closed at source and host-test tiers; S24 visual proof remains in the
final Android pass**

Implemented and verified contract:

- Candidate overlap placement and the actual low-ink seam crop are recorded as
  separate values. Delayed leading rows are no longer mislabeled as rows
  removed from the continuation.
- The seam chooser still rejects an automatic join when it cannot find a safe
  low-ink band between printed receipt lines.
- Full-proof coordinate tests verify that delayed overlap preserves its leading
  continuation band and that the selected seam lies inside—not beyond—the
  mapped overlap.
- Data Saver receives the accepted combined-image path for a multi-photo
  receipt. A fallback or stale/mismatched result cannot satisfy the save
  contract with only the currently selected source photo.
- No-OCR geometry may create a reviewable composite, but it is capped below the
  automatic-clear trust tier so the person still sees the full combined image
  before assisted reading continues.

QA evidence:

- Scoped analyzer: no issues.
- Seam coordinate, accepted-image ownership, evidence acceptance, and phase-6
  OCR handoff bundle: 15/15 tests passed.
- The prior phase-6 review regression remains enforced: a geometry-only
  combined image requires visible review instead of silently auto-clearing.

## Pass 7 — Full-canvas manual alignment recovery

Status: **Closed at source and focused-test tiers; physical S24 gesture and
visual evidence remains in the final Android pass**

Implemented contract:

- A failed automatic join now opens an edge-to-edge alignment canvas instead
  of a 190-pixel receipt preview trapped inside a bordered card.
- The previous receipt section stays fixed while the next section is the
  reversible working layer. Drag adjusts horizontal position and shared area;
  pinch adjusts scale; two-finger rotation adjusts straightening.
- Labeled precision controls remain available for accessibility and fine
  correction. They can be hidden so the receipt pixels fill the working area.
- Reset returns the selected pair to neutral manual alignment without changing
  either source image.
- The canvas remains visible while a debounced retry is running. A loading
  state can no longer replace the very surface the person is adjusting.
- Three-or-more-section receipts retain pair-by-pair navigation, and each
  accepted join still produces one combined receipt image for saved-proof and
  OCR ownership.

QA evidence:

- Scoped analyzer across the receipt review library and new alignment
  components: no issues.
- Manual recovery, phase-transition, accepted-composite ownership, evidence
  acceptance, and coordinate-space bundle: 13/13 tests passed.
- Both new alignment component files remain under the 500-line project limit
  (300 and 224 lines).

## Pass 8 — Missing-total reconciliation and source lifecycle

Status: **Closed at source and focused-test tiers; broader Android evidence is
deferred to the final device pass**

Implemented contract:

- When a printed subtotal and final total are both absent, the parser now
  supplies a reviewable working total from every visible priced item instead
  of leaving an otherwise usable receipt without a total.
- Repeated legitimate item rows remain separate and each contributes to the
  working total. Tender, barcode, and administrative rows remain excluded.
- Printed totals retain authority whenever present. A calculated total is
  explicitly marked as review-required and never masquerades as printed
  receipt evidence.
- Review screens explain the calculated value in ordinary language and direct
  the person to add the lower section when the receipt continues. No internal
  score, confidence percentage, or parser analytics are exposed.
- Direct parser calls now default to line-item parsing rather than implicitly
  initializing the full inventory catalog. Inventory matching remains an
  explicit capability/policy choice.
- Full-quality OCR sources remain retained until the receipt is durably saved;
  temporary-source cleanup still runs only after that successful save.

QA evidence:

- Scoped analyzer across the receipt parser and receipt-entry screen: no
  issues.
- Missing/footer total reconciliation and repeated-item coverage: 6/6 tests
  passed.
- Focused assisted-review warning contract: 1/1 test passed.
- Tender exclusion and split-payment coverage: 9/9 tests passed.
- Durable save/source cleanup contract: 3/3 tests passed.

Performance finding carried to Pass 9:

- An explicit inventory-matching parse initializes the full work-supply
  catalog context and can hold a host test at full CPU for more than one
  minute. Receipt capture must not invoke that work synchronously; the next
  pass will bind catalog matching and stitch workload to capability-derived
  budgets and off-main execution/fallback behavior.

## Pass 9 — Capability-derived registration and parser workload

Status: **Closed at source and focused host-test tiers; physical low-tier
device timing remains a release-evidence requirement**

Implemented contract:

- The existing capability-selected comparison width now controls registration
  complexity, not merely image size. Light, medium, and heavyweight profiles
  receive progressively larger bounded sets of scale, rotation, perspective,
  horizontal-offset, continuation-offset, and overlap-refinement candidates.
- Light devices skip perspective search entirely and use fewer transform and
  continuity candidates. The final geometry, continuity, OCR, seam, and trust
  gates are unchanged; reduced work cannot lower the acceptance standard.
- Stitch work remains isolated from the UI isolate, retains a capability
  timeout, kills timed-out work, removes partial output, and returns the ordered
  source photos for review instead of blocking or inventing a composite.
- Receipt capture on every device tier now defaults to line-item parsing.
  Full inventory catalog matching remains available only when explicitly
  requested outside the critical receipt-reading path, preventing flagship
  capability from turning a normal receipt review into synchronous catalog
  initialization.

QA and measured host evidence:

- Scoped analyzer across capability policy and stitch processor: no issues.
- Capability tiers, assistance policy, search-budget contract, size caps,
  cancellation, coordinate mapping, acceptance, and photo-pipeline bundles:
  43/43 tests passed.
- Walmart sequence A at the light workload safely declined in 1,476 ms with
  `overlap_confidence_low`; no untrusted composite was created.
- Walmart sequence B at the light workload safely declined in 908 ms with
  `overlap_confidence_low`; the prior false-positive composite did not recur.
- Both real-fixture probes preserved the original source hashes. These host
  probes had no ML Kit positional OCR, so they prove bounded safe fallback—not
  production OCR-assisted acceptance or physical low-end runtime.

## Pass 10 — Registration coordinate integrity and mixed-transform diagnosis

Status: **Closed as a diagnostic/repair pass; one image-only mixed-transform
regression remains open and blocks the Android milestone**

Implemented and retained:

- Horizontal search now preserves several distinct overlap basins for each
  nonzero offset instead of allowing one repetitive receipt row to erase every
  alternative at that offset.
- Promising horizontal basins receive a bounded pixel-level refinement before
  scoring, so the coordinate proved by geometry is the coordinate later used
  for composition.
- Final candidate refinement jointly checks a bounded neighborhood of overlap,
  horizontal offset, and continuation start using two-dimensional receipt
  geometry. Candidate selection and final acceptance now use the same geometry
  support rule.
- Two- and three-photo high-capability registration use the same 1,400-pixel
  target width before the existing device-capability clamp, avoiding a
  pair-count-dependent resolution discontinuity that caused cumulative drift.

Focused QA evidence:

- Wide handheld horizontal drift: passed.
- Three-photo cumulative horizontal drift: passed, including both joins.
- Combined scale, rotation, and horizontal drift: passed.
- Scoped analyzer: no issues. Receipt stitch source-size gate: passed.
- The isolated second-to-third join from the mixed three-photo transform test
  still safely declines: selected scale 1.12 but zero rotation, confidence
  0.518865, continuity 7/7, and insufficient geometry (6/12 cells at 0.50328).

Verified remaining cause:

- The current image-only transform search still proposes each transform from a
  brightness/profile-led overlap winner. On the failing pair, the correct
  rotation neighborhood is generated, but its correct translation/overlap
  does not survive into the geometry reranker. Repetitive receipt rows therefore
  hide the valid transform before independent evidence can prove it.
- A bounded Dart keypoint experiment was evaluated and removed in this pass.
  It produced ambiguous translation hypotheses and materially higher runtime;
  existing geometry correctly rejected them. No unproven matcher or lowered
  acceptance threshold was left in production.
- The safe decline is preferable to a false composite, but it is not the
  requested commercial result. The next repair must use the existing
  positional OCR evidence and a robust native registration proposal, with
  capability-derived budgets and the unchanged geometry/seam trust gates.

## Pass 11 — Positional OCR as bounded registration evidence

Status: **Closed; positional OCR registration is implemented and focused QA is
green, while independent native image registration remains open**

Implemented and retained:

- Matched OCR lines now preserve horizontal centers, line widths, and text-line
  angles in addition to the existing vertical anchors.
- The text-guided registration path derives bounded scale evidence from both
  vertical anchor spacing and matched line-width ratios, horizontal drift from
  matched line centers, and rotation correction from matched line angles.
- Android ML Kit line angles are consumed directly, with a corner-point angle
  fallback when the platform angle is unavailable.
- OCR guidance remains proposal evidence only. Existing visual continuity,
  two-dimensional geometry, seam, and final trust gates still decide whether
  a composite may be produced; repeated or ambiguous text cannot silently
  force a stitch.

Focused QA evidence:

- Positional text-evidence and text-guided registration bundle: 16/16 tests
  passed.
- Synthetic scale, rotation, horizontal-drift, and overlap registration using
  matched OCR anchors: passed.
- Receipt stitch source-size health: passed.
- `git diff --check`: passed.

Remaining gap:

- This pass does not claim robust native image registration, S24 runtime proof,
  or low-tier device proof. The next pass must introduce a capability-bounded
  independent image-registration proposal at the registration boundary and
  keep the same final trust gates and safe fallback behavior.

## Pass 12 — Capability-bounded native registration and phone-frame integrity

Status: **Closed as a source/host/Android-compile pass; physical S24 and
low-tier runtime evidence remain open**

Implemented and retained:

- Android now exposes a private receipt-registration MethodChannel backed by
  OpenCV ORB descriptors, Hamming KNN filtering, partial-affine RANSAC,
  inlier/reprojection/coverage checks, and capability-derived feature,
  comparison-width, and timeout budgets.
- Native registration returns proposals and normalized inlier anchors only.
  It cannot write or approve a receipt composite; existing Dart continuity,
  two-dimensional geometry, seam, ambiguity, and final trust gates remain
  authoritative.
- The Dart boundary rejects malformed, weak, extreme-scale, high-rotation,
  high-error, or under-supported native proposals and safely falls back when
  Android registration is unavailable or times out.
- Private stitch-working copies now isolate a confidently detected paper frame
  before both matching and composition. The original selected files remain
  unchanged for fallback and OCR review, while phone display borders and
  status/navigation chrome no longer distort overlap coordinates or appear in
  the stitched artifact.
- Candidate geometry now retains bounded distinct overlap-length basins,
  including zero-X candidates. A fast return that previously trusted
  one-dimensional continuity now also requires verified two-dimensional
  geometry.
- For the second and later photos, a bounded sequence-consistency proposal can
  inspect the prior proven overlap and both horizontal directions. It replaces
  a current match only when fresh two-dimensional geometry proves the new pair;
  it does not lower acceptance thresholds.

Focused QA evidence:

- Native proposal parsing, native-guided registration, and positional
  text-guided registration: 4/4 tests passed.
- Phone-window fast gate: 4/4 tests passed, covering skipped-section and
  out-of-order safe declines plus valid four-photo dark-border and
  status/navigation-bar receipt sequences.
- Affected analyzer: no issues. Receipt stitch source-size health: passed.
  `git diff --check`: passed.
- Android Kotlin compilation with the OpenCV bridge completed successfully.

Remaining evidence boundary:

- No S24 runtime invocation, native timing, saved-composite inspection, or
  physical low-tier measurement is claimed by this pass. Those require the
  later device-validation milestone; host execution does not run the Android
  MethodChannel implementation.

## Pass 13 — Camera release-gate coverage audit

Status: **Closed**

- The camera QA gate now owns the Android receipt-registration bridge, OpenCV
  dependency surface, Dart native boundary, and native-, text-, and
  sequence-guided registration regressions.
- The full stitch plan also now includes five focused stitch tests that were
  present on disk but absent from the release plan: acceptance, final-timeout
  recovery, real-device probe contract, working-resolution contract, and
  coordinate-space coverage.
- Camera QA shell syntax, printed-plan existence/coverage, stitch ownership,
  scope/failure behavior, and `git diff --check` are green: 8/8 focused gate
  contract tests passed.

## Pass 14 — Android package integration

Status: **Source/package evidence closed; runtime evidence blocked by target
availability**

- The first full debug APK build exposed a duplicate `libc++_shared.so` from
  OpenCV and the existing native dependency. Android packaging now selects one
  shared C++ runtime deterministically; a focused source regression protects
  the OpenCV dependency and packaging rule.
- `flutter build apk --debug` now passes. APK inspection confirms one shared
  C++ runtime and `libopencv_java4.so` for arm64-v8a, armeabi-v7a, and x86_64.
- Native proposal and packaging contract tests: 3/3 passed. Scoped analyzer
  and `git diff --check`: passed.
- ADB currently exposes `SM_S938U` (Galaxy S25 Ultra), not the requested
  `SM_S928U` S24 Ultra. No emulator profiles are installed. Nothing was
  installed or launched on the wrong phone, and no S24 or low-tier runtime
  result is claimed.

## Pass 15 — Frame-coordinate, screenshot, seam, and transformed-stack hardening

Status: **Closed as a source/host regression pass; physical S24 and low-tier
runtime evidence remain open**

Defects repaired:

- Private receipt-frame cropping had changed the stitch coordinate space while
  positional OCR and native registration anchors remained normalized to the
  original image. Frame transforms now remap OCR boxes and native anchors into
  the isolated working frame, including crop-relative native scale.
- Near-white uploaded screenshots could make the paper detector consume the
  entire phone frame. Document isolation now falls back to bounded ink geometry
  with receipt-preserving margins while leaving original evidence untouched.
- Seam ink density counted both images but divided by one image's sample count,
  doubling the value and rejecting valid low-ink joins. It now remains on the
  intended 0–1 scale.
- Delayed overlap could be rejected even with exceptional full-band continuity.
  Moderate two-dimensional geometry can now corroborate an exceptional
  continuity result, while weak geometry and lone OCR/visual evidence still
  decline safely.
- The upright fast path could validate only its small comparison image and then
  return an invalid full-size transform. The materialized candidate must now
  pass the same two-dimensional geometry check or the bounded transform search
  continues.

Focused QA evidence:

- Uploaded light- and dark-chrome screenshot cases pass with production-style
  positional OCR evidence; passenger-seat regression passes.
- Transformed damaged-receipt regression passes with positional OCR plus the
  unchanged image/geometry vetoes. The no-signal path remains a safe fallback,
  not a fabricated join.
- Long-stack core, cap, drift, worn, mixed-transform, phone-window,
  alternating-side-crop, and mixed-exposure/side-crop cases all pass.
- Phone-window fast gate: 4/4 passed. Native registration, positional OCR, and
  acceptance-policy regressions: 10/10 passed.
- Scoped analyzer: no issues across 14 affected files. Source-size health and
  `git diff --check`: passed.

Remaining evidence boundary:

- This pass proves source and host behavior only. It does not claim Android
  MethodChannel runtime timing, physical saved-composite inspection, S24 field
  behavior, or low-tier memory/latency evidence.

## Pass 16 — Reconciliation, lifecycle, and target-availability revalidation

Status: **Closed as a focused QA pass; physical device evidence remains open**

Current-state verification:

- Missing-total and repeated-item reconciliation still produces reviewable
  working totals without overriding printed totals.
- OCR source and saved proof ownership remain distinct; full-quality temporary
  sources survive until durable save, kept-for-later and malformed recovery
  remain recoverable, and explicit discard/finalization deletes only app-owned
  staged artifacts.
- Focused parser, OCR-source relationship, durable recovery, and native staging
  cleanup suite: 23/23 tests passed.
- The existing Git safety checkpoint remains `56fc33ec` on
  `backup/receipt-pipeline-pre-registration-2026-08-04`; no unrelated dirty
  work was staged, committed, or discarded in this pass.

Physical evidence boundary:

- ADB exposes only `SM_S938U` (Galaxy S25 Ultra), not the authorized
  `SM_S928U` S24 Ultra. No Android emulator executable/profile is available.
  The app was not installed or launched on the wrong device, so S24 and
  low-tier runtime, memory, latency, and saved-composite proof remain open.

## Pass 17 — Capability workload and bounded-fast-path contract revalidation

Status: **Closed as a source/host regression pass; physical low-tier evidence
remains open**

Current-state verification:

- Shared device facts still select constrained, medium, and heavyweight receipt
  workloads, respect Android low-RAM declarations and older-platform limits,
  preserve safe manual overrides, and tighten photo storage behavior when free
  space is low.
- The receipt camera continues to consume the shared capability adapter rather
  than independently reprobe and drift from the app-wide device assessment.
- Stitch working copies remain bounded before crop/composition while original
  user sources remain unchanged. The upright shortcut may propose a bounded
  candidate, but both its comparison-scale and materialized full-size geometry
  must pass before it returns; the final fused evidence gate remains mandatory.
- Timeout recovery preserves ordered source sections, late preview completion
  becomes a bounded fallback, and managed cancellation stops stitch work.
- Focused capability, adapter, working-resolution, and timeout suite: 13/13
  tests passed. Scoped analyzer, source-size health, and `git diff --check`:
  passed.

Contract correction:

- One source-contract test still expected the obsolete OCR-only fast-path
  switch. It now verifies the stronger current boundary: bounded proposal,
  two-stage geometry validation, and final fused-evidence acceptance. Production
  behavior was not weakened to satisfy the stale expectation.

Remaining evidence boundary:

- These are source and host-test results. No low-tier Android target is
  available, so peak memory, latency, thermal behavior, cancellation timing,
  and physical saved-composite quality remain unproven on constrained hardware.

## Pass 18 — Physical-evidence contract and target-availability hardening

Status: **Closed as a QA-contract pass; authorized S24 and constrained-device
execution remain externally blocked**

Defect repaired:

- The real-device script still described multi-photo capture as a passive
  handoff that must not stitch. That stale requirement contradicted the active
  capability-aware reconstruction architecture and could have allowed the
  Android milestone to be judged against the wrong product behavior.
- The script and privacy-safe result template now require automatic
  reconstruction to produce one visually valid continuous receipt or decline
  safely with every ordered source preserved. They explicitly check every join,
  text-source ownership, retake/manual alignment, timeout recovery, and absence
  of repeated, missing, squeezed, or crossed receipt content.
- Flagship and constrained Android results must be recorded separately with
  device/API, effective capability tier and stitch limits, source count,
  Continue-to-result time, before/peak/after app-memory totals, output size,
  status/reason code, cancellation preservation, and crash/ANR evidence. A
  flagship result cannot stand in for constrained-device performance.

Focused QA evidence:

- Real-device script, result-template gate, and metadata-only starter-script
  suite: 8/8 tests passed.
- Scoped analyzer and `git diff --check`: passed.
- ADB/Flutter discovery again exposes only `SM_S938U` (Galaxy S25 Ultra).
  `SM_S928U` (the authorized S24 Ultra) is absent, and no Android emulator
  executable/profile is available. Nothing was installed or launched on the
  wrong phone.

Remaining evidence boundary:

- The QA contract is now aligned and executable, but the required S24 and
  constrained Android measurements cannot be truthfully produced until those
  targets are connected or provisioned.

## Pass 19 — Authoritative milestone reconciliation and full regression closure

Status: **Closed as a source/host milestone pass; physical-device proof remains
open**

Defects and drift repaired:

- Removed stale nullable access patterns in photo-review save and exit actions.
- Split oversized receipt text-similarity ownership and the stitch search-budget
  contract test so every audited source remains at or below 500 lines without
  changing production matching behavior.
- Reconciled stale native-camera, long-receipt guidance, storage/parser-routing,
  OCR-source-risk, Android import-ownership, and photo-review action contracts
  with the current implementation. Human-facing guidance now consistently uses
  “top reference strip,” while privacy diagnostics retain stable machine codes.
- Heavy wrong-order and missing-middle synthetic reconstruction tests now use
  the suite's existing heavy-fixture test budget. Production capability-derived
  processing timeouts and ordered-photo fallback behavior were not relaxed.

Focused and authoritative QA evidence:

- Text-evidence and text-guided registration suite: 16/16 passed.
- Source-ownership and stitch search-budget contract suite: 2/2 passed.
- Native recovery, guidance, photo-review, storage-policy, Android import, and
  focused stitch regressions passed after each correction.
- Authoritative `receipt_camera_qa_gate.sh milestone`: 286/286 tests passed.
- Changed-route coverage: 28 milestone routes and 21 fast guard smokes passed.
- External dataset manifest, local audit, and fixture schema gates passed.
- Scoped analyzer, 500-line source audit across 371 files, scope gate, and final
  exit code all passed cleanly.

Evidence boundary:

- This pass proves source contracts and host reconstruction behavior. It does
  not claim S24, older-flagship, constrained-emulator, iPhone SE, or physical
  budget-Android timing, memory, camera, OCR, or saved-composite quality. Those
  remain separate runtime and field-evidence gates.

## Pass 20 — Executable external long-receipt corpus

Status: **Closed as a fixture-corpus and pure-Dart QA pass; physical receipt
evidence remains open**

Readiness gap repaired:

- Migrated the four synthetic long-receipt parser fixtures from compiled Dart
  constants into `test/fixtures/receipt_qa/long_receipt.json`.
- The receipt QA runner now loads that external pack through a strict schema,
  pack-name, non-empty-list, required-field, and typed-expectation boundary.
  Missing or malformed files produce blockers; there is no stale inline
  fallback that could hide a broken corpus.
- The inventory and manifest now identify `long_receipt` as externally loaded
  while accurately retaining global `externalFixtureFilesReady: false` until
  the other nine packs are migrated.
- The schema gate now verifies file existence, declared fixture count,
  synthetic/redacted-only policy, editable expected output, and removed
  sensitive fields.
- Four older line-count fixtures were completed with description/category/
  family/use expectations so the runner's detailed-line contract remains
  uniform instead of being weakened for the migration.

QA evidence:

- External long-receipt pack: 4 fixtures, 84/84 checks passed.
- Full pure-Dart receipt matrix: 34 fixtures, 964/964 checks, score 100%, no
  blockers.
- Focused analyzer: no issues. Focused runner/schema/gate suite: 19/19 tests
  passed. All changed Dart sources remain below 500 lines and
  `git diff --check` passed.
- The top-level pure-Dart wrapper stopped before its parser phase on the
  unchanged `docs/receipt_camera_cleanup_pass_log.md` baseline at 506 lines.
  That pre-existing shared-log ownership issue was not hidden or edited during
  this pass; the parser, schema, and affected test phases were run directly and
  passed.

Evidence boundary:

- This proves the runner consumes the external synthetic long-receipt corpus.
  It does not turn synthetic text into physical-camera, OCR, reconstruction,
  latency, memory, or saved-artifact proof.

## Pass 21 — Receipt artifact lifecycle and deletion-safety hardening

Status: **Closed as a source/host lifecycle regression pass; physical-device
save and recovery proof remains open**

Defects repaired:

- Failed receipt-preparation cleanup previously called `File.delete()` on any
  non-kept path supplied to it. It now delegates to the shared temporary
  artifact cleanup boundary, which deletes only verified Maintainiac-owned
  receipt JPEGs inside the resolved system temporary directory.
- Temporary OCR-source cleanup had a second, weaker string-prefix deletion
  policy. It now uses the same canonical cleanup boundary and preserved-path
  contract, removing duplicate path-safety logic.
- Added a symlink-escape regression proving that a receipt-named link in the
  temporary directory cannot delete either the link or its target outside the
  trusted temporary root.
- Reconciled obsolete photo-review source contracts with the responsive
  equal-width action row, current 46-pixel touch targets, and current accessible
  labels. Production layout was not reverted to fixed-width controls.

Focused QA evidence:

- Receipt artifact lifecycle suite: 32/32 tests passed, covering gallery and
  non-native staging, OCR-source ownership, durable-save cleanup, failed-prep
  cleanup, data-saver separation, malformed-image recovery, and saved-proof
  preview behavior.
- Targeted analyzer: no issues. `git diff --check`: passed. Every affected
  implementation and test source remains below 500 lines.

Evidence boundary:

- This proves host-side ownership and deletion-safety contracts. It does not
  claim physical Android/iOS process-death recovery, storage-pressure behavior,
  durable save, or user-visible saved-proof fidelity; those remain separate
  runtime gates.

## Pass 22 — Lossless external receipt-fixture loading

Status: **Closed as a corpus-infrastructure and pure-Dart regression pass;
remaining inline packs still require migration**

Defect repaired:

- The external fixture loader previously reconstructed only core merchant,
  totals, line, and readiness expectations. Migrating damaged-photo, barcode,
  privacy, fuel, maintenance, adjustment, or device-tier fixtures through that
  path could silently drop assertions while the report still appeared green.
- The loader now preserves the complete receipt QA fixture contract: receipt
  modes, dates and reconciliation, fuel and maintenance fields, review details,
  privacy counts, photo-quality evidence, barcode inputs and expectations, and
  capability-derived workload/storage expectations.
- External enum and device-profile values are validated by name and rejected
  when unsupported. Required photo-quality and barcode structures fail closed
  on malformed types instead of quietly defaulting.
- The schema now declares the supported device-capability profiles.

Executable coverage added:

- The external long-receipt pack now exercises photo-quality review on a
  cropped/missing-bottom section, older-phone capability limits on a continued
  section, and barcode summarization on a reconstructed-overlap fixture.
- Long-receipt external pack: 4 fixtures, 113/113 checks passed.
- Full pure-Dart receipt matrix: 34 fixtures, 993/993 checks, score 100%, no
  blockers.
- Focused schema/runner suite: 8/8 tests passed. Analyzer, external schema gate,
  source-size checks, and `git diff --check`: passed.

Evidence boundary:

- The loader is now capable of preserving every current fixture expectation,
  but nine packs are still inline and the inventory correctly remains not
  externally complete. This is deterministic host proof, not physical-camera
  or low-tier runtime proof.

## Pass 23 — Executable degraded-receipt corpus migration

Status: **Closed as a degraded-receipt corpus and pure-Dart QA pass; physical
dirty/folded/faded receipt evidence remains open**

Corpus migration:

- Migrated all seven degraded-receipt fixtures from compiled Dart constants to
  `test/fixtures/receipt_qa/damaged_ocr.json` and removed the obsolete inline
  source from the runner.
- The external pack preserves wrinkled/missing-bottom, smudged duplicate
  overlap, blurry, glare-washed, low-light, partial-crop, and weak-contrast
  scenarios, including the exact review action, readable-continue boundary,
  retake recommendation, warning/guidance text, and parser expectations.
- Every fixture explicitly declares synthetic/redacted-only ownership,
  sensitive-field removal, editable expected results, and complete
  photo-quality inputs.
- Manifest, inventory, schema gate, and runner now agree that `damaged_ocr` and
  `long_receipt` are externally loaded. Global external readiness remains false
  while the other eight packs are inline.

QA evidence:

- External damaged-receipt pack: 7 fixtures, 202/202 checks passed.
- Full pure-Dart receipt matrix retained exact parity: 34 fixtures, 993/993
  checks, score 100%, no blockers.
- Focused schema/runner suite: 9/9 tests passed. Analyzer, schema gate,
  source-size checks, JSON validation, and `git diff --check`: passed.

Evidence boundary:

- These fixtures prove deterministic parser and review-policy behavior for
  synthetic degradation signals. They do not prove ML Kit OCR extraction or
  camera-quality classification against real wrinkled, greasy, faded, folded,
  or shadowed receipt photographs on a physical device.

## Pass 24 — Specialized receipt-corpus externalization

Status: **Closed as a specialized-corpus migration and pure-Dart regression
pass; physical-device evidence remains open**

Corpus migration:

- Migrated the contractor-supply, device-tier, maintenance, and privacy/admin
  packs from compiled Dart constants into versioned JSON fixtures under
  `test/fixtures/receipt_qa/` and removed their obsolete inline runner parts.
- Updated the fixture manifest, inventory, loader, schema gate, and focused
  contracts so all six currently external packs are loaded and counted from
  their declared files: contractor supply, damaged OCR, device tiers, long
  receipt, maintenance, and privacy/admin.
- Preserved every specialized expectation, including capability-derived
  workload and storage behavior, maintenance fields, contractor line details,
  and privacy/admin redaction counts.

QA evidence:

- Contractor-supply pack: 2 fixtures, 60/60 checks passed.
- Device-tier pack: 2 fixtures, 63/63 checks passed.
- Maintenance pack: 2 fixtures, 69/69 checks passed.
- Privacy/admin pack: 2 fixtures, 51/51 checks passed.
- Full pure-Dart receipt matrix retained exact parity: 34 fixtures, 993/993
  checks, score 100%, no blockers.
- Focused schema/runner suite: 10/10 tests passed. Analyzer, external schema
  gate, source-size checks, JSON validation, and `git diff --check`: passed.

Evidence boundary:

- This proves lossless host-side migration and deterministic behavior for the
  four specialized packs. It does not prove camera capture, OCR extraction,
  runtime memory limits, or receipt reconstruction on any physical device.

## Pass 25 — Complete external receipt-corpus ownership

Status: **Closed as a complete fixture-corpus migration and pure-Dart
regression pass; physical receipt/device proof remains open**

Corpus migration:

- Migrated the final adjustment, fuel, noisy OCR, and retail fixtures into
  versioned JSON packs and removed the two obsolete compiled-Dart fixture
  sources.
- The runner now loads all ten packs exclusively through the validated external
  fixture contract. The manifest and inventory declare the corpus fully
  external and ready; no receipt test text remains hidden in runner constants.
- Preserved adjustment reconciliation, fuel quantities/unit prices/types and
  odometers, noisy OCR substitutions, tender-row handling, category families,
  business/personal allocation, readiness outcomes, and exact line totals.

QA evidence:

- Adjustment pack: 1 fixture, 33/33 checks passed.
- Fuel pack: 6 fixtures, 189/189 checks passed.
- Noisy OCR pack: 4 fixtures, 106/106 checks passed.
- Retail pack: 4 fixtures, 107/107 checks passed.
- Full pure-Dart receipt matrix retained exact parity: 34 fixtures, 993/993
  checks, score 100%, no blockers.
- Focused schema/runner suite: 10/10 tests passed. Analyzer, schema gate, JSON
  validation, source-size checks, and `git diff --check`: passed.

Evidence boundary:

- This is deterministic host-side parser/review-policy proof and establishes a
  maintainable corpus for later real-redacted fixtures. It does not prove ML Kit
  OCR extraction accuracy, image stitching, memory behavior, or field accuracy
  on physical phones.

## Pass 26 — Post-migration authoritative host milestone

Status: **Closed as a source/host readiness pass; controlled physical-device
testing is the next evidence tier**

Regression closure:

- Re-ran the receipt-camera milestone after completing fixture externalization
  and artifact-lifecycle work. The shared wrapper correctly stopped at its
  ownership fence because unrelated maintenance, calendar, trip, and shared
  dirty files exist in the checkout; those files were not hidden or changed.
- Ran the wrapper's receipt-owned static gates, schema gates, audits, and exact
  milestone test plan directly. Removed one obsolete schema-gate declaration
  exposed by the analyzer after all packs became external.
- The external receipt corpus remains 34 fixtures and 993/993 checks with no
  blockers.

QA evidence:

- Receipt capture/review, long-receipt ordering and reconstruction, native and
  positional-text registration, manual alignment, OCR-source handoff, data
  saver, staging/recovery, privacy, compact-screen, and native bridge milestone:
  374/374 tests passed.
- Scoped analyzer: no issues. Changed-route coverage: 28 milestone routes and
  21 fast guard smokes. External dataset, local audit, fixture-schema, source
  audit, shell syntax, and `git diff --check`: passed.
- Source audit: 371 files inspected; none exceed 500 lines.

Evidence boundary:

- This is the final deterministic host milestone. It does not replace capture,
  OCR, saved-composite inspection, latency, memory, cancellation, or recovery
  measurements on the S24/flagship, older flagship, constrained emulator,
  iPhone SE, or future budget Android target.

## Pass 27 — Non-substitutable device evidence preparation

Status: **Closed as a deterministic target-matrix and capability-contract
pass; runtime rows remain NOT RUN until the exact targets are available**

Evidence preparation:

- Replaced generic device-class evidence placeholders with explicit rows for
  Galaxy S24 Ultra, additional Galaxy S25 Ultra, Galaxy S9 Plus older flagship,
  constrained Android emulator, iPhone SE third generation, and a future budget
  Android phone.
- The result gate now requires every row and explicitly prevents a newer
  flagship from satisfying S24 evidence, another iPhone/simulator from
  satisfying iPhone SE evidence, or results being copied between rows.
- Added deterministic representative capability profiles. These validate
  workload selection without pretending to be physical-device measurements.
  The S9 Plus-class profile remains a medium receipt-capability former flagship
  while its Android generation applies a safe camera-workload cap.

QA evidence:

- Result-template/start-script/matrix contract suite: 11/11 tests passed.
- Capability, shared-adapter, stitch working-resolution, and search-budget
  suite: 15/15 tests passed.
- S24-class profile selects heavyweight/flagship limits; S9 Plus-class selects
  medium receipt capability with a safe generation cap; iPhone SE-class and a
  declared low-RAM budget Android select bounded light limits.
- Analyzer, result gates, source-size checks, and `git diff --check`: passed.

Evidence boundary:

- Representative hardware inputs prove deterministic policy behavior only.
  They do not identify a connected phone, measure runtime, or establish field
  accuracy. Each physical/virtual target row must still be executed separately.

## Pass 28 — iPhone SE compile preflight

Status: **Closed as a non-installing iOS compile-readiness pass; physical iPhone
SE runtime evidence remains NOT RUN**

QA evidence:

- `tool/ios_receipt_camera_compile_gate.sh` completed successfully with exit
  code 0 for the iPhone Simulator SDK and code signing disabled.
- The connected Apple device was identified read-only as an iPhone SE (third
  generation), product type `iPhone14,6`; the compile gate did not install to,
  launch on, or otherwise exercise that phone.
- No receipt-camera compile error occurred. Third-party dependency warnings were
  emitted, along with three first-party receipt-camera warnings that remain
  follow-up defects: a non-exhaustive session-recovery switch, an invalid
  `UIAction`-to-`UISwitch` cast, and a duplicate diagnostics dictionary key.
- `git diff --check`: passed after the gate.

Evidence boundary:

- This proves simulator-SDK compilation only. It does not prove camera capture,
  OCR, stitching, data-saver output, memory/latency behavior, recovery, or saved
  receipt correctness on the physical iPhone SE.

## Pass 29 — iOS receipt-camera warning closure

Status: **Closed as a first-party compile-defect and focused-regression pass;
physical iPhone runtime remains NOT RUN**

Repairs:

- Added the iOS 26 sensitive-content-mitigation interruption reason to the
  receipt camera's named recovery diagnostics.
- Corrected the full-screen settings switch callback to read the actual
  `UISwitch` state instead of attempting to cast a `UIAction` to `UISwitch`.
- Removed the duplicate shutter-exposure diagnostics dictionary key so the
  privacy-safe evidence payload has one authoritative value.
- Repaired a brittle source-contract test that depended on cross-file
  concatenation order rather than reading the owning Swift source.

QA evidence:

- Focused iOS receipt camera source-contract suite: 6/6 tests passed.
- Targeted Dart analyzer: no issues.
- `tool/ios_receipt_camera_compile_gate.sh`: exit code 0.
- The three first-party warnings recorded in Pass 28 no longer appear. Remaining
  output is limited to third-party framework/linker and build-phase warnings.
- `git diff --check`: passed.

Evidence boundary:

- This proves source contracts and simulator-SDK compilation. It does not prove
  switch interaction, interruption recovery, camera/OCR behavior, or saved
  receipt correctness on a physical iPhone.

## Pass 30 — First-party iOS warning enforcement

Status: **Closed as a compile-gate hardening pass**

Gate hardening:

- The iOS receipt-camera compile gate now captures the complete build log while
  preserving `pipefail` and the original `xcodebuild` failure result.
- After a successful build, the gate rejects any Swift warning originating
  under `ios/Runner`; dependency and build-phase warnings remain visible but do
  not masquerade as first-party receipt-camera defects.
- Temporary build logs are removed on every exit.

QA evidence:

- Shell syntax gate: passed.
- Compile-warning source contract: 1/1 test passed.
- Targeted Dart analyzer: no issues.
- Hardened `tool/ios_receipt_camera_compile_gate.sh`: exit code 0 and emitted
  `iOS receipt camera compile gate passed with no first-party Swift warnings.`
- `git diff --check`: passed.

Evidence boundary:

- This prevents first-party Swift warnings from being silently accepted by the
  compile gate. It does not convert compilation into physical-device runtime
  evidence.

## Pass 31 — Authoritative QA-plan ownership for iOS warning enforcement

Status: **Closed as a camera-QA integration pass**

Coverage repair:

- Added the iOS first-party warning-gate regression to the authoritative camera
  QA quick pack. Milestone and full plans now execute that contract instead of
  relying on an ad hoc one-off invocation.

QA evidence:

- Camera QA shell syntax: passed.
- Printed milestone plan contains the warning-gate regression in the quick
  pack.
- Warning-gate, plan-coverage, gate-contract, execution, and runtime-wrapper
  suite: 18/18 tests passed.
- `git diff --check`: passed.

Evidence boundary:

- This proves durable QA ownership of the compile-warning rule. Exact-device
  camera, OCR, stitching, latency, memory, and saved-artifact proof remain
  separate physical evidence.

## Pass 32 — Deterministic completion audit and milestone closure

Status: **Closed as the current deterministic source/host completion audit;
all exact physical and constrained-runtime rows remain separate evidence**

Authority repairs:

- Reconciled the receipt completion map with the current ten-pack external
  corpus, Pass 26 host milestone, Passes 29-31 iOS warning closure, and the
  non-substitutable six-target evidence matrix.
- Removed obsolete July gate snapshots, the stale four-phone matrix, the
  outdated claim that fixture expansion remained pending, and fixed
  400-550/450 pass forecasts that no longer represented current evidence.
- Updated the release blueprint to require commercial-grade path/target proof
  rather than treating a headline percentage or fixed pass count as evidence.

Completion-audit evidence:

- Changed-route coverage: 28 milestone routes and 21 fast guard smokes passed.
- Bug-regression ledger, external dataset manifest/local audit, and external
  fixture schema gates: passed.
- Current milestone plan: 95 test entries with no duplicate plan rows.
- Scoped analyzer across receipt capture, shared receipt contracts, gates, and
  all milestone tests: no issues.
- Receipt source audit: 325 files inspected; none exceed 500 lines.
- Entire direct milestone plan: 375/375 tests passed.
- Focused active-document suite: 6/6 tests passed.
- `git diff --check`: passed.

Evidence boundary:

- Deterministic source, host, package, compile, corpus, fallback, lifecycle,
  privacy, capability, OCR handoff, and reconstruction contracts are green.
  This does not prove capture quality, positional ML Kit output, native OpenCV
  timing, memory, latency, recovery gestures, or saved-composite correctness on
  the S24 Ultra, S25 Ultra, S9 Plus, constrained emulator, physical iPhone SE,
  or future budget Android. Those rows remain independently measurable and
  non-substitutable.

## Pass 33 — Ordered photo review and terminal assembly workflow

Status: **Closed as a substantial shared receipt-review workflow pass; no
physical device was accessed**

Workflow repairs:

- Replaced the multi-photo review's single pannable image surface with an
  ordered `PageView`. A normal horizontal swipe now changes receipt photos;
  panning is disabled until the selected photo is actually zoomed.
- Kept thumbnail selection and programmatic selection synchronized with the
  page controller after add, retake, remove, and reorder operations.
- Changed Continue for multi-photo receipts to an opaque assembly state. While
  automatic reconstruction is pending, the UI renders no source photo,
  partial composite, alignment canvas, or duplicate action bar.
- The completed composite remains the only automatic-stitch image shown after
  success and continues into the saved-image preview.
- Added an explicit failed-join decision before manual controls: **Retake
  Photos** or **Align Photos Myself**. Original sources remain unchanged.
- Preserved the existing single-photo path, multi-signal stitch engine,
  device-derived budgets, complete-image Data Saver source, clear OCR source,
  durable-save result, and temporary-artifact lifecycle.

QA evidence:

- New ordered-review/assembly/fallback contract: 3/3 checks passed.
- Focused review/pipeline/layout regression bundle: 12/12 checks passed.
- Manual alignment, fallback metadata, timeout/exception recovery, stitched
  OCR handoff, Data Saver/durable-save cleanup, and temporary-artifact bundle:
  44/44 checks passed.
- Scoped analyzer: no issues. Changed-file `git diff --check`: passed.
- New and expanded source files remain below 500 lines.

Evidence boundary:

- This proves the source and deterministic host workflow. It does not prove a
  physical swipe, native OCR/registration timing, or visual composite quality
  on any phone. The Galaxy S25 Ultra was explicitly excluded and was not
  accessed, built for, installed on, launched, inspected, or tested.

## Pass 34 — Real-receipt registration, seam, and runtime repair

Status: **Closed as a substantial isolated engine and pipeline-regression
pass; the corrected source is not yet physically verified in the app**

Field failure accepted:

- The owner reported that a recent build ran for about 20 seconds and failed
  on the Galaxy S25 Ultra. This is treated as valid field evidence against the
  installed build, not as a successful or acceptable fallback.
- The S25 Ultra was not accessed, built for, installed on, launched, or used
  for testing during this repair pass.

Engine repairs:

- Bounded the transform search by device workload instead of allowing a
  flagship tier to multiply scale, rotation, perspective, vertical-offset,
  horizontal-offset, and seam searches into a timeout-prone matrix.
- Stopped upscaling decoded receipt photos above their available evidence
  width. The effective working width now remains at or below the requested
  device-derived budget and source width.
- Added sparse ordered positioned-text anchors so a long overlap remains
  matchable when OCR inserts, omits, or splits lines and when the shared text
  exceeds the old short contiguous window.
- Added an acceptance route that requires multiple positioned text matches
  plus receipt continuity or adequate visual evidence. A lone OCR-like match
  still cannot approve a join.
- Moved the seam below the last duplicated positioned receipt line when
  trustworthy anchors exist. This prevents a visually plausible mid-overlap
  seam from deleting unique item rows.

Real-fixture evidence:

- Two locally supplied two-photo receipt sequences were exercised through the
  production stitch API with local positioned-text sidecars. This was isolated
  host evidence only; the sidecars approximate positional device OCR and are
  not a claim of ML Kit runtime proof.
- Sequence A produced one 591 x 2511 composite in 1099 ms. Seven source item
  rows remained, the two shared rows occurred once, and the subtotal/footer
  followed the item body.
- Sequence B produced one 614 x 2076 composite in 1087 ms. Twelve item rows
  remained once, totals remained once, and the payment/footer region followed
  the totals. Without text evidence the same sequence safely declined with
  `overlap_confidence_low` instead of accepting weak geometry.
- Both composites were visually inspected from temporary output outside the
  repository. Earlier intermediate output that deleted unique rows was
  rejected and corrected before this pass was closed.

QA evidence:

- Focused acceptance, sparse-text, search-budget, working-resolution,
  coordinate-space, text/native guidance, result-contract, and photo-pipeline
  bundle: 46/46 checks passed.
- Timeout recovery, OCR-source ownership, ordered fallback, exit protection,
  and temporary-artifact cleanup: 21/21 checks passed.
- Manual alignment, multi-section recovery, exposure shift, unsafe overlap,
  and output-cap regression: 15/15 checks passed; three optional local-probe
  cases were skipped when no environment fixture was supplied.
- Scoped analyzer: no issues. Changed-file `git diff --check`: passed.

Evidence boundary and remaining work:

- This proves the corrected isolated engine can join the two supplied receipt
  pairs quickly when trustworthy positioned OCR evidence is available, and it
  proves safe fallback when that evidence is absent.
- It does not prove the installed S25 build contains these repairs, does not
  prove ML Kit supplies equivalent positional evidence on either device, and
  does not prove end-to-end stitch-plus-OCR latency or memory on a phone.
- The next pass must validate the actual OCR-to-stitch evidence handoff and
  packaged app on the approved S24 Ultra only. The S25 remains excluded unless
  the owner gives new explicit authorization.

## Pass 35 — Positioned OCR evidence handoff audit

Status: **Closed as a substantial source-ownership and regression pass; native
ML Kit runtime remains a separate physical-device evidence row**

Verified ownership chain:

- The device-scoped OCR service reads ML Kit text lines and normalizes each
  bounding box into receipt-image coordinates.
- Positioned lines remain keyed to their selected photo path through automatic
  order evaluation, including the unchanged-order case.
- Preview stitching receives those positioned lines for the current ordered
  source paths.
- Final stitching rebinds the same evidence to prepared OCR artifact paths,
  rather than losing the evidence when Data Saver preparation creates derived
  files.
- Generation and path-order guards reject stale asynchronous evidence after a
  photo edit, reorder, removal, or review exit.

Regression evidence:

- Expanded the phase-6 handoff contract so it fails if ML Kit bounding boxes,
  positioned-line ownership, preview handoff, or final prepared-path rebinding
  is removed.
- Phase-6 final stitch handoff suite: 8/8 checks passed.
- Section-order health gate: 62/62 checks passed.
- Stitch handoff health gate: 57/57 checks passed.
- Scoped analyzer: no issues.

Evidence boundary:

- The corrected source is wired for positioned OCR evidence end to end. This
  refutes an entirely unwired-OCR explanation for the field failure.
- A physical run is still required to prove that the packaged Android ML Kit
  plugin returns usable positioned lines for the owner's photos and that the
  corrected code, rather than an earlier build, is installed.
- No device was accessed in this pass. The S25 remains prohibited.

## Pass 36 — Bounded performance gate and source-cap recovery

Status: **Closed as a substantial performance/regression pass; physical
end-to-end timing remains pending on the approved S24**

Gate-driven repair:

- The fast health gate correctly rejected the main stitch API after it grew to
  527 lines, above the repository's 500-line receipt-stitch source cap.
- Extracted input normalization, manual-pair preparation, zero-overlap lookup,
  and exception fallback into a focused stitch-manual-pair module without
  changing the public stitch contract.
- The main stitch API is now exactly 500 lines and the extracted module is 94
  lines. The source-size gate passes without weakening its limit.

Regression and timing evidence:

- Manual overlap regression after extraction: 15/15 checks passed.
- Fast health gate: source-size, bad-input, and four phone-window cases passed.
  The phone-window group took 74 seconds as an aggregate host test workload;
  this is not an individual receipt or device-runtime claim.
- Final heavyweight host rerun of supplied sequence A: stitched in 1110 ms,
  591 x 2511, with review required.
- Final heavyweight host rerun of supplied sequence B: stitched in 1095 ms,
  614 x 2076.
- Both final composites were visually inspected. Receipt content and ordering
  remained intact. Sequence B still has a visible horizontal join and side
  offset; it is functionally complete but is not claimed visually seamless.
- Scoped analyzer: no issues. Changed-file `git diff --check`: passed.

Evidence boundary:

- Host timing proves the bounded OCR-guided stitch itself is no longer the
  roughly 15-second search seen before this repair. It does not include native
  ML Kit OCR time, Flutter transitions, encoding on Android, or device thermal
  and memory behavior.
- The owner's approximately 20-second S25 failure remains valid evidence
  against that installed build. No S25 access occurred in this pass.

## Pass 37 — Android package compilation

Status: **Closed as a packaging pass; no device was accessed**

Evidence:

- `flutter build apk --debug` completed successfully in 17.9 seconds.
- Output: `build/app/outputs/flutter-apk/app-debug.apk`.
- This proves the corrected Dart receipt pipeline and Android plugin graph
  compile into a debug package.

Evidence boundary:

- The APK was not installed or launched on any phone.
- Package compilation does not prove Android ML Kit positional output, native
  stitch timing, memory behavior, transition behavior, or visual correctness.
- The next physical target is the S24 Ultra only after authorization. The S25
  remains excluded.

## Pass 38 — Wrong-device field-tool interlock

Status: **Closed as a receipt-device safety pass; no physical device was
accessed**

Safety repair:

- Removed the receipt pipeline trace helper's implicit/default ADB target.
- The helper now requires an explicit serial, confirms that serial is in ADB
  `device` state, reads the model, and refuses every model except `SM-S928U`
  or `SM-S928U1` before requesting the app PID or logcat.
- This prevents a remembered serial, changing wireless endpoint, or device
  ordering from silently targeting the owner's S25 or another phone.

QA evidence:

- Missing-serial refusal, connected-S25 refusal, and verified-S24 acceptance:
  3/3 process-level tests passed with a fake ADB executable.
- The S25 refusal test proves the helper exits before `pidof` or log access.
- Shell syntax, scoped analyzer, and changed-file diff checks passed.

Evidence boundary:

- This proves the tooling interlock, not a real S24 connection or runtime.
- `adb devices -l` remained empty. No install, launch, UI action, screenshot,
  log access, or app-data operation occurred on any phone.
