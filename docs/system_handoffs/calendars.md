# Calendars Living Handoff

## Current Status

`PRESENT / UNVERIFIED / NEEDS RECONCILIATION`. Shared contractor, employee,
Dashboard, Expense, Invoice, and Maintenance calendar flows exist alongside
feature-specific calendars.

## Implemented Evidence

- Shared calendars: `lib/shared/calendar/`
- Expense calendar: `lib/screens/expenses/calendar/`
- Invoice calendar: `lib/screens/invoices/home/invoice_home_calendar.dart`
- Work Supplies calendar: `lib/screens/work_supplies/calendar/`
- Requirements: `screen_notes/calendar.txt` and
  `screen_notes/batch_004_calendar_recaps_navigation.txt`

## Remaining

- Reconcile dates, recaps, routes, entry ownership, and shared-versus-feature
  responsibilities without duplicate calendar implementations.
- Run targeted navigation/date-boundary/timezone tests before completion.

## Rolling Log

- 2026-07-22: Created as a cross-feature system handoff.
