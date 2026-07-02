# Receipt Camera OCR Master Pass Plan Archive - Receipt Camera Reopen Pass 949: Accepted Photo Local-First Readiness Handoff

Archived from `docs/receipt_camera_ocr_master_pass_plan.md` to keep the active plan under the 500-line file limit.

### Receipt Camera Reopen Pass 949: Accepted Photo Local-First Readiness Handoff

Status: complete.

What changed:
- Carried local-first receipt readiness diagnostics from accepted receipt-photo
  capture into the receipt reader/details handoff counts.
- Added handoff count buckets for base local reading availability, base
  without cloud assist, local-first readiness code, local-first action code,
  and presence-only local-first user guidance.
- Added privacy-safe metadata fields for the same readiness counts plus top
  readiness/action outcomes so Command1 can later summarize whether the base
  app is protecting low-storage phones without seeing private receipt content.
- Strengthened the accepted-photo result test so a lean-base receipt capture
  proves it will open receipt details next while also reporting that heavy
  offline receipt packs are optional and deferred.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is allowing the local-first readiness
  handoff metadata through expense telemetry and Command1 health summaries.

### Receipt Camera Reopen Pass 950: Command Health Local-First Readiness

Status: complete.

What changed:
- Allowlisted local-first receipt readiness metadata in expense telemetry:
  base local reading availability, base works without cloud assist, readiness
  counts/outcome, action counts/outcome, and presence-only user guidance.
- Aggregated those counters across OCR started/completed and parser
  completed/needs-review/failed events so Command1 can detect when the receipt
  stack is protecting low-storage users or drifting toward a required heavy
  install.
- Added the readiness counters and top readiness/action outcomes to the
  Command1 health snapshot map.
- Strengthened the parser/receipt health test so Command1 reports that a lean
  base can keep local capture and reading available while optional detail packs
  stay deferred.
- Updated telemetry schema expectations so the new Command1 fields cannot be
  dropped accidentally.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `git diff --check -- lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is adding a low-storage camera/OCR
  acceptance gate that fails tests if the base receipt flow requires a large
  offline parser pack before the user can capture, save, or locally review a
  receipt.

### Receipt Camera Reopen Pass 951: Local-Only Receipt Acceptance Gate

Status: complete.

What changed:
- Added a local-only acceptance gate to the receipt brain footprint policy so
  the base app can prove it still supports capture, proof save, and basic local
  receipt review before any heavy offline OCR/parser pack or cloud assist is
  required.
- Added explicit blocked states for capture missing, proof save missing, basic
  local review missing, heavy pack required before capture, cloud required
  before capture, and oversized base footprint review.
- Added privacy-safe diagnostics for local-only acceptance status, next action,
  base-flow readiness, low-storage blocking, and evidence codes.
- Allowed those local-only gate diagnostics through native capture staging,
  accepted-photo receipt reader handoff counts, and Command1 expense telemetry
  without receipt text, vendor names, prices, addresses, file paths, or device
  identifiers.
- Strengthened tests so cramped/low-storage devices must keep the receipt flow
  usable locally while optional packs remain deferred.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_assistance_policy_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_assistance_policy_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_result_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the runtime receipt flow and
  settings surfaces consume the local-only acceptance status so low-storage
  users see a lean default path first, with heavy local OCR/parser packs clearly
  optional instead of silently becoming part of the required camera flow.

### Receipt Camera Reopen Pass 952: Settings Surface Local-Only Readiness

Status: complete.

What changed:
- Added settings-controller getters for the local-only receipt acceptance gate:
  base receipt flow can run locally now, low-storage users are not blocked,
  readiness status/action, and a user-facing readiness summary.
- Surfaced the readiness summary in the receipt proof-size settings area so
  settings explain that receipt capture, proof save, and basic local review work
  before any optional offline OCR/parser pack is downloaded.
- Kept the settings language storage-focused instead of technical compression
  language: saved proof size saves phone/cloud space, while OCR still uses the
  clearest receipt source first.
- Strengthened controller/source tests so the settings surface cannot drop the
  local-only readiness getter, and maximum/strong/balanced data-saver modes all
  prove they do not block low-storage users from the base receipt flow.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart test/receipt_capture_settings_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is making the receipt capture/review
  runtime react to local-only readiness with non-blocking guidance: camera and
  proof save stay available, optional packs/cloud assist are clearly later, and
  no low-storage device gets stranded before a receipt is captured.

### Receipt Camera Reopen Pass 953: Runtime Review Local-Only Guidance

Status: complete.

What changed:
- Updated the receipt details review storage cue to consult the local-only
  acceptance gate before talking about optional parser packs.
- Added a release-blocking runtime cue for any future regression where capture,
  proof save, or basic local review depends on heavy offline packs or cloud
  assist.
- Changed the normal runtime cue to say receipt capture, proof save, and basic
  local review stay available now, while saved proof size does not change the
  clear OCR source used for review.
- Added non-blocking action labels for local review and proof save, plus a
  clear base-flow fix action if low-storage users are blocked.
- Strengthened the assisted receipt review flow contract test so these
  local-only runtime branches and actions cannot disappear silently.

Validation:
- `dart format lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `flutter test test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter analyze lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`
- `git diff --check -- lib/screens/expenses/entry/expense_receipt_parse_review.dart test/expense_receipt_assisted_review_flow_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tying local-only readiness into the
  capture-start/camera settings handoff so the in-app camera receives a clear
  lightweight policy before capture begins, instead of only explaining it after
  OCR review.

### Receipt Camera Reopen Pass 954: Native Launch Local-Only Policy

Status: complete.

What changed:
- Added explicit local-only capture policy getters to the native camera session
  config so Android/iOS do not have to infer low-storage behavior from
  footprint fields.
- Sent local-only policy through native camera launch arguments: capture/save/
  basic review now, heavy packs cannot block capture, cloud assist cannot block
  capture, proof save stays available, and basic review stays available.
- Added the same local-only policy to capture diagnostics returned from the
  native camera service so downstream staging, OCR handoff, and Command1-safe
  telemetry can see whether the native launch obeyed the base-flow rule.
- Strengthened native camera contract tests for both normal and storage-saver
  sessions so the method-channel contract fails if optional OCR/parser packs or
  cloud assist become required before capture.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart test/receipt_native_camera_contract_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is folding the local-only launch policy
  into accepted-photo/capture recovery diagnostics so interrupted low-storage
  captures can be resumed without requiring optional packs or cloud assist.

### Receipt Camera Reopen Pass 955: Staged Capture Local-Only Policy Recovery

Status: complete.

What changed:
- Added the native launch local-only policy keys to the native capture staging
  diagnostic allowlist.
- Preserved local-only capture policy through staged photo diagnostics,
  recovery manifests, and the Hive recovery index.
- Proved interrupted low-storage captures keep the policy that camera, proof
  save, and basic local review remain available before optional offline packs
  or cloud assist.
- Kept the staging/recovery diagnostics privacy-safe: no receipt text, vendor
  names, prices, addresses, file paths, or device identifiers are exposed.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_capture_staging_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_native_capture_staging_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is aggregating the native local-only
  launch/recovery policy into accepted-photo handoff and Command1 health so
  diagnostics can show whether low-storage users ever get blocked before receipt
  review.

### Receipt Camera Reopen Pass 956: Accepted Photo Native Local-Only Handoff

Status: complete.

What changed:
- Added accepted-photo handoff counters for native local-only capture policy,
  base-flow readiness, heavy-pack capture blocking, and cloud-assist capture
  blocking.
- Added a top native local-only capture policy outcome to privacy-safe receipt
  reader metadata.
- Folded the native launch/recovery policy into receipt reader/details handoff
  counts so diagnostics can distinguish policy-summary readiness from the
  actual native camera launch path.
- Strengthened the accepted photo handoff regression so a normal receipt photo
  proves native capture opens receipt details while heavy local packs and cloud
  assist do not block capture.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `flutter test test/receipt_camera_result_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart test/receipt_camera_result_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is allowing the native local-only
  handoff counters through expense telemetry/Command1 health so admin can see
  whether any real camera path blocked low-storage users before receipt review.

### Receipt Camera Reopen Pass 957: Command1 Native Local-Only Telemetry

Status: complete.

What changed:
- Allowed the native local-only capture policy handoff fields through the
  privacy-safe expense telemetry metadata contract.
- Aggregated native local-only capture policy, base-flow readiness, heavy-pack
  capture blocking, and cloud-assist capture blocking into the Command1 health
  snapshot.
- Exposed the top native local-only capture policy and supporting count maps in
  the Command1-safe expense telemetry map.
- Strengthened the parser/category health regression so admin telemetry proves
  the real native camera handoff keeps capture, proof save, and basic receipt
  review available before optional offline packs or cloud assist.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `git diff --check -- lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is tightening the low-storage/base
  install contract around receipt capture so the app can ship a small required
  camera/OCR path while keeping large parser/OCR packs optional or cloud-backed.

### Receipt Camera Reopen Pass 958: First-Install Receipt Brain Boundary

Status: complete.

What changed:
- Added an explicit first-install receipt boundary contract to the receipt
  assistance policy.
- Separated required base receipt capabilities from deferred offline OCR/parser
  packs and optional cloud assist.
- Added boundary status/action codes for blocked first installs, review-sized
  first installs, optional local packs, optional cloud assist, and lean base-only
  installs.
- Added a user-facing boundary summary that explains the required base install,
  optional offline receipt intelligence, and cloud assist without exposing
  private receipt content.
- Allowed the new boundary fields through privacy-safe expense telemetry
  sanitization so future Command1 wiring can inspect the policy without receipt
  text, merchant names, prices, addresses, or file paths.
- Strengthened receipt assistance tests for roomy phones, cramped phones, and
  intentionally oversized first-install receipt brains.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_assistance_policy_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_assistance_policy_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is carrying the first-install boundary
  codes through native capture launch/staging/handoff so every real receipt
  photo can prove it did not require a heavy OCR/parser download before capture.

### Receipt Camera Reopen Pass 959: Native First-Install Boundary Handoff

Status: complete.

What changed:
- Preserved first-install receipt boundary diagnostics through native capture
  staging and interrupted-capture recovery.
- Verified native camera launch arguments include first-install boundary status,
  action, and low-storage readiness from the footprint policy.
- Added accepted-photo aggregation for first-install boundary status, boundary
  action, low-storage readiness, base-capability readiness, and summary
  presence.
- Added first-install boundary buckets to receipt reader/details handoff counts
  so real captured photos can prove they did not require a heavy OCR/parser
  download before capture.
- Added Command1-safe telemetry allowlist/schema entries for the new handoff
  metadata without exposing receipt text, merchant names, prices, addresses, or
  file paths.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart test/receipt_camera_result_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart`
- `flutter test test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_result_test.dart -r compact`
- `flutter test test/expense_screen_telemetry_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/receipt_camera_result_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_models.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_camera_result_test.dart test/receipt_native_camera_contract_test.dart test/receipt_native_capture_staging_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is aggregating first-install boundary
  health inside Command1 snapshots so admin can see whether any device class or
  capture path is drifting toward a mandatory heavy receipt download.

### Receipt Camera Reopen Pass 960: Command1 First-Install Boundary Health

Status: complete.

What changed:
- Aggregated first-install boundary status, boundary action, low-storage
  readiness, base-capability readiness, and summary presence into the expense
  Command1 health snapshot.
- Exposed first-install boundary counts and top outcomes in the Command1-safe
  telemetry map.
- Strengthened the parser/category health regression so Command1 can show
  whether real receipt handoffs are staying on the lean base install or drifting
  toward a mandatory heavy OCR/parser download.
- Kept the aggregation privacy-safe: no receipt text, merchant names, prices,
  addresses, photo paths, or device identifiers are surfaced.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter analyze lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `git diff --check -- lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is using the first-install boundary in
  runtime review/settings copy so users understand that capture works now while
  larger offline receipt packs are optional.

### Receipt Camera Reopen Pass 961: First-Install Boundary Settings Copy

Status: complete.

What changed:
- Added a settings-controller summary for the first-install receipt boundary.
- Surfaced that summary in the receipt saved-proof/data-saver settings section.
- Added the same boundary summary to receipt review storage cues so users are
  told they can continue with capture/basic review now while larger offline
  receipt packs remain optional.
- Strengthened settings tests so the UI source and controller both expose the
  first-install boundary without raw device details.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_capture_settings_store_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart test/expense_receipt_assisted_review_flow_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_capture_settings_store_test.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/screens/expenses/entry/expense_receipt_parse_review.dart test/receipt_capture_settings_store_test.dart`

Next camera/OCR focus:
- Continue camera/OCR only. Next target is hardening base receipt capture
  storage checks so proof saving remains available on very low-storage phones
  without keeping unnecessary originals.

### Receipt Camera Reopen Pass 962: Install Footprint Strategy Guard

Status: complete.

What changed:
- Added a dedicated receipt install-footprint strategy that separates the required capture shell from optional offline receipt intelligence.
- Classified required receipt install size, full-offline receipt brain size, low-storage user impact, and recommended distribution mode.
- Made the privacy-safe diagnostics show whether the camera shell is parser-free, whether the base flow is still useful on tiny phones, and whether optional offline packs require explicit user consent.
- Strengthened the receipt assistance tests for cramped-phone, roomy-phone, and oversized-release cases so a large OCR/parser brain cannot silently become mandatory before capture.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart test/receipt_assistance_policy_test.dart`
- `flutter test test/receipt_assistance_policy_test.dart -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is carrying this install-footprint strategy through settings/staging/Command1 so we can see if any device class is being pushed toward a too-large required receipt install.

### Receipt Camera Reopen Pass 963: Install Footprint Settings And Privacy Plumbing

Status: complete.

What changed:
- Added a settings-controller install footprint summary so users can see that first install covers receipt capture, proof save, manual entry, and basic local reading while stronger offline receipt help stays optional.
- Surfaced that summary in the receipt scanner settings area without exposing raw hardware or private receipt data.
- Allowlisted privacy-safe install-footprint diagnostic fields through native capture staging and expense telemetry sanitization.
- Kept free-form receipt content blocked; user-facing install summaries are sanitized readable text, not raw receipt data.

Validation:
- `dart format lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_capture_settings_store_test.dart test/expense_screen_telemetry_test.dart`
- `flutter test test/receipt_capture_settings_store_test.dart test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart -r compact`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is aggregating receipt install-footprint strategy into Command1 counts and top outcomes so admin can see whether real devices are staying on a lean first-install path.

### Receipt Camera Reopen Pass 964: Command1 Install Footprint Health

Status: complete.

What changed:
- Aggregated receipt install-footprint strategy into the expense Command1 health snapshot.
- Added counts for required install segment, full-offline segment, low-storage impact, recommended distribution, parser-free camera shell, tiny-phone usefulness, and optional-pack consent.
- Added top Command1 outcomes for install distribution and low-storage impact.
- Strengthened schema expectations and telemetry tests so these size/pack health fields cannot disappear without a test failure.
- Kept the telemetry privacy-safe: only codes, counts, booleans, and sanitized install summaries are allowed; receipt text, merchant names, prices, paths, and device identifiers remain blocked.

Validation:
- `dart format lib/screens/expenses/data/expense_screen_telemetry.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `flutter test test/expense_screen_telemetry_test.dart -r compact`
- `flutter test test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/expense_screen_telemetry_test.dart test/receipt_native_capture_staging_test.dart -r compact`
- `flutter analyze lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart`
- `git diff --check -- lib/shared/widgets/receipt_capture/receipt_assistance_policy.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_store.dart lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart lib/shared/widgets/receipt_capture/receipt_native_capture_staging.dart lib/screens/expenses/data/expense_screen_telemetry.dart test/receipt_assistance_policy_test.dart test/receipt_capture_settings_store_test.dart test/expense_screen_telemetry_test.dart test/helpers/expense_telemetry_schema_expectations.dart docs/receipt_camera_ocr_master_pass_plan.md`

Next camera/OCR focus:
- Continue local camera/OCR/parser only. Next target is using install-footprint and storage class directly in receipt capture/review decisions so low-storage devices stay on the lean proof/basic-read path and full offline packs remain explicit.
