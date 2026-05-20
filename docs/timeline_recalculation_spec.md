# Timeline Recalculation Spec

Maintaniac must treat historical edits as normal app behavior. Users will forget receipts, payments, trips, stops, maintenance events, and entire workdays. The app must let them correct the past without breaking future recaps.

## Core Rule

Source records are the truth. Recaps, averages, dashboard readouts, maintenance status, alerts, and reports are derived from source records.

When any source record is added, edited, deleted, restored, or moved to a different date, every affected derived value from that record date forward must be recalculated.

## Records That Must Trigger Recalculation

- Trip entries
- Stops, pickups, and drop-offs
- Workday start/end records
- Odometer readings
- Expenses
- Receipts and receipt line items
- Payments
- Invoices and estimates
- Maintenance events
- Maintenance supplies
- Materials
- Notes that affect records
- Schedule/reminder items when they become completed work

## Required Date Fields

Every dated record must store:

- `eventDate`
- optional `eventTime`
- `createdAt`
- `updatedAt`
- `sourceScreen`
- `vehicleId` when applicable
- `workProfileId` when applicable
- `businessPersonalClass` when applicable

## Propagation Examples

- A fuel receipt added for last week updates last week's expenses, profit, cost per mile, vehicle expense totals, monthly totals, year-to-date totals, and any reports covering that date range.
- A missed payment added for a past day updates gross pay, profit, pay per hour, pay per mile, weekly/monthly/year-to-date totals, and invoice/payment status.
- A missed trip or stop added in the past updates miles, business/personal mileage split, cost per mile, MPG calculations when fuel records are present, and dashboard/calendar summaries.
- A maintenance event added in the past updates maintenance history, interval position, threshold color, next due odometer/date, and maintenance alerts.

## Testing Requirement

Historical propagation must have dedicated tests. At minimum, tests must cover:

- Add past expense and verify later weekly/monthly/year-to-date recaps change.
- Add past payment and verify gross, profit, pay/hour, and pay/mile change.
- Add past trip and verify mileage totals and cost-per-mile change.
- Add past maintenance event and verify interval status and alerts change.
- Edit a past record and verify derived values update again.
- Delete a past record and verify derived values roll back correctly.

These tests must run without AI assistance, without manual database cleanup, and without relying on cached derived values as truth.
