# Fuel And Vehicle Energy Living Handoff

## Current Status

`PRESENT / NEEDS RECONCILIATION`. Fuel is an Expense-integrated system with
liquid fuel, charging, hydrogen, quantity/pricing, merchant profiles, odometer,
economy metrics, recaps, reminders, and receipt parsing behavior.

## Implemented Evidence

- Categories: `lib/screens/expenses/categories/fuel_category.dart` and files
  matching `fuel` or `charging` under that directory.
- Parsing and pricing: files matching `fuel` under `lib/screens/expenses/data/`
- Recaps: `lib/screens/expenses/reports/expense_recap_fuel_summary.dart`
- Odometer integration: `lib/screens/expenses/entry/expense_receipt_entry_odometer_lifecycle.dart`

## Boundaries And Remaining

- Fuel OCR/parser output is a suggestion and must be reviewed. Never silently
  route a receipt to Fuel or infer user truth from GPS/odometer evidence.
- `NEEDS RECONCILIATION`: semantically compare the Fuel_System source and Git
  history for unique pricing, units, propulsion, odometer, merchant, and recap
  behavior; do not import a parallel Expense or receipt architecture.
- Extensive fuel parser tests exist; record the exact current gate before making
  a verified completion claim.
- `VERIFIED SUBSET`: the complete fuel-format parent suite passed all 82 tests.
  Its twelve `part` files no longer end in `_test.dart`, so Flutter discovers
  only the owning parent suite instead of incorrectly launching library parts
  as independent tests.

## Rolling Log

- 2026-07-22: Created because Fuel has a dedicated source repository and
  substantial behavior even though it integrates with Expenses.
- 2026-07-22: Corrected the test-discovery boundary and recorded the green
  82-test fuel-format regression suite.
