# Expenses Living Handoff

## Current Status

`PRESENT / VERIFIED SUBSET / NEEDS RECONCILIATION`. Expense home, receipt entry,
calendar/detail, reports, reminders, settings, and work profiles exist.

## Screens And Implemented Evidence

- Home/category entries: `lib/screens/expenses/home/`
- Add/edit/review: `lib/screens/expenses/entry/`
- Calendar and saved detail: `lib/screens/expenses/calendar/`
- Reports/recaps/export/allocation: `lib/screens/expenses/reports/`
- Reminders, settings, profiles: `lib/screens/expenses/reminders/`,
  `lib/screens/expenses/settings/`, `lib/screens/expenses/profiles/`
- Requirements: `screen_notes/expenses_receipts.txt` and
  `screen_notes/app_screens/expense_receipt_entry_screen.txt`

## Verified / Deferred / Remaining

- `VERIFIED SUBSET`: checkpoint `361a85e0` reconciled Basic, Detailed Items,
  and Quick Classify total fields; analyzer clean and 12 focused tests passed.
- `VERIFIED SUBSET`: the Receipt OCR history reconciliation removed silent
  50/50 split ownership, requires an explicit allocation, and preserves an
  unchanged amount/quantity split method; analyzer clean and 26 focused tests
  passed. Record the final checkpoint hash in the next rolling update.
- Mandatory user review and receipt ownership rules live in
  `docs/expense_receipt_storage_and_duplicate_contract.md`.
- `DEFERRED`: configurable draft retention and visual duplicate review are
  specified in the receipt-system handoff; do not implement fragments.
- `NEEDS RECONCILIATION`: continue source-by-source Expense behavior and history
  comparison; final full tests and platform builds are not complete.
- `VERIFIED SUBSET`: the Receipt OCR repository's final Expense persistence and
  cloud batch is covered by newer 5.7 owners; 124 focused tests passed.
- `VERIFIED SUBSET`: receipts now choose, clear, or create jobs through the
  shared durable Jobs owner and preserve `jobId`/`jobLabel` in drafts and saved
  history. No Expense-only Jobs store was introduced; 9 focused tests passed.

## Rolling Log

- 2026-07-22: Split Expenses from the former combined OCR/camera handoff and
  recorded the verified review-mode totals checkpoint.
- 2026-07-22: Reconciled source commits `7b053a05b` and `27694e9d1`; integrated
  explicit split ownership and retained the newer 5.7 evidence-display model.
- 2026-07-22: Closed the Receipt OCR repository's Expense persistence/cloud
  history; recorded centralized receipt-context chooser work still required.
- 2026-07-22: Connected receipt job selection to the shared durable Jobs owner
  and closed the queued Expense-only chooser/store consolidation gap.
