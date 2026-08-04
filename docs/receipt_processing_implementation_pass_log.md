# Receipt Processing Implementation Pass Log

Passes in this log follow the owner's definition: inspect one related folder
or subsystem bundle, complete the necessary implementation and regression work,
run the focused gates, resolve introduced failures, and close that bundle before
starting the next pass.

## Pass 1 - Active Pipeline Baseline And Ownership

- Status: closed
- Scope: receipt capture/image-processing/OCR contracts and focused QA only
- Preserved ownership: CameraX, ML Kit OCR, device capability, durable storage,
  receipt models, manual entry, and unrelated vehicle mileage allocation work
- Unrelated worktree state preserved:
  `screen_notes/master_blueprint_working_notes_2026_08_03.txt` remains deleted
  and untouched
- Baseline evidence:
  - focused OCR, overlap, totals, and save-lifecycle tests: 20 passed
  - long-receipt QA pack: 84/84 passed
  - damaged-receipt OCR pack: 196/196 passed
  - camera `core_remaining` gate: analyzer passed, 40-file source audit passed,
    and 102 focused stitching, OCR-source, and storage tests passed
  - camera scope-gate contract: 4 passed after aligning its allowlist with the
    `receipt_image_*` tests already declared by the camera gate
- Confirmed source risks under investigation:
  - automatic stitch geometry is derived from reduced comparison images and
    must be proven coordinate-safe on full proof images
  - OCR section overlap cleanup suppresses exact repeated header lines using
    text alone and needs a repeated-identical-purchase safety contract
  - synthetic fixture success is not physical receipt/device proof
- Repair boundaries carried forward:
  - Pass 2 owns temporary originals, prepared OCR sources, compressed saved
    images, durable-save acknowledgement, recovery, and post-save cleanup
  - later stitch passes own coordinate mapping, candidate validation, output
    composition, long-stack ordering, and honest fallback
  - later OCR passes own positional overlap reconstruction, repeated-item
    ambiguity, and arithmetic reconciliation without replacing ML Kit
- Closure evidence: all declared Pass 1 gates are green; physical-receipt and
  device-runtime proof remains intentionally unclaimed for later passes

## Pass 2 - Temporary Original And Durable Save Lifecycle

- Status: closed
- Scope: review completion, attachment publication, receipt-record save
  acknowledgement, recoverable staging, and deletion of temporary derivatives
- Invariant: a full-quality source remains available through OCR and user
  confirmation; only a verified durable receipt plus saved compressed image may
  authorize final temporary-source cleanup
- Implemented:
  - accepted review and OCR sources are retained by the expense receipt owner
    instead of being deleted as soon as OCR returns
  - native CameraX recovery manifests and staged originals remain recoverable
    through review and are finalized only after the ledger save succeeds
  - app-owned optimized JPEGs under system temporary storage are deleted only
    after durable save, while gallery originals, malformed recovery records,
    and the permanent saved receipt image are preserved
  - staged proof cleanup now occurs after, rather than before, the durable
    receipt-record acknowledgement
- Closure evidence:
  - focused lifecycle and recovery regression pack: 17 passed
  - completion-audit correction/capture bundle: 37 passed across safe crop and
    straighten preparation, cleanup settings, Android edge/perspective signals,
    continuous focus, pinch zoom, best-shot OCR ownership, saved-copy timing,
    storage contracts, and continuation crop controls
  - targeted analyzer: no issues
  - camera `core_remaining` gate: scope clean, 40-file source audit clean, and
    102 focused stitching, OCR-source, and storage tests passed
- Recovery limitation carried forward: pending system-temp derivatives are not
  serialized into a draft across process death; native staged originals remain
  recoverable and can regenerate those derivatives
- Native guidance correction: the camera settings now state in ordinary words
  that the temporary full-quality photo is read first and a smaller saved copy
  is created only afterward; the shutter remains immediately available while
  framing guidance runs

## Pass 3 - Coordinate-Safe Multi-Photo Alignment

- Status: closed
- Scope: ordered section inputs, normalized comparison geometry, overlap
  candidates, original-coordinate transforms, seam composition, result
  validation, and explicit manual fallback
- Invariant: an automatic stitch may be accepted only when the transform and
  seam are valid in the full-resolution source coordinate system; ambiguity or
  repeated indistinguishable content must never silently delete receipt lines
- Implemented:
  - comparison images now mask surrounding capture background without cropping
    or stretching receipt geometry away from the proof-image coordinate space
  - detailed and noise-resistant overlap candidates are cross-checked when the
    first result has implausibly delayed geometry; the stronger independently
    corroborated result owns the proof transform
  - large-overlap scale, rotation, and perspective candidates require
    exceptional continuity or fall back to ordered-photo review
  - immediate duplicates displaced by small vertical capture shifts are
    rejected before stitching
  - indistinguishable repeated purchase lines and stacks beyond the bounded
    reorder search preserve the selected photo order and require review
- Real-receipt evidence:
  - Walmart sequence A safely falls back at 59% confidence instead of producing
    the earlier destructive header-to-total composite
  - Walmart sequence B produces a complete review-required composite containing
    the header, all 12 item lines, totals, payment section, and footer; the
    visible width transition at the seam remains a later polish concern
- Closure evidence:
  - focused alignment, transform, screenshot, duplicate, manual-overlap, and
    acceptance bundle: 52 passed
  - long-stack regression: 8 passed across five-, six-, and mixed-transform
    stacks
  - long-receipt health: 84/84; damaged OCR health: 196/196
  - camera `core_remaining` gate: scope clean, analyzer clean, 40-file source
    audit clean, and 102 focused tests passed
- Performance gap carried forward: the eight-test long-stack suite required
  10m14s on the host, and the final 102-test stitch gate required 4m55s. These
  are not S24 or low-end-device runtime proof; Pass 5 owns measured budgets,
  capability-tier tuning, and physical-device evidence

## Pass 4 - OCR Reconstruction And Arithmetic Reconciliation

- Status: closed
- Scope: ordered per-section ML Kit output, positional overlap reconstruction,
  repeated-identical purchase preservation, header/footer recognition, parsed
  line ownership, subtotal/tax/total reconciliation, and review reasons
- Invariant: ML Kit remains the text-recognition engine; reconstruction may
  suppress only overlap proven by section position and must never invent or
  silently remove purchase lines to force arithmetic agreement
- Implemented:
  - section overlap is now recognized only as a contiguous suffix-to-prefix
    sequence instead of any repeated line found in a trailing text set
  - automatic suppression requires at least two distinct ordered lines;
    single-line and all-identical overlaps remain visible and require review
  - parser source locations stay aligned with every retained OCR line
  - repeated purchases spanning two receipt photos remain separate line items,
    while subtotal/total disagreement raises review instead of deleting lines
- Preserved existing capability:
  - ML Kit remains the OCR engine and normalized layout owner
  - existing merchant header, item body, totals, payment, and footer analysis
    remains intact; no parallel parser or receipt model was introduced
- Closure evidence:
  - targeted analyzer: no issues
  - OCR overlap and delayed-section stress bundle: 17 passed
  - parser overlap, source-anchor, window, and arithmetic bundle: 24 passed
  - normalized layout and header/footer completion bundle: 15 passed
  - long-receipt health: 84/84; damaged OCR health: 196/196

## Pass 5 - Performance, Recovery, And Device-Tier Verification

- Status: closed for source, host, and real-fixture evidence; physical-device
  runtime evidence remains unavailable because no authorized S24 is connected
- Scope: capability-derived stitch budgets, decode and output limits, peak
  memory, timeout/cancellation behavior, process recovery, low-end fallbacks,
  and bounded real-device/receipt verification
- Invariant: low-capacity devices must receive cheaper deterministic work and
  honest fallback rather than unbounded image processing, memory pressure, or
  silent quality loss; host tests are not physical-device runtime proof
- Implemented:
  - the existing device-capability policy now supplies tier-specific stitch
    output pixels, output height, working width, comparison widths, and a
    processing deadline to both preview and final stitch ownership
  - low/medium/high tiers use progressively bounded 9/14/18 MP output budgets,
    14k/18k/24k output-height limits, 900/1200/1400 working widths, and
    12/12/15 second processing deadlines
  - duplicate detection retains source hashes and bounded proof images rather
    than compressed and full-resolution duplicates of every source
  - stitch processing runs in a managed isolate that is killed at its deadline;
    any exact app-owned partial output is removed and ordered sources remain
    available for manual review instead of a background stitch continuing
  - the final output path is chosen before isolate work, so cancellation and
    recovery own one deterministic artifact rather than searching broadly
  - upright overlap matching may use a cheaper geometry path only when OCR has
    already proven at least two distinct shared suffix/prefix lines; repeated
    identical purchases cannot unlock that shortcut and stay on the fully
    guarded geometry path
  - an attempted unconditional shortcut was rejected during regression because
    it falsely stitched Walmart sequence A; the guarded implementation restores
    the exact safe fallback for A and the exact valid composite for B
- Real-receipt evidence at the low-capability 900/320/280 working budget:
  - Walmart sequence A returned `overlap_confidence_low` after 10.743 seconds
    on the macOS Flutter-test host. Its proposed 1.18 scale, 2.2-degree rotation,
    and 34-pixel vertical adjustment were rejected rather than destructively
    joining unrelated receipt regions
  - Walmart sequence B stitched after 10.932 seconds on the same host with a
    1.06 scale, zero rotation, 68-pixel horizontal adjustment, and 783-pixel
    overlap. Visual inspection of the 968x3232 output confirmed the header, all
    12 item lines, totals, payment section, and footer; a visible width change
    at the seam remains review polish, not missing-content acceptance
- Closure evidence:
  - managed timeout, handoff, working-resolution, and output-size bundle:
    14 passed, including a behavioral zero-duration cancellation test
  - staging recovery and post-save cleanup bundle: 15 passed
  - guarded alignment and cancellation regression bundle: 31 passed, covering
    delayed overlap, continuation, drift, faded paper, clipped edges, wrinkles,
    screenshots, OCR ordering, and stale-work cancellation
  - direct OCR geometry-acceleration contracts: distinct shared lines permit
    the shortcut; identical repeated purchases forbid it
  - long-stack regression: 8 passed in 10m57s on the host, covering five- and
    six-section stacks, faded paper, mixed transforms, alternating side crops,
    mixed exposure, ordered fallback, and output caps
  - camera `core_remaining` gate: scope clean, analyzer clean, 40-file source
    audit clean, and 102 focused tests passed in 4m56s
  - final scoped analyzer: no issues; debug APK built successfully in 35.6s at
    `build/app/outputs/flutter-apk/app-debug.apk`
  - post-optimization scoped analyzer: 28 affected targets clean; focused OCR
    safety/working-resolution/acceptance bundle: 14 passed
  - after the completion-audit native-guidance correction, the final debug APK
    built in 13.4s with SHA-256
    `cf806296bbb878085e9b81a1b512c275bf09aa6f649662f583f88d4830c31f74`
- Evidence boundary:
  - host correctness, cancellation, recovery, and real-image behavior are
    verified; S24 and lower-end Android latency, peak RSS, thermal behavior,
    and CameraX-to-save field behavior remain unmeasured until an authorized
    device is connected

## Pass 6 - Physical Device And Field Receipt Regression

- Status: pending external device availability
- Scope: authorized S24 model verification, non-destructive debug install,
  regular and multi-photo CameraX capture, live-guidance responsiveness,
  production deadline/fallback behavior, OCR handoff, compressed durable save,
  temporary-original cleanup, peak RSS, latency, and thermal evidence
- Current evidence: `adb devices -l` returned no devices after the final build;
  no installation or launch was attempted and no S25 was targeted
- Entry requirement: connect or authorize only the Galaxy S24 Ultra, verify its
  model identifier before installation, and preserve installed application data
- Completion boundary: this pass cannot be represented by host Flutter tests or
  the successful APK build; it requires measured behavior on the named device

## Receipt Brain Completion Goal - Pass 1

- Status: closed
- Scope: requirement-to-source/test completion audit for the entire active
  capture, preparation, stitch, OCR, parser, review, save, recovery, and
  performance brain
- Authority created:
  `docs/receipt_processing_brain_completion_matrix.md`
- Current parser evidence:
  - receipt QA runner: 956/956 checks passed across 34 synthetic fixtures
  - the runner itself reports `externalFixtureFilesReady: false` and
    `schema_ready_no_real_samples`; synthetic success is not physical accuracy
- Source-proven gaps carried into later passes:
  - automatic stitch-order OCR uses a fixed 28-second timeout rather than a
    device-capability budget
  - exact automatic reorder search stops at six photos although native capture
    allows eight
  - automatic straightening and perspective readiness need image-output proof,
    not only bridge/settings contracts
  - header/body/footer topology, seam continuity, 7-8 section stacks, external
    redacted fixtures, rendered edit/save/reopen, and physical performance are
    not yet complete
- Closure evidence:
  - live stitch/OCR call sites traced from photo review through ML Kit evidence,
    ordering, geometry, final OCR source ownership, and fallback
  - completion matrix: 107 lines, no line exceeds 220 characters
  - `git diff --check`: clean
- Ownership preserved: no `vehicleMileageAllocation` path was read for design
  or modified; unrelated deleted blueprint note remains untouched

## Receipt Brain Completion Goal - Pass 2

- Status: closed
- Scope: temporary source ownership, document preparation, safe correction,
  OCR-before-compression, saved-copy generation, and cleanup regression
- Source defects repaired:
  - automatic straightening compared a full-resolution quality score with
    candidate scores from a 760-pixel review image; it now compares candidates
    in one coordinate/resolution space
  - straightening now uses horizontal edge concentration and directionality,
    so it changes document angle instead of treating lateral translation as a
    correction
  - the preparation pipeline previously reported perspective readiness but did
    not apply a perspective transform; it now detects four independent paper
    corners and applies a bounded quadrilateral rectification
  - the first perspective implementation incorrectly forced both top corners
    onto one Y coordinate; a dark-corner output assertion exposed the defect,
    and independent corner geometry replaced that assumption
  - perspective output is rejected for weak corners, small quads, excessive
    distortion, lost text bands, unreadable contrast, or degraded review score
- Closure evidence:
  - the new skewed-receipt regression failed on the prior implementation and
    now proves the corrected image is selected as the OCR source
  - the new trapezoidal-receipt regression proves a portrait rectified output,
    readable light corners, bounded resolution, and enhanced OCR-source
    ownership rather than a readiness-only diagnostic
  - focused document preparation, rotation, cleanup-setting, OCR-source, and
    preview/final compression bundle: 18 passed
  - scoped analyzer: no issues across the processor, new perspective helper,
    fixtures, and regressions
- Evidence boundary: host correction behavior is proven with generated images;
  physical folded, curled, glossy, and low-contrast receipts remain part of the
  final S24 and representative-fixture pass
- Ownership preserved: no `vehicleMileageAllocation` or unrelated expense
  domain was changed; no build, install, commit, push, or device action occurred
