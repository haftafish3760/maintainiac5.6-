# Jobs And Estimates Living Handoff

## Current Status

`SHARED DURABLE JOBS OWNER IMPLEMENTED / ESTIMATES NEED RECONCILIATION`.
Jobs now have one app-wide local owner; estimate conversion and the complete
job command center remain separate unfinished work.

## Implemented Evidence

- Work Supplies jobs screen: `lib/screens/work_supplies/jobs/work_supply_jobs_screen.dart`
- Shared durable owner: `lib/shared/jobs/maintainiac_job_store.dart`
- Receipt chooser: `lib/screens/expenses/entry/expense_receipt_entry_job_context_panel.dart`
- Inventory/job lifecycle contract: `docs/inventory_estimate_job_lifecycle_spec.md`
- Requirements: `screen_notes/jobs.txt` and `screen_notes/invoices_estimates.txt`
- Search invoices and shared records before adding a new model or store.

## Preserved Capability

- Receipt OCR source commit `07370e351` contains a Hive-backed job directory
  with stable IDs, name, work profile, vehicle, customer reference, archive,
  backup, and receipt create/choose UI.
- 5.7 now preserves that capability through `MaintainiacJobController`, not an
  Expense-only copy. It stores stable IDs/numbers, work profile, multiple
  vehicles, customer identity/reference, address, member assignments,
  estimate/invoice references, schedule, archive state, timestamps, and backup
  payloads.
- Legacy `expense_jobs` records are copied without deletion. If low storage
  blocks the copy, they remain readable from the untouched legacy box.
- `WorkSupplyJobsScreen` reads real active records and no longer seeds demo
  jobs. Expense/material receipt drafts can choose, clear, or create a job and
  preserve the historical `jobId` and `jobLabel` snapshot.

## Remaining

- Compare source repositories and Git history for job, estimate, customer,
  material-cost, tax, PDF, and invoice handoff differences.
- Verify that confirmed inventory cost is reused without silent mutation and
  that no duplicate Jobs or Estimates owner is introduced.
- Add targeted tests and update this record when implementation is changed.
- Connect Dashboard, Estimates, Invoices, mileage, inventory transactions,
  employees, calendars, and Firebase mirroring to this same owner as those
  systems are implemented. Never create another Jobs store.
- Add full create/edit/archive/schedule/customer/assignment UI and permission
  gates; the current preservation pass intentionally implements only the source
  capability needed to replace the demo directory and receipt chooser.

## Rolling Log

- 2026-07-22: Created as a separate lane; current presence is not a completion
  claim.
- 2026-07-22: Recorded the unique durable job-directory and receipt-linking
  capability found in Receipt OCR history; central merge remains required.
- 2026-07-22: Implemented the single shared durable Jobs owner, non-destructive
  legacy migration, real Work Supplies directory, and receipt create/choose/
  clear flow. Analyzer and Android Kotlin compile passed; 9 focused Jobs/
  context tests plus 9 adjacent receipt regressions passed.
- 2026-07-25: Replaced the fragile Create Job dialog with a dedicated form;
  added client contact/address, schedule, recurrence, reminder preferences,
  reviewed estimate selection from the existing invoice ledger, and explicit
  feedback for still-unconnected job expense/inventory actions. The job record
  preserves the estimate id rather than creating another estimate owner. See
  `docs/jobs_commercial_readiness_blueprint.md` for the staged system contract.
