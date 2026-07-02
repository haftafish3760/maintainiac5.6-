# Receipt Camera OCR Pipeline Handoff Archive - QA And Remaining Work

Archived from `docs/receipt_camera_ocr_pipeline_handoff_report.md`.

### QA Harness And Tests

Relevant files:

- `test/helpers/receipt_parse_accuracy_harness.dart`
- `test/helpers/receipt_regression_fixture_packs.dart`
- `test/receipt_parser_qa_harness_test.dart`
- `test/receipt_regression_report_test.dart`
- `test/receipt_end_to_end_regression_matrix_test.dart`
- `test/receipt_native_android_bridge_test.dart`
- `test/receipt_native_ios_bridge_test.dart`
- `test/receipt_stitching_test.dart`
- `tool/receipt_regression_report.sh`

Verified recently:

- `flutter test test/receipt_parser_qa_harness_test.dart -r compact` passed.
- `flutter test test/receipt_stitching_test.dart -r compact` passed.
- `flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart -r compact` passed.

Important issue:

- The current QA loop is too slow if every inner-loop change runs through `flutter test`.
- A faster pure Dart QA runner should be added for parser/OCR text handoff fixtures.
- Flutter tests should be reserved for gate checks after bundled logic changes, not every tiny parser iteration.

Needed QA strategy:

1. Fast inner loop:
   - pure Dart command-line receipt fixture runner,
   - no Flutter widget binding,
   - no emulator/device,
   - no full app startup.
2. Mid-level gate:
   - targeted `dart analyze` on touched files,
   - targeted parser/OCR/stitch unit tests.
3. Full gate:
   - Flutter tests for bridge/UI/contracts,
   - real-device smoke scripts,
   - manual S24/S25/S9/iPhone checks.

The next model should strongly consider creating:

- `tool/receipt_qa_runner.dart`
- `tool/receipt_qa_report.sh`

The runner should:

- import receipt fixture packs,
- score them through the parser/OCR handoff,
- print readiness by pack,
- print weakest fixtures,
- print issue buckets,
- optionally fail under thresholds,
- support `--pack fuel`, `--pack noisy`, `--pack materials`, `--json`, and `--fail-under`.

## Major Remaining Work

### 1. Real Device Camera Hardening

Must verify and fix on:

- Galaxy S24 Ultra.
- Galaxy S25 Ultra.
- Galaxy S9 Plus.
- iPhone SE 3.

Must test:

- open camera,
- permission flow,
- back button,
- cancel,
- manual shutter,
- tap focus,
- pinch zoom,
- exposure slider/reset,
- flash,
- photo review speed,
- accept photo,
- add another photo,
- long receipt mode,
- rotate/tilt,
- app background/resume,
- screen sleep recovery,
- camera unavailable fallback.

### 2. Camera Brightness/Exposure

Known complaint:

- Maintainiac camera preview/capture has appeared darker than native Samsung camera.
- Bottom of receipt has appeared blurrier than top.
- The user suspects shutter/exposure/focus behavior.

Needed:

- Audit Android CameraX exposure/focus/shutter behavior.
- Audit iOS AVFoundation exposure/focus behavior.
- Add or fix auto-exposure assist.
- Add exposure bias slider and reset.
- Add focus lock after readable receipt is achieved.
- Avoid forcing slow shutter in a way that causes motion blur.
- Compare app capture against native camera on same target.

### 3. Capture UI/UX

Needed:

- Minimal but clear camera capture screen.
- Top controls:
  - Back,
  - settings,
  - flash,
  - possibly help.
- No random settings button in the middle of the screen.
- No zoom button if pinch zoom is available.
- Pinch zoom must work.
- Settings screen must contain the actual Maintainiac receipt settings, not just stock phone settings.
- User guidance should be helpful, not blocking or obnoxious.
- Manual shutter must always work unless the camera is truly not usable.
- Auto capture should be opt-in, not default.

### 4. Photo Review UI/UX

Needed:

- Main receipt preview should remain visible.
- Controls should not cover the receipt.
- Add Another Photo must be obvious.
- Retake, crop, rotate, accept/continue must be obvious.
- The label should be `Next`, `Continue`, or `Save and continue`, not confusing OCR jargon.
- If only one photo exists, do not say `choose the best receipt photo` in a way that sounds like multiple photos exist.
- Quality score must not be misleading.
- User should be able to zoom/pan the preview.
- Crop/manual edge adjustment must be usable at top and bottom.

### 5. Long Receipt Flow

Needed:

- If no bottom edge and no subtotal/total are detected, suggest adding another photo.
- If bottom edge or total/subtotal appears, allow user to continue.
- Ghost overlay from previous bottom section should guide the next capture.
- Duplicate overlap lines must be suppressed after OCR.
- If stitching confidence is low, keep ordered sections for OCR instead of blocking save.
- User should understand that fallback still works.

### 6. OCR Quality And Confidence

Needed:

- Confidence score must be calibrated against real receipts.
- A clear receipt should not get a silly low score.
- Score should separate:
  - image readability,
  - receipt completeness,
  - OCR text extraction,
  - parser confidence,
  - total/tax reconciliation,
  - line classification confidence.
- The user needs actionable guidance:
  - continue,
  - retake because blurry,
  - add another photo,
  - crop/straighten,
  - review parsed lines.

### 7. OCR Pipeline Hardening

Needed:

- More fixture packs:
  - fuel,
  - convenience store,
  - Walmart/Target,
  - Lowe's/Home Depot,
  - auto parts,
  - restaurants,
  - groceries,
  - tolls/parking,
  - mobile/telecom,
  - damaged/faded receipts,
  - long receipts,
  - receipts photographed from another phone screen.
- OCR should preserve line order and line IDs.
- OCR should number lines internally so parser/review can refer to them cleanly.
- OCR should produce privacy-safe evidence summaries.

### 8. Parser Hand-Off

Needed:

- Camera/OCR should hand over:
  - source image paths,
  - stitched/fallback status,
  - OCR text blocks,
  - line IDs,
  - line roles,
  - confidence/readiness,
  - warnings,
  - duplicate suppression info,
  - original/proof file relationship.
- Parser should not need to know camera UI details.
- Inventory/material parser and expense parser should be able to share OCR line structures without owning each other's business logic.

### 9. Low Storage And Older Device Strategy

Needed:

- Detect device capabilities and available storage.
- Keep base receipt capture usable on older/low-storage phones.
- Optional local parser/OCR packs should be user-chosen.
- Cloud OCR/parser can be added later but should not be required for basic capture.
- Do not force a 100+ MB camera/parser payload on users with little free space.

### 10. Maintenance Parsing Later

Do not work this yet unless explicitly assigned.

Future maintenance receipt parser should extract:

- service type,
- oil type,
- oil weight,
- filter,
- mileage,
- next due mileage/date,
- tire rotation,
- other vehicle service items,
- maintenance interval suggestions.

It should help set up maintenance intervals, but only after camera/OCR is dependable.

## Recommended Next Work Order

1. Add fast non-Flutter receipt QA runner.
2. Finish any currently in-progress mixed-family review readiness pass.
3. Audit native camera UI against the product expectations above.
4. Fix capture screen fundamentals:
   - Back,
   - settings,
   - flash,
   - pinch zoom,
   - tap focus,
   - manual shutter.
5. Fix photo review flow:
   - visible preview,
   - obvious add-photo,
   - no hidden bottom-panel traps,
   - accept goes to assisted review when enabled.
6. Calibrate OCR/image quality scoring.
7. Harden exposure/focus behavior on Android first.
8. Harden iOS AVFoundation behavior.
9. Expand fuel OCR/parser fixtures.
10. Expand long receipt/overlap fixtures.
11. Run real-device QA on S24/S25/S9/iPhone.
12. Only after the camera/OCR path is usable, resume PDF/cloud/inventory/maintenance integrations.

## Expected Acceptance Criteria

The system is not done until all of these are true:

- User can open Maintainiac receipt camera without seeing stock phone camera as the primary UI.
- Back/cancel works reliably.
- Manual shutter works reliably.
- Pinch zoom works during capture.
- Tap focus works during capture.
- Exposure is not obviously worse than stock camera under the same lighting.
- User can accept a photo and continue to assisted receipt review.
- User can add another photo for long receipts.
- The app can stitch or safely fall back to ordered OCR sections.
- OCR uses the clearest/original source before compression.
- Saved proof can be compressed without damaging OCR.
- OCR identifies store, date, totals, tax, line items, tender/reference rows, and fuel details in covered fixtures.
- Parser review shows business/personal/mixed classification affordances.
- Mixed receipts can classify line by line.
- Diagnostics are privacy-safe.
- Fast QA runner exists and can report readiness by fixture pack.
- Real-device smoke tests pass on at least one modern Android, one older Android, and one iPhone before claiming production readiness.

## Commands Recently Used As Evidence

These passed recently in the 5.6 workspace:

```sh
flutter test test/receipt_parser_qa_harness_test.dart -r compact
flutter test test/receipt_stitching_test.dart -r compact
flutter test test/receipt_native_android_bridge_test.dart test/receipt_native_ios_bridge_test.dart -r compact
```

These are useful but too slow for every tiny iteration. Prefer a fast Dart QA runner for parser/OCR inner-loop work.

## Important Warning For The Next Codex Model

Do not assume that a large number of prior passes means the system is complete. Verify the current worktree.

Do not keep making tiny one-line passes. Bundle coherent work safely.

Do not run Flutter tests after every small parser edit unless the change touches Flutter UI, platform bridge contracts, or widgets. Use a faster QA script for receipt text/parser iterations, then run Flutter tests as a gate.

Do not claim the camera is ready until it has been tested on real devices and the user has confirmed the flow is understandable.

Do not throw away reusable OCR/parser/stitch/review code just because the camera backend is native. Keep reusable business logic and replace only bad camera-control plumbing.
