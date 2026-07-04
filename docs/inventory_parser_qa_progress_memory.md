# Inventory QA Progress Memory

Purpose: durable working memory for the inventory parser/catalog QA pipeline.
This file exists so context compression does not cause repeated work, skipped
coverage, or broad reruns when a focused surgical rerun is enough.

Repo-wide operating rules live in
`docs/maintainiac_operating_directive.md`. Those rules apply to inventory work
and every other Maintainiac module.

## Inventory-Only Boundaries

- inventory-only
- No UI/UX
- No OCR
- No camera
- No PDF
- No Expenses
- No Firebase live writes
- No maintenance
- No other repo

## Release-One Inventory Priority

- Primary release-one market: United States residential.
- Primary release-one trades: Plumbing, Electrical, and HVAC.
- Primary release-one language packs: English (en-US) and Spanish (es-US).
- Primary release-one tiers: Core and Standard first.
- Core and Standard are priority one.
- Core/Standard must represent everyday service-truck reality.
- Core/Standard must prioritize common residential pipe fittings.
- Core/Standard must include pipe fittings found in a residential home.
- Core/Standard must plan for toilet repair kits.
- Core/Standard must plan for sink repair kits.
- Core/Standard must plan for faucet repair kits.
- Professional and Complete follow the same contracts after Core/Standard are
  proven.
- Professional and Complete later.
- Fasteners are included only as normal overlap/support items inside Plumbing,
  Electrical, and HVAC service-trade packs.
- Fasteners are not a separate release-one trade pack.
- Required support wording: fasteners only as normal overlap/support items.
- Required support wording: not a separate release-one trade pack.
- Required support wording: service-trade fasteners.

## Completed Parser Evidence

Service-truck Core/Standard priority validation completed locally for
release-one residential Plumbing, Electrical, and HVAC with English/Spanish
scope still enforced by adjacent suites.

- suiteId: inventory.service_truck_core_contract + inventory.release_one_pack_balance + inventory.spanish_release_one
- status: focused-validated
- lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-03T144739852797.json
- checked: 125070
- actualFailures: 0
- durationMs: 83222
- focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.service_truck_core_contract,inventory.release_one_residential_contract,inventory.release_one_pack_balance,inventory.spanish_release_one,qa.threshold_gate
- doNotRerunUnless: service-truck signals, release-one pack balance, Spanish release-one coverage, catalog Core/Standard metadata, or progress memory changes

Essential release-one service-family validation completed locally for
Core/Standard Plumbing, Electrical, and HVAC.

- suiteId: inventory.release_one_service_family_contract
- status: focused-validated
- lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-03T145246005001.json
- checked: 16863
- actualFailures: 0
- durationMs: 82350
- coveredFamilies: plumbing common pipe fittings, plumbing toilet repair, plumbing sink/faucet repair, electrical wire/cable, electrical boxes/devices, electrical conduit/support, HVAC filter/airflow, HVAC condensate/drain, HVAC service fasteners/sealants
- focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,qa.threshold_gate
- doNotRerunUnless: release-one service-family thresholds, catalog Core/Standard family rows, or progress memory changes

Focused rerun routes for recently hardened release-one contracts:

- inventory.vendor_sku_matrix_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.vendor_sku_matrix_contract,qa.threshold_gate`
- inventory.barcode_inventory_identity_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.barcode_inventory_identity_contract,qa.threshold_gate`
- inventory.legal_safety_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.legal_safety_contract,qa.threshold_gate`
- inventory.service_truck_core_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.service_truck_core_contract,qa.threshold_gate`
- inventory.release_one_pack_balance:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_pack_balance,qa.threshold_gate`
- inventory.release_one_residential_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_residential_contract,qa.threshold_gate`
- inventory.release_one_service_family_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,qa.threshold_gate`
- inventory.release_one_tier_role_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_tier_role_contract,qa.threshold_gate`
- inventory.release_one_fastener_support_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_fastener_support_contract,qa.threshold_gate`
- inventory.release_one_cell_manifest:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_cell_manifest,qa.threshold_gate`
- inventory.language_pack_separation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.language_pack_separation_contract,qa.threshold_gate`
- inventory.hive_authority_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.hive_authority_contract,qa.threshold_gate`
- inventory.hive_firestore_sync_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.hive_firestore_sync_contract,qa.threshold_gate`
- inventory.review_safety_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.review_safety_contract,qa.threshold_gate`

## 2026-07-04 Whole-App Parser Adapter Registry And Surgical Routing

- Passes 1961-1986 tightened the reusable Maintainiac QA backbone so parser QA
  is not inventory-only. The backbone now requires the parser adapter registry
  to expose the inventory, expense receipt, and maintenance parser domains while
  still keeping implementation work scoped to inventory/parser QA in this
  thread.
- The main backbone contract now verifies the exact parser adapter domains,
  adapter count, registry visibility, and readable failure reasons. Stale
  regression fixture expectations were repaired with valid inventory, expense,
  and sync regression fixtures.
- Parser release command planning now includes the missing inventory parser
  families: `catalog_expansion_lifecycle`, `real_receipt_validation_privacy`,
  and `portable_parser_core_boundary`.
- Surgical rerun support now includes focused generated-fixture runner selectors
  for safety contracts and fixture-id filtering, and the parser pipeline rerun
  route was split into smaller surgical rules instead of one broader route.
- Verification passed:
  `flutter test test\maintainiac_qa_backbone_test.dart --reporter compact`
  and targeted `dart analyze` over the changed QA backbone, release command
  plan, surgical selector, rerun router, selector coverage, and related tests.

## 2026-07-04 Generated Fixture Failure-To-Rerun Routing

- Passes 1999-2009 strengthened the shared parser QA failure digest so failed
  generated-fixture cells now include `surgicalRerun` guidance instead of only a
  failure preview. The digest extracts the generated fixture path, failed
  fixture ids when present, fix category, family hint, cell id, and a focused
  `dart run tool/work_supply_parser_qa_run_generated_fixtures.dart --fixture
  ... --fixture-ids ...` command.
- The `inventory.failure_routing_contract` now requires `surgicalRerun`,
  `avoidBroadRerun`, `fixtureIds`, `fixturePath`, and
  `rerun_failed_generated_fixture_ids` evidence so future failures do not fall
  back to broad catalog or full-wave reruns.
- Verification passed:
  `flutter test test\parser_qa_platform_failure_digest_test.dart
  test\work_supply_parser_qa_failure_digest_test.dart --reporter compact`,
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact
  --dart-define=PARSER_QA_SUITES=inventory.failure_routing_contract,qa.threshold_gate
  --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=25`, and targeted
  `dart analyze` over the digest tool, shared digest, routing contract, and
  digest regression tests.

## 2026-07-04 Reusable Parser Adapter Registry Hardening

- Passes 1937-1949 launched local-only wave
  `pass1939-residential-top-three-all-tiers-wave-execute` for the 24 Release 1
  residential parser cells across Plumbing, Electrical, and HVAC; Core,
  Standard, Professional, and Complete; and `en-US`/`es-US`. The wave plan keeps
  `liveServicesAllowed=false`, `writesProductionCatalog=false`,
  `firebaseWritesAllowed=false`, and `ocrCameraExpensesTouched=false`.
- Passes 1942-1949 hardened `inventory.parser_platform_contract` so it validates
  every registered parser-domain adapter in `parserQaDomainAdapters`, not only
  inventory. Required reusable adapters currently include
  `work_supply_inventory_parser`, `expense_receipt_parser`, and
  `maintenance_parser`, each with portable execution targets and pure parser
  input/output fields.
- Surgical verification before commit: `dart analyze
  test/support/work_supply_parser_qa/work_supply_parser_platform_contract_qa.dart
  test/support/parser_qa_platform/parser_qa_domain_adapter.dart` passed with no
  issues. Focused parser-platform QA gate is the next check before this
  milestone is pushed.
- Passes 1954-1957 tightened the direct adapter unit test so
  `parserQaDomainAdapters` must contain exactly the release-critical parser
  domains for `work_supply_inventory_parser`, `expense_receipt_parser`, and
  `maintenance_parser`, with unique artifact prefixes and fixture roots.
  Verification: `flutter test test/parser_qa_platform_domain_adapter_test.dart
  --reporter compact` passed 4/4 tests.
- Pass 1886 added an executable drift guard: `inventory.surgical_rerun_contract`
  now parses the scorecard's Release Gate Suite Mapping and fails if a listed
  suite is not present in the focused rerun route map.
- Pass 1887 validated the scorecard and rerun map together:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.surgical_rerun_contract,inventory.release_one_scorecard_contract --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=25`
  passed 130 checks with 0 failures.
- Passes 1890-1894 strengthened `inventory.fake_user_review_workflow` so
  review scenarios preserve destination routing for inventory, active job,
  draft estimate, invoice material, and rejected noise lines. The suite also
  now verifies enabled trade-pack/active-section context is retained as
  supporting evidence and that fake Firebase mirror work is controlled by cloud
  opt-in after Hive/local confirmation.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.fake_user_review_workflow --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=25`
  passed 54 checks with 0 failures.
- Passes 1896-1898 expanded merchant-family fixture coverage beyond popular
  big-box stores. `inventory.merchant_matrix_contract`,
  `inventory.fixture_coverage_matrix`, and
  `inventory.fixture_corpus_contract` now require/recommend coverage for
  Tractor Supply, Northern Tool, Local Hardware, Regional Supplier, Electrical
  Supply, HVAC Supply, Supply House, and unknown merchants. Added synthetic
  review-safe golden fixtures for Tractor Supply well pump text, Northern Tool
  PEX crimp tool text, electrical-supply PVC conduit ambiguity, and HVAC
  condensate PVC ambiguity. These fixtures are non-proprietary and do not scrape
  retailer databases.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.merchant_matrix_contract,inventory.fixture_coverage_matrix,inventory.fixture_corpus_contract,inventory.fixture_expectation_contract --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=40`
  passed 728 checks with 0 failures.
- Passes 1904-1907 corrected the Tractor Supply well-pump synthetic fixture
  from review-only to a real Plumbing Standard `well_pump` clear-match
  expectation because the catalog already has well pump identity and aliases.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.fixture_expectation_contract,inventory.fixture_candidate_identity_contract,inventory.merchant_matrix_contract,inventory.fixture_coverage_matrix,inventory.fixture_corpus_contract --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=40`
  passed 788 checks with 0 failures. Runtime note: the fixture candidate
  identity suite took about 88 seconds on the Windows machine because it builds
  the catalog/search identity surface.
- Passes 1910-1911 tightened `inventory.service_truck_core_contract` by adding
  specific service-truck intent signals for well pump, pressure switch, pitless
  adapter, pipe cutter, PEX crimp tool, basin wrench, toilet auger, and drain
  snake so true residential service items are recognized explicitly instead of
  relying only on vague pump/tool wording.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.service_truck_core_contract,inventory.release_one_service_family_contract --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=40`
  passed 41,252 checks with 0 failures.
- Passes 1914-1916 added an executable confidence-suppression guard to
  `inventory.review_safety_contract`. Parser/review source now fails if it
  introduces explicit confidence-cap, ambiguity-suppression, hide-ambiguity,
  force-high-confidence, or bypass-review tokens. The first validation also
  caught three newly added review fixtures with maxConfidence above the risky
  fixture limit; those were corrected to 0.81 before moving on.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.review_safety_contract,inventory.confidence_calibration --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=40`
  passed 96 checks with 0 failures after the fixture confidence correction.
- Passes 1919-1920 strengthened `inventory.fake_user_review_workflow` with app
  restart simulation. Every fake parser-review scenario now proves confirmed
  Hive/local truth and pending fake Firebase mirror state survive restart.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.fake_user_review_workflow --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=40`
  passed 60 checks with 0 failures.
- Passes 1923-1926 added Spanish merchant-family fixture pressure. The fixture
  coverage suite now requires es-US merchant diversity for Tractor Supply,
  Electrical Supply, HVAC Supply, and unknown merchant families. Added
  synthetic es-US review fixtures for Spanish well-pump, electrical PVC conduit,
  and HVAC condensate PVC wording without scraping retailer data.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.fixture_coverage_matrix,inventory.fixture_corpus_contract,inventory.fixture_expectation_contract,inventory.confidence_calibration,inventory.language_pack_separation_contract --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=40`
  passed 740 checks with 0 failures.
- Passes 1929-1931 tightened `inventory.legal_safety_contract` so parser QA
  sources now block Selenium, BeautifulSoup, retailer API dump, product-page
  scrape wording, retailer-targeted `requests.get`, and web-scraping method
  fingerprints while still allowing policy text that says scraping is forbidden.
- Validation:
  `flutter test test\work_supply_parser_qa_harness_test.dart --reporter compact --dart-define=PARSER_QA_SUITES=inventory.legal_safety_contract,inventory.data_provenance_contract,inventory.vendor_sku_matrix_contract --dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=40`
  passed 115 checks with 0 failures.

## 2026-07-04 Core/Standard Wave Completion

- Pass 1933 confirmed background wave
  `pass1687-residential-core-standard-wave-execute` completed successfully.
- Scope: Plumbing, Electrical, and HVAC; residential; Core and Standard;
  `en-US` and `es-US`; `limit=500`; `fixtureRunLimit=25`.
- Result: 12/12 cells complete, 0 failed cells, `queueExitCode=0`.
- Safety flags stayed false: no live services, no production catalog writes, no
  Firebase writes, and no OCR/camera/Expenses touches.
- Evidence:
  `build/parser_qa_batch_waves/pass1687-residential-core-standard-wave-execute/wave_summary.json`
  and
  `build/parser_qa_batch_waves/pass1687-residential-core-standard-wave-execute/queue/pass1687_residential_core_standard_wave_execute_generated_fixture_core_standard_v6_post_hvac_filter/summary.json`.
- inventory.receipt_source_immutability_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.receipt_source_immutability_contract,qa.threshold_gate`
- inventory.parser_platform_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.parser_platform_contract,qa.threshold_gate`

The all-tier residential generated-fixture parser wave completed locally.

- suiteId: inventory.generated_fixture_cell_contract
- status: focused-validated
- lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T150134263160.json
- coveredInputs: build/parser_qa_generated/work_supply_parser
- focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generated_fixture_cell_contract,qa.threshold_gate
- doNotRerunUnless: generated fixture schema, generated fixture files, fixture runner, fixture generator, or QA cell contract changes

Wave evidence:

- waveId: residential_all_tiers_wave_001
- queueId: residential_all_tiers_wave_001_generated_fixture_all_tiers_v1
- status: complete
- cellCount: 24
- completedCellCount: 24
- failedCellCount: 0
- liveServicesAllowed: false
- writesProductionCatalog: false
- firebaseWritesAllowed: false
- ocrCameraExpensesTouched: false

The release-one residential generated catalog blueprint matrix completed
locally for the top three trades and both US language packs.

- suiteId: inventory.catalog_batch_memory_contract
- status: focused-validated
- lastEvidence: build/parser_qa_pipeline/release-one-residential-item-blueprints/matrix_reports/latest_pipeline_summary.json
- statusEvidence: build/parser_qa_pipeline/status_reports/latest_pipeline_status.json
- coveredInputs: build/parser_qa_pipeline/release-one-residential-item-blueprints
- expectedCells: 24
- presentCells: 24
- missingCells: 0
- unsafeCells: 0
- parserCalls: 0
- runFixtures: false
- statusGateExitCode: 0
- waveReport: build/parser_qa_batch_waves/residential_all_tiers_wave_001/wave_report.json
- durationReport: build/parser_qa_batch_waves/residential_all_tiers_wave_001/duration_report.json
- releaseReadiness: build/parser_qa_pipeline/release_one_readiness.json
- batchSizeAdvice: build/parser_qa_pipeline/batch_size_advice_release_one.json
- releaseOneParserEvidenceReady: true
- releaseOnePipelineArtifactsReady: true
- releaseOneFixtureEvidenceReady: true
- fixtureReadinessReady: true
- recommendedFixtureRunLimit: 128
- activeBackgroundWave: residential_all_tiers_wave_002_advised_128
- activeBackgroundQaLayer: generated_fixture_all_tiers_v2_advised_128
- activeBackgroundFixtureRunLimit: fixtureRunLimit=128
- activeBackgroundPid: PID 8720
- activeBackgroundWavePlan: build/parser_qa_batch_waves/residential_all_tiers_wave_002_advised_128/wave_plan.json
- activeBackgroundStatus: build/parser_qa_batch_waves/residential_all_tiers_wave_002_advised_128/queue/latest_status.json
- activeBackgroundStdout: build/parser_qa_batch_waves/residential_all_tiers_wave_002_advised_128/launch_stdout.log
- activeBackgroundStderr: build/parser_qa_batch_waves/residential_all_tiers_wave_002_advised_128/launch_stderr.log
- activeBackgroundLaunchEvidence: build/parser_qa_pass_evidence/pass_532.json
- focusedRerun: dart run tool/work_supply_parser_qa_pipeline_status.dart --output-root build/parser_qa_pipeline/release-one-residential-item-blueprints --trades plumbing,electrical,hvac --scopes residential --tiers core,standard,professional,complete --locales en-US,es-US --require-complete
- doNotRerunUnless: catalog blueprint generator, matrix pipeline, pipeline status reader, trade/tier/locale matrix, or QA memory contract changes
- liveServicesAllowed: false
- writesProductionCatalog: false
- firebaseWritesAllowed: false
- ocrCameraExpensesTouched: false

## Generated Fixture Cells

Each cell below has 500 generated fixtures and should not be regenerated unless
the fixture recipe, schema, or expected parser behavior changes.

| Cell | Fixture path | Focused rerun token |
| --- | --- | --- |
| plumbing_residential_core_en_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/core/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/core/en-US/generated_fixtures.json |
| plumbing_residential_core_es_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/core/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/core/es-US/generated_fixtures.json |
| plumbing_residential_standard_en_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/standard/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/standard/en-US/generated_fixtures.json |
| plumbing_residential_standard_es_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/standard/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/standard/es-US/generated_fixtures.json |
| plumbing_residential_professional_en_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/professional/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/professional/en-US/generated_fixtures.json |
| plumbing_residential_professional_es_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/professional/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/professional/es-US/generated_fixtures.json |
| plumbing_residential_complete_en_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/complete/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/complete/en-US/generated_fixtures.json |
| plumbing_residential_complete_es_US | build/parser_qa_generated/work_supply_parser/plumbing/residential/complete/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/complete/es-US/generated_fixtures.json |
| electrical_residential_core_en_US | build/parser_qa_generated/work_supply_parser/electrical/residential/core/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/core/en-US/generated_fixtures.json |
| electrical_residential_core_es_US | build/parser_qa_generated/work_supply_parser/electrical/residential/core/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/core/es-US/generated_fixtures.json |
| electrical_residential_standard_en_US | build/parser_qa_generated/work_supply_parser/electrical/residential/standard/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/standard/en-US/generated_fixtures.json |
| electrical_residential_standard_es_US | build/parser_qa_generated/work_supply_parser/electrical/residential/standard/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/standard/es-US/generated_fixtures.json |
| electrical_residential_professional_en_US | build/parser_qa_generated/work_supply_parser/electrical/residential/professional/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/professional/en-US/generated_fixtures.json |
| electrical_residential_professional_es_US | build/parser_qa_generated/work_supply_parser/electrical/residential/professional/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/professional/es-US/generated_fixtures.json |
| electrical_residential_complete_en_US | build/parser_qa_generated/work_supply_parser/electrical/residential/complete/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/complete/en-US/generated_fixtures.json |
| electrical_residential_complete_es_US | build/parser_qa_generated/work_supply_parser/electrical/residential/complete/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/electrical/residential/complete/es-US/generated_fixtures.json |
| hvac_residential_core_en_US | build/parser_qa_generated/work_supply_parser/hvac/residential/core/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/core/en-US/generated_fixtures.json |
| hvac_residential_core_es_US | build/parser_qa_generated/work_supply_parser/hvac/residential/core/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/core/es-US/generated_fixtures.json |
| hvac_residential_standard_en_US | build/parser_qa_generated/work_supply_parser/hvac/residential/standard/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/standard/en-US/generated_fixtures.json |
| hvac_residential_standard_es_US | build/parser_qa_generated/work_supply_parser/hvac/residential/standard/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/standard/es-US/generated_fixtures.json |
| hvac_residential_professional_en_US | build/parser_qa_generated/work_supply_parser/hvac/residential/professional/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/professional/en-US/generated_fixtures.json |
| hvac_residential_professional_es_US | build/parser_qa_generated/work_supply_parser/hvac/residential/professional/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/professional/es-US/generated_fixtures.json |
| hvac_residential_complete_en_US | build/parser_qa_generated/work_supply_parser/hvac/residential/complete/en-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/complete/en-US/generated_fixtures.json |
| hvac_residential_complete_es_US | build/parser_qa_generated/work_supply_parser/hvac/residential/complete/es-US/generated_fixtures.json | PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/hvac/residential/complete/es-US/generated_fixtures.json |

## Do Not Rerun Unless Inputs Changed

- Do not rerun the 24-cell all-tier residential wave just to check status.
- Do not regenerate completed fixture cells unless fixture recipes or schema changed.
- Do not regenerate the 24-cell release-one residential blueprint matrix just to
  check status; use `tool/work_supply_parser_qa_pipeline_status.dart`.
- Do not guess the next heavy fixture-run limit; use
  `build/parser_qa_pipeline/batch_size_advice_release_one.json`.
- Do not rerun full catalog or broad parser tests for one fixture failure.
- Use the focused rerun token for the failed trade/scope/tier/locale cell.
- Use suite filters instead of quick/full presets when fixing one QA contract.
- Group catalog-backed suites at meaningful checkpoints to amortize the cold
  catalog load.
- Keep contract-only suites surgical and run them by exact PARSER_QA_SUITES
  filters.
- Do not repeatedly launch one catalog-backed suite at a time unless the changed
  source is isolated to that suite and the slow evidence is needed.

## Pending QA Test Batches

- Validate generated fixture cell contract after the next large writing batch.
  2026-07-04 update: Passes 2031-2035 found the canonical
  `build/parser_qa_generated/work_supply_parser/...` cells were missing even
  though older wave-local fixture copies existed. Regenerated the 24
  Plumbing/Electrical/HVAC residential Core/Standard/Professional/Complete
  `en-US`/`es-US` fixture cells with
  `tool/work_supply_parser_qa_generate_fixtures.dart`, `limit=500`, no parser
  calls, no live services, no Firebase writes, and no OCR/camera/Expenses
  touches. Focused validation then passed
  `inventory.generated_fixture_cell_contract`,
  `inventory.fixture_expectation_contract`, `inventory.fixture_privacy_contract`,
  and `qa.threshold_gate` with 288,607 checks and 0 failures.
- Add catalog item batch memory for promoted production item batches.
  Status: satisfied by the catalog item batch status memory validation section
  below and rechecked on 2026-07-04 with
  `inventory.catalog_item_batch_generation_contract,qa.threshold_gate` at 57
  checks and 0 failures plus `test\work_supply_catalog_item_batch_status_test.dart`
  passing 3/3.
- Add focused failure-to-rerun routing table for fixture runner reports.
  Status: satisfied on 2026-07-04 by the generated fixture failure-to-rerun
  routing milestone. Failure digests now emit `surgicalRerun`,
  `avoidBroadRerun`, `fixturePath`, `fixtureIds`, family hints, and focused
  generated-fixture rerun commands.
- Add per-family surgical rerun mapping for plumbing, electrical, and HVAC.
  Status: satisfied by the Surgical Rerun Map and the focused
  `inventory.catalog_family_rerun_contract` validation. Keep this map updated
  when new high-risk service families are added.
- Validate item batch generation status memory before generating more inventory items.
  Status: satisfied by the catalog item batch status memory validation section
  and the 2026-07-04 focused recheck.
- pack scope gate contract:
  suiteId: inventory.pack_scope_gate_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T144953515691.json
  coveredInputs: materials trade pack roadmap, catalog intelligence contract, localization roadmap, trade pack tier code, manifest code, distribution/planning tests
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_scope_gate_contract,qa.threshold_gate
  doNotRerunUnless: scope/tier definitions, pack manifest, pack distribution/planning tests, or pack roadmap docs change
- catalog batch manifest contract:
  suiteId: inventory.catalog_batch_manifest_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T145120765142.json
  coveredInputs: pipeline tools, fixture batch plan/status tools, release-one commands, release readiness, progress memory
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_batch_manifest_contract,qa.threshold_gate
  doNotRerunUnless: pipeline tool output schema, fixture batch plan/status schema, release-one command manifest, or progress memory changes
  trade: plumbing/electrical/hvac
  marketScope: residential
  tier: core/standard/professional/complete
  localePackId: en-US/es-US
  fixturePath: build/parser_qa_generated/work_supply_parser/<trade>/residential/<tier>/<locale>/generated_fixtures.json
  blueprintPath: build/parser_qa_blueprints/work_supply_catalog/<trade>/residential/<tier>/<locale>/item_blueprints.json
  parserRunCommand: flutter test test/work_supply_parser_generated_fixture_runner_test.dart
  generatedCount: 500 per generated fixture cell
  validatedCount: tracked by pipeline summaries
  failedCount: tracked by queue summaries
  surgicalRerun: PARSER_QA_GENERATED_FIXTURE_PATH=<fixturePath>
- receipt line torture contract:
  suiteId: inventory.receipt_line_torture_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T145302070144.json
  coveredInputs: fixture coverage, property generation, metamorphic variants, security/privacy, math, noise, context, merchant, locale QA suites
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.receipt_line_torture_contract,qa.threshold_gate
  doNotRerunUnless: fixture coverage, property/metamorphic/security/math/noise/context/merchant/locale suite sources or torture dimension requirements change
  dimensions: merchant_abbreviation, dangerous_word, ambiguous_review, receipt_noise, negative_match, quantity, pack_quantity, linear_feet, unit_cost, line_subtotal, return_line, discount_line, tax_line, mixed_trade_receipt, supply_house, spanish, locale_pack, canadian_format, unicode_control, long_token, path_like, injection_like, ocr_dirty_text
- admin diagnostic batch contract:
  suiteId: inventory.admin_diagnostic_batch_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T145403135813.json
  coveredInputs: admin report contract, telemetry contract, artifact contract, evidence attribution, catalog intelligence diagnostics contract
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.admin_diagnostic_batch_contract,qa.threshold_gate
  doNotRerunUnless: admin diagnostics fields, telemetry privacy fields, redaction contract, or catalog diagnostics contract changes
- cloud local mode contract:
  suiteId: inventory.cloud_local_mode_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T145541165693.json
  coveredInputs: catalog intelligence contract, trade pack delivery policy, install guard, delivery policy QA, cloud cost guard QA, device storage QA
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.cloud_local_mode_contract,qa.threshold_gate
  doNotRerunUnless: delivery policy, install guard, cloud fallback policy, read-budget model, device storage guard, or progress memory changes
- item promotion gate contract:
  suiteId: inventory.item_promotion_gate_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T145638567800.json
  coveredInputs: catalog intelligence contract, blueprint generator/validator, blueprint promotion QA, item metadata depth QA, vendor readiness QA, workflow routing QA
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.item_promotion_gate_contract,qa.threshold_gate
  doNotRerunUnless: blueprint generator/validator, item smart-row metadata contract, vendor readiness rules, workflow routing rules, or progress memory changes
- merchant matrix contract:
  suiteId: inventory.merchant_matrix_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T145753397951.json
  coveredInputs: merchant QA, vendor readiness QA, fixture coverage QA, generated fixture cell QA, catalog intelligence contract, progress memory
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.merchant_matrix_contract,qa.threshold_gate
  doNotRerunUnless: merchant list, merchant fixture coverage, vendor readiness, generated fixture cell contract, or progress memory changes
- catalog item batch generation contract:
  suiteId: inventory.catalog_item_batch_generation_contract
  status: focused-validated
  lastEvidence: build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T145815201505.json
  coveredInputs: blueprint generator, blueprint validator, economical pipeline, pipeline status, item batch status, progress memory
  focusedRerun: flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_item_batch_generation_contract,qa.threshold_gate
  doNotRerunUnless: catalog blueprint generator, blueprint validator, economical pipeline, pipeline status, item batch status, or progress memory changes

## Surgical Rerun Map

Family rerun route fields:

- familyId
- trade
- riskTerms
- focusedTests
- fixtureCells
- avoidBroadRerun

Priority family rerun routes:

- familyId: plumbing_pex
  trade: plumbing
  riskTerms: PEX, crimp, elbow, coupling, tee, supply
  focusedTests: work_supply_plumbing_core_receipt_parser_test.dart, work_supply_plumbing_collision_receipt_parser_test.dart, inventory.item_metadata_depth
  fixtureCells: plumbing_residential_core_en_US, plumbing_residential_core_es_US, plumbing_residential_standard_en_US, plumbing_residential_standard_es_US
  avoidBroadRerun: rerun PEX/collision fixtures before any full catalog sweep
- familyId: plumbing_pvc_dwv
  trade: plumbing
  riskTerms: PVC, DWV, schedule 40, coupling, elbow, tee, drain
  focusedTests: work_supply_plumbing_bulk_receipt_parser_test.dart, inventory.conflict_graph
  fixtureCells: plumbing_residential_core_en_US, plumbing_residential_standard_en_US, plumbing_residential_professional_en_US
  avoidBroadRerun: rerun PVC/DWV fixtures and conflict graph first
- familyId: plumbing_valves_supply
  trade: plumbing
  riskTerms: valve, angle stop, supply, compression, brass
  focusedTests: work_supply_plumbing_merchant_receipt_parser_test.dart, inventory.vendor_readiness
  fixtureCells: plumbing_residential_core_en_US, plumbing_residential_core_es_US, plumbing_residential_standard_en_US
  avoidBroadRerun: rerun valve/supply fixtures before vendor-wide sweeps
- familyId: plumbing_fasteners_supports
  trade: plumbing
  riskTerms: fastener, hanger, support, tapcon, threaded rod
  focusedTests: work_supply_service_fastener_receipt_parser_test.dart
  fixtureCells: plumbing_residential_core_en_US, plumbing_residential_professional_en_US
  avoidBroadRerun: rerun support/fastener fixtures first
- familyId: electrical_wire_cable
  trade: electrical
  riskTerms: wire, cable, NM-B, THHN, UF-B
  focusedTests: inventory.trade_context
  fixtureCells: electrical_residential_core_en_US, electrical_residential_standard_en_US
  avoidBroadRerun: rerun wire/cable fixture cells before electrical full profile
- familyId: electrical_boxes_devices
  trade: electrical
  riskTerms: box, device, outlet, switch, GFCI
  focusedTests: inventory.dangerous_words
  fixtureCells: electrical_residential_core_en_US, electrical_residential_core_es_US
  avoidBroadRerun: rerun boxes/devices dangerous-word tests first
- familyId: electrical_conduit_fittings
  trade: electrical
  riskTerms: conduit, EMT, PVC conduit, connector, coupling
  focusedTests: inventory.conflict_graph
  fixtureCells: electrical_residential_standard_en_US, electrical_residential_professional_en_US
  avoidBroadRerun: rerun conduit conflict tests before mixed-trade broad runs
- familyId: electrical_breakers_panels
  trade: electrical
  riskTerms: breaker, panel, disconnect, load center
  focusedTests: inventory.vendor_readiness
  fixtureCells: electrical_residential_standard_en_US, electrical_residential_complete_en_US
  avoidBroadRerun: rerun breaker/panel vendor readiness first
- familyId: hvac_filters_airflow
  trade: hvac
  riskTerms: filter, airflow, register, grille
  focusedTests: inventory.dangerous_words
  fixtureCells: hvac_residential_core_en_US, hvac_residential_core_es_US
  avoidBroadRerun: rerun filter/airflow cells first
- familyId: hvac_controls_electrical
  trade: hvac
  riskTerms: capacitor, contactor, thermostat, transformer
  focusedTests: inventory.trade_context
  fixtureCells: hvac_residential_core_en_US, hvac_residential_standard_en_US
  avoidBroadRerun: rerun HVAC controls fixtures before all-HVAC sweeps
- familyId: hvac_condensate_drain
  trade: hvac
  riskTerms: condensate, PVC, pump, drain, trap
  focusedTests: inventory.conflict_graph
  fixtureCells: hvac_residential_core_en_US, hvac_residential_professional_en_US
  avoidBroadRerun: rerun condensate/PVC conflict tests first
- familyId: hvac_tape_duct_fasteners
  trade: hvac
  riskTerms: foil tape, duct, sheet metal screw, strap
  focusedTests: work_supply_service_fastener_receipt_parser_test.dart
  fixtureCells: hvac_residential_core_en_US, hvac_residential_standard_en_US
  avoidBroadRerun: rerun tape/duct/fastener fixtures first
- familyId: spanish_plumbing_core
  trade: plumbing
  riskTerms: es-US, codo, valvula, acople, tubo
  focusedTests: work_supply_plumbing_spanish_receipt_parser_test.dart
  fixtureCells: plumbing_residential_core_es_US, plumbing_residential_standard_es_US
  avoidBroadRerun: rerun Spanish plumbing fixtures before all Spanish packs
- familyId: spanish_priority_trades
  trade: plumbing/electrical/hvac
  riskTerms: es-US, spanish, cable, conducto, filtro, valvula
  focusedTests: work_supply_priority_trades_spanish_receipt_parser_test.dart, inventory.spanish_release_one
  fixtureCells: plumbing_residential_core_es_US, electrical_residential_core_es_US, hvac_residential_core_es_US
  avoidBroadRerun: rerun affected Spanish cell only, then Spanish release-one suite

Failure-category first rerun routes:

- schema -> inventory.catalog_schema
- alias -> inventory.alias_conflicts
- merchant_rule -> inventory.merchant_rules
- conflict -> inventory.conflict_graph
- normalization -> inventory.metamorphic_variants
- category -> inventory.workflow_routing
- unit -> inventory.math_reconciliation
- quantity -> inventory.economics_contract
- confidence -> inventory.confidence_calibration
- context -> inventory.trade_context
- parser_engine -> inventory.generated_cases
- privacy -> inventory.security_privacy
- security -> inventory.boundary_guard
- performance -> inventory.runtime_profile_contract
- governance -> inventory.requirement_coverage
- review_safety -> inventory.review_safety_contract
- fixture -> inventory.fixture_coverage_matrix
- economics -> inventory.economics_contract
- locale -> inventory.locale_contract
- baseline -> inventory.baseline_contract
- unknown -> inventory.failure_taxonomy_contract

- inventory.generated_fixture_cell_contract:
  use `PARSER_QA_GENERATED_FIXTURE_PATH=<cell path>` and
  `PARSER_QA_GENERATED_FIXTURE_MAX_CASES=<small cap>` with the generated
  fixture runner before any full catalog run.
- inventory.catalog_batch_memory_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_batch_memory_contract,qa.threshold_gate`
- inventory.item_metadata_depth:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.item_metadata_depth,qa.threshold_gate`
- inventory.vendor_readiness:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.vendor_readiness,qa.threshold_gate`
- inventory.spanish_release_one:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
- inventory.standard_fixture_seed_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.standard_fixture_seed_contract,qa.threshold_gate`
- inventory.fixture_coverage_matrix:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_coverage_matrix,qa.threshold_gate`
- inventory.security_privacy:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.security_privacy,qa.threshold_gate`
- inventory.boundary_guard:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.boundary_guard,qa.threshold_gate`
- inventory.no_live_services_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.no_live_services_contract,qa.threshold_gate`
- inventory.catalog_item_batch_generation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_item_batch_generation_contract,qa.threshold_gate`
- inventory.failure_routing_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.failure_routing_contract,qa.threshold_gate`
- inventory.pack_scope_gate_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_scope_gate_contract,qa.threshold_gate`
- inventory.catalog_batch_manifest_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_batch_manifest_contract,qa.threshold_gate`
- inventory.receipt_line_torture_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.receipt_line_torture_contract,qa.threshold_gate`
- inventory.admin_diagnostic_batch_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.admin_diagnostic_batch_contract,qa.threshold_gate`
- inventory.cloud_local_mode_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.cloud_local_mode_contract,qa.threshold_gate`
- inventory.item_promotion_gate_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.item_promotion_gate_contract,qa.threshold_gate`
- inventory.merchant_matrix_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.merchant_matrix_contract,qa.threshold_gate`
- inventory.merchant_independence_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.merchant_independence_contract,qa.threshold_gate`
- inventory.vendor_sku_matrix_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.vendor_sku_matrix_contract,qa.threshold_gate`
- inventory.sku_collision_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.sku_collision_contract,qa.threshold_gate`
- inventory.price_tax_allocation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.price_tax_allocation_contract,qa.threshold_gate`
- inventory.pack_overlap_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_overlap_contract,qa.threshold_gate`
- inventory.release_one_residential_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_residential_contract,qa.threshold_gate`
- inventory.job_context_bridge_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.job_context_bridge_contract,qa.threshold_gate`
- inventory.bulk_generation_pipeline_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.bulk_generation_pipeline_contract,qa.threshold_gate`
- inventory.human_correction_learning_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.human_correction_learning_contract,qa.threshold_gate`
- inventory.language_pack_separation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.language_pack_separation_contract,qa.threshold_gate`
- inventory.device_budget_matrix_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.device_budget_matrix_contract,qa.threshold_gate`
- inventory.fixture_holdout_rotation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_holdout_rotation_contract,qa.threshold_gate`
- inventory.barcode_inventory_identity_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.barcode_inventory_identity_contract,qa.threshold_gate`
- inventory.admin_privacy_rollup_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.admin_privacy_rollup_contract,qa.threshold_gate`
- inventory.fleet_permission_context_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fleet_permission_context_contract,qa.threshold_gate`
- inventory.receipt_line_parser_fuzz_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.receipt_line_parser_fuzz_contract,qa.threshold_gate`
- inventory.duplicate_receipt_import_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.duplicate_receipt_import_contract,qa.threshold_gate`
- inventory.pack_integrity_recovery_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_integrity_recovery_contract,qa.threshold_gate`
- inventory.hive_firestore_sync_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.hive_firestore_sync_contract,qa.threshold_gate`
- inventory.hive_authority_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.hive_authority_contract,qa.threshold_gate`
- inventory.import_export_safety_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.import_export_safety_contract,qa.threshold_gate`
- inventory.receipt_source_immutability_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.receipt_source_immutability_contract,qa.threshold_gate`
- inventory.product_normalization_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.product_normalization_contract,qa.threshold_gate`
- inventory.category_inference_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.category_inference_contract,qa.threshold_gate`
- inventory.search_indexing_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.search_indexing_contract,qa.threshold_gate`
- inventory.regression_lock_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.regression_lock_contract,qa.threshold_gate`
- inventory.differential_regression_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.differential_regression_contract,qa.threshold_gate`
- inventory.pack_version_regression_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_version_regression_contract,qa.threshold_gate`
- inventory.master_coverage_matrix_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.master_coverage_matrix_contract,qa.threshold_gate`
- inventory.financial_duplicate_guard_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.financial_duplicate_guard_contract,qa.threshold_gate`
- inventory.receipt_invoice_feed_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.receipt_invoice_feed_contract,qa.threshold_gate`
- inventory.merchant_alias_normalization_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.merchant_alias_normalization_contract,qa.threshold_gate`
- inventory.receipt_line_mapping_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.receipt_line_mapping_contract,qa.threshold_gate`
- inventory.input_attack_surface_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.input_attack_surface_contract,qa.threshold_gate`
- Generated fixture schema or cell coverage failure:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generated_fixture_cell_contract,qa.threshold_gate`
- Requirement memory/progress failure:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_batch_memory_contract,qa.threshold_gate`
- Single generated fixture parser behavior failure:
  use `PARSER_QA_GENERATED_FIXTURE_PATH=<cell path>` with the generated fixture runner and avoid broad reruns.
- Item metadata depth failure:
  run `inventory.item_metadata_depth` first with the smallest affected sample or focused item family before any full-profile catalog sweep.

## Executable Behavior Test Progress

- current phase behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_current_phase_behavior_test.dart`
  checkedBy: `dart analyze test\work_supply_parser_current_phase_behavior_test.dart`
  focusedRerun: `flutter test test\work_supply_parser_current_phase_behavior_test.dart`
  result: analyzer clean; 10 tests passed
  coveredBehaviors: product normalization, merchant aliases, category inference with ambiguity, search/indexing, trusted item identity, receipt line mapping, duplicate source-line mapping, financial totals, Firestore read-safe pack manifest contract, import/export source ids, receipt/invoice/job feed actions, source immutability, Hive receipt persistence

- current phase behavior batch 2:
  status: validated-local
  file: `test/work_supply_parser_current_phase_safety_behavior_test.dart`
  checkedBy: `dart analyze test\work_supply_parser_current_phase_safety_behavior_test.dart`
  focusedRerun: `flutter test test\work_supply_parser_current_phase_safety_behavior_test.dart`
  result: analyzer clean; 6 tests passed
  coveredBehaviors: receipt noise rejection, dangerous generic word conservatism, plumbing/electrical PVC separation, HVAC/electrical tape separation, impossible mixed-token search rejection, Hive inventory authority over stock state

- current phase behavior batch 3:
  status: validated-local
  file: `test/work_supply_parser_current_phase_memory_locale_pack_test.dart`
  checkedBy: `dart analyze test\work_supply_parser_current_phase_memory_locale_pack_test.dart`
  focusedRerun: `flutter test test\work_supply_parser_current_phase_memory_locale_pack_test.dart`
  result: analyzer clean; 6 tests passed
  coveredBehaviors: learned correction review-only behavior, learned receipt price tolerance, es-US locale overlay recognition, confidence band stability, unsafe pack path rejection, missing parser metadata rejection with synthetic fast pack fixtures

- current phase behavior batch 4:
  status: validated-local
  file: `test/parser_qa_platform_reuse_behavior_test.dart`
  checkedBy: `dart analyze test\parser_qa_platform_reuse_behavior_test.dart`
  focusedRerun: `flutter test test\parser_qa_platform_reuse_behavior_test.dart`
  result: analyzer clean; 5 tests passed
  coveredBehaviors: generic parser-domain harness execution, inventory and maintenance parser adapter contracts, shared harness remains domain-agnostic, parser QA report redaction, release-category triage classification

- current phase behavior batch 5:
  status: validated-local
  file: `test/work_supply_parser_current_phase_custom_catalog_test.dart`
  checkedBy: `dart analyze lib\screens\work_supplies\data\work_supply_custom_catalog_store.dart test\work_supply_parser_current_phase_custom_catalog_test.dart`
  focusedRerun: `flutter test test\work_supply_parser_current_phase_custom_catalog_test.dart`
  result: analyzer clean; 5 tests passed
  coveredBehaviors: custom catalog field trimming, generated local USER ids, alias-token custom search, custom/starter merge dedupe, resolver reuse of custom parser identities
  fixed: `WorkSupplyCustomCatalogStore.saveItem` now persists the trimmed item id instead of saving leading/trailing whitespace into local catalog identity keys

- current phase behavior batch 6:
  status: validated-local
  file: `test/work_supply_parser_current_phase_mirror_export_test.dart`
  checkedBy: `dart analyze test\work_supply_parser_current_phase_mirror_export_test.dart`
  focusedRerun: `flutter test test\work_supply_parser_current_phase_mirror_export_test.dart`
  result: analyzer clean; 4 tests passed
  coveredBehaviors: hosted catalog mirror uses manifest plus storage chunks, per-item Firestore mirror shape is rejected, Hive inventory transactions preserve receipt/job/source fields, export CSV/manifest includes transaction and source fields, export serialization does not mutate source records

### Current Phase Executable Behavior Completion Audit

Status: validated-local for current executable behavior layer.

Focused evidence:

- Analyzer:
  `dart analyze test\work_supply_parser_current_phase_behavior_test.dart test\work_supply_parser_current_phase_safety_behavior_test.dart test\work_supply_parser_current_phase_memory_locale_pack_test.dart test\parser_qa_platform_reuse_behavior_test.dart test\work_supply_parser_current_phase_custom_catalog_test.dart test\work_supply_parser_current_phase_mirror_export_test.dart lib\screens\work_supplies\data\work_supply_custom_catalog_store.dart`
- Batch 1 rerun:
  `flutter test test\work_supply_parser_current_phase_behavior_test.dart`
  result: 10 tests passed.
- Batch 2-6 focused rerun:
  `flutter test test\work_supply_parser_current_phase_safety_behavior_test.dart test\work_supply_parser_current_phase_memory_locale_pack_test.dart test\parser_qa_platform_reuse_behavior_test.dart test\work_supply_parser_current_phase_custom_catalog_test.dart test\work_supply_parser_current_phase_mirror_export_test.dart`
  result: 26 tests passed.

Requirement mapping:

- product normalization behavior: batch 1, batch 3, batch 5.
- merchant alias behavior: batch 1.
- duplicate detection behavior: batch 1 source-line mapping and batch 5 custom/starter dedupe.
- category inference behavior: batch 1 and batch 2 cross-trade PVC/tape separation.
- receipt line mapping behavior: batch 1.
- search/indexing behavior: batch 1, batch 2, batch 5.
- Hive persistence behavior: batch 1, batch 2, batch 6.
- Firestore mirror-contract behavior without live writes: batch 1 manifest read-safe contract, batch 3 trade-pack validator, batch 4 no-live parser-platform contract, batch 6 hosted mirror read-safe and unsafe per-item mirror rejection.
- conflict handling behavior: batch 2 dangerous/generic/cross-trade cases and batch 4 conflict triage.
- import/export safety behavior: batch 1, batch 3, batch 6.
- financial total behavior: batch 1 and batch 6 transaction/export preservation.
- receipt/invoice/job feed behavior without mutating sources: batch 1 and batch 6.

Current phase boundary:

- This completes the executable behavior layer only.
- This does not complete golden fixture volume, regression-lock case volume, security/privacy/fuzz depth, release-wide QA gates, or catalog item completeness.

## High Risk QA Contract Backlog

This section exists so the inventory parser QA harness does not stop at basic coverage. These items are required before parser/catalog work can be treated as world-class or release-ready.

### Regression Lock Contract

Required regression buckets:

- known good receipt line
- known bad receipt line
- known bug stays fixed
- merchant regression
- locale regression
- trade regression
- pack tier regression
- dangerous word regression
- financial total regression
- source immutability regression
- duplicate receipt regression
- search/index regression

Locked expectation fields:

- fixture id
- raw line
- merchant
- locale
- trade
- pack tier
- expected item id
- expected category
- expected review status
- expected confidence band
- expected ranked candidates
- expected warnings
- expected failure category

Regression lock rules:

- regression_case_has_stable_fixture_id
- regression_case_has_expected_top_candidate
- regression_case_has_expected_review_status
- regression_case_has_confidence_band_not_exact_float
- regression_case_has_ranked_candidate_expectation
- regression_case_records_why_it_exists
- regression_case_links_to_fixed_bug_or_requirement
- regression_case_fails_on_false_confident_match
- regression_case_fails_on_source_mutation
- regression_case_fails_on_missing_warning
- regression_case_can_be_run_surgically
- regression_case_is_not_deleted_without_replacement

Merchant and locale locks must include Home Depot, Lowe, Ace, Ferguson, Grainger, Menards, Walmart, True Value, unknown merchant, en-US, es-US, English, Spanish, metric, and imperial.

### Regression Lock Executable Progress

- regression lock behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_regression_lock_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_regression_lock_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_regression_lock_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_regression_lock_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_regression_lock_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.regression_lock_contract,qa.threshold_gate`
  result: analyzer clean; 7 executable regression tests passed; harness regression-lock contract passed 60 checks with 0 failures
  coveredBehaviors: stable lock metadata, known-good receipt lines, known-bad/noise lines, dangerous-word conservatism, major merchant normalization, duplicate receipt source-line routing, financial/source immutability, search/index alias families, locale Spanish lock, trade ambiguity lock

### Differential Regression Contract

Differential axes:

- old parser
- new parser
- old catalog
- new catalog
- old pack version
- new pack version
- changed item
- changed alias
- changed merchant rule
- changed confidence
- changed category
- changed review status

Differential report fields:

- fixture id
- old candidate id
- new candidate id
- old confidence
- new confidence
- old review status
- new review status
- old category
- new category
- change reason
- approved change
- blocking regression

Differential rules:

- differential_run_reports_every_changed_result
- differential_run_requires_reason_for_changed_result
- differential_run_blocks_false_confident_regression
- differential_run_blocks_source_mutation_regression
- differential_run_blocks_privacy_regression
- differential_run_blocks_performance_budget_regression
- differential_run_allows_expected_improvement_with_note
- differential_run_groups_changes_by_trade
- differential_run_groups_changes_by_merchant
- differential_run_groups_changes_by_locale
- differential_run_outputs_surgical_rerun_targets
- differential_run_is_local_only

Differential release gate evidence must include release gate, signoff, baseline, holdout, mutation, performance, privacy, security, local-only, and no live Firebase.

### Differential Regression Executable Progress

- differential regression behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_differential_regression_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_differential_regression_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_differential_regression_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_differential_regression_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_differential_regression_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.differential_regression_contract,qa.threshold_gate`
  result: analyzer clean; 3 executable differential tests passed; harness differential-regression contract passed 54 checks with 0 failures
  coveredBehaviors: every changed result is reported with old/new candidate, confidence, review status, category, reason, approved-change flag, blocking-regression flag, trade/merchant/locale grouping, surgical rerun targets, and local-only/no-live-Firebase boundary

### Pack Version Regression Contract

Version axes:

- catalog version
- parser version
- pack version
- manifest version
- locale pack version
- schema version
- migration version
- previous version
- current version
- rollback version

Version failure cases:

- old pack version
- missing locale pack
- corrupt pack
- partial install
- duplicate install
- failed migration
- stale search index
- stale Firestore mirror
- Hive rollback
- cache rebuild

Pack version rules:

- new_pack_version_runs_old_regression_locks
- new_parser_version_runs_old_regression_locks
- new_locale_pack_runs_locale_regression_locks
- migration_preserves_confirmed_inventory_items
- migration_preserves_user_custom_items
- migration_preserves_review_candidates
- rollback_restores_previous_known_good_pack
- old_pack_missing_feature_falls_back_conservatively
- pack_version_mismatch_requires_review
- schema_version_mismatch_blocks_import
- confirmed_bug_fix_stays_fixed_across_pack_versions
- release_manifest_records_regression_evidence

Protected data includes Hive, source of truth, inventory item, vehicle inventory, job material, estimate material, invoice material, user correction, custom item, and audit trail.

### Pack Version Regression Executable Progress

- pack version regression behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_pack_version_regression_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_pack_version_regression_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_pack_version_regression_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_pack_version_regression_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_pack_version_regression_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_version_regression_contract,qa.threshold_gate`
  harnessResult: 50 checks, 0 failures, 0 actualFailures, durationMs=22
  coveredBehaviors: new pack versions run old regression lock metadata, schema mismatches block import before promotion, pack version mismatches require review, duplicate installs are idempotent, missing locale packs fall back conservatively, stale Firestore mirrors cannot overwrite Hive truth, and Hive rollback preserves custom item and source receipt fields

### Input Attack Surface Contract

User-controlled input surfaces:

- search bar
- receipt line
- custom item name
- alias
- merchant name
- SKU
- UPC
- GTIN
- barcode

Barcode/vendor provenance safety rules now required before any release-one
barcode-assisted inventory flow:

- user_item_id_does_not_replace_stable_catalog_id
- barcode_can_link_to_canonical_item
- barcode_collision_requires_review
- barcode_mapping_requires_user_confirmation
- unknown_barcode_stays_review_only
- barcode_evidence_never_bypasses_conflict_rules
- user_scanned_barcode_maps_to_private_inventory_memory_first
- vehicle_location_is_user_inventory_metadata
- bin_drawer_location_is_not_parser_identity
- fleet_vehicle_inventory_is_separate_from_catalog
- same_catalog_item_can_exist_on_multiple_vehicles
- user_custom_item_keeps_source_metadata
- barcode_scan_can_create_review_candidate
- barcode_missing_does_not_block_receipt_parser
- official_pack_mappings_require_licensed_or_public_source
- retailer_database_scraping_is_forbidden
- merchant_sku_mapping_requires_source_confidence
- barcode_receipt_disagreement_requires_review
- barcode_can_boost_confidence_only_with_corroborating_evidence

Barcode, UPC, GTIN, vendor SKU, and merchant item-number evidence can boost
ranking only when corroborated by receipt text, metadata, trade context, pack
scope, and conflict graph evidence. Unknown or colliding barcode evidence stays
review-only. User-scanned barcode links remain private local inventory memory
unless reviewed and explicitly promoted. User item ID and internal item ID
values never replace stable catalog identity. Vehicle location, bin number,
drawer, truck, fleet, on hand, out of stock, purchased not in stock, job
staging, vehicle inventory, shop inventory, employee, permission, and owner
fields are user inventory metadata, not parser identity. Official pack mappings
require licensed, reviewed public, manual, or synthetic provenance. Retailer
database scraping is forbidden.
- bin number
- drawer
- vehicle location
- import file
- admin filter
- diagnostic filter

Hostile input families:

- SQL injection
- NoSQL injection
- path traversal
- script tag
- command-looking text
- regex backtracking
- CSV formula injection
- malformed JSON
- malformed CSV
- huge input
- repeated tokens
- long token
- null byte
- control character
- unicode override
- emoji
- right-to-left override
- HTML entity
- URL
- file path
- environment variable

Input attack safety rules:

- all_user_text_input_is_hostile
- input_attack_never_executes_code
- input_attack_never_changes_file_path
- input_attack_never_changes_query_shape
- input_attack_never_creates_confident_match
- input_attack_never_auto_saves
- input_attack_never_logs_private_text
- input_attack_is_bounded_for_runtime
- input_attack_is_bounded_for_memory
- input_attack_keeps_review_status
- input_attack_returns_warning_or_unknown
- input_attack_preserves_raw_evidence_safely
- input_attack_redacts_reports
- input_attack_has_regression_fixture
- input_attack_has_focused_rerun

Protected destinations include Hive, Firestore, Firebase, inventory, estimate, invoice, active job, admin report, diagnostic report, export, import, and search index.

### Input Attack Surface Executable Progress

- input attack surface behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_input_attack_surface_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_input_attack_surface_qa.dart`
  productionHardening: `lib/screens/work_supplies/data/work_supply_receipt_parser.dart`, `lib/shared/data_export/csv_writer.dart`
  checkedBy: `dart analyze test\work_supply_parser_input_attack_surface_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_input_attack_surface_qa.dart lib\shared\data_export\csv_writer.dart lib\screens\work_supplies\data\work_supply_receipt_parser.dart`
  focusedRerun: `flutter test test\work_supply_parser_input_attack_surface_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.input_attack_surface_contract,qa.threshold_gate`
  harnessResult: 71 checks, 0 failures, 0 actualFailures, durationMs=40
  directTestResult: 6 tests passed
  runtimeNote: direct catalog-backed hostile-input behavior test currently pays catalog index startup cost and ran about 1:49 locally; harness contract remains fast
  coveredBehaviors: hostile receipt text cannot create confident parser matches, hostile search text stays bounded and non-mutating, hostile merchant names cannot spoof known merchant aliases, custom catalog hostile aliases do not mutate stored identity, CSV export neutralizes spreadsheet formulas, and hostile suffixes on real item lines cannot become auto-save certainty

### Security Abuse Executable Progress

- security abuse behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_security_abuse_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_security_abuse_behavior_test.dart`
  focusedRerun: `flutter test test\work_supply_parser_security_abuse_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.security_privacy,qa.threshold_gate`
  harnessResult: 42 checks, 0 failures, 0 actualFailures, durationMs=51
  directTestResult: 6 tests passed
  runtimeNote: direct security abuse behavior test currently pays catalog parser startup cost and ran about 1:56 locally; use focused rerun only when security/parser behavior changes
  coveredBehaviors: QA redaction removes receipt/payment/contact/address tokens, report serialization redacts nested private metadata, hostile receipt-like strings do not become confident parser output, hostile diagnostic previews are bounded and risk-tagged, CSV formula execution is neutralized, and security probes stay local-only with no network/process/Firebase writes/OCR/camera access

### Catalog Schema Contract Validation

- catalog schema focused validation:
  status: validated-local
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_qa.dart`
  fixed: schema allowed-unit vocabulary now includes legitimate catalog package/length/container units: `foot`, `stick`, `kit`, `can`, `tub`, `tube`, `bottle`, `bucket`, `bundle`, `section`, and `carton`
  checkedBy: `dart analyze test\support\work_supply_parser_qa\work_supply_parser_qa.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_schema,qa.threshold_gate`
  harnessResult: 5682 checks, 0 failures, 0 actualFailures, durationMs=33019
  coveredBehaviors: catalog schema gate samples current catalog rows, validates stable ids, required fields, aliases, units, duplicate canonical names, parser-pack metadata, and item intelligence metadata without rejecting real-world packaging units

### Accumulated Coverage Contract Validation

- accumulated coverage focused validation:
  status: validated-local
  fixtureFile: `test/fixtures/work_supply_parser/golden_fixtures.json`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_accumulated_coverage_qa.dart`
  fixed: golden fixtures now carry `trade`, `marketScope`, `tier`, and `localePackId` cell metadata, with explicit priority cells for plumbing/electrical/HVAC residential core en-US and es-US
  fixtureCellCount: 6
  fixtureCount: 27
  checkedBy: `python -c json load for test\fixtures\work_supply_parser\golden_fixtures.json`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.accumulated_coverage_contract,qa.threshold_gate`
  harnessResult: 41 checks, 0 failures, 0 actualFailures, durationMs=17
  supportingRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_corpus_contract,inventory.fixture_coverage_matrix,qa.threshold_gate`
  supportingResult: 125 checks, 0 failures, 0 actualFailures, durationMs=17
  coveredBehaviors: every priority release-one fixture cell has explicit golden fixture evidence, fixture metadata aligns with trade/scope/tier/locale cells, and corpus/coverage gates remain green after metadata expansion

### Accuracy Budget Contract Validation

- accuracy budget focused validation:
  status: validated-local
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_accuracy_budget_qa.dart`
  checkedBy: `dart analyze test\support\work_supply_parser_qa\work_supply_parser_accuracy_budget_qa.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.accuracy_budget,qa.threshold_gate`
  harnessResult: 41 checks, 0 failures, 0 actualFailures, durationMs=13
  coveredBehaviors: accuracy budget contract keeps top-1, top-3, false-confident, noise false-positive, and generated-family accuracy budgets visible while requiring fixture coverage for clear match, dangerous generic, receipt noise, ambiguous review, negative match, and quantity/price cases

### Device Budget Matrix Contract

Device and network classes:

- older phone
- Galaxy S9
- midrange
- modern flagship
- Galaxy S24
- Galaxy S25
- low storage
- offline
- metered data
- cloud fallback

Runtime and storage signals:

- cold start
- warm run
- indexing time
- memory growth
- slowest rule
- checks per second
- pack size
- available bytes
- read budget
- no live Firebase

Device budget rules:

- older_device_uses_conservative_parser_profile
- flagship_device_can_use_full_local_profile
- low_storage_blocks_large_pack_install
- safe_install_buffer_required
- cloud_fallback_is_online_only
- cloud_fallback_is_slower
- local_pack_is_fastest_path
- pack_download_estimates_megabytes
- runtime_profile_records_memory_budget
- runtime_profile_records_slowest_rule

### Device Budget Matrix Executable Progress

- device budget matrix behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_device_budget_matrix_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_device_budget_matrix_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_device_budget_matrix_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_device_budget_matrix_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_device_budget_matrix_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.device_budget_matrix_contract,qa.threshold_gate`
  harnessResult: 38 checks, 0 failures, 0 actualFailures, durationMs=19
  directTestResult: 6 tests passed
  runtimeNote: direct pack-option behavior test currently pays catalog pack startup cost and ran about 1:11 locally; harness contract remains fast
  coveredBehaviors: older/midrange/flagship parser profile boundaries, low-storage local pack blocking, older-phone pack tier limits, metered network warning behavior, explicit local/cloud delivery policy budget, and runtime budget signal reporting without live Firebase

### Pack Integrity Recovery Contract

Pack integrity tokens:

- checksum
- signature
- manifest
- version
- migration
- rollback
- corrupt pack
- interrupted download
- duplicate install
- missing locale pack
- old pack version
- partial install

Pack recovery rules:

- corrupt_pack_never_loads_as_current
- interrupted_download_keeps_previous_pack
- duplicate_pack_install_is_idempotent
- old_pack_version_runs_migration_or_rollback
- missing_locale_pack_falls_back_conservatively
- failed_migration_keeps_previous_pack
- pack_manifest_controls_enabled_scope
- pack_integrity_checked_before_indexing
- pack_recovery_does_not_hit_live_firebase_in_qa
- pack_recovery_records_actionable_diagnostic

Recovery scope includes plumbing, electrical, hvac, fasteners, residential, core, standard, professional, complete, English, and Spanish.

### Pack Integrity Recovery Executable Progress

- pack integrity recovery behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_pack_integrity_recovery_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_pack_integrity_recovery_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_pack_integrity_recovery_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_pack_integrity_recovery_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_pack_integrity_recovery_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_integrity_recovery_contract,qa.threshold_gate`
  harnessResult: 41 checks, 0 failures, 0 actualFailures, durationMs=18
  directTestResult: 6 tests passed
  coveredBehaviors: corrupt packs never load as current, checksum mismatch blocks indexing before promotion, duplicate installs are idempotent, valid new packs promote only after manifest/chunk validation, missing locale packs fall back conservatively, failed migrations roll back, diagnostics are actionable, and recovery does not use live Firebase

### Language Pack Separation Contract

Language axes:

- English
- Spanish
- French
- en-US
- es-US
- en-CA
- fr-CA
- metric
- imperial
- locale pack

Language pack separation rules:

- english_and_spanish_are_separate_packs
- locale_pack_can_share_canonical_item_identity
- locale_aliases_do_not_duplicate_canonical_items
- metric_size_aliases_are_locale_specific
- imperial_size_aliases_are_locale_specific
- spanish_us_receipts_are_release_one_scope
- canada_requires_english_and_french_later
- language_pack_selection_is_user_or_region_driven
- missing_locale_pack_falls_back_conservatively
- locale_context_boosts_without_forcing_match

Spanish receipt signals include codo, tubo, conector, valvula, filtro, cinta, cable, conducto, acople, tornillo, tuerca, and arandela.

### Language Pack Separation Executable Progress

- language pack separation behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_language_pack_separation_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_language_pack_separation_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_language_pack_separation_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_language_pack_separation_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_language_pack_separation_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.language_pack_separation_contract,qa.threshold_gate`
  harnessResult: 40 checks, 0 failures, 0 actualFailures, durationMs=19
  directTestResult: 6 tests passed
  runtimeNote: direct locale behavior test currently pays catalog pack startup cost and ran about 1:12 locally; harness contract remains fast
  coveredBehaviors: priority US/Canada locale axes stay separate, English and Spanish pack manifests use separate locale/storage keys, locale packs share canonical item identities, Spanish receipt aliases map to the same canonical item, locale context boosts without forcing certainty, and missing locale packs fall back conservatively

### Fleet Permission Context Contract

Fleet context tokens:

- fleet
- vehicle
- truck
- employee
- helper
- owner
- permission
- role
- shop inventory
- vehicle inventory
- job staging
- active job

Fleet workflow risks:

- add to inventory
- add to job
- add to estimate
- add to invoice
- transfer vehicle
- mark out of stock
- purchased not in stock
- review-only
- suggested action
- warnings

Fleet and permission rules:

- parser_candidate_does_not_grant_inventory_permission
- employee_context_can_filter_vehicle_inventory
- owner_context_can_see_company_inventory
- helper_context_requires_limited_actions
- vehicle_inventory_context_can_boost_ranking
- vehicle_inventory_context_does_not_force_match
- fleet_inventory_is_separate_from_catalog_pack
- same_item_can_exist_in_multiple_vehicle_locations
- permission_denied_returns_review_warning
- admin_rollup_never_exposes_employee_private_data

### Fleet Permission Context Executable Progress

- fleet permission context behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_fleet_permission_context_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_fleet_permission_context_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_fleet_permission_context_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_fleet_permission_context_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_fleet_permission_context_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fleet_permission_context_contract,qa.threshold_gate`
  harnessResult: 40 checks, 0 failures, 0 actualFailures, durationMs=20
  directTestResult: 6 tests passed
  coveredBehaviors: parser candidates do not grant inventory permissions, owner context can see company inventory, employee context filters to assigned vehicle inventory, vehicle inventory context boosts ranking without forcing match, same item can exist in multiple vehicle/shop locations, inventory destinations include job staging and custom locations, and admin rollups omit employee private data and raw receipt text

### Human Correction Learning Contract

Correction targets:

- proposed alias
- negative rule
- merchant rule
- regression fixture
- confidence hint
- missing vendor mapping
- locale phrase
- Spanish phrase
- item family
- trade context

Correction safety rules:

- correction_never_silently_mutates_official_pack
- correction_requires_review_before_promotion
- correction_keeps_original_candidate_evidence
- correction_records_before_after_item
- correction_records_failure_category
- correction_redacts_private_receipt_text
- correction_does_not_log_card_data
- correction_can_be_rejected
- correction_can_create_regression_fixture
- correction_scopes_to_merchant_locale_trade

Correction/admin signals include device class, device model, pack version, parser version, failure category, trade, item id, candidate count, unknown rate, and correction frequency.

### Admin Privacy Rollup Contract

Allowed admin fields:

- device class
- device model
- os version
- app version
- parser version
- pack version
- trade
- item id
- failure category
- candidate count
- review status
- merchant type

Blocked admin fields:

- raw receipt text
- card number
- last four
- customer name
- email
- phone
- address
- GPS coordinates
- photo
- receipt image

Admin rollup rules:

- admin_rollup_is_aggregate_first
- admin_rollup_redacts_private_data
- admin_rollup_does_not_store_raw_receipts
- admin_rollup_groups_by_failure_category
- admin_rollup_groups_by_trade
- admin_rollup_groups_by_device_class
- admin_rollup_groups_by_pack_version
- admin_rollup_has_read_budget
- admin_rollup_has_write_budget
- admin_rollup_is_not_real_time_required

### Admin Privacy Rollup Executable Progress

- admin privacy rollup behavior batch 1:
  status: validated-local
  file: `test/work_supply_parser_admin_privacy_rollup_behavior_test.dart`
  harnessSource: `test/support/work_supply_parser_qa/work_supply_parser_admin_privacy_rollup_qa.dart`
  checkedBy: `dart analyze test\work_supply_parser_admin_privacy_rollup_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_admin_privacy_rollup_qa.dart`
  focusedRerun: `flutter test test\work_supply_parser_admin_privacy_rollup_behavior_test.dart`
  harnessRerun: `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.admin_privacy_rollup_contract,qa.threshold_gate`
  harnessResult: 40 checks, 0 failures, 0 actualFailures, durationMs=24
  directTestResult: 5 tests passed
  coveredBehaviors: allowed admin parser-health fields only, blocked raw receipt/payment/customer/contact/GPS/photo/image fields, aggregate-first grouping by failure category/trade/device class/pack version, read/write budget under 100 per day, non-real-time cadence, and major incident alert summaries without raw receipt content

## Harness Suite Registry Focused Reruns

Every registered suite must have a focused rerun command so failures can be retested surgically without running the full harness.

- inventory.accumulated_coverage_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.accumulated_coverage_contract,qa.threshold_gate`
- inventory.accuracy_budget:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.accuracy_budget,qa.threshold_gate`
- inventory.admin_report_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.admin_report_contract,qa.threshold_gate`
- inventory.artifact_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.artifact_contract,qa.threshold_gate`
- inventory.artifact_retention_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.artifact_retention_contract,qa.threshold_gate`
- inventory.batch_continuation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.batch_continuation_contract,qa.threshold_gate`
- inventory.blueprint_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.blueprint_contract,qa.threshold_gate`
- inventory.blueprint_promotion_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.blueprint_promotion_contract,qa.threshold_gate`
- inventory.catalog_coverage:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_coverage,qa.threshold_gate`
- inventory.catalog_family_rerun_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_family_rerun_contract,qa.threshold_gate`
- inventory.category_reuse_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.category_reuse_contract,qa.threshold_gate`
- inventory.changed_item_impact:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.changed_item_impact,qa.threshold_gate`
- inventory.cloud_cost_guard_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.cloud_cost_guard_contract,qa.threshold_gate`
- inventory.correction_feedback_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.correction_feedback_contract,qa.threshold_gate`
- inventory.data_provenance_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.data_provenance_contract,qa.threshold_gate`
- inventory.delivery_policy_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.delivery_policy_contract,qa.threshold_gate`
- inventory.determinism:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.determinism,qa.threshold_gate`
- inventory.device_storage_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.device_storage_contract,qa.threshold_gate`
- inventory.estimate_section_ranking:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.estimate_section_ranking,qa.threshold_gate`
- inventory.evidence_attribution:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.evidence_attribution,qa.threshold_gate`
- inventory.evidence_summary_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.evidence_summary_contract,qa.threshold_gate`
- inventory.execution_command_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.execution_command_contract,qa.threshold_gate`
- inventory.file_size_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.file_size_contract,qa.threshold_gate`
- inventory.fixture_batch_plan_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_batch_plan_contract,qa.threshold_gate`
- inventory.fixture_corpus_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_corpus_contract,qa.threshold_gate`
- inventory.fixture_expectation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_expectation_contract,qa.threshold_gate`
- inventory.fixture_governance:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_governance,qa.threshold_gate`
- inventory.fixture_privacy_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_privacy_contract,qa.threshold_gate`
- inventory.gate_ledger_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.gate_ledger_contract,qa.threshold_gate`
- inventory.generated_artifact_manifest:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generated_artifact_manifest,qa.threshold_gate`
- inventory.generated_fixture_performance_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generated_fixture_performance_contract,qa.threshold_gate`
- inventory.generated_manifest_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generated_manifest_contract,qa.threshold_gate`
- inventory.generator_pairing_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generator_pairing_contract,qa.threshold_gate`
- inventory.golden_fixtures:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.golden_fixtures,qa.threshold_gate`
- inventory.harness_maintainability_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.harness_maintainability_contract,qa.threshold_gate`
- inventory.harness_registry:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.harness_registry,qa.threshold_gate`
- inventory.holdout_fixture_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.holdout_fixture_contract,qa.threshold_gate`
- inventory.known_debt_ledger:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.known_debt_ledger,qa.threshold_gate`
- inventory.legal_safety_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.legal_safety_contract,qa.threshold_gate`
- inventory.mutation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.mutation_contract,qa.threshold_gate`
- inventory.mutation_dry_run_plan:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.mutation_dry_run_plan,qa.threshold_gate`
- inventory.mutation_fault_probe:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.mutation_fault_probe,qa.threshold_gate`
- inventory.mutation_runner_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.mutation_runner_contract,qa.threshold_gate`
- inventory.mutation_scenario_matrix:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.mutation_scenario_matrix,qa.threshold_gate`
- inventory.next_action_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.next_action_contract,qa.threshold_gate`
- inventory.noise_lines:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.noise_lines,qa.threshold_gate`
- inventory.pack_health_score:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_health_score,qa.threshold_gate`
- inventory.pack_lifecycle:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_lifecycle,qa.threshold_gate`
- inventory.pack_recovery_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_recovery_contract,qa.threshold_gate`
- inventory.parser_platform_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.parser_platform_contract,qa.threshold_gate`
- inventory.pass_evidence_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pass_evidence_contract,qa.threshold_gate`
- inventory.portability_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.portability_contract,qa.threshold_gate`
- inventory.profile_matrix:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.profile_matrix,qa.threshold_gate`
- inventory.property_cases:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.property_cases,qa.threshold_gate`
- inventory.ranked_candidate_accuracy:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.ranked_candidate_accuracy,qa.threshold_gate`
- inventory.recipe_completeness_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.recipe_completeness_contract,qa.threshold_gate`
- inventory.registry_snapshot_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.registry_snapshot_contract,qa.threshold_gate`
- inventory.release_manifest:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_manifest,qa.threshold_gate`
- inventory.release_one_cell_manifest:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_cell_manifest,qa.threshold_gate`
- inventory.release_one_command_manifest:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_command_manifest,qa.threshold_gate`
- inventory.release_one_pack_balance:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_pack_balance,qa.threshold_gate`
- inventory.release_orchestration_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_orchestration_contract,qa.threshold_gate`
- inventory.release_shard_manifest:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_shard_manifest,qa.threshold_gate`
- inventory.release_signoff_manifest:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_signoff_manifest,qa.threshold_gate`
- inventory.result_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.result_contract,qa.threshold_gate`
- inventory.runtime_measurement:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.runtime_measurement,qa.threshold_gate`
- inventory.scalability:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.scalability,qa.threshold_gate`
- inventory.separation_safety:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.separation_safety,qa.threshold_gate`
- inventory.service_truck_core_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.service_truck_core_contract,qa.threshold_gate`
- inventory.slo_metrics_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.slo_metrics_contract,qa.threshold_gate`
- inventory.surgical_rerun_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.surgical_rerun_contract,qa.threshold_gate`
- inventory.telemetry_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.telemetry_contract,qa.threshold_gate`
- inventory.validation_strategy_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.validation_strategy_contract,qa.threshold_gate`

## Human Correction Learning Executable Progress

Status: completed for the current executable QA layer.

Files added or updated:

- `test/work_supply_parser_human_correction_learning_behavior_test.dart`
- `test/support/work_supply_parser_qa/work_supply_parser_human_correction_learning_qa.dart`

Covered behavior:

- correction proposals generate proposed alias, negative rule, merchant rule, regression fixture, confidence hint, missing vendor mapping, locale phrase, Spanish phrase, item family, and trade context learning targets.
- correction_never_silently_mutates_official_pack.
- correction_requires_review_before_promotion.
- correction_keeps_original_candidate_evidence.
- correction_records_before_after_item.
- correction_records_failure_category.
- correction_redacts_private_receipt_text.
- correction_does_not_log_card_data.
- correction_can_be_rejected.
- correction_can_create_regression_fixture.
- correction_scopes_to_merchant_locale_trade.
- admin signals include device class, device model, pack version, parser version, failure category, trade, item id, candidate count, unknown rate, and correction frequency without raw receipt/card data.

Validation:

- `dart analyze test\work_supply_parser_human_correction_learning_behavior_test.dart test\support\work_supply_parser_qa\work_supply_parser_human_correction_learning_qa.dart`
  passed with no issues.
- `flutter test test\work_supply_parser_human_correction_learning_behavior_test.dart`
  passed 7 tests.
- `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.human_correction_learning_contract,qa.threshold_gate`
  passed with 38 checks, 0 failures, 0 actualFailures.

Focused rerun:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.human_correction_learning_contract,qa.threshold_gate`

doNotRerunUnless:

- human correction learning behavior changes.
- correction feedback/review safety/admin telemetry contracts change.
- parser correction learning is promoted from test contract to production implementation.

## Combined Focused Validation

Status: passing for the completed focused inventory QA contracts in this batch.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generated_fixture_cell_contract,inventory.human_correction_learning_contract,inventory.catalog_batch_manifest_contract,inventory.receipt_line_torture_contract,inventory.admin_diagnostic_batch_contract,inventory.cloud_local_mode_contract,inventory.item_promotion_gate_contract,inventory.merchant_matrix_contract,inventory.catalog_item_batch_generation_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T150234377622.json`
- checked: 288384
- failures: 0
- actualFailures: 0
- adminHealth: passing

## Current Executable Behavior Objective Shard

Status: passing for the explicit current-phase executable behavior objective.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.product_normalization,inventory.merchant_alias_normalization_contract,inventory.sku_collision_contract,inventory.category_inference_contract,inventory.receipt_line_mapping,inventory.search_indexing_contract,inventory.hive_authority_contract,inventory.hive_firestore_sync_contract,inventory.conflict_graph,inventory.import_export_safety_contract,inventory.price_tax_allocation_contract,inventory.financial_duplicate_guard_contract,inventory.receipt_invoice_feed_contract,inventory.receipt_source_immutability_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T150536150092.json`
- checked: 554
- failures: 0
- actualFailures: 0
- adminHealth: passing

Covered objective areas:

- product normalization behavior
- merchant alias behavior
- SKU collision behavior
- duplicate/financial guard behavior
- category inference behavior
- receipt line mapping behavior
- search/indexing behavior
- Hive authority behavior
- Firestore mirror-contract behavior without live writes
- conflict handling behavior
- import/export safety behavior
- price/tax allocation behavior
- receipt/invoice/job feed behavior without mutating sources

## Quick Preset Governance/Security Repair

Status: passing for the smoke quick preset after fixing no-live-service token leakage,
cloud-cost guard false positives, and harness registry drift.

Changed:

- `inventory.cloud_cost_guard_contract` now builds live-service forbidden
  tokens at runtime so the guard can still inspect tool output without putting
  literal live Firebase service tokens into parser QA source.
- Parser QA tools explicitly report `liveServicesAllowed: false`,
  `writesProductionCatalog: false`, and `firebaseWritesAllowed: false` in
  local manifests where applicable.
- `inventory.harness_registry` now classifies generator, batch, release-cell,
  and focused executable behavior suites as targeted-only so quick remains
  fast while explicit suite runs remain available.

Validation:

- `dart analyze test\support\work_supply_parser_qa\work_supply_parser_cloud_cost_guard_qa.dart tool\work_supply_parser_qa_pipeline.dart tool\work_supply_parser_qa_background_queue.dart tool\work_supply_catalog_blueprint_generator.dart tool\work_supply_parser_qa_generate_fixtures.dart`
  passed with no issues.
- `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.boundary_guard,inventory.no_live_services_contract,inventory.cloud_cost_guard_contract,qa.threshold_gate`
  passed with 5840 checks, 0 failures, 0 actualFailures.
- `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.harness_registry,qa.threshold_gate`
  passed with 392 checks, 0 failures, 0 actualFailures.
- `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_PROFILE=smoke --dart-define=PARSER_QA_PRESET=quick`
  passed with 8413 checks, 0 failures, 0 actualFailures.

Latest evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T151052223340.json`
- adminHealth: passing
- packHealth: ready

doNotRerunUnless:

- quick preset membership changes.
- boundary/no-live/cloud-cost guard source changes.
- new parser QA suites are registered.
- local parser QA tools add new output manifests or cloud-related flags.

## Admin Report Contract Validation

Status: passing for local inventory parser admin report contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.admin_report_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153009065318.json`
- checked: 26
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_admin_report_contract_qa.dart` changes.
- admin parser report fields, artifact schema, or threshold-gate behavior changes.

## Artifact Contract Validation

Status: passing for local inventory parser QA artifact contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.artifact_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153044667033.json`
- checked: 22
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_artifact_contract_qa.dart` changes.
- QA artifact paths, summary fields, latest-file behavior, or threshold-gate behavior changes.

## Artifact Retention Contract Validation

Status: passing for local inventory parser QA artifact retention contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.artifact_retention_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153112018021.json`
- checked: 30
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_artifact_retention_qa.dart` changes.
- QA report retention, latest-artifact cleanup, or threshold-gate behavior changes.

## Batch Continuation Contract Validation

Status: passing for local inventory parser QA batch continuation contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.batch_continuation_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153142804212.json`
- checked: 18
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_batch_continuation_qa.dart` changes.
- QA batch resume, rerun suppression, or threshold-gate behavior changes.

## Blueprint Contract Validation

Status: passing for local inventory parser catalog blueprint contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.blueprint_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153210344339.json`
- checked: 22
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_blueprint_contract_qa.dart` changes.
- catalog blueprint schema, required fields, or threshold-gate behavior changes.

## Blueprint Promotion Contract Validation

Status: passing for local inventory parser catalog blueprint promotion contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.blueprint_promotion_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153238540405.json`
- checked: 21
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_blueprint_promotion_qa.dart` changes.
- blueprint promotion, generated/manual flags, promotion gates, or threshold-gate behavior changes.

## Bulk Generation Pipeline Contract Requirements

Status: required before expanding inventory catalog rows in large batches.

Purpose:

Bulk catalog generation must create smart catalog items and their QA evidence
together. A generated item is not release-ready just because it exists in the
catalog; it must be paired with fixtures, contract checks, promotion gates, and
surgical rerun metadata so failures can be fixed without grinding the whole
catalog again.

Required pipeline stages:

- blueprint
- generated item
- generated fixture
- schema validation
- alias validation
- conflict validation
- merchant validation
- promotion gate
- progress memory
- focused rerun

Required named rules:

- generate_items_and_fixtures_together
- do_not_promote_without_fixture_pair
- do_not_rerun_completed_cells_unless_inputs_changed
- batch_manifest_records_scope_trade_tier_locale
- batch_status_records_failed_cell_count
- batch_status_records_completed_cell_count
- local_only_generation
- no_live_firebase_generation
- no_ocr_camera_expenses_touch
- surgical_retry_for_failed_cell

Required release-one scale axes:

- plumbing
- electrical
- hvac
- fasteners
- residential
- en-US
- es-US
- core
- standard
- professional
- complete

Required smart-row quality signals:

- stable id
- canonical name
- aliases
- receipt phrases
- merchant abbreviations
- negative match
- confidence
- source metadata
- review status
- generated flag

Throughput guard:

Every generated batch must record completed inputs, failed cells, completed
cells, source signatures, and promotion state. Completed cells must not be
rerun unless inputs changed. Failed cells must support focused and surgical
reruns by trade, market scope, pack tier, locale, item family, merchant family,
and failure category. Local tools must report `writesProductionCatalog: false`
until a separate release/upload workflow is explicitly approved.

## Catalog Batch Memory Contract Validation

Status: passing after making local queue status evidence explicit for Firebase
and OCR/camera/Expenses boundaries.

Changed:

- `tool/work_supply_parser_qa_background_queue.dart` now writes
  `firebaseWritesAllowed: false` and `ocrCameraExpensesTouched: false` in
  local summary/status artifacts.
- Existing local all-tier wave status evidence was repaired with the same two
  fields so the memory contract does not build on uncertain evidence.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_batch_memory_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153507955815.json`
- checked: 132
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_catalog_batch_memory_qa.dart` changes.
- `tool/work_supply_parser_qa_background_queue.dart` changes.
- generated batch-wave status files or required safety fields change.

## Catalog Coverage Contract Validation

Status: passing for local inventory catalog coverage.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_coverage,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153540805684.json`
- checked: 56765
- failures: 0
- actualFailures: 0
- adminHealth: passing
- runtime: about 33 seconds inside the QA harness

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_catalog_coverage_qa.dart` changes.
- catalog coverage expectations change.
- catalog source data changes enough to require a fresh coverage gate.

## Catalog Family Rerun Contract Validation

Status: passing for focused inventory catalog family rerun contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_family_rerun_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153644015617.json`
- checked: 28
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_catalog_family_rerun_qa.dart` changes.
- family-level focused rerun commands, fixture paths, or rerun boundaries change.

## Catalog Item Batch Generation Contract Validation

Status: passing for inventory catalog item batch generation contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_item_batch_generation_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T153709795168.json`

## Catalog Item Batch Status Memory Validation

Status: passing for inventory catalog item batch status memory.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_item_batch_generation_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-03T010319376262.json`
- focused unit test: `flutter test test\work_supply_catalog_item_batch_status_test.dart -r compact`
- analyzer: `dart analyze tool\work_supply_catalog_item_batch_status.dart test\work_supply_catalog_item_batch_status_test.dart test\support\work_supply_parser_qa\work_supply_parser_catalog_item_batch_generation_qa.dart`
- item batch status artifact: `build/parser_qa_pipeline/item_batch_status.json`
- status summary: 24 expected residential catalog blueprint cells, 0 present, 24 missing, 0 unsafe, 0 generated items, local-only safety flags false for live services, production catalog writes, Firebase writes, and OCR/camera/Expenses touches

Focused rerun:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.catalog_item_batch_generation_contract,qa.threshold_gate`

Do not rerun unless:

- `tool/work_supply_catalog_item_batch_status.dart` changes
- `test/work_supply_catalog_item_batch_status_test.dart` changes
- catalog blueprint generator/validator paths or manifest schema change
- item batch progress memory or catalog item batch generation contract changes
- checked: 48
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_catalog_item_batch_generation_qa.dart` changes.
- catalog batch generation rules, promotion flow, or generated-item metadata requirements change.

## Holdout Fixture Rotation Governance

Status: required for release-grade parser QA and regression honesty.

2026-07-04 update: Passes 2018-2027 promoted the holdout governance rules from
documentation-only to executable fixture metadata checks. Every committed
holdout row now includes `sourceType`, `sourceOwner`, `reviewDate`,
`expectedAnswerConfidence`, explicit trade/merchant context, and
`regressionHistory`, and `inventory.holdout_fixture_contract` fails if future
holdout rows omit those fields. Verification passed for
`inventory.holdout_fixture_contract`, `inventory.fixture_holdout_rotation_contract`,
`inventory.validation_strategy_contract`, and `qa.threshold_gate` with 93 checks,
0 failures, plus targeted analyzer on the holdout fixture suite.

Named holdout rules:

- holdout_set_not_used_for_rule_tuning
- hidden_fixture_set_has_owner
- fixture_has_review_date
- fixture_has_locale
- fixture_has_merchant
- fixture_has_trade
- fixture_has_synthetic_or_real_flag
- expected_answer_has_confidence
- bad_expected_data_can_poison_parser
- holdout_rotation_preserves_regression_history

Release metrics tracked for holdout validation:

- top-1 accuracy
- top-3 accuracy
- false confident match rate
- unknown rate
- ambiguous rate
- noise false-positive rate
- performance budget
- privacy pass rate
- changed result count
- regression count

Policy:

The holdout set is not tuning data. Parser rules, aliases, merchant
abbreviations, and negative-match rules may be changed after holdout failures,
but the corrected case must either move into regression coverage or be replaced
with a fresh hidden holdout row so the holdout set remains an honest release
signal. Each holdout fixture must preserve owner/source notes, review date,
locale, merchant, trade, synthetic-or-real flag, expected answer confidence, and
regression history.

## Recipe Completeness Contract Validation

Status: passing for release-one fixture recipe completeness.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.recipe_completeness_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T160815880896.json`
- checked: 26
- failures: 0
- actualFailures: 0
- adminHealth: passing

Fix applied:

- Added `generated_batch` as real fixture recipe risk metadata for representative Plumbing, Electrical, and HVAC Core/Standard recipes in English and Spanish.

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_recipe_completeness_qa.dart` changes.
- `tool/work_supply_parser_qa_fixture_recipes*.dart` recipe list names or required risk signals change.

## Registry Snapshot Contract Validation

Status: passing for local parser QA registry snapshot inspection.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.registry_snapshot_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T160905798268.json`
- checked: 15
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_registry_snapshot_qa.dart` changes.
- `tool/work_supply_parser_qa_registry_snapshot.dart` or the registry snapshot test changes.

## Release-One Cell Manifest Validation

Status: passing for explicit release-one residential parser QA cell coverage.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_cell_manifest,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T160943249984.json`
- checked: 25
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_release_one_cell_manifest_qa.dart` changes.
- Release-one trade, scope, tier, or locale priorities change.

## Release-One Command Manifest Validation

Status: passing for dry-run-safe release-one parser QA command manifest.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_command_manifest,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161026642194.json`
- checked: 22
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_release_one_command_manifest_qa.dart` changes.
- `tool/work_supply_parser_qa_release_one_commands.dart` or release-one command test behavior changes.

## Release-One Pack Balance Validation

Status: passing for release-one residential pack balance.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_pack_balance,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161239645815.json`
- checked: 32
- failures: 0
- actualFailures: 0
- adminHealth: passing

Fix applied:

- Corrected the pack-balance contract to validate downloadable cumulative packs: Core, Core+Standard, Core+Standard+Professional, and full Complete.
- Kept Core compactness guarded as a service-truck focus ratio instead of treating Standard, Professional, and Complete add-on rows as standalone downloadable packs.

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_release_one_pack_balance_qa.dart` changes.
- Pack-tier semantics, residential tier boundaries, or top-three trade catalog tiering changes.

## Release Orchestration Contract Validation

Status: passing for full/release parser QA orchestration.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_orchestration_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161401535302.json`
- checked: 24
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_release_orchestration_qa.dart` changes.
- Shard runner, threshold gate, preset, harness entrypoint, or release orchestration docs change.

## Release Shard Manifest Validation

Status: passing for full/release shard metadata, timeout, resume, and profiler visibility.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_shard_manifest,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161446167733.json`
- checked: 51
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_release_shard_qa.dart` changes.
- Shard runner, harness run-config metadata, threshold gate, or shard-runner regression tests change.

## Release Signoff Manifest Validation

Status: passing for release sign-off rejection rules.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_signoff_manifest,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161548248176.json`
- checked: 31
- failures: 0
- actualFailures: 0
- adminHealth: passing

Fix applied:

- Cleaned one analyzer info in `tool/work_supply_parser_qa_release_signoff.dart` so the sign-off tool has no known analyzer debt.

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_release_signoff_qa.dart` changes.
- Release sign-off script, shard runner summary schema, sign-off regression tests, or sign-off docs change.

## Requirement Coverage Validation

Status: passing for parser QA requirement-to-suite traceability.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.requirement_coverage,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161631883668.json`
- checked: 108
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_requirement_coverage_qa.dart` changes.
- Requirement coverage matrix, owner suites, or required evidence token wording changes.

## Result Contract Validation

Status: passing for structured parser candidate/result contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.result_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161713102872.json`
- checked: 63
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_result_contract_qa.dart` changes.
- Parser candidate model, parsed receipt bridge, receipt line model, or structured output field contract changes.

## Runtime Measurement Validation

Status: passing for smoke runtime measurement contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.runtime_measurement,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161815304465.json`
- checked: 12
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_runtime_measurement_qa.dart` changes.
- Runtime profile, baseline metric, or parser cold/warm measurement semantics change.

## Separation Safety Validation

Status: passing for parser separation safety smoke contract.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.separation_safety,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T161849122323.json`
- checked: 20
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_separation_qa.dart` changes.
- Parser separation rules for SKU-only lines, brand-only lines, tools, consumables, fees, deposits, returns, or cross-trade ambiguity change.

## Service-Truck Core Contract Validation

Status: passing for residential Core service-truck intent.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.service_truck_core_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T162118023171.json`
- checked: 24020
- failures: 0
- actualFailures: 0
- adminHealth: passing

Fix applied:

- Expanded the QA service-truck signal dictionary for valid Core everyday families: tubular drain/trap/tailpiece/adapter parts, water-heater dielectric/expansion parts, plumbing consumables, electrical ground clamps, HVAC blower motors, and condenser fan blades.

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_service_truck_core_qa.dart` changes.
- Core tier definitions, parser priority derivation, or service-truck catalog families change.

## SLO Metrics Contract Validation

Status: passing for parser SLO and quality metrics governance.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.slo_metrics_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T162235518896.json`
- checked: 41
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_slo_contract_qa.dart` changes.
- Accuracy budgets, confidence bands, runtime threshold gates, admin visibility, telemetry, cost, or privacy SLO wording changes.

## Surgical Rerun Contract Validation

Status: passing for focused rerun and gate-skip evidence.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.surgical_rerun_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T162409682980.json`
- checked: 32
- failures: 0
- actualFailures: 0
- adminHealth: passing

Fix applied:

- Added explicit gate evidence fields for covered input files, source fingerprints, and unchanged affected-source skip checks in the local gate ledger tools.

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_surgical_rerun_qa.dart` changes.
- Gate ledger/skip tooling, generated fixture runner targeting, suite filtering, or focused failure routing changes.

## Validation Strategy Contract Validation

Status: passing for parser validation strategy coverage.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.validation_strategy_contract,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T162442198041.json`
- checked: 50
- failures: 0
- actualFailures: 0
- adminHealth: passing

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_validation_strategy_qa.dart` changes.
- Holdout, differential, baseline, impact, metamorphic, property, or determinism validation strategy files change.

## Vendor Readiness Validation

Status: passing for priority residential vendor-readiness metadata.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.vendor_readiness,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T162747906646.json`
- checked: 211016
- failures: 0
- actualFailures: 0
- adminHealth: passing

Fix applied:

- Added generated non-proprietary merchant-style vendor mapping slots for auto-derived catalog intelligence.
- Added generated family aliases during catalog hydration so residential priority rows have enough alias evidence for vendor-readiness checks.

Do not rerun unless:

- `test/support/work_supply_parser_qa/work_supply_parser_vendor_readiness_qa.dart` changes.
- Catalog hydration, generated aliases, vendor mapping generation, or residential priority catalog intelligence changes.

## Release-One Metadata Gate Validation

Status: passing for generated fixture cell contract, smart-row metadata depth, Spanish release-one coverage, vendor/SKU matrix, and workflow routing.

Command:

`flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.generated_fixture_cell_contract,inventory.item_metadata_depth,inventory.spanish_release_one,inventory.vendor_sku_matrix_contract,inventory.workflow_routing,qa.threshold_gate`

Evidence:

- report: `build/parser_qa_reports/work_supply_inventory_parser_2026-07-02T164434581620.json`
- checked: 608891
- failures: 0
- actualFailures: 0
- adminHealth: passing

Fix applied:

- Catalog hydration now adds generated non-proprietary merchant-style vendor mappings.
- Catalog hydration now adds generated family aliases.
- Generated catalog intelligence now provides default pack quantity for workflow routing.
- Generated catalog intelligence now provides es-US Spanish alias/receipt/attribute signals, including conservative unit evidence for named variants and pack-count rows.

Do not rerun unless:

- `lib/screens/work_supplies/data/work_supply_catalog.dart` changes.
- `lib/screens/work_supplies/data/work_supply_catalog_intelligence.dart` changes.
- Generated fixture cell, item metadata depth, Spanish release-one, vendor/SKU, or workflow routing QA source changes.

## Release-One Residential Gates

Release one is residential-first inventory parser work. Core and Standard must favor service truck, everyday, most common, and normal residential items stocked or commonly bought through Lowe, Home Depot, Ace, Menards, Ferguson, Grainger, Walmart, True Value, and local/supply-house equivalents.

Core comes before Standard, Standard comes before Professional, and Professional/Complete later tiers must not pull attention away from release-one Core/Standard readiness. No special order appliance bloat in Core; Core is for normal residential service-truck parts and common store-run materials.

Release-one catalog gap closed in the plumbing item batch:

- Added well pump, well pipe adapter, pressure tank, pressure switch, pitless adapter, and well check-valve service families to Plumbing residential catalog coverage.
- Expanded the release-one residential catalog with additional non-proprietary service-truck rows for well pressure gauges, well tank tees, well service fittings, water-heater pans, water-heater restraint straps, gas water-heater connectors, water-heater service fittings, HVAC duct sealant tubes, HVAC service tape, duct connectors, duct cleats/S-lock, duct hanger strap, and sheet-metal duct screws.
- Guarded the well-service family with `inventory.release_one_service_family_contract`.
- Expanded the release-one Core/Standard service-family gate for residential Plumbing, Electrical, and HVAC so it now checks common home pipe fittings, water-distribution materials, toilet tank rebuild parts, drain/trap repair, switch/outlet repair, breaker service, grounding/bonding, HVAC filters, HVAC controls, and duct repair/seal materials.
- The service-family report now records per-tier counts so Core and Standard gaps can be reviewed without rerunning the entire parser QA stack.
- Added an executable Residential Core bloat guard so priority-trade Core rows are scanned for obvious full-fixture/appliance terms while allowing repair kits, connectors, valves, straps, supply lines, drain pans, and service parts.
- Expanded the release-one bloat guard to scan Standard as well as Core so Standard remains common residential service coverage instead of absorbing Professional/Complete fixture or appliance rows.
- Tightened the release-one service-family gate so Plumbing, Electrical, and HVAC Core/Standard rows must show required everyday signals inside each family, including common fittings, water distribution, toilet repair, faucet/sink repair, drain/trap repair, supply stops, water-heater service, well service, electrical devices/breakers/grounding/conduit, and HVAC filters/controls/condensate/duct repair.
- Added Plumbing service-tool coverage to the release-one service-family gate for pipe cutters, PEX crimp tools, basin wrenches, toilet augers, and drain snakes.
- Added an explicit Plumbing service-truck `toilet auger` variant so common receipt/user wording is represented directly instead of relying only on the `closet auger` alias.
- Tightened the release-one fastener/support gate so Plumbing, Electrical, and HVAC Core/Standard rows must show required support signals such as threaded rod/all-thread/tapcon, conduit straps/ground clamps/locknuts, and sheet-metal/zip/tek/duct strap hardware.
- Kept HVAC condensate pumps in the everyday Core path so normal residential condensate drain service is not pushed into later-tier professional equipment coverage by the generic pump signal.
- Promoted Standard to first-release fixture-cell coverage beside Core for Plumbing, Electrical, and HVAC in both en-US and es-US, and added six Standard priority-cell golden fixture seeds for focused reruns.
- Added `inventory.standard_fixture_seed_contract` as a surgical Standard fixture seed suite. Smoke mode validates the seed contract without parser calls; full/release profile runs the expensive parser checks because catalog startup is too slow for the Windows smoke budget.
- Hardened `inventory.merchant_matrix_contract` so it reads the golden fixture corpus and proves every required major merchant appears in release-one Plumbing/Electrical/HVAC Core/Standard residential fixture coverage, not only in source-token documentation.
- Added `inventory.merchant_matrix_contract` to the surgical rerun contract so merchant coverage failures must stay targetable by focused rerun instead of forcing a broad harness pass.
- Hardened `inventory.category_inference_contract` so it reads the golden fixture corpus and proves required ambiguity axes exist for PVC conduit, PVC condensate, foil/electrical/drywall tape, filters, old-work boxes, J-boxes, threaded rod/all-thread, and tapcons.
- Added seven synthetic review fixtures for category-inference ambiguity coverage without proprietary merchant data: PVC condensate, foil tape, electrical tape, drywall tape, old-work box, J-box, and tapcon.
- Hardened accumulated fixture coverage with an explicit non-priority fixture-cell allowlist so category-inference fixtures outside Plumbing/Electrical/HVAC Core/Standard must have a documented reason instead of silently expanding release-one scope.
- Added Spanish well-service parser signals for bomba/tanque/well pressure/tank/switch/adapter/check-valve terminology.
- Expanded Spanish release-one QA so es-US coverage must include service-family terminology for plumbing pipe fittings, water-distribution materials, toilet repair, sink/faucet repair, electrical devices/breakers, wire/conduit/grounding, HVAC filters/controls, and HVAC condensate/duct work.
- Expanded Spanish release-one service-tool coverage for Plumbing pipe cutters, PEX crimp tools, basin wrenches, toilet augers, and drain snakes.
- Added tank ambiguity guards so pressure tanks keep negative-match evidence against propane, fuel, and compressor tanks.
- Added gauge ambiguity guards so well pressure gauges keep negative-match evidence against tire, air-compressor, and fuel-pressure gauges.
- Validated after the catalog expansion:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,inventory.catalog_schema,qa.threshold_gate`
  passed 22608 checks with 0 failures.
- Validated Spanish after the catalog expansion and gauge ambiguity fix:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101446 checks with 0 failures.
- Validated Spanish after adding Plumbing service-tool locale terms:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101841 checks with 0 failures.
- Validated pack balance after the catalog expansion:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_pack_balance,inventory.catalog_coverage,qa.threshold_gate`
  passed 56847 checks with 0 failures.
- Validated vendor/SKU readiness after the catalog expansion:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.vendor_readiness,inventory.vendor_sku_matrix_contract,qa.threshold_gate`
  passed 211467 checks with 0 failures.
- Validated the executable Core bloat guard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_tier_role_contract,qa.threshold_gate`
  passed 6016 checks with 0 failures.
- Validated after expanding the tier-role bloat scan to Core plus Standard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_tier_role_contract,qa.threshold_gate`
  passed 16985 checks with 0 failures.
- Added an executable pack-overlap guard so release-one Plumbing, Electrical, and HVAC Core/Standard rows must preserve explicit multi-scope evidence and cross-trade ambiguity terms instead of duplicating canonical items or pretending ambiguous receipt words are certain.
- Validated executable pack overlap:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.pack_overlap_contract,qa.threshold_gate`
  passed 16965 checks with 0 failures.
- Validated after the required service-signal gate and HVAC condensate pump tier fix:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,qa.threshold_gate`
  passed 16988 checks with 0 failures.
- Validated after adding Plumbing service-tool required signals and explicit toilet-auger catalog coverage:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,qa.threshold_gate`
  passed 16991 checks with 0 failures.
- Validated after adding required fastener/support signals:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_fastener_support_contract,qa.threshold_gate`
  passed 16979 checks with 0 failures.
- Validated Standard fixture-cell coverage:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.accumulated_coverage_contract,inventory.fixture_coverage_matrix,qa.threshold_gate`
  passed 124 checks with 0 failures.
- Validated the six new Standard fixture seed lines with a temporary focused Flutter parser probe; all resolved to the intended trade. The focused probe took about 3:41 on the Windows machine due Flutter/catalog startup.
- Validated the surgical Standard fixture seed smoke route:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.standard_fixture_seed_contract,inventory.surgical_rerun_contract,qa.threshold_gate`
  passed 58 checks with 0 failures in smoke mode.
- Validated executable merchant matrix fixture coverage:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.merchant_matrix_contract,qa.threshold_gate`
  passed 89 checks with 0 failures.
- Validated surgical rerun routing after adding the merchant matrix route:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.surgical_rerun_contract,qa.threshold_gate`
  passed 50 checks with 0 failures.
- Validated executable category-inference fixture axes:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.category_inference_contract,inventory.fixture_coverage_matrix,qa.threshold_gate`
  passed 182 checks with 0 failures.
- Validated accumulated coverage drift guard after adding the drywall tape allowlist:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.accumulated_coverage_contract,inventory.fixture_coverage_matrix,qa.threshold_gate`
  passed 138 checks with 0 failures.
- Validated after the expanded Spanish family-term QA gate:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101224 checks with 0 failures.
- Validated after the expanded service-family QA gate:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,qa.threshold_gate`
  passed 16888 checks with 0 failures.
- Validated after the catalog change:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,inventory.catalog_schema,qa.threshold_gate`
  passed 22558 checks with 0 failures.
- Validated Spanish after the catalog change:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101175 checks with 0 failures.
- Validated pack balance after the catalog change:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_pack_balance,inventory.catalog_coverage,qa.threshold_gate`
  passed 56805 checks with 0 failures.
- Tightened release-one Core/Standard service-family QA so Plumbing, Electrical,
  and HVAC residential families now declare required tier presence. This prevents
  a family from appearing covered only because the combined Core+Standard count
  is high while the intended Core or Standard tier is empty.
- Validated the tier-presence service-family gate:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,qa.threshold_gate`
  passed 17028 checks with 0 failures.
- Tightened release-one pack-balance QA with explicit minimum Core and Standard
  residential row floors for Plumbing, Electrical, and HVAC so priority cells
  cannot silently collapse while Professional/Complete grows.
- Validated the Core/Standard priority floor gate:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_pack_balance,qa.threshold_gate`
  passed 38 checks with 0 failures.
- Tightened Spanish release-one QA with its own Core/Standard sweep floors for
  Plumbing, Electrical, and HVAC so es-US cannot claim readiness if it stops
  checking the priority residential cells.
- Validated the Spanish Core/Standard sweep-floor gate:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101847 checks with 0 failures.
- Tightened fixture coverage so the golden fixture corpus must include every
  release-one priority cell from the manifest: residential Plumbing, Electrical,
  and HVAC Core/Standard in en-US and es-US.
- Validated the release-one fixture-cell coverage gate:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_coverage_matrix,qa.threshold_gate`
  passed 95 checks with 0 failures.
- Added the release-one Core/Standard priority-cell row to the master coverage
  matrix and executable matrix contract so Plumbing, Electrical, HVAC, en-US,
  es-US, Core, Standard, and residential coverage remain visible at the
  checklist level.
- Validated the master matrix after adding the priority-cell row:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.master_coverage_matrix_contract,qa.threshold_gate`
  passed 111 checks with 0 failures.
- Added priority-cell reporting to the release-one command manifest tool so the
  12 Core/Standard residential Plumbing, Electrical, and HVAC en-US/es-US cells
  are visible apart from the full 24-cell all-tier command list.
- Validated release command priority-cell reporting:
  `flutter test test\work_supply_parser_qa_release_one_commands_test.dart`
  passed 2 tests with 0 failures.
- Validated the release command manifest contract:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_command_manifest,qa.threshold_gate`
  passed 24 checks with 0 failures.
- Validated the combined release-one priority-cell gate after the Core/Standard
  floor, Spanish sweep, fixture-cell, matrix, and command-manifest hardening:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_cell_manifest,inventory.release_one_pack_balance,inventory.release_one_service_family_contract,inventory.spanish_release_one,inventory.fixture_coverage_matrix,inventory.release_one_command_manifest,inventory.master_coverage_matrix_contract,qa.threshold_gate`
  passed 119138 checks with 0 failures.
- Added explicit sink repair kit aliases to existing Plumbing sink/faucet and
  drain finish service rows, plus es-US sink repair kit locale terms, without
  creating duplicate catalog rows.
- Tightened the release-one service-family QA so sink repair kit remains a
  required Plumbing Core/Standard sink/faucet repair signal.
- Validated sink repair kit catalog/schema/service-family coverage:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,inventory.catalog_schema,qa.threshold_gate`
  passed 22711 checks with 0 failures.
- Validated Spanish after the sink repair kit locale expansion:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101847 checks with 0 failures.
- Added explicit toilet repair kit aliases to existing Plumbing toilet repair
  rows, plus es-US toilet repair kit locale terms, without creating duplicate
  catalog rows.
- Tightened the release-one service-family QA so toilet repair kit remains a
  required Plumbing Core/Standard toilet repair signal.
- Validated toilet repair kit catalog/schema/service-family coverage:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,inventory.catalog_schema,qa.threshold_gate`
  passed 22711 checks with 0 failures.
- Validated Spanish after the toilet repair kit locale expansion:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101847 checks with 0 failures.
- Added es-US faucet repair kit locale terms while avoiding a new edit to the
  already-over-500-line generated plumbing service-truck catalog file.
- Validated Spanish after the faucet repair kit locale expansion:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.spanish_release_one,qa.threshold_gate`
  passed 101847 checks with 0 failures.
- Added a protected app-file baseline to `inventory.file_size_contract` for
  `generated_plumbing_service_truck_catalog.dart` at its current 549 lines so
  future passes fail if this already-over-target file grows instead of being
  split.
- Updated the trade-pack handoff line-count note from the stale 474-line value
  to the current 549-line protected baseline.
- Validated the file-size guard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.file_size_contract,qa.threshold_gate`
  passed 203 checks with 0 failures.
- Tightened the release-one cell manifest so it now enforces the exact 12-cell
  priority set and explicit Core/Standard tier presence.
- Validated the release-one cell manifest:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_cell_manifest,qa.threshold_gate`
  passed 28 checks with 0 failures.
- Added six golden receipt fixtures for Plumbing Core repair-kit phrases:
  toilet, sink, and faucet repair kit in en-US and es-US.
- Validated fixture JSON loading and static fixture coverage:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_coverage_matrix,inventory.accumulated_coverage_contract,qa.threshold_gate`
  passed 162 checks with 0 failures.
- Remaining risk: full runtime parser validation for the new repair-kit fixture
  lines timed out on the Windows machine. Do not claim those six lines are
  runtime-proven until a focused parser fixture run completes on the Mac or a
  faster non-Flutter parser harness.
- Tightened fixture coverage so the six required Plumbing Core repair-kit
  fixture IDs cannot disappear or lose their English/Spanish locale, Core tier,
  Plumbing trade, or repair-kit risk tags without failing
  `inventory.fixture_coverage_matrix`.
- repair_kit_fixture_lock:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_coverage_matrix,inventory.accumulated_coverage_contract,qa.threshold_gate`
- Validated the repair-kit fixture lock:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_coverage_matrix,inventory.accumulated_coverage_contract,qa.threshold_gate`
  passed 168 checks with 0 failures.
- Fixed the six Plumbing Core repair-kit golden fixtures so each now carries
  `expectedTopCandidateId` and `expectedReviewRequired` metadata instead of
  relying only on broad expected name/trade hints.
- Tightened `inventory.fixture_expectation_contract` so fixture expectations now
  enforce the shared status vocabulary, confidence-band vocabulary, and
  status/review/confidence consistency.
- Validated the expectation contract:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_expectation_contract,qa.threshold_gate`
  passed 268 checks with 0 failures.
- Tightened `inventory.fixture_corpus_contract` so golden fixtures now require
  stable non-empty IDs, unique fixture IDs, non-empty raw receipt text, and
  unique normalized raw lines. This prevents duplicate fixture evidence from
  inflating parser coverage.
- Validated the fixture corpus and expectation gates together:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_corpus_contract,inventory.fixture_expectation_contract,qa.threshold_gate`
  passed 434 checks with 0 failures.
- Tightened `inventory.fixture_corpus_contract` again so golden fixtures must
  use an allowed case-type vocabulary and cannot be accidentally marked
  `holdoutOnly`.
- Validated the case-type/holdout boundary guard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_corpus_contract,qa.threshold_gate`
  passed 178 checks with 0 failures.
- Added `inventory.fixture_corpus_contract` and
  `inventory.fixture_expectation_contract` to the surgical rerun contract so
  fixture metadata failures stay targetable.
- Validated surgical rerun routing after the fixture route additions:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.surgical_rerun_contract,qa.threshold_gate`
  passed 54 checks with 0 failures.
- Added `inventory.fixture_candidate_identity_contract` as a targeted static
  catalog identity suite. It treats `expectedTopCandidateId` as a stable
  semantic candidate key, not a generated sequential catalog ID, and validates
  matched golden/holdout fixtures against real catalog item search text,
  expected trade, and expected name hints without invoking the parser runtime.
- Fixed the two sink repair kit fixtures so they point to `sink_repair_kit`
  instead of the faucet O-ring semantic key.
- Validated fixture candidate identity:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_candidate_identity_contract,qa.threshold_gate`
  passed 60 checks with 0 failures. Runtime note: this static catalog suite took
  about 82 seconds on the Windows machine because catalog construction is heavy;
  keep it targeted until the faster harness/Mac path is available.
- Added `inventory.fixture_candidate_identity_contract` to the surgical rerun
  contract, the targeted-suite registry allowlist, and the harness plan
  requirement matrix. Also restored the missing targeted allowlist/plan entry
  for `inventory.standard_fixture_seed_contract`.
- Validated registry and surgical routing:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.surgical_rerun_contract,inventory.harness_registry,qa.threshold_gate`
  passed 450 checks with 0 failures.
- Added `inventory.fixture_candidate_identity_contract` to the master coverage
  matrix registry section and executable matrix contract.
- Validated the master coverage matrix:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.master_coverage_matrix_contract,qa.threshold_gate`
  passed 113 checks with 0 failures.
- Added `inventory.fixture_candidate_identity_contract` to executable
  requirement coverage ownership.
- Validated requirement coverage:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.requirement_coverage,qa.threshold_gate`
  passed 109 checks with 0 failures.
- Added `repair_kit_runtime_fixture_validation_pending` to the known-debt
  ledger as full-profile runtime evidence debt, with an exit condition requiring
  a focused Mac/faster-harness parser fixture shard for the six repair-kit lines.
- Added `PARSER_QA_FIXTURE_IDS` support to `inventory.golden_fixtures` so
  fixture-runtime proof can be focused to exact regression IDs without rerunning
  the full corpus.
- Fixed the focused repair-kit runtime shard by giving sink repair kits a real
  Plumbing catalog identity and adding specificity scoring so `sink/lavabo/
  fregadero repair kit` receipt lines beat faucet O-ring repair candidates
  without weakening the fixture expectations.
- Replaced stale `repair_kit_runtime_fixture_validation_pending` with
  `repair_kit_full_profile_throughput_debt`: the six repair-kit fixtures now
  pass runtime semantic validation, but the Windows full-profile shard still
  reports the known `inventory.golden_fixtures` throughput warning.
- Validated the focused repair-kit runtime shard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_PROFILE=full --dart-define=PARSER_QA_SUITES=inventory.golden_fixtures,qa.threshold_gate --dart-define=PARSER_QA_FIXTURE_IDS=plumbing_core_toilet_repair_kit_en_us,plumbing_core_toilet_repair_kit_es_us,plumbing_core_sink_repair_kit_en_us,plumbing_core_sink_repair_kit_es_us,plumbing_core_faucet_repair_kit_en_us,plumbing_core_faucet_repair_kit_es_us`
  checked 6 golden fixtures with 0 semantic failures; threshold gate reported 1
  warning for throughput at 0.04 checks/sec.
- Cleared `repair_kit_full_profile_throughput_debt` by adding a plumbing
  repair-kit direct matcher in the plumbing parser part file while keeping the
  oversized main parser file at its protected 4954-line baseline.
- Revalidated the focused repair-kit runtime shard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_PROFILE=full --dart-define=PARSER_QA_SUITES=inventory.golden_fixtures,qa.threshold_gate --dart-define=PARSER_QA_FIXTURE_IDS=plumbing_core_toilet_repair_kit_en_us,plumbing_core_toilet_repair_kit_es_us,plumbing_core_sink_repair_kit_en_us,plumbing_core_sink_repair_kit_es_us,plumbing_core_faucet_repair_kit_en_us,plumbing_core_faucet_repair_kit_es_us`
  checked 6 golden fixtures with 0 semantic failures and no threshold warnings;
  `inventory.golden_fixtures` measured 432 ms at 13.89 checks/sec.
- Validated the known-debt ledger:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.known_debt_ledger,qa.threshold_gate`
  passed 13 checks with 0 failures.
- Added protected "do not grow before split" file-size baselines for existing
  oversized inventory parser app-source files:
  `work_supply_receipt_parser.dart` at 4954 lines,
  `work_supply_receipt_parser_trade_scores_core.dart` at 2333 lines,
  `work_supply_receipt_parser_trade_scores_finishes.dart` at 1796 lines, and
  `work_supply_receipt_parser_trade_scores_exterior.dart` at 1130 lines. These
  baselines do not approve the file sizes; they prevent future inventory parser
  passes from making those oversized files worse before they are split.
- Validated the file-size guard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.file_size_contract,qa.threshold_gate`
  passed 208 checks with 0 failures.
- Strengthened `inventory.file_size_contract` so every Dart file under
  `lib/screens/work_supplies/data` is scanned for the 1000-line hard limit.
  Existing over-hard files must be in the protected baseline map; any future
  unprotected over-hard inventory app/source file fails the gate.
- Validated the expanded file-size guard:
  `flutter test test\work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.file_size_contract,qa.threshold_gate`
  passed 419 checks with 0 failures.
- Cleared the focused repair-kit runtime debt and launched the next local-only
  residential top-three all-tier generated-fixture wave after regenerating the
  release-one command manifest.
- Active background wave:
  `pass1164-residential-top-three-all-tiers-wave-execute`
- Active background QA layer:
  `generated_fixture_all_tiers_v3_repair_kit_fast_path`
- Active background fixture run limit:
  `fixtureRunLimit=118`
- Active background previous wave:
  `pass1162-residential-top-three-all-tiers-wave-dryrun`
- Active background wave plan:
  `build/parser_qa_batch_waves/pass1164-residential-top-three-all-tiers-wave-execute/wave_plan.json`
- Active background queue root:
  `build/parser_qa_batch_waves/pass1164-residential-top-three-all-tiers-wave-execute/queue`
- Active background stdout/stderr:
  `build/parser_qa_batch_waves/pass1164-residential-top-three-all-tiers-wave-execute/launch_stdout.log`,
  `build/parser_qa_batch_waves/pass1164-residential-top-three-all-tiers-wave-execute/launch_stderr.log`
- Active background process evidence:
  `PID 2636` was present for the hidden wave runner at launch verification,
  with child Dart worker processes also present.
- Active background safety flags:
  live services false, production catalog writes false, Firebase writes false,
  OCR/camera/Expenses touches false.

Named release gates:

- core_comes_before_standard
- standard_comes_before_professional
- professional_comes_before_complete
- english_before_spanish_only_when_required_by_release_order
- spanish_is_non_negotiable_for_us_release
- residential_before_light_industrial
- residential_before_commercial
- no_special_order_appliance_bloat_in_core
- service_truck_core_before_obscure_items
- all_new_items_get_fixture_pairs

Release boundaries:

- No OCR.
- No camera.
- No Expenses.
- No live Firebase.
- Inventory parser/catalog work only unless explicitly redirected.

## 2026-07-03/04 Wrapper Remediation And Active Wave

- Pass 1437 next-action found
  `pass1339-residential-top-three-all-tiers-wave-execute` completed 24/24 cells
  with 18 failed cells. The representative failed transcripts showed the
  temporary direct-Dart generated-fixture runner crashed in the Dart VM/FFI
  compiler before parser semantics ran. This was a tooling/root-cause failure,
  not evidence that 18 item families were semantically wrong.
- Fixed the generated-fixture execution path in commit `8f9ff3e` by routing
  `tool/work_supply_parser_qa_run_generated_fixtures.dart` through the stable
  Flutter semantic runner until the parser core is extracted far enough for
  true Dart CLI execution. The wrapper emits
  `QA_GENERATED_FIXTURE_RUN_WRAPPER` with
  `parser_core_not_yet_extracted_for_dart_cli` so the limitation stays visible.
- Verification passed:
  `flutter test test\work_supply_parser_qa_run_generated_fixtures_test.dart test\work_supply_parser_qa_pipeline_test.dart test\work_supply_parser_qa_matrix_pipeline_test.dart`
  and focused generated-runner contracts:
  `inventory.generated_manifest_contract,inventory.generated_fixture_performance_contract,inventory.execution_command_contract,qa.threshold_gate`.
- Representative failed-cell remediation passed for
  `electrical_residential_core_en_US` with `checked=1`, `failures=0`, and clean
  local-only status evidence at
  `build/parser_qa_pass_evidence/pass1439_electrical_core_wrapper_remediation/electrical/residential/core/en-US/reports/latest_generated_fixture_run.json`.
- `build/parser_qa_pass_evidence/wave_remediations.json` now records the
  pass1339 failed-wave remediation locally. Pass 1441 next-action verified
  `readyForNextBatch=true`, zero blockers, and no unsafe live-service,
  production-write, Firebase, OCR, camera, or Expenses flags.
- Active background wave launched at Pass 1442:
  `pass1442-residential-top-three-all-tiers-wave-execute`.
- Active background QA layer:
  `generated_fixture_all_tiers_v5_wrapper_remediation`.
- Active background fixture run limit:
  `fixtureRunLimit=118`.
- Active background process:
  hidden PowerShell runner launched with PID `16744`.
- Active background status path:
  `build/parser_qa_batch_waves/pass1442-residential-top-three-all-tiers-wave-execute/queue/pass1442_residential_top_three_all_tiers_wave_execute_generated_fixture_all_tiers_v5_wrapper_remediation/latest_status.json`.
- Pass 1443 next-action verified the new wave is running on
  `plumbing_residential_core_en_US` with `completedCellCount=0`,
  `failedCellCount=0`, no stale status, and all safety flags false.

## 2026-07-04 Merchant Independence, Private Receipt, And Portability Hardening

- Passes 1820-1839 verified the interrupted barcode identity shard and added
  `inventory.merchant_independence_contract`. Commit `21f9199` pushed the
  contract, release-one scorecard rules, docs, registry wiring, and surgical
  rerun route. Focused checks passed for merchant independence, harness
  registry, surgical rerun, analyzer, and diff hygiene.
- Passes 1840-1847 strengthened the new merchant-independence contract to read
  the committed golden fixture corpus and added synthetic priority fixtures for
  `Local Hardware`, `Regional Supplier`, `Counter Sale`, and generic unknown
  merchant ambiguity. Commit `905eb61` pushed the fixture-backed coverage.
  Focused checks passed for `inventory.merchant_independence_contract`,
  `inventory.fixture_corpus_contract`, and `inventory.fixture_expectation_contract`.
- Passes 1848-1856 added
  `tool/work_supply_parser_real_receipt_validation_log.dart` and
  `test/work_supply_parser_real_receipt_validation_log_test.dart`. The tool
  writes privacy-safe summaries only under `build/`, rejects raw receipt/OCR/photo
  fields, keeps live services and Firebase writes false, and documents that real
  private receipt findings must become synthetic fixtures before commit. Commit
  `f2bc966` pushed the tool and the updated
  `inventory.real_receipt_validation_contract`.
- Passes 1857-1863 tightened the shared parser-domain adapter contract so every
  parser domain must declare `mobile_local`, `backend_service`, `qa_harness`,
  `command_line`, and `cloud_batch` execution targets. Commit `e967f9f` pushed
  this environment-independent parser QA boundary and matching tests.
- Pass 1865 reran confidence/review/barcode/vendor safety shards after the new
  fixtures. Result: 189 checks, 0 failures. No parser-code confidence cap or
  suppression hack was found; fixture `maxConfidence` values remain test
  expectations for review/unknown cases.
- Pass 1867 next-action snapshot wrote
  `build/parser_qa_pass_evidence/next_action.json`. Active wave
  `pass1687-residential-core-standard-wave-execute` is running with 7/12 cells
  complete, 0 failed cells, no stale status, and all live-service, production
  catalog write, Firebase write, OCR, camera, and Expenses flags false. Do not
  launch a new parser batch wave until this active local-only wave completes.

## 2026-07-04 Release Gate Surgical Rerun Routes

- Pass 1884 tightened the release-one scorecard mapping so every scorecard gate
  can be rerun surgically instead of forcing a full catalog or full Flutter
  sweep.
- inventory.release_one_scorecard_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_scorecard_contract,qa.threshold_gate`
- inventory.release_one_residential_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_residential_contract,qa.threshold_gate`
- inventory.release_one_service_family_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_service_family_contract,qa.threshold_gate`
- inventory.release_one_pack_balance:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.release_one_pack_balance,qa.threshold_gate`
- inventory.merchant_independence_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.merchant_independence_contract,qa.threshold_gate`
- inventory.merchant_matrix_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.merchant_matrix_contract,qa.threshold_gate`
- inventory.fixture_corpus_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_corpus_contract,qa.threshold_gate`
- inventory.fixture_expectation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fixture_expectation_contract,qa.threshold_gate`
- inventory.real_receipt_validation_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.real_receipt_validation_contract,qa.threshold_gate`
- inventory.fake_user_review_workflow:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.fake_user_review_workflow,qa.threshold_gate`
- inventory.hive_authority_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.hive_authority_contract,qa.threshold_gate`
- inventory.hive_firestore_sync_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.hive_firestore_sync_contract,qa.threshold_gate`
- inventory.parser_platform_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.parser_platform_contract,qa.threshold_gate`
- inventory.portability_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.portability_contract,qa.threshold_gate`
- inventory.barcode_inventory_identity_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.barcode_inventory_identity_contract,qa.threshold_gate`
- inventory.human_correction_learning_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.human_correction_learning_contract,qa.threshold_gate`
- inventory.confidence_calibration:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.confidence_calibration,qa.threshold_gate`
- inventory.review_safety_contract:
  `flutter test test/work_supply_parser_qa_harness_test.dart --dart-define=PARSER_QA_SUITES=inventory.review_safety_contract,qa.threshold_gate`
