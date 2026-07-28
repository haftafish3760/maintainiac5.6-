# Maintainiac Receipt Camera — GPT-5.3-Codex-Spark Execution Roadmap

## Purpose

This roadmap gives GPT-5.3-Codex-Spark one bounded receipt-camera system at a
time. Spark must complete the active package, run its focused QA, and stop for
SOL review before opening the next package.

The active checkout is:

`/Users/rbbie/Documents/Maintainiac_5.7_Active`

The active branch is:

`codex/receipt-camera-ocr-20260726`

Do not work in Maintainiac 5.6. Do not create another branch, worktree, or
repository.

## Non-negotiable operating rules

1. Work on only the active package in this roadmap.
2. Do not browse the repository generally. Read only the files listed in the
   package reading manifest.
3. Do not alter parsing internals, Work Supplies, Materials, inventory packs,
   fuel parsing, Maintenance, GPS, TripLog, PDF, invoices, Firebase, Calendar,
   permissions, onboarding outside Expenses, or long-receipt stitching.
4. Existing unrelated dirty changes belong to the user or another worker.
   Never reset, clean, revert, move, or stage them.
5. Use only public Android/iOS APIs and existing project dependencies. Do not
   use private Samsung, Google, Apple, Motorola, or other OEM APIs.
6. Phone-owned autofocus, exposure, stabilization, lens selection, and HDR are
   preferred whenever publicly exposed through CameraX or AVFoundation.
7. Do not implement tap-to-focus. Maintainiac uses continuous autofocus. A
   separate reversible manual-focus control may be considered in a later
   approved package.
8. Keep every production source file below 500 lines. Split by responsibility
   if necessary; do not create vague helper dumping grounds.
9. One pass is a coherent file change plus its directly required QA. Do not
   count individual commands, formatting, test reruns, or log inspection as
   separate passes.
10. Stop on the first failure. Fix the root cause and rerun the exact failed
    check before running the package bundle again. Never bypass, weaken, skip,
    delete, or rewrite a valid test merely to obtain green output.
11. Redirect command output to `/tmp`. Never stream Flutter or Gradle progress.
    Normalize carriage returns before reading a final result.
12. Do not poll a running test repeatedly. Run it once and wait. Read only its
    final PASS/FAIL summary unless it fails.
13. Do not use ADB, unlock a device, press confirmation dialogs, install an APK,
    commit, or push during a Spark package. SOL reviews the package first.
14. Do not claim real-device proof, OCR accuracy, or world-class readiness from
    source contracts or simulations.

## Product rules Spark must preserve

- This is a receipt camera, not a landscape or general photography app.
- The preview must maximize readable receipt area and avoid large black bands.
- Controls must remain compact and must not cover the receipt unnecessarily.
- Pinch-out zooms in; pinch-in zooms out, matching normal phone-camera behavior.
- The photo saved at shutter time must retain the zoom/framing shown in the
  live preview. Saving a wider unzoomed image defeats the purpose of zoom.
- The user must get visible feedback promptly after pressing the shutter.
- A capture must occur once, not twice, even if zoom is still settling.
- The saved original-quality image is used for OCR. Storage copies may be
  compressed later under the separate storage/compression package.
- OCR is Google ML Kit on-device by default. Premium cloud extraction is a
  later optional provider and must never block offline manual review.
- OCR output is advisory and editable. Unknown is acceptable; invented data is
  not.
- Camera/upload results eventually populate the same editable Simple, Basic,
  or Detailed receipt form completed in Pass 904.

## Current verified state

- Pass 904 completed the manual receipt structure and its focused QA:
  - Simple Receipt: store, optional whole-receipt category, final total, and
    Business/Personal/Split.
  - Basic Receipt: category and price per line without quantity/unit-price
    fields.
  - Detailed Receipt: faithful editable receipt lines with full details.
  - Photo attachments remain on the same editable receipt form.
  - Drafts preserve receipt level and category.
- The shared Work Supplies receipt-memory integration test passed unchanged.
- Do not reopen Pass 904 unless Package 1 directly breaks its contract.

## Active Package 1 — Pass 905: Android zoom-to-saved-photo fidelity

### Outcome

On Android, when a user pinches to a zoom level and presses the shutter, the
saved JPEG and the following review screen must represent that zoomed camera
framing. If CameraX is still applying the latest zoom request, the manual
shutter action must wait briefly for that request and then capture exactly once.

### Current unfinished work

The worktree already contains an in-progress Pass 905 change:

- `ReceiptCameraAnalysis.kt` binds Preview and ImageCapture through the same
  PreviewView viewport using a CameraX `UseCaseGroup`.
- `ReceiptCameraControls.kt` now tracks CameraX zoom-application completion.
- `ReceiptCameraCaptureClose.kt` queues a manual shutter while zoom is applying.
- `ReceiptCameraActivity.kt` stores the small amount of zoom/capture state.
- `receipt_native_pinch_zoom_contract_test.dart` covers the source contract.
- The focused Dart contract passed.
- Android compilation was interrupted and remains unverified. Do not claim the
  Kotlin change compiles until the compile gate passes.

### Strict reading manifest

Read only these files, in this order:

1. `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt`
   - Read only the zoom/capture state declarations unless compilation points to
     another exact line.
2. `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt`
   - Pinch gesture, CameraX zoom request, completion, and queued capture only.
3. `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraCaptureClose.kt`
   - `capturePhoto` and the immediate capture-start path only.
4. `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt`
   - `startCamera`, Preview, ImageCapture, `UseCaseGroup`, and viewport only.
5. `test/receipt_native_pinch_zoom_contract_test.dart`
6. Read another file only when a compiler error names that exact file and line.

Do not reread entire files after the first inspection. Use exact line ranges
around changed symbols or compiler failures.

### Required behavior

1. CameraX Preview and ImageCapture must remain in the same `UseCaseGroup` and
   use the PreviewView viewport.
2. Pinch gestures must continue reaching `ScaleGestureDetector` from the first
   pointer-down event.
3. Zoom must remain clamped to the public CameraX-reported min/max range.
4. Each zoom request must have an identity so completion of an older request
   cannot release a shutter queued for a newer request.
5. A manual shutter pressed while the newest zoom request is applying must:
   - acknowledge the action immediately with short guidance;
   - queue only one capture intent;
   - wait for the newest zoom request to complete;
   - capture once without double-counting the shutter tap.
6. If zoom application fails, do not silently capture a wider image. Keep the
   camera open, show concise recovery guidance, and allow another attempt.
7. Auto-capture must not fire while zoom is applying.
8. Existing capture timeout, exposure preparation, photo-quality processing,
   byte budget, and close/review behavior must remain intact.
9. Do not crop or digitally enlarge the saved JPEG after capture to fake zoom.
   Use CameraX zoom and viewport behavior.
10. Do not add proprietary OEM behavior or new packages.

### Edge cases

- The user pinches and presses shutter immediately.
- Several zoom updates are in flight; an older request completes last.
- The device reports a locked 1x zoom range.
- Camera or zoom state becomes unavailable.
- Zoom application fails.
- The user taps shutter twice while zoom is settling.
- Auto-capture becomes eligible while zoom is settling.
- Activity closes or camera surface becomes inactive before queued capture.
- Exposure preparation occurs only after zoom is ready.
- Capture failure still restores the existing recovery behavior.

### QA procedure

Run only these checks for Package 1.

#### 1. Focused zoom contract

```bash
flutter test --reporter compact \
  test/receipt_native_pinch_zoom_contract_test.dart \
  >/tmp/spark_pass905_zoom_contract.log 2>&1
```

Read the result with:

```bash
tr '\r' '\n' </tmp/spark_pass905_zoom_contract.log | tail -5
```

#### 2. Android receipt-camera compile gate

```bash
bash tool/android_receipt_camera_compile_gate.sh \
  >/tmp/spark_pass905_android_compile.log 2>&1
```

On success, read only:

```bash
tr '\r' '\n' </tmp/spark_pass905_android_compile.log | tail -8
```

On failure, inspect only compiler/failure lines:

```bash
rg -n -C 3 '(^e:|error:|FAILURE:|Compilation error)' \
  /tmp/spark_pass905_android_compile.log | tail -80
```

Fix only the named Package 1 source failure. Rerun the failed compile gate.

#### 3. Focused Android capture regression bundle

Run only after the compile gate is green:

```bash
flutter test --reporter compact \
  test/receipt_native_android_bridge_capture_flow_test.dart \
  test/receipt_native_android_capture_watchdog_test.dart \
  test/receipt_native_android_camera_startup_resilience_test.dart \
  test/receipt_native_android_bridge_capture_quality_contract_test.dart \
  test/receipt_native_android_bridge_ui_contract_test.dart \
  >/tmp/spark_pass905_android_capture_regression.log 2>&1
```

Read only:

```bash
tr '\r' '\n' </tmp/spark_pass905_android_capture_regression.log | tail -8
```

Do not run the full repository suite, stitch suite, Work Supplies parser suite,
or real-device QA in Package 1.

### Acceptance criteria

Package 1 is ready for SOL review only when:

- the focused zoom contract passes;
- the Android camera compile gate passes;
- the five focused capture regression files pass;
- no Package 1 production file exceeds 500 lines;
- no parser, long-receipt, Work Supplies, GPS, Maintenance, PDF, Firebase, or
  unrelated source changed;
- `git diff --check` passes for Package 1 files;
- the agent clearly states that real-device zoom-to-JPEG fidelity remains for
  SOL/user verification on the S24 Ultra.

Do not mark Pass 905 complete in the cleanup ledger. Do not commit or push.
SOL will review the diff, run or accept the final gate, conduct device QA, and
then decide whether Pass 905 is complete.

### Spark handoff format

Return no more than these items:

1. `Package 1 status: READY FOR SOL REVIEW` or `BLOCKED`.
2. Exact files changed.
3. Exact root cause fixed.
4. Zoom contract result.
5. Android compile-gate result.
6. Capture-regression result.
7. Remaining real-device verification.
8. Confirmation that no forbidden lane changed.

Do not paste raw logs, diffs, or long explanations.

## Locked future packages

Spark must not begin any package below until SOL or the user explicitly opens
it. Each future package receives its own reading manifest, tests, and acceptance
criteria before work begins.

### Package 2 — Camera viewer layout and settings

- Full-screen receipt preview without large black top/bottom bands.
- Compact, unobstructive controls and readable frame guidance.
- Settings that actually adjust supported behavior.
- Public device capability use for autofocus, exposure, stabilization, torch,
  and lens behavior.
- No tap focus; consider a later explicit manual-focus control only if public
  APIs and device capabilities support it.

### Package 3 — Capture, crop, straighten, and photo review

- Saved preview matches the captured framing.
- Crop handles auto-zoom the selected region and never overflow.
- Clear straighten/rotate/retake/use-photo actions.
- Review image supports pinch zoom.
- Duplicate-photo warning and bounded failure/recovery behavior.

### Package 4 — Manual receipt runtime UI verification

- Verify Pass 904 Simple, Basic, and Detailed forms at phone sizes.
- Verify attachment, draft restore, category, line entry, split allocation,
  save readiness, and no overflow.
- Adjust UI only; do not alter parsers.

### Package 5 — On-device ML Kit extraction and progress/recovery

- Confirm captured/uploaded images reach Google ML Kit.
- Bound extraction time and prevent endless spinners.
- Show one unambiguous current stage and actionable recovery.
- Preserve offline manual review and privacy-safe diagnostics.

### Package 6 — Editable OCR handoff and category routing

- OCR suggestions populate the same editable receipt form.
- Fuel selection hands off only through the existing fuel boundary.
- Inventory selection hands off only through the existing inventory boundary.
- All other categories remain faithful generic receipt form-fill.
- Do not modify parser internals.

### Package 7 — SOL review and S24 Ultra runtime validation

- Build and install the reviewed milestone.
- Verify pinch zoom, saved JPEG framing, capture latency, crop, review, OCR
  progress, editable form population, and recovery on the S24 Ultra.
- Real-device evidence is required before claiming completion.

## Paste-ready Package 1 instruction for Spark

Use this exact instruction when opening the Spark worker:

> Work only on Active Package 1 in
> `/Users/rbbie/Documents/Maintainiac_5.7_Active/docs/receipt_camera_spark_execution_roadmap.md`.
> You are finishing Pass 905 Android zoom-to-saved-photo fidelity. Follow its
> strict reading manifest, forbidden-lane rules, required behavior, QA order,
> failure rules, and eight-item handoff format exactly. Do not start a future
> package, use ADB, change parsers or long-receipt code, commit, or push. Do not
> stream test output or broadly search the repository. Stop only when Package 1
> is ready for SOL review or a genuine package boundary blocks you.
