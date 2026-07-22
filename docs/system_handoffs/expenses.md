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
- Mandatory user review and receipt ownership rules live in
  `docs/expense_receipt_storage_and_duplicate_contract.md`.
- `DEFERRED`: configurable draft retention and visual duplicate review are
  specified in the receipt-system handoff; do not implement fragments.
- `NEEDS RECONCILIATION`: continue source-by-source Expense behavior and history
  comparison; final full tests and platform builds are not complete.

## Rolling Log

- 2026-07-22: Split Expenses from the former combined OCR/camera handoff and
  recorded the verified review-mode totals checkpoint.
