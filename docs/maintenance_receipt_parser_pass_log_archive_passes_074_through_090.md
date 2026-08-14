# Maintenance Receipt Parser Pass Log Archive — Passes 74-90

This immutable archive preserves the accepted maintenance receipt and setup
ledger for Passes 74-90.
Accepted Passes 1-73 and their full QA evidence are preserved in
[`maintenance_receipt_parser_pass_log_archive_through_pass_073.md`](maintenance_receipt_parser_pass_log_archive_through_pass_073.md).

A pass is one declared file or file-group cycle: inspect existing coverage,
complete all scoped edits, run impact-selected QA until green, record the
eight-part report, close the group, and increment exactly once. Failed or
interrupted checks are evidence inside the open pass, not extra passes.

## Accepted passes after the archive

74. Rolled the complete Pass 1-73 ledger and roadmap into clearly named,
    immutable archives and replaced the canonical files with concise living
    documents that retain the pass definition, ownership fences, QA tiers,
    accuracy floor, current priorities, and handoff instructions.

    1. Production files changed: none.
    2. Existing tests modified: none.
    3. New tests added: none.
    4. Tests consolidated or removed: none.
    5. Tier 1: document line-limit, archive-link, heading, counter, required-
       boundary, `git diff --check`, and existing accuracy-roadmap contract
       checks green.
    6. Tier 2 or Tier 3: not required for documentation-only organization.
    7. Remaining risk: archives are intentionally static; future accepted
       passes must be recorded in this living ledger and roadmap counters.
    8. Maintenance receipt check count: 215 before, 215 after.

75. Added Wheel Alignment and Wheel Balancing as separate merchant-neutral
    manual/parser families, then split shared vehicle models from the oversized
    app-state controller without changing its public API or behavior.

    1. Production files changed: `maintenance_models.dart`,
       `maintenance_receipt_parser_catalog.dart`, `app_state.dart`, and new
       descriptive `app_state_vehicle_models.dart`.
    2. Existing tests modified: no test function; the existing parameterized
       synthetic corpus fixture was extended.
    3. New tests added: two generated corpus checks protect distinct alignment
       and balancing recognition plus spacing/case-noise stability. Extending
       the existing corpus avoided a duplicate test file. The realistic defect
       prevented these services from reaching maintenance review at all. Tier
       2 owns them; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: changed-file analysis, formatting, JSON/diff/line checks, 60
       focused parser/catalog checks, and 21 vehicle/persistence/application
       checks green.
    6. Tier 2: unchanged `maintenance_receipt_qa_gate.sh` green with 217 total
       maintenance and downstream contract checks. Tier 3 is not due.
    7. Remaining risk: the annual alignment/balancing interval is an editable
       app suggestion, not OEM proof; real-receipt holdout evidence is pending.
    8. Maintenance receipt check count: 215 before, 217 after.

76. Extracted the manual maintenance catalog and setup-option logic from the
    near-limit models file into descriptive `maintenance_catalog.dart`, while
    preserving the existing public import and behavior through a Dart part.

    1. Production files changed: `maintenance_models.dart`; new
       `maintenance_catalog.dart`.
    2. Existing tests modified: none.
    3. New tests added: none; existing catalog/setup contracts cover the move.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, line-limit/diff checks, changed-file analysis, and
       14 existing catalog/manual-setup tests green.
    6. Tier 2 or Tier 3: not required for a behavior-preserving extraction;
       Pass 75 completed Tier 2 and no interface or schema changed.
    7. Remaining risk: future catalog additions must keep the new descriptive
       catalog file below 500 lines.
    8. Maintenance receipt check count: 217 before, 217 after.

77. Added Advanced detail extraction for wheel services and extended the
    existing corpus/accuracy framework to measure declared `detailA` and
    `detailB` fields, including spacing/case-noise stability.

    1. Production files changed: parser library/catalog, new descriptive
       `maintenance_receipt_parser_wheel_service_details.dart`, and the manual
       maintenance catalog.
    2. Existing tests modified: catalog contract, parameterized corpus, and
       accuracy gate; the existing synthetic fixture gained expected fields.
    3. New tests added: none; existing parameterized checks were extended.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON/line/diff checks, changed-file analysis, and 60
       focused catalog/corpus/field-accuracy checks green. A fixture generic-
       map loading failure was corrected and rerun green before closure.
    6. Tier 2 or Tier 3: not required for focused detail extraction; Tier 2 was
       green at Pass 75 and the next scheduled Tier 2 checkpoint is Pass 80.
    7. Remaining risk: only wheel-service Advanced fields are annotated so far;
       oil, fluid, filter, date, odometer, and schedule fields remain to add.
    8. Maintenance receipt check count: 217 before, 217 after.

78. Generalized expected-field accuracy checks through the candidate JSON
    contract and annotated five existing oil receipts for oil type, viscosity,
    filter part, completion/purchase state, dates, odometers, and intervals.

    1. Production files changed: none.
    2. Existing tests modified: parameterized corpus and accuracy gate; existing
       synthetic fixtures gained structured expected fields.
    3. New tests added: none.
    4. Tests consolidated: replaced detail-specific branches and counters with
       one table-driven serialized-field comparison without reducing coverage.
    5. Tier 1: formatting, JSON/line/diff checks, changed-file analysis, and 55
       strengthened corpus/field-accuracy checks green.
    6. Tier 2 or Tier 3: not required for test-fixture/measurement hardening;
       the next scheduled Tier 2 checkpoint remains Pass 80.
    7. Remaining risk: fluid, brake, battery, tire, filter, regulatory, and
       additional schedule fields still need systematic expected annotations.
    8. Maintenance receipt check count: 217 before, 217 after.

79. Added receipt-explicit field expectations to seven existing brake,
    battery, tire/wiper, fluid/filter, belt/hose, and completed-service corpus
    fixtures, using the generalized accuracy contract from Pass 78.

    1. Production files changed: none.
    2. Existing tests modified: no test function; the existing parameterized
       synthetic corpus fixture gained structured expected fields.
    3. New tests added: none.
    4. Tests consolidated or removed: none.
    5. Tier 1: JSON, line-limit, and diff checks plus 55 existing corpus and
       per-family/per-field 90% accuracy checks green.
    6. Tier 2 or Tier 3: Tier 2 is scheduled for Pass 80; Tier 3 is not due.
    7. Remaining risk: the 447-line corpus fixture needs a descriptive split
       before expansion; regulatory, drivetrain, and schedule annotations
       remain incomplete.
    8. Maintenance receipt check count: 217 before, 217 after.

80. Split the near-limit synthetic corpus into a frozen baseline shard and a
    descriptive wheel-service shard, then centralized ordered loading and
    duplicate/empty-ID validation in a reusable test-support file.

    1. Production files changed: none.
    2. Existing tests modified: corpus and accuracy loaders; Spark handoff paths
       were updated. All 26 fixture IDs and their order remain preserved.
    3. New tests added: none.
    4. Tests consolidated: removed duplicate JSON loading from two test files
       in favor of one validated shard loader; no behavioral coverage changed.
    5. Tier 1: formatting, JSON, path, unique-ID, count, line/diff checks,
       changed-file analysis, and 57 focused corpus/accuracy/handoff checks
       green.
    6. Tier 2: unchanged `maintenance_receipt_qa_gate.sh` green with 217 total
       maintenance and downstream checks. Tier 3 is not due.
    7. Remaining risk: the 425-line baseline shard is intentionally stable;
       new scenarios must use descriptive family-specific shards.
    8. Maintenance receipt check count: 217 before, 217 after.

81. Added separate Brake Inspection and Steering and Suspension Inspection
    manual/parser families, with completed-service recognition that remains
    distinct from brake-part replacement and generic regulatory inspections.

    1. Production files changed: `maintenance_catalog.dart` and
       `maintenance_receipt_parser_catalog.dart`.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended; no existing test function was duplicated.
    3. New tests added: two generated checks from one safety-inspection fixture
       protect the distinct uncovered behavior under normal and spacing/case-
       noisy text. The existing parameterized corpus could be extended, so no
       separate test file/function was needed. The realistic defect prevented
       completed safety inspections from reaching review or misclassified them
       as brake parts/regulatory inspection. Tier 1 owns these checks; they
       replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 64 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused two-family bundle; Pass
       80 completed Tier 2 and the next scheduled Tier 2 is Pass 90.
    7. Remaining risk: annual inspection intervals are editable app suggestions,
       not OEM proof; real-receipt holdout evidence and broader advisory wording
       remain incomplete.
    8. Maintenance receipt check count: 217 before, 219 after.

82. Added separate Brake Shoes and Brake Drums manual/parser families so drum-
    brake service can be reviewed without being collapsed into disc brake pads,
    rotors, or a generic brake inspection.

    1. Production files changed: `maintenance_catalog.dart` and
       `maintenance_receipt_parser_catalog.dart`.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended; no existing test function was duplicated.
    3. New tests added: two generated checks from one drum-brake fixture protect
       rear shoe/drum completed-service recognition under normal and spacing/
       case-noisy text. The existing parameterized corpus was extendable, so no
       separate test file/function was needed. The realistic defect was loss or
       disc-brake misclassification of completed drum-brake work. Tier 1 owns
       these checks; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 66 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required; Pass 80 completed Tier 2 and this was a
       focused catalog/parser addition. The next scheduled Tier 2 is Pass 90.
    7. Remaining risk: axle extraction is covered, but real receipts may use
       hardware-kit, resurfacing, or machine-shop wording not represented yet.
    8. Maintenance receipt check count: 219 before, 221 after.

83. Added item-local Advanced friction-material extraction for brake pads and
    shoes, and moved the existing axle reader out of the near-limit shared
    parser-support file into descriptive `maintenance_receipt_parser_brake_details.dart`.

    1. Production files changed: parser library/catalog/support, new brake-
       details part, and `maintenance_catalog.dart`.
    2. Existing tests modified: two existing synthetic fixtures gained Ceramic
       and Semi-metallic source/field expectations.
    3. New tests added: none; existing parameterized normal/noisy corpus checks
       already exercised the exact field contract.
    4. Tests consolidated: the axle reader moved from the 468-line general
       support file into its dedicated 19-line module without losing coverage.
    5. Tier 1: formatting, JSON, line/diff checks, changed-file analysis, and 76
       focused parser/catalog/corpus/field-accuracy checks green.
    6. Tier 2: required by the shared parser-helper move; the unchanged
       `maintenance_receipt_qa_gate.sh` completed green with 221 maintenance and
       downstream checks. Tier 3 is not due.
    7. Remaining risk: real receipts may abbreviate friction compounds or place
       material on a separate nonadjacent line; holdout evidence is pending.
    8. Maintenance receipt check count: 221 before, 221 after.

84. Added completed resurfacing/machining recognition and Advanced service-type
    details for brake rotors and drums, using one mixed disc/drum scenario to
    cover multiple related behaviors without increasing test count.

    1. Production files changed: parser catalog/brake-details part and
       `maintenance_catalog.dart`.
    2. Existing tests modified: the existing drum-brake fixture now covers rear
       shoe replacement plus front rotor and rear drum resurfacing.
    3. New tests added: none; the existing parameterized normal/noisy checks
       already protected the expanded candidate and field contract.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, line/diff checks, changed-file analysis, and 64
       focused catalog/corpus/field-accuracy checks green. An initial format
       check failed, formatting was applied, and the same checks reran green
       before closure.
    6. Tier 2 or Tier 3: not required for this focused extraction addition;
       Pass 83 completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: real receipts may identify lathe work only through labor
       codes; the deterministic parser still requires recognizable item text.
    8. Maintenance receipt check count: 221 before, 221 after.

85. Extracted interval and Advanced-option logic from the growing catalog data
    into descriptive `maintenance_catalog_options.dart`, preserving the public
    library API while restoring safe capacity for additional families.

    1. Production files changed: `maintenance_models.dart`,
       `maintenance_catalog.dart`, and new `maintenance_catalog_options.dart`.
    2. Existing tests modified: none.
    3. New tests added: none; existing catalog/manual-setup contracts cover the
       part extraction and public extension behavior.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, line/diff checks, changed-file analysis, and 14
       existing catalog/manual-setup/widget checks green.
    6. Tier 2 or Tier 3: not required for a behavior-preserving extraction;
       Pass 83 completed Tier 2 and no schema or interface changed.
    7. Remaining risk: future catalog growth must keep both the item and option
       parts below 500 lines and retain descriptive ownership.
    8. Maintenance receipt check count: 221 before, 221 after.

86. Made Advanced axle choices consistent across brake pads, rotors, shoes,
    and drums so receipt-prefilled Front/Rear values remain selectable during
    manual review and setup.

    1. Production files changed: `maintenance_catalog_options.dart`.
    2. Existing tests modified: the existing adjacent-family catalog contract
       now verifies axle options for all four brake hardware families.
    3. New tests added: none; the existing test directly covered the same
       catalog/setup contract and was extended.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, line/diff checks, changed-file analysis, and five
       focused catalog contract checks green.
    6. Tier 2 or Tier 3: not required for this focused option correction; Pass
       83 completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: axle wording beyond Front/Rear/Both remains editable
       free text and requires real-receipt holdout evidence.
    8. Maintenance receipt check count: 221 before, 221 after.

87. Added merchant-neutral Fuel System Service and Air Conditioning Service
    manual/parser families with Advanced service-type and refrigerant details.

    1. Production files changed: manual catalog/options, parser library/catalog,
       and new `maintenance_receipt_parser_system_service_details.dart`.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one mixed service fixture
       protect distinct fuel/induction and A/C recognition under normal and
       spacing/case-noisy text. The parameterized corpus was extendable, so no
       separate test function/file was needed. The realistic defect was loss of
       completed service and refrigerant evidence. Tier 1 owns the checks; they
       replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 68 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 83
       completed Tier 2, Pass 90 remains the scheduled checkpoint.
    7. Remaining risk: app intervals are editable suggestions rather than OEM
       proof; real receipts may abbreviate labor operations or refrigerants.
    8. Maintenance receipt check count: 221 before, 223 after.

88. Added separate Brake Calipers and Brake Hoses and Lines manual/parser
    families with axle and caliper service-type details.

    1. Production files changed: manual catalog/options, parser catalog, and
       brake-details extraction.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one hydraulic-hardware fixture
       protect caliper and hose/line separation under normal and spacing/case-
       noisy text. Existing purchase/advisory safety tests already cover shared
       completion semantics, so they were not duplicated. The realistic defect
       was loss or misclassification of safety-critical brake work. Tier 1 owns
       the checks; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 70 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       remains the scheduled Tier 2 checkpoint.
    7. Remaining risk: hard-line labor codes, remanufactured abbreviations, and
       real mixed advisories need holdout evidence.
    8. Maintenance receipt check count: 223 before, 225 after.

89. Split transaction/schedule signals and JSON decoding helpers out of the
    near-limit parser catalog into descriptive parser parts without changing
    public behavior or contracts.

    1. Production files changed: parser library/catalog and new
       `maintenance_receipt_parser_signals.dart` plus
       `maintenance_receipt_parser_json_helpers.dart`.
    2. Existing tests modified: none.
    3. New tests added: none; existing parser, serialization, catalog, corpus,
       and accuracy checks cover the behavior-preserving move.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, line/diff checks, changed-file analysis, and 80
       focused parser/catalog/corpus/accuracy checks green.
    6. Tier 2 or Tier 3: not required for a behavior-preserving file extraction;
       the scheduled Tier 2 checkpoint remains Pass 90.
    7. Remaining risk: signal growth must remain behavior-oriented and avoid
       merchant-layout coupling; the new parts create capacity, not release proof.
    8. Maintenance receipt check count: 225 before, 225 after.

90. Added separate Shocks and Struts, Ball Joints, and Tie Rod Ends manual/
    parser families with item-local position and component details, then
    completed the scheduled ten-pass Tier 2 checkpoint.

    1. Production files changed: manual catalog/options, parser library/catalog,
       and new `maintenance_receipt_parser_suspension_details.dart`.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one mixed steering/suspension
       fixture protect three distinct families and Advanced fields under normal
       and spacing/case-noisy text. The parameterized corpus was extendable, so
       no separate test function/file was needed. The realistic defect was loss
       or collapse of completed suspension and steering work. Tier 2 owns the
       checkpoint coverage; the checks replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 72 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2: scheduled at Pass 90; unchanged
       `maintenance_receipt_qa_gate.sh` passed 221 maintenance, one tracking,
       four shared-adapter, and one downstream expense-boundary check, 227
       total. Tier 3 is not due.
    7. Remaining risk: these are editable condition-based app suggestions, not
       OEM replacement intervals; real labor-code and advisory holdouts remain.
    8. Maintenance receipt check count: 225 before, 227 after.

## Current counter

- Last accepted pass: **90**
- Next pass: **91**
- Architecture/drift review due: after Pass 200 at the earliest, and no later
  than after Pass 300.

## QA accounting

- Current maintenance receipt check count: **227**.
- Latest full maintenance receipt checkpoint: Pass 90, **227 checks green**.
- Tier 1 runs after ordinary changes; Tier 2 runs after feature/shared-contract
  changes and every 10 passes; Tier 3 runs at checkpoints/every 50 passes; Tier
  4 is release-candidate evidence.
- The complete suite is not run after every small edit.

## Ownership boundaries

- OCR owns camera/image quality, perspective, crumple/dirt preparation,
  stitching, and duplicated recognized lines.
- Maintenance begins with OCR-supplied text and must not change OCR/camera.
- Parser/review never silently writes maintenance history or canonical
  odometer state.
- Durable storage/Firebase and Materials/Inventory remain separately owned.
- Work stays in `/Users/rbbie/Documents/Maintainiac_5.7_Active` only.
- Every maintenance receipt source, test, fixture, gate, and living/archive
  document remains below 500 lines.
