# Maintainiac Main QA Harness Plan

This document defines the permanent Maintainiac QA backbone. Inventory parser QA is only one consumer of this infrastructure.

## Active Local Repo

- Work from `C:\Users\rjenk\source\Mainteniac 5.6`.
- Do not work from `F:\maintainiac_two`.
- Do not use Google Drive, OneDrive, or synced Documents folders as the active repo.
- Keep `C:\Users\rjenk\Documents\Mainteniac 5.6` as a recovery copy until the local source copy and GitHub backup are confirmed.

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

## Quality Gate Matrix

The reusable quality gate matrix must cover:

- Sync: local write, dirty marker, online sync, failed sync, retry/backoff, manual sync, scheduled sync, Wi-Fi only, cellular allowed, roaming blocked, battery saver pause, restart before sync, restart after partial sync, same-field conflict, different-field merge, past-day edit versioning, local-wins daytime policy, and Firestore mirror payload.
- Security/privacy: user isolation, profile isolation, vehicle isolation, company/employee scoping, receipt ownership, export ownership, no VIN storage, no plate storage, no passenger data, no patient data, no secrets in repo, permission denial flows, deleted file cleanup, and no cross-account bleed.
- Financial correctness: expense totals, business/personal totals, daily recap math, extended recap math, invoice totals, estimate totals, taxes, discounts, refunds, negative adjustments, inventory consumption costs, decimal-safe money handling, and rounding consistency.
- Performance/load: 100,000+ catalog items, large inventory movement history, large receipt fixture sets, multi-year day logs, large exports, startup load, search/index performance, sync payload generation, import validation, and memory safety.
