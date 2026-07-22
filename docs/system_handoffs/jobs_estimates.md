# Jobs And Estimates Living Handoff

## Current Status

`PRESENT / UNVERIFIED / NEEDS RECONCILIATION`. Jobs and estimate-related
requirements and bridges exist, but no current independent release gate is
recorded.

## Implemented Evidence

- Work Supplies jobs screen: `lib/screens/work_supplies/jobs/work_supply_jobs_screen.dart`
- Inventory/job lifecycle contract: `docs/inventory_estimate_job_lifecycle_spec.md`
- Requirements: `screen_notes/jobs.txt` and `screen_notes/invoices_estimates.txt`
- Search invoices and shared records before adding a new model or store.

## Discovered Preserved Capability

- Receipt OCR source commit `07370e351` contains a Hive-backed job directory
  with stable IDs, name, work profile, vehicle, customer reference, archive,
  backup, and receipt create/choose UI.
- Current 5.7 already persists `jobId` and `jobLabel` with receipt context and
  recap filters, but `WorkSupplyJobsScreen` still uses `_demoJobs()`.
- Do not copy `ExpenseJobStore` as a parallel owner. Semantically migrate its
  durable capabilities into one shared Jobs owner used by Expenses, Work
  Supplies, Dashboard, Estimates, Invoices, mileage, and inventory.

## Remaining

- Compare source repositories and Git history for job, estimate, customer,
  material-cost, tax, PDF, and invoice handoff differences.
- Verify that confirmed inventory cost is reused without silent mutation and
  that no duplicate Jobs or Estimates owner is introduced.
- Add targeted tests and update this record when implementation is changed.

## Rolling Log

- 2026-07-22: Created as a separate lane; current presence is not a completion
  claim.
- 2026-07-22: Recorded the unique durable job-directory and receipt-linking
  capability found in Receipt OCR history; central merge remains required.
