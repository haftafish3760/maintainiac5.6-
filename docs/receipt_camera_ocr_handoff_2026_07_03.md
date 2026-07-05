# Receipt Camera/OCR Handoff - 2026-07-03

This is the current operational handoff for the Maintainiac 5.6 receipt camera,
OCR-source, receipt-review, and expense receipt pipeline lane.

It is intentionally long. The user asked for a complete transfer document so a
new Codex thread/model can continue without losing context or repeating earlier
mistakes.

## Start Here

Workspace:

- `/Users/rbbie/Documents/Maintainiac_5.6`

Active branch:

- `codex/expense-camera-lane`

Current known clean checkpoint:

- Commit: `1b65eeab5`
- Commit message: `checkpoint receipt camera cleanup and ordering hardening`
- Remote: `origin`
- Remote URL: `https://github.com/haftafish3760/maintainiac5.6-.git`
- Pushed branch: `origin/codex/expense-camera-lane`
- At the time this handoff was started, `git status --branch --short` showed:
  `## codex/expense-camera-lane...origin/codex/expense-camera-lane`

Before continuing, run:

```sh
cd /Users/rbbie/Documents/Maintainiac_5.6
git status --branch --short
git log -1 --oneline --decorate
```

If the worktree is dirty, do not assume those changes are junk. They may be from
another Codex thread or the user. Inspect before editing. Do not run destructive
cleanup.

## User Intent And Product Standard

The user is building Maintainiac as a production commercial app, not a demo.
The receipt camera/OCR system is foundational infrastructure for expenses,
materials/inventory, maintenance receipts, jobs, estimates, invoices, export,
and future customer-safe receipt proof views.

The user wants:

- A world-class receipt camera experience.
- Native Android CameraX and native iOS AVFoundation camera paths.
- Google ML Kit as the main free/local OCR engine.
- Google Cloud Vision OCR later as an optional premium/cloud assist.
- Strong camera guidance so OCR receives the clearest possible source.
- Long receipt multi-photo capture.
- Stitching or safe ordered fallback.
- Original receipt source preservation.
- Privacy-safe telemetry and admin diagnostics.
- Regression tests for every confirmed bug.
- No silent overwrites of user-confirmed financial data.
- No raw receipt text or personal data in admin telemetry.

The user explicitly does not want this project to try to "out-Google Google" on
OCR. The near-term priority is the camera system and handoff quality:

1. Capture clear photos.
2. Preserve originals.
3. Support long receipts with ordering, ghost guidance, and stitching/fallback.
4. Hand good OCR-ready sources to ML Kit/Google OCR.
5. Review parser/OCR suggestions without treating them as truth.

## Absolute Rules

Follow these rules exactly:

- Work only in Maintainiac 5.6 unless the user explicitly says otherwise.
- Do not touch Maintainiac 5.5.
- Do not build on a failing analyzer, failing QA runner, failing source audit,
  failing doc gate, or failing quality gate.
- If anything fails, stop adding features and fix the failure first.
- Do not bypass tests. Do not delete or weaken tests just to pass.
- Every confirmed bug fix must include a regression test.
- When a bug reveals a family of risks, add a generalized regression if practical.
- Do not create giant files. Keep handwritten source files under the project cap.
- Do not split files with lazy names like `file1`, `file2`, etc. Use meaningful
  names.
- Do not mutate unrelated modules unless a documented dependency requires it.
- Do not revert or delete other-agent/user changes without explicit instruction.
- Run targeted tests during work. Run full gates only at milestones.
- Long-running QA/build commands must be non-interactive: start them, wait for
  exit, then inspect final logs. Do not watch console output scroll.
- Push/back up at clean milestones, roughly every 30 minutes or after a verified
  batch. Commit/push safely; do not use destructive cleanup.

## Cross-Platform Camera Scope

This system is not for Samsung only.

Samsung/Galaxy/S24/S9 language appears in docs and tests because those are real
or example test devices. The production runtime must remain capability-based:

- Android: CameraX native Maintainiac camera path.
- iOS: AVFoundation native Maintainiac camera path.
- Flutter: shared orchestration, review, OCR handoff, storage, tests.
- Device policy: capability/storage tier based, not manufacturer based.

Named device examples are acceptable in:

- real-device test scripts
- documentation
- historical pass logs
- privacy/redaction tests that prove brand/model names do not leak

Named device behavior is not acceptable in production logic. Do not make the
receipt camera depend on Samsung-only, Pixel-only, or iPhone-model-only rules.
Use hardware/capability signals instead:

- RAM
- CPU cores
- Android SDK/performance class where available
- free storage
- camera count
- rear/front camera availability
- continuous focus/readability support
- exposure support
- zoom support
- torch support
- YUV live frame support
- native edge signal support
- max still dimensions
- low power/storage mode

## Current Architecture

### Major Shared Camera/OCR Areas

Shared receipt camera and OCR infrastructure:

- `lib/shared/widgets/receipt_capture/**`
- `lib/shared/receipts/**`

Native Android camera bridge:

- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSessionArguments.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsPayload.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt`
- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraCapturedQuality.kt`
- other `android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt` files

Native iOS camera bridge:

- `ios/Runner/ReceiptCameraViewController.swift`
- `ios/Runner/ReceiptCameraViewControllerSessionArguments.swift`
- `ios/Runner/ReceiptCameraViewControllerDiagnostics.swift`
- `ios/Runner/ReceiptCameraViewControllerSessionSettings.swift`
- `ios/Runner/ReceiptCameraViewControllerLiveFrameAnalysis.swift`
- other `ios/Runner/ReceiptCameraViewController*.swift` files

Expense receipt entry/review:

- `lib/screens/expenses/entry/**`
- `lib/screens/expenses/data/expense_receipt_*`
- `lib/screens/expenses/data/expense_screen_telemetry*`

Materials/work-supply parser files were touched during cleanup because previous
work left oversized receipt parser/scoring files. Those are related to receipt
parsing, but the next camera model should avoid expanding inventory/materials
scope unless the shared receipt handoff requires it.

## Production Flow Contract

The intended receipt camera flow is:

1. User starts receipt capture from expenses or another app module.
2. Maintainiac opens its own camera UI.
3. User sees receipt-specific guidance, not a generic phone camera app.
4. Manual shutter always works unless the camera is unavailable/busy/closing or
   the surface is inactive.
5. Optional auto capture may help only when enabled and safe.
6. User gets continuous autofocus/readability guidance, can pinch zoom, adjust
   brightness/exposure, and use torch when supported.
7. User captures one receipt photo or multiple ordered sections.
8. Long receipt continuation shows previous-section ghost/overlap guidance where
   practical.
9. User can review, crop, retake, add another section, remove, reorder, or
   continue.
10. If retaking a section, replacement preserves the original section index.
11. If adding after a selected section, inserted sections are tracked after that
    anchor.
12. OCR uses a temporary full-quality source before saved proof compression.
13. Derived OCR-ready images, cropped images, stitched images, compressed proof
    images, and redacted images are artifacts, not source truth.
14. OCR reads the clearest prepared temporary source before compressed proof
    copies.
15. OCR/parser output is suggestion data.
16. User review confirms financial truth.
17. Saved expense records preserve proof, line references, confidence, warnings,
    and correction/audit state.

## Temporary OCR Source And Saved Proof Rule

This rule is central:

- Never imply full-quality original proof retention is the default.
- Never mutate saved proof in place.
- Cropped, stitched, enhanced, OCR-ready, compressed, PDF-rendered, and redacted
  copies are derived artifacts.
- OCR should read the clearest available temporary source first, usually the
  capture/prepared OCR source, not the smaller saved proof.
- Saved proof/storage copies may be compressed after OCR source selection.
- Full-quality original proof retention must be an explicit user choice.
- Customer-safe redacted views must be separate derived artifacts.

## OCR Boundary

Current local OCR direction:

- Use Google ML Kit on device for free/local OCR.
- Treat OCR as suggestion data.
- Preserve raw OCR text and structured OCR line/block data where available.
- Keep OCR source paths and proof paths separate.
- Preserve confidence, warnings, review-needed flags, and source section/line
  references.

Future/premium OCR direction:

- Google Cloud Vision OCR can be optional/premium/cloud-assisted later.
- Cloud OCR must be opt-in or clearly explained.
- Cloud/admin telemetry must not receive raw receipt content except where the
  user explicitly requests cloud processing for their own receipt.

Do not spend near-term work trying to build a better OCR engine than Google.
Spend the work on:

- clear capture
- quality scoring
- crop/deskew
- low light/glare/blur warnings
- long receipt section ordering
- stitching/fallback
- reliable OCR-source handoff
- review UX and parser suggestion handling

## Parser/Review Boundary

The parser should:

- Parse merchant, date, subtotal, tax, total, payment hints, line amounts, and
  category/fuel details where possible.
- Handle discounts, refunds, returns, duplicate totals, missing total, malformed
  subtotal, tips, split payments, and bad OCR.
- Return confidence and warnings.
- Never invent values.
- Require review for low-confidence results.
- Never overwrite user-confirmed values silently.

Two user review modes matter:

- Price-only/simple mode: many users care only about prices, business/personal
  or split classification, and saved proof.
- Detailed-line mode: users can inspect item descriptions, categories, line
  amounts, and later use lines for inventory, jobs, estimates, invoices, and
  customer-safe proof.

Stable receipt line numbering matters for future inventory/job/customer proof:

- Section number.
- Line number within section.
- Stable line id.
- Proof label.
- Privacy-safe redaction anchor.
- Business/personal/split state.
- Optional detailed item text locally.

Command/admin telemetry must never include private item descriptions, merchant
addresses, phone numbers, transaction numbers, loyalty numbers, full file paths,
customer names, notes, or raw OCR text.

## What Was Recently Completed

### Clean Checkpoint

The worktree was previously very dirty. A safe checkpoint commit was made and
pushed so work is backed up:

- Commit: `1b65eeab5`
- Branch: `codex/expense-camera-lane`
- Pushed to: `origin/codex/expense-camera-lane`

This was intentionally non-destructive. Nothing was reverted or deleted as a
"cleanup." The checkpoint preserved all current verified work.

### Source Audit Cleanup

`tool/maintainiac_source_audit.dart` was hardened:

- `.symlinks` is ignored so vendored/native plugin symlink files do not count as
  app-owned source.
- Generated work-supply catalog data is classified separately.
- Default source audit skips generated catalog files and reports skip count.
- `--include-generated-catalog-data` intentionally includes generated catalog
  files and should report oversized generated data when requested.

Regression coverage:

- `test/maintainiac_source_audit_contract_test.dart`

Verified:

- focused source-audit contract test passed
- focused work-supply data source audit passed for handwritten/source files
- include-generated mode still reports oversized generated catalog data

### Oversized Parser Cleanup

Several oversized work-supply receipt parser/scoring files were split into
focused part files with meaningful names. This was cleanup of inherited
oversized work, not a new inventory feature push.

Important examples:

- `work_supply_receipt_parser.dart` reduced under cap.
- `work_supply_receipt_parser_terms.dart` split into named part files.
- trade scoring split into meaningful files such as:
  - carpentry
  - electrical
  - plumbing
  - HVAC duct/equipment/service/final/install support/tools hydronic
  - insulation
  - landscaping
  - masonry/concrete
  - painting
  - roofing
  - siding/exterior
  - tile/waterproofing/tools
  - windows/doors

Verified with focused parser/catalog tests and analyzer before checkpoint.

### Long Receipt Add/Retake Ordering

Files:

- `lib/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart`
- `lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_review_result_native_signals.dart`
- `lib/shared/widgets/receipt_capture/receipt_capture_review_result_helper_diagnostics.dart`
- `test/receipt_photo_review_retake_order_test.dart`
- `test/receipt_camera_long_receipt_guidance_test.dart`
- `test/receipt_camera_result_stitch_scanner_test.dart`

What changed:

- Retake planning preserves the original section slot.
- Retake replacement paths carry diagnostics:
  - original section number
  - replacement offset
  - final section number
  - guidance code
  - previous/next/two-sided alignment context flags
  - retake order policy
- Add Another Photo after a selected section now carries inserted-section
  diagnostics:
  - anchor section number
  - insert offset
  - final section number
  - preserved anchor slot
  - insert order policy
- Inserted-section diagnostics now flow into result-level handoff counts and
  privacy-safe receipt section order outcomes.
- Malformed insert metadata is counted as invalid instead of being summarized as
  preserved order.
- Picked native/backup diagnostics are preserved when order diagnostics are
  empty or partial.

Regression bugs recorded:

- `BUG-RECEIPT-0106`: Add Another Photo could drop picked diagnostics when
  insert-order metadata was empty.
- `BUG-RECEIPT-0107`: Malformed insert-after metadata could be summarized as
  preserved order.

Verified:

- targeted analyzer passed
- `test/receipt_photo_review_retake_order_test.dart` passed
- `test/receipt_camera_long_receipt_guidance_test.dart` passed
- `test/receipt_camera_result_stitch_scanner_test.dart` passed
- receipt QA runner passed after this batch

### Native Review Depth Normalization

Files include:

- `android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSessionArguments.kt`
- `ios/Runner/ReceiptCameraViewControllerSessionArguments.swift`

Review depth is normalized before native UI labels/diagnostics use it:

- `pricesOnly`
- `detailedLines`

Malformed values must not create unbounded metadata keys.

Regression:

- `BUG-RECEIPT-0104`

### OCR Source Continuation/Ghost Handoff

Derived OCR-source attachments can inherit aligned original proof-photo
continuation and ghost-guide diagnostics when the OCR-ready source path differs
from the original proof path.

Regression:

- `BUG-RECEIPT-0105`

This matters because OCR-ready artifacts are derived. The original proof photo
may hold the camera continuation evidence, ghost-guide policy, bottom-edge risk,
and repeat target. Do not lose that evidence just because the OCR source path is
different.

## Current Known Clean Verification

Recent verified checks from the clean checkpoint work:

- `git diff --check` passed before commit.
- scoped receipt source audit passed.
- receipt cleanup log gate passed.
- receipt doc size gate passed.
- receipt QA runner passed.
- focused source audit contract tests passed.
- focused long-receipt add/retake/order tests passed.
- focused receipt result stitch/scanner tests passed.
- focused parser cleanup regressions passed.

Before new work, re-run only the checks relevant to your first change. Do not
rerun full suites repeatedly without source changes.

Useful commands:

```sh
dart tool/maintainiac_source_audit.dart --max-line-length=220
bash tool/receipt_cleanup_log_gate.sh
bash tool/receipt_doc_size_gate.sh
dart tool/receipt_qa_runner.dart
flutter test test/receipt_photo_review_retake_order_test.dart -r compact
flutter test test/receipt_camera_long_receipt_guidance_test.dart -r compact
flutter test test/receipt_camera_result_stitch_scanner_test.dart -r compact
flutter test test/maintainiac_source_audit_contract_test.dart -r compact
```

Run long commands non-interactively:

```sh
flutter test SOME_TEST.dart -r compact > /tmp/some_test.log 2>&1
rc=$?
if [ $rc -ne 0 ]; then tail -160 /tmp/some_test.log; fi
exit $rc
```

Do not watch test output scroll.

## Important Existing Docs

Read these before major camera/OCR work:

- `docs/receipt_camera_ocr_master_pass_plan.md`
- `docs/receipt_camera_release_one_blueprint.md`
- `docs/receipt_camera_ocr_state_of_art_spec.md`
- `docs/receipt_camera_ocr_product_standard.md`
- `docs/receipt_native_camera_service_spec.md`
- `docs/receipt_camera_world_class_qa_standard.md`
- `docs/receipt_camera_parallel_work_boundary.md`
- `docs/expense_release_one_blueprint.md`
- `docs/receipt_bug_regression_ledger.md`
- `docs/receipt_camera_cleanup_pass_log.md`

This new handoff should be the first file for a new model, then use the files
above for depth.

## What Still Needs Cleanup

### 1. Camera Runtime Manufacturer-Agnostic Guard

The user explicitly asked whether the system is only for Samsung phones. It is
not. The next model should add a small regression confirming production receipt
camera runtime code is manufacturer-agnostic.

Important nuance:

- Docs and real-device scripts may mention S9/S24/S25/iPhone as test examples.
- Privacy tests may mention Samsung/Galaxy to prove those values do not leak.
- Production runtime should not hard-code brand/model-specific behavior.

Potential test location:

- `test/receipt_native_camera_privacy_diagnostics_test.dart`

Potential test behavior:

- Read production source under:
  - `lib/shared/widgets/receipt_capture`
  - `android/app/src/main/kotlin/com/maintainiac`
  - `ios/Runner`
- Assert no production runtime source contains brand/model tokens like
  `Samsung`, `Galaxy`, `S24`, `S25`, `S9`, `Pixel`, `Motorola`, `OnePlus`.
- If a legitimate source line collects `deviceManufacturer` or `deviceModel`,
  that is allowed only as generic field names and must be sanitized before
  privacy-safe diagnostics. Do not block generic field names.

Do not overreach and fail docs/history files for named devices.

### 2. Real Device Camera QA

Still needed when the user asks for device testing:

- S24/S25-class Android flagship.
- S9-class/older Android behavior.
- iPhone/iOS behavior.

Real-device proof still needed:

- native camera opens Maintainiac UI, not stock camera app
- back/cancel behavior
- manual shutter behavior
- continuous autofocus/readability guidance
- pinch zoom
- exposure/brightness control
- torch/light behavior
- long receipt add section
- ghost overlay/continuation
- retake section preserves slot
- add section after selected anchor preserves order
- review -> OCR/parser handoff
- low-storage/data saver behavior
- darker preview/saved photo diagnostics
- bottom missing/totals missing guidance

Do not run phone UI/device tests unless the user explicitly asks.

### 3. Stitching And Ordered Fallback

Current state:

- Stitching models and tests exist.
- Long receipt section ordering and insert/retake diagnostics are stronger now.
- Stitch result handoff distinguishes stitched output from ordered fallback.

Still needed:

- More synthetic long-receipt fixture coverage.
- Better evidence labels for partial overlap, duplicate overlap, and missing
  middle section.
- More memory-limit tests for large receipt sections.
- More real-device proof that the ghost/overlap UX guides users well enough.
- Confirm OCR gets ordered fallback sections if stitching is unsafe.

### 4. Image Quality And Capture Guidance

Existing/started:

- Quality models for blur/focus, brightness, contrast, crop, text bands.
- Native diagnostics for live/saved brightness/parity.
- Warnings for retake/brightness/blur/bottom section risks.

Still needed:

- Validate scoring thresholds on real receipts.
- Tune false positives on clear photos.
- Tune false negatives on blurry, glare, low-light, cropped, thermal faded
  receipts.
- Continue adding synthetic receipt/photo degradation tests.
- Make user-facing guidance clear and not annoying.
- Ensure manual capture remains available.

### 5. Review UX

Still needed:

- Polish photo review screen on real phone sizes.
- Make Add Photo, Retake, Done/Use Receipt/Next obvious.
- Keep receipt preview dominant.
- Avoid hiding important controls in cramped panels.
- Verify text does not overflow on smaller phones.
- Verify the simple/detailed receipt mode choice is visible and understandable.
- Verify business/personal/split controls are ergonomic.

### 6. OCR/Parser Review

Still needed:

- Better fixture-backed parser coverage for common expense receipts.
- Fuel receipt parser hardening.
- Spanish/English basic keyword support for release one.
- Maintenance receipt parser should wait until camera/OCR foundation is stable.
- Inventory/materials parser should consume shared receipt line references, not
  fork camera/OCR.

### 7. Admin Diagnostics

User wants admin failure visibility without private user data:

- failure type
- app version
- platform
- device tier
- storage mode
- Android/iOS version where safe
- camera/OCR/parser/save stage
- crash/error/failure bucket
- retry count
- privacy-safe quality/readiness signals
- optionally redacted/derived image evidence later, not raw private receipt
  content

Never store:

- VINs
- license plates
- passenger/patient data
- raw receipt text
- merchant address/phone
- user notes
- card/auth/loyalty numbers
- full private file paths
- customer/private names

## Current Bug Ledger Direction

Use `docs/receipt_bug_regression_ledger.md`.

Every confirmed bug gets:

- unique bug id
- category
- symptom
- root cause
- fix
- regression test file(s)
- status

Recent ids:

- `BUG-RECEIPT-0104`: malformed native review depth normalized.
- `BUG-RECEIPT-0105`: derived OCR-source continuation/ghost diagnostics.
- `BUG-RECEIPT-0106`: Add Another Photo diagnostic merge preservation.
- `BUG-RECEIPT-0107`: malformed insert-after metadata invalid label.

Next ids should continue from `BUG-RECEIPT-0108` unless another thread already
adds entries.

## QA Philosophy

The user does not want shallow tests.

Tests should prove behavior:

- ordering preserved
- stale async paths rejected
- duplicate/unnormalized paths rejected
- no source mutation
- user-confirmed data remains truth
- low-confidence parser output requires review
- privacy-safe telemetry excludes sensitive data
- generated data is separated from handwritten source audit
- native Android/iOS bridge contracts stay intact
- older/low-storage devices remain usable
- expensive behavior is capability-gated

When a test fails:

1. Stop adding features.
2. Diagnose root cause.
3. Fix the code.
4. Add/adjust regression coverage for the actual bug.
5. Rerun the failed targeted test.
6. Rerun only the relevant broader checks.

Do not move on while a known test is failing.

## Backups And Git Discipline

User asked for pushes every 30 minutes or clean milestone.

Safe backup workflow:

```sh
git status --short
git diff --check
git add -A
git diff --cached --stat
git commit -m "clear milestone message"
git push origin codex/expense-camera-lane
git status --branch --short
```

Only commit after a verified batch. If the worktree contains unknown changes
from another model, do not blindly stage unless the user explicitly wants a
preservation checkpoint. If in doubt, inspect and explain.

Do not use:

```sh
git reset --hard
git checkout -- .
git clean -fd
```

unless the user explicitly asks and understands it will discard work.

## Suggested Next Work Order

Do this in order. Do not drift.

### Pass 1: Manufacturer-Agnostic Runtime Guard

Goal:

- Prove production camera runtime is capability-based, not Samsung-only.

Likely files:

- `test/receipt_native_camera_privacy_diagnostics_test.dart`

Checks:

- targeted analyzer
- focused privacy diagnostics test
- scoped receipt source audit

### Pass 2: Long Receipt Section Ordering Audit

Goal:

- Audit add/retake/remove/reorder flows for stale async selections and diagnostic
  preservation.

Likely files:

- `receipt_photo_review_retake_order.dart`
- `receipt_photo_review_capture_actions.dart`
- `receipt_photo_review_order_actions.dart`
- `receipt_capture_review_result_native_signals.dart`
- related tests

Checks:

- `test/receipt_photo_review_retake_order_test.dart`
- `test/receipt_camera_long_receipt_guidance_test.dart`
- `test/receipt_camera_result_stitch_scanner_test.dart`

### Pass 3: Stitch/Fallback Fixture Strengthening

Goal:

- Improve synthetic long-receipt coverage:
  - overlap present
  - overlap missing
  - duplicate overlap
  - missing middle section
  - unsafe manual overlap
  - max output limits

Likely tests:

- `test/receipt_stitching_test.dart`
- `test/receipt_stitching_manual_overlap_test.dart`
- `test/receipt_stitching_result_contract_test.dart`

### Pass 4: Camera Quality Fixture Expansion

Goal:

- Add or strengthen fixture-style tests for blur, glare, low light, crop, bottom
  missing, text too small, and thermal/faded receipt risk.

Likely tests:

- `test/receipt_camera_quality_guidance_test.dart`
- `test/receipt_camera_result_quality_test.dart`
- `test/receipt_camera_result_best_shot_ocr_test.dart`
- `test/receipt_camera_saved_photo_warning_diagnostics_test.dart`

### Pass 5: Review UX Polish Readiness

Goal:

- Make the capture/review flow ready for a real S24/iPhone style UI check when
  the user asks.

Focus:

- Add Photo/Retake/Done labels.
- Preview dominance.
- No overflow.
- No hidden essential controls.
- Clear simple/detailed mode.
- Clear business/personal/split path.

Do not run device install unless user asks.

## Known Pitfalls

- Do not confuse generated catalog data with handwritten source line caps.
- Do not let OCR source evidence disappear when derived OCR paths differ from
  proof paths.
- Do not let retake/add/insert paths mutate the wrong section after async camera
  return.
- Do not rely on raw file path strings without normalization.
- Do not allow duplicate paths to collapse section identity.
- Do not let malformed numeric diagnostics such as `NaN`, `Infinity`, or string
  equivalents become positive camera evidence.
- Do not leak device manufacturer/model/name in privacy-safe diagnostics.
- Do not make Samsung/Galaxy-specific runtime rules.
- Do not let stock camera UI become the normal production path.
- Do not let compressed proof images become the first OCR source.
- Do not let admin telemetry receive private receipt content.

## Exact Recent Test Evidence To Preserve

The previous model verified these after the latest cleanup batch:

```sh
flutter test test/receipt_photo_review_retake_order_test.dart test/receipt_camera_long_receipt_guidance_test.dart test/receipt_camera_result_stitch_scanner_test.dart -r compact
dart tool/receipt_qa_runner.dart
dart tool/maintainiac_source_audit.dart --max-line-length=220
bash tool/receipt_cleanup_log_gate.sh
bash tool/receipt_doc_size_gate.sh
git diff --check
```

All passed before the checkpoint commit/push.

## If You Only Read One Section

Continue from clean commit `1b65eeab5` on `codex/expense-camera-lane`.

Work the camera foundation, not random expense/inventory features. Start with a
manufacturer-agnostic runtime regression, then keep hardening long-receipt
ordering, stitching/fallback, image quality, OCR-source preservation, and review
handoff. Add real regressions for every bug. Keep privacy clean. Push verified
milestones. Do not delete or revert unknown work.
