# Maintenance Receipt Parser Pass Log

This is the living pass ledger for the maintenance receipt and setup lane.
Accepted Passes 1-73 are preserved in
[`maintenance_receipt_parser_pass_log_archive_through_pass_073.md`](maintenance_receipt_parser_pass_log_archive_through_pass_073.md).
Accepted Passes 74-90 are preserved in
[`maintenance_receipt_parser_pass_log_archive_passes_074_through_090.md`](maintenance_receipt_parser_pass_log_archive_passes_074_through_090.md).

A pass is one declared file or file-group cycle: inspect existing coverage,
complete all scoped edits, run impact-selected QA until green, record the
eight-part report, close the group, and increment exactly once. Failed or
interrupted checks are evidence inside the open pass, not extra passes.

## Accepted passes after the latest archive

91. Archived the complete Pass 74-90 living ledger before it could approach
    the 500-line limit, then recreated this concise living ledger with archive
    links, pass definition, QA accounting, and ownership fences intact.

    1. Production files changed: none.
    2. Existing tests modified: none.
    3. New tests added: none.
    4. Tests consolidated or removed: none.
    5. Tier 1: archive/link, heading, counter, line-limit, diff, and existing
       accuracy-roadmap contract checks green.
    6. Tier 2 or Tier 3: not required for documentation-only organization;
       Pass 90 completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: archives are intentionally static; new accepted passes
       must be recorded in this living ledger.
    8. Maintenance receipt check count: 227 before, 227 after.

92. Added separate Sway Bar Links and Wheel Bearings manual/parser families,
    including position and hub-assembly details.

    1. Production files changed: manual catalog/options, parser catalog, and
       suspension-detail extraction.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one chassis-service fixture
       protect link and wheel-bearing separation under normal and spacing/case-
       noisy text. Existing parameterized coverage was extendable, so no new
       test function/file was needed. The realistic defect was losing completed
       chassis work or confusing it with alignment/balancing. Tier 1 owns the
       checks; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 74 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: bearing labor codes and left/right positions need real-
       receipt evidence; intervals remain editable suggestions, not OEM proof.
    8. Maintenance receipt check count: 227 before, 229 after.

93. Added Water Pump and Thermostat manual/parser families with pump-type and
    thermostat-temperature Advanced details.

    1. Production files changed: manual catalog/options, parser library/catalog,
       and new `maintenance_receipt_parser_cooling_details.dart`.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one cooling-hardware fixture
       protect completed water-pump/thermostat service and temperature details
       under normal and spacing/case-noisy text. The parameterized corpus was
       extendable, so no separate test function/file was needed. The realistic
       defect was losing critical cooling-system service or its temperature
       evidence. Tier 1 owns the checks; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 76 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: labor codes and OEM-specific thermostat ratings require
       real-receipt holdout evidence; intervals are editable suggestions only.
    8. Maintenance receipt check count: 229 before, 231 after.

94. Added Alternator and Starter manual/parser families with component-type
    details, plus a remote-starter false-positive guard.

    1. Production files changed: manual catalog/options, parser library/catalog,
       and new `maintenance_receipt_parser_engine_electrical_details.dart`.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: four generated checks from two scenarios in one engine-
       electrical shard. They protect alternator/starter service and the distinct
       uncovered failure mode where a remote-starter installation could become an
       engine-starter candidate. Existing general purchase/safety tests could not
       be extended to verify that term-specific distinction. Tier 1 owns them;
       they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 80 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: retail abbreviations and remote-start accessory language
       beyond the explicit phrase need real-receipt holdout evidence.
    8. Maintenance receipt check count: 231 before, 235 after.

95. Added separate Ignition Coils and Spark Plug Wires manual/parser families,
    including a guard that keeps wire service from becoming Spark Plugs.

    1. Production files changed: manual catalog/options, parser library/catalog,
       and new `maintenance_receipt_parser_ignition_details.dart`.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one ignition-service fixture
       protect coils and plug wires under normal and spacing/case-noisy text.
       The fixture also protects the distinct false-positive risk of classifying
       plug wires as plug replacement. Existing parameterized corpus coverage
       was extended, so no new test function/file was needed. Tier 1 owns the
       checks; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 82 focused catalog/corpus/accuracy/handoff checks green.
       The initial focused run exposed a Spark Plugs precision failure; its
       pattern now excludes `spark plug wires` and the complete rerun is green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: abbreviated coil or wire labels and real-receipt wording
       still need locked holdout evidence; intervals stay editable suggestions.
    8. Maintenance receipt check count: 235 before, 237 after.

96. Added distinct CV Axles and Engine Mounts manual/parser families, with
    position, axle-state, and mount-type Advanced details.

    1. Production files changed: manual catalog/options, parser library/catalog,
       shared suspension details, and new mount-detail extraction.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one drivetrain/support fixture
       protect completed CV-axle and engine-mount service under normal and
       spacing/case-noisy text. This covers the distinct gap of retaining axle
       position/state and hydraulic mount type without confusing adjacent
       suspension work. Existing parameterized coverage was extendable, so no
       new test function/file was needed. Tier 1 owns the checks; they replace
       no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 84 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: abbreviated axle/mount labor descriptions and left/right
       position phrasing require locked real-receipt holdout evidence.
    8. Maintenance receipt check count: 237 before, 239 after.

97. Split the engine-oil weight options into its own descriptive catalog part
    before further manual-maintenance expansion.

    1. Production files changed: maintenance model part declarations, catalog,
       and new `maintenance_catalog_oil_options.dart`.
    2. Existing tests modified: none.
    3. New tests added: none. This is behavior-preserving capacity work; the
       existing catalog and accuracy contracts already verify the exported oil
       options and parser coverage, so a new test would be redundant. Tier 1
       owns the existing checks; no test was replaced.
    4. Tests consolidated or removed: the oil-weight declaration was moved out
       of the near-capacity catalog file without changing its public contract.
    5. Tier 1: formatting, diff checks, changed-file analysis, and 8 direct
       catalog/accuracy checks green.
    6. Tier 2 or Tier 3: not required; no schema, shared service, or behavior
       changed, and Pass 90 completed Tier 2.
    7. Remaining risk: none introduced by the move; future family growth still
       needs parser collision evidence and locked real-receipt holdouts.
    8. Maintenance receipt check count: 239 before, 239 after.

98. Added separate Belt Tensioner and Idler Pulley manual/parser families.

    1. Production files changed: manual catalog and parser catalog.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one belt-drive fixture protect
       completed tensioner and idler service under normal and spacing/case-noisy
       text, without creating Serpentine Belt or Timing Belt candidates. The
       existing parameterized corpus was extendable, so no test function/file
       was added. Tier 1 owns the checks; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 86 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: abbreviated pulley/tensioner codes need locked real-
       receipt holdout evidence; part purchases remain review-only suggestions.
    8. Maintenance receipt check count: 239 before, 241 after.

99. Added separate Radiator and Radiator Cap manual/parser families.

    1. Production files changed: manual catalog and parser catalog.
    2. Existing tests modified: the catalog contract and shared synthetic-
       corpus loader were extended.
    3. New tests added: two generated checks from one radiator-hardware fixture
       protect completed radiator/cap service under normal and spacing/case-
       noisy text. It specifically verifies that cap, hose, and flush wording
       does not become radiator replacement. Existing parameterized coverage
       was extended, so no new test function/file was needed. Tier 1 owns the
       checks; they replace no existing coverage.
    4. Tests consolidated or removed: none.
    5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
       analysis, and 88 focused catalog/corpus/accuracy/handoff checks green.
    6. Tier 2 or Tier 3: not required for this focused family bundle; Pass 90
       completed Tier 2 and Tier 3 is not due.
    7. Remaining risk: cooling-system shorthand and real service layouts need
       locked holdout evidence; parts purchases remain review-only suggestions.
    8. Maintenance receipt check count: 241 before, 243 after.

100. Added Fuel Pump as a separate manual/parser family and completed the
     scheduled Tier 2 maintenance receipt checkpoint.

     1. Production files changed: manual catalog and parser catalog.
     2. Existing tests modified: the catalog contract and shared synthetic-
        corpus loader were extended.
     3. New tests added: two generated checks from one fuel-pump fixture protect
        completed pump service under normal and spacing/case-noisy text, without
        creating Fuel Filter or Fuel System Service candidates. The existing
        parameterized corpus was extended, so no test function/file was added.
        Tier 1 owns the checks; they replace no existing coverage.
     4. Tests consolidated or removed: none.
     5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
        analysis, and 90 focused catalog/corpus/accuracy/handoff checks green.
     6. Tier 2: the unchanged official `maintenance_receipt_qa_gate.sh` passed:
        formatter and analyzer clean; 239 maintenance, 1 tracking, 4 adapter,
        and 1 expense-maintenance handoff checks green (245 total). Tier 3 is
        not due until the Pass 150 checkpoint.
     7. Remaining risk: pump-module shorthand and real service layouts require
        locked holdout evidence; retail pump purchases remain review-only.
     8. Maintenance receipt check count: 243 before, 245 after.

101. Split utility, electrical, fluid, tire, and renewal catalog entries into
     `maintenance_catalog_utility_items.dart` before further catalog growth.

     1. Production files changed: maintenance model part declarations, catalog,
        and new utility-item catalog part.
     2. Existing tests modified: none.
     3. New tests added: none. The move preserves the public catalog sequence;
        existing catalog and accuracy contracts already verify its complete
        export and parser coverage, so another test would be redundant. Tier 1
        owns those existing checks; no test was replaced.
     4. Tests consolidated or removed: catalog declarations were separated by
        responsibility without changing items, defaults, or Advanced fields.
     5. Tier 1: formatting, diff checks, changed-file analysis, and 8 direct
        catalog/accuracy checks green.
     6. Tier 2 or Tier 3: not required; no behavior, schema, or shared service
        changed, and Pass 100 completed Tier 2.
     7. Remaining risk: none introduced by the move; further family expansion
        still requires collision coverage and locked real-receipt holdouts.
     8. Maintenance receipt check count: 245 before, 245 after.

102. Added Oxygen Sensors as a distinct manual/parser maintenance family.

     1. Production files changed: manual catalog and parser catalog.
     2. Existing tests modified: the catalog contract and shared synthetic-
        corpus loader were extended.
     3. New tests added: two generated checks from one oxygen-sensor fixture
        protect completed service under normal and spacing/case-noisy text. The
        gap is distinct emissions-component maintenance without false matches to
        fuel service or plugs. Existing parameterized coverage was extended, so
        no test function/file was added. Tier 1 owns the checks; none replaced.
     4. Tests consolidated or removed: none.
     5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
        analysis, and 92 focused catalog/corpus/accuracy/handoff checks green.
     6. Tier 2 or Tier 3: not required for this focused family; Pass 100
        completed Tier 2 and Tier 3 is not due.
     7. Remaining risk: upstream/downstream sensor shorthand and real service
        layouts need locked holdout evidence; purchases remain review-only.
     8. Maintenance receipt check count: 245 before, 247 after.

103. Split key-fob and renewal parser definitions into
     `maintenance_receipt_parser_renewal_catalog.dart` before further expansion.

     1. Production files changed: parser library, parser catalog, and new
        renewal-catalog part.
     2. Existing tests modified: none.
     3. New tests added: none. This preserves definition order and behavior;
        existing catalog and accuracy contracts already cover the exported
        parser catalog, so a new test would be redundant. Tier 1 owns them.
     4. Tests consolidated or removed: renewal definitions were separated by
        responsibility with no contract change.
     5. Tier 1: formatting, diff checks, changed-file analysis, and 8 direct
        catalog/accuracy checks green.
     6. Tier 2 or Tier 3: not required; no behavior, schema, or shared service
        changed, and Pass 100 completed Tier 2.
     7. Remaining risk: none introduced by the split; new families still need
        collision tests and locked real-receipt holdouts.
     8. Maintenance receipt check count: 247 before, 247 after.

104. Added separate EGR Valve and Mass Air Flow Sensor manual/parser families.

     1. Production files changed: manual catalog and parser catalog.
     2. Existing tests modified: the catalog contract and shared synthetic-
        corpus loader were extended.
     3. New tests added: two generated checks from one emissions/air-management
        fixture protect EGR cleaning and MAF replacement under normal and
        spacing/case-noisy text. It covers the distinct gap without confusing
        air-filter or fuel-system service. Existing parameterized coverage was
        extended, so no test function/file was added. Tier 1 owns the checks.
     4. Tests consolidated or removed: none.
     5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
        analysis, and 94 focused catalog/corpus/accuracy/handoff checks green.
     6. Tier 2 or Tier 3: not required for this focused family; Pass 100
        completed Tier 2 and Tier 3 is not due.
     7. Remaining risk: emissions abbreviations and real service layouts need
        locked holdout evidence; purchases remain review-only suggestions.
     8. Maintenance receipt check count: 247 before, 249 after.

105. Added distinct Valve Cover Gasket and Oil Pan Gasket manual/parser families.

     1. Production files changed: manual catalog and parser catalog.
     2. Existing tests modified: the catalog contract and shared synthetic-
        corpus loader were extended.
     3. New tests added: two generated checks from one engine-gasket fixture
        protect completed gasket repairs under normal and spacing/case-noisy
        text. It covers the distinct leak-repair gap without treating the work
        as an oil change or filter service. Existing parameterized coverage was
        extended, so no test function/file was added. Tier 1 owns the checks.
     4. Tests consolidated or removed: none.
     5. Tier 1: formatting, JSON, unique-ID, line/diff checks, changed-file
        analysis, and 96 focused catalog/corpus/accuracy/handoff checks green.
     6. Tier 2 or Tier 3: not required for this focused family; Pass 100
        completed Tier 2 and Tier 3 is not due.
     7. Remaining risk: abbreviated gasket labor labels and real repair layouts
        need locked holdout evidence; purchases remain review-only suggestions.
     8. Maintenance receipt check count: 249 before, 251 after.

106. Split Wheel Balancing into its own parser catalog part to keep the main
     parser catalog below the line limit before further expansion.

     1. Production files changed: parser library, parser catalog, and new
        `maintenance_receipt_parser_wheel_balancing_catalog.dart`.
     2. Existing tests modified: none.
     3. New tests added: none. The definition and its catalog order are
        preserved; existing catalog and accuracy contracts cover this behavior,
        so another test would be redundant. Tier 1 owns those checks.
     4. Tests consolidated or removed: one wheel definition moved into its
        descriptive responsibility file without a contract change.
     5. Tier 1: formatting, diff checks, changed-file analysis, and 8 direct
        catalog/accuracy checks green.
     6. Tier 2 or Tier 3: not required; no behavior, schema, or shared service
        changed, and Pass 100 completed Tier 2.
     7. Remaining risk: none introduced by the split; new families require
        collision tests and locked real-receipt holdouts.
     8. Maintenance receipt check count: 251 before, 251 after.

107. Added Catalytic Converter as a distinct emissions-repair family.

     1. Production files changed: manual and parser catalogs.
     2. Existing tests modified: catalog contract and shared corpus loader.
     3. New tests added: two generated checks from one converter-service fixture
        cover normal and spacing/case-noisy completed-service text, without
        creating oxygen-sensor or EGR candidates. Parameterized coverage was
        extended; no test function/file was added. Tier 1 owns the checks.
     4. Tests consolidated or removed: none.
     5. Tier 1: formatting, JSON, analyzer, and 96 focused checks green.
     6. Tier 2/Tier 3: not due; Pass 100 completed Tier 2.
     7. Remaining risk: exhaust shorthand needs real-receipt holdouts.
     8. Maintenance receipt check count: 251 before, 253 after.

## Current counter

- Last accepted pass: **107**
- Next pass: **108**
- Architecture/drift review due: after Pass 200 at the earliest, and no later
  than after Pass 300.

## QA accounting

- Current maintenance receipt check count: **253**.
- Latest full maintenance receipt checkpoint: Pass 100, **245 checks green**.
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
