# Maintainiac Main QA Harness Plan

This document defines the permanent Maintainiac QA backbone. Inventory parser QA is only one consumer of this infrastructure.

## Active Local Repo

- Active parser/QA repo: `C:\Users\rjenk\Documents\Mainteniac 5.6`.
- Do not work from `F:\maintainiac_two`.
- Treat `C:\Users\rjenk\Documents\Mainteniac 5.6` as the authoritative local
  parser/QA checkout unless a newer handoff marker explicitly names a
  replacement path.
- Do not use Google Drive, OneDrive, or synced Documents folders as the active repo.
- If a second local clone is created later, the handoff marker must name which
  path is authoritative before parser/QA work moves there.

## Core Rules

- Test behavior, not object existence.
- Every confirmed bug fix gets a regression test.
- Every financial calculation gets deterministic tests.
- Every source-of-truth rule gets mutation-guard tests.
- Hive/local storage is the immediate source of truth.
- Firestore is a mirror/backup only.
- Recap, notifications, exports, reports, and dashboards must read source records, not mutate them.
- Estimates and invoices may create output records but must not mutate source expense, trip, odometer, inventory, or receipt records.
- OCR and parser output remains suggestion data until user confirmation.
- User-confirmed data must never be silently overwritten.
- Do not store VINs, plates, passenger data, patient data, card numbers, tax IDs, or Social Security numbers.

## Shared Infrastructure

The main harness must provide reusable support for:

- Fake app bootstrap and fake clock.
- Fake Hive/local boxes and repositories.
- Fake Firestore mirror and fake Cloud Storage.
- Fake network states: offline, Wi-Fi, cellular, roaming, blocked.
- Fake user, account, profile, vehicle, company, employee, fleet vehicle, subscription, permissions, notification scheduler, export writer, file/image storage, and device/App Check state.
- Shared builders for every app record type.
- Shared assertions for source-of-truth, privacy, financial math, sync, review status, audit trails, exports, and regression fixtures.
- JSON, receipt image, OCR text, parser, inventory catalog, estimate/invoice, sync conflict, malformed, corrupted, generated, and real bug regression fixtures.
- A regression registry where every bug has an ID, description, root cause, input fixture, expected behavior, fixed version, area, permanent test, and module tags.

## Required QA Domains

- Inventory and catalog parsing.
- Receipt parsing and OCR-output review contracts, without implementing OCR/camera in this thread.
- Expenses and financial ledger totals.
- TripLog, odometer, recap, and calendar.
- Estimates, invoices, jobs, payments, exports, and maintenance.
- Profiles, vehicles, employees, company/fleet permissions.
- Sync, security, privacy, performance, and load.

## Release Gates

Before release, the project needs passing gates for:

- Analyzer and formatting.
- Source audit and line-count audit.
- Unit, parser, ledger, sync, security/privacy, regression, and performance suites.
- Firebase emulator tests for sync/security rules before any live Firebase testing.
- No live Firebase writes from local QA harness tests.
- No brittle real-time, random, or network dependencies.

## Current First Slice

The first reusable slice adds:

- `maintainiac_qa_environment.dart`
- `maintainiac_qa_builders.dart`
- `maintainiac_qa_assertions.dart`
- `maintainiac_qa_fixtures.dart`
- `maintainiac_regression_registry.dart`
- `maintainiac_qa_backbone.dart`
- `test/maintainiac_qa_backbone_test.dart`

Next milestones are sync scenario runners, financial deterministic ledgers, privacy/security attack fixtures, and performance/load generators.

## Executable Scenario Runners

The second reusable slice adds `maintainiac_qa_scenario_runners.dart` so modules can execute behavior contracts without duplicating fakes:

- Sync runner: local-write-before-mirror, dirty marker lifecycle, network policy, restart/conflict policy, and mirror payload parity.
- Security/privacy runner: ownership isolation, forbidden sensitive-data scan, permission denial, and export scoping.
- Financial runner: expense adjustments, tax allocation, and invoice/estimate read-only source behavior.
- Performance runner: generated dataset budgets, storage-shape budget, and search-index budget that rejects full-catalog scanning.

These runners are still harness infrastructure. They do not touch OCR/camera implementation and do not hit live Firebase.

Run the backbone intentionally with the `main` or `backbone` preset once it is wired into a harness entry point:

- `maintainiac.qa_backbone_contract`
- `qa.threshold_gate`

The command runner is:

- `dart run tool/maintainiac_qa_backbone.dart --profile smoke --preset main`

It writes timestamped and `latest_maintainiac_main` QA report artifacts through the same redacted report writer used by parser QA.

## Source Boundary Guards

The main QA backbone includes a reusable source-boundary scanner. It is meant for parser, sync, security, and module suites that need hard proof they did not drift into forbidden implementation lanes.

Initial production defaults catch:

- Live Firestore usage in QA harness code, except explicitly scoped Firebase emulator tests.
- Google Vision, ML Kit, and camera controller implementation tokens inside parser QA lanes.
- Generated build folders are skipped so scans stay focused on source and tests.

## Readiness Ledger

The main QA harness includes a readiness ledger so progress survives context compression and handoffs:

- `ready`: completed backbone pieces with evidence.
- `partial`: consumers or modules with real evidence but named remaining gaps.
- `missing`: release-required suites or domains that still need executable coverage.

The ledger must reject any item marked ready without evidence.

## QA Case Registry

Every reusable QA behavior should have a durable label:

- Case ID, title, module, behavior, evidence target, priority, optional command, and tags.
- Release blockers must be visible separately from core, standard, and hardening checks.
- Feature work can run the relevant labeled cases while the feature is being built, not only at final release time.

List labeled QA cases with:

- `dart run tool/maintainiac_qa_cases.dart`
- `dart run tool/maintainiac_qa_cases.dart --priority releaseBlocker`
- `dart run tool/maintainiac_qa_cases.dart --json --priority core`

## Financial Ledger Probe

The backbone includes a cents-only financial ledger probe for deterministic module tests:

- Expense totals, taxes, discounts, refunds, business/personal splits, and category rollups.
- Inventory consumption cost lines for jobs, estimates, invoices, and material usage.
- Balance assertions so category totals and business/personal totals cannot drift from the source ledger.

## Sync Lifecycle Probe

The backbone includes a local-only sync lifecycle probe:

- Local dirty writes happen first.
- Syncing, failed, retry, and synced states are explicit.
- Successful mirror writes go to the fake Firestore mirror only.
- Failed records remain in a pending retry queue.

## Device Capability Probe

The backbone includes a deterministic device/storage policy probe:

- Classifies legacy, standard, modern, and high-end devices by coarse model bucket.
- Chooses local, compact-local, cloud-assisted, or blocked pack mode.
- Blocks cloud/local pack decisions when App Check is invalid or the device lacks space and cannot go online.

## Scope Policy Probe

The backbone includes a reusable permission and ownership probe:

- Account isolation.
- Company and employee scoping.
- Vehicle assignment checks.
- Required permission checks with admin override.

## Audit Trail Probe

The backbone includes an audit trail probe:

- Audit events must have actor, action, target, and ordered timestamps.
- Duplicate audit IDs fail.
- User-confirmed suggestion events preserve before/after values and prove confirmed data outranks parser automation.

## Export Privacy Probe

The backbone includes an export privacy probe:

- Exports must contain only records owned by the active account.
- Private keys such as VIN, plates, passengers, patients, raw receipt text, tax IDs, SSNs, and card numbers are rejected.
- Sanitized export records drop private fields before writing.

## Mutation Guard Probe

The backbone includes a mutation guard:

- Derived outputs such as recap, export, notification, estimate, invoice, and report writes must not mutate source collections.
- Source operations must declare the exact source collections they are allowed to write.
- This protects Hive/local source-of-truth records from side effects.

## Failure Taxonomy Probe

The backbone includes a failure taxonomy probe:

- Routes failures into schema, privacy, security, sync, money, permissions, source mutation, parser, performance, fixture, or unknown buckets.
- Helps QA reports explain what kind of failure happened and what team/module should handle it.

## Release Gate Plan

The backbone includes a release gate plan:

- Groups release-blocking and core QA cases into a machine-readable plan.
- Produces the concrete focused commands to run while building features.
- Fails if a release-blocking case lacks evidence or a runnable command.
- Feeds a QA execution manifest where each check has a label, behavior it proves, owner, cadence, command, live-service policy, and failure action.
- Records QA run evidence in a run ledger so clean focused checks can be skipped when their command and input signature are unchanged.
- Uses deterministic source fingerprints so fixture/catalog/test changes can trigger surgical reruns instead of full-suite churn.
- Applies a checkpoint policy: push at milestones, after thirty minutes of changed work, when the user asks, or when failing-gate evidence must be preserved.
- Enforces artifact policy so reports, fixtures, and regression evidence stay redacted and out of Google Drive, OneDrive, F-drive, or other unsafe locations.
- Defines a parser candidate contract so inventory and expense parsers return review-only candidates with preserved evidence, confidence reasons, warnings, missing fields, and explicit user confirmation before writes.
- Governs parser fixture sets with locale, country, merchant, trade, owner, source type, expected behavior, review date, and privacy/review tags.
- Converts user corrections into reviewable alias, negative-rule, merchant-rule, category-mapping, or regression-fixture proposals without silently mutating official packs or confirmed source records.
- Proves local-first write ordering: Hive/local source writes must happen before Firestore mirror writes, and derived outputs must not point at or mutate source collections.
- Covers sync conflicts: same-field conflicts, safe different-field merges, local-wins policy for confirmed financial data, review queues, audit ids, and mirror-only Firestore behavior.
- Proves pricing math for estimates/invoices/jobs: integer-cent subtotals, tax allocation, discounts, markups, total balancing, and read-only source pricing behavior.
- Tracks module suite coverage with executable, scaffolded, and planned suite contracts for inventory, expenses, jobs, estimates, invoices, calendar, maintenance, fleet, exports, and payments.
- Validates schedule and reminder behavior with UTC storage, audit IDs for job scheduling, maintenance vehicle scoping, notification permission behavior, overlap detection, and non-mutating derived reminders.
- Validates payment records with audit IDs, invoice links, no full card storage, deterministic payment/refund ledger effects, and read-only invoice source totals.
- Validates job material attachment with confirmed estimate or receipt-backed sources, audit IDs, local-first writes, user confirmation, and read-only derived job summaries.
- Validates the inventory parser consumer with release-one QA families for schema, alias/vendor/SKU, ambiguity, fixture governance, security/privacy, performance, US Spanish, workflow routing, sync authority, financial math, pack recovery, and generated batch execution.
- Validates the expense parser consumer with release-one QA families for parser review suggestions, draft storage lifecycle, ledger math, category classification, privacy redaction, materials bridge, failure diagnostics, and telemetry boundaries.
- Adds a parser consumer gate that validates inventory and expense parser consumers together so parser readiness cannot pass if either consumer loses breadth, offline safety, route coverage, or OCR/camera boundaries.
- Adds a parser release command plan that groups parser consumer QA into smoke, focused, and release tiers so failures can be rerun surgically instead of rerunning the whole app.
- Adds parser regression bindings so inventory and expense parser consumer risks map to permanent bug IDs, fixtures, expected behavior, and focused rerun commands.
- Adds surgical test selectors using `flutter test <file> --plain-name "<behavior>"` so individual QA behaviors can be rerun without running a whole test batch.
- Adds a surgical rerun router that maps changed QA contract files to exact individual selector commands, preventing broad reruns when only one parser QA surface changed.
- Adds surgical selector coverage expectations so every focused parser-consumer QA behavior has an individual selector before release.
- Adds a source-truth gate that formalizes local/Hive source records, Firestore mirror-only records, parser suggestion records, and derived read-only outputs across expenses, inventory, jobs, estimates, invoices, recap, exports, and sync.
- Adds a financial formula registry that labels deterministic money formulas, rounding policies, source-mutation rules, and individual test commands across expenses, inventory, jobs, estimates, invoices, and payments.
- Adds a QA telemetry privacy gate for QA reports, admin dashboards, parser diagnostics, export artifacts, and run ledgers so actionable diagnostics do not leak raw receipts, customer data, vehicle identifiers, card data, or device secrets.
- Adds a release evidence bundle that records required analyzer, individual-test, backbone, privacy, source-truth, and GitHub-push evidence for milestone handoff.
- Adds fixture governance for parser, expense, sync-conflict, malformed, generated-dataset, bug-regression, and private-blocked fixture families with owner, metadata, privacy, review cadence, and repository storage rules.
- Adds a restart lifecycle gate for expense drafts, inventory/parser review, job materials, partial sync, and parser review recovery after app kill/restart.
- Adds a module boundary gate that labels allowed paths and forbidden path tokens for inventory, expenses, parser QA, sync, exports, and security/privacy lanes.
- Adds a performance budget registry for QA backbone cold start, catalog indexing, generated fixture runs, report writing, surgical rerun routing, and memory pressure.

Print the release gate with:

- `dart run tool/maintainiac_release_gate.dart`
- `dart run tool/maintainiac_release_gate.dart --json`
- `dart run tool/maintainiac_release_gate.dart --commands-only`

## Parser Platform Consumers

The reusable parser QA platform must register each parser as a domain adapter instead of burying assumptions in module tests:

- Inventory/material parser: maps receipt text into catalog/inventory/estimate/job/invoice material suggestions.
- Expense receipt parser: maps OCR/plain receipt text into expense drafts, review records, ledger entries, recap, and exports.
- Maintenance parser: maps service/maintenance text into maintenance tasks, service history, work orders, and fleet maintenance.

Each adapter declares forbidden implementation boundaries. Expense receipt parsing may consume text produced by OCR later, but this QA thread must not implement camera capture, ML Kit, Google Vision, or OCR provider code.

## Quality Gate Matrix

The reusable quality gate matrix must cover:

- Sync: local write, dirty marker, online sync, failed sync, retry/backoff, manual sync, scheduled sync, Wi-Fi only, cellular allowed, roaming blocked, battery saver pause, restart before sync, restart after partial sync, same-field conflict, different-field merge, past-day edit versioning, local-wins daytime policy, and Firestore mirror payload.
- Security/privacy: user isolation, profile isolation, vehicle isolation, company/employee scoping, receipt ownership, export ownership, no VIN storage, no plate storage, no passenger data, no patient data, no secrets in repo, permission denial flows, deleted file cleanup, and no cross-account bleed.
- Financial correctness: expense totals, business/personal totals, daily recap math, extended recap math, invoice totals, estimate totals, taxes, discounts, refunds, negative adjustments, inventory consumption costs, decimal-safe money handling, and rounding consistency.
- Performance/load: 100,000+ catalog items, large inventory movement history, large receipt fixture sets, multi-year day logs, large exports, startup load, search/index performance, sync payload generation, import validation, and memory safety.
