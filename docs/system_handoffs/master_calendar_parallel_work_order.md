# Master Calendar Parallel Work Order

## Purpose

This file assigns the Calendar lane to one Codex model. The Dashboard calendar
is Maintainiac's master chronological projection of work. It lets a user select
a date and understand everything recorded, proposed, or needing review for that
day. It does not own the underlying records.

## Do not modify

- Dashboard/GPS/active-workday/odometer/Bluetooth/trip-proposal ownership.
- Invoice, estimate, payment, expense, receipt, job, inventory, maintenance,
  customer, or vehicle source-record ownership.
- Durable Storage/Firebase implementation. Consume its established interfaces
  only; do not create direct cloud paths or a duplicate persistence layer.

## This lane owns

- Shared calendar navigation and date-selection UI.
- Day, week, and month presentation where supported.
- Master-calendar projection and filtering UI.
- Chronological day timeline UI.
- Read-only event adapters/contracts consumed from owning modules.
- Deep-link routing from an event to the owning module's detail/review screen.
- Responsive, accessible, polished calendar UI/UX.

## Pay and tax boundary

Calendar may present worked time, configured gross rates, gross-pay estimates,
and source-owned pay-period boundaries. It must never calculate, retain, or
present payroll taxes, withholdings, deductions, filings, tax liability, or
take-home pay. Those are outside Maintainiac Calendar scope.

## Master-calendar rule

The calendar projects data. Owning modules own records.

The calendar must not create duplicate Trips, Expenses, Jobs, Customers,
Inventory, Maintenance, Invoices, Payments, Receipts, or GPS records. A tap
opens the source record in its owning screen.

## Required event contract

Every projected event must contain:

- immutable event ID;
- source module;
- source record ID;
- event date;
- actual event time when known;
- recorded-at timestamp;
- actual-time-versus-recorded-time flag;
- vehicle ID;
- work-profile ID;
- title;
- concise detail;
- review status;
- source record status;
- evidence ID and proposal ID when applicable;
- evidence summary;
- evidence strength;
- recommendation confidence;
- human-readable explanation;
- audit/revision reference;
- deep-link target.

When actual time is unknown, show the recorded/entered time honestly. Never
present an entry timestamp as the actual fuel purchase, service, or trip time.

## Events the calendar must support

- Confirmed trips and proposed trips.
- Stops and proposed scheduled stops.
- Fuel, expenses, and receipts.
- Payments, invoices, and estimates.
- Jobs, appointments, and service work.
- Maintenance and reminders.
- Odometer corrections.
- Vehicle/profile handoffs.
- Review-required and incomplete-workday items.

## Required user experience

### Calendar overview

- A user selects a day and sees meaningful badges/counts, not an unexplained
  wall of dots.
- Allow filters by vehicle, profile, module, review state, and business/personal
  classification when data supports it.
- Clearly distinguish confirmed records from proposed or needs-review records.

### Day timeline

- Show events in chronological order.
- Group closely related evidence without hiding the owning record.
- Surface actionable issues first: review required, incomplete workday,
  conflicting vehicle/profile, missing time, and unresolved corrections.
- A timeline item opens the correct source detail screen.
- Provide an empty-state explanation and a way to add a date-specific record in
  the owning module; do not create a generic duplicate editor.

### Job day detail

When the user taps a Smith or Jones job entry, open the Job detail/review flow.
That owning flow may show all related confirmed information: appointment,
customer, address, arrival/stop evidence, service entries, invoices/estimates,
payments, expenses, receipts, vehicle, profile, notes, and audit history.
The calendar itself remains a projection/navigation layer.

## Evidence and proposal rules

- Proposals must display why they exist, their evidence, evidence strength,
  confidence, expected result if accepted, and what happens if ignored.
- Calendar never turns evidence into business truth.
- A proposal may be displayed but only its owning module may confirm the final
  record.
- Do not create unexplained automation or infer certainty from incomplete data.

## UI/UX rules

- Use the shared Maintainiac layout/color/typography rules when published.
- A color may identify a module or status, but color alone never conveys state.
- Avoid dense, flat, identical containers. Use clear hierarchy, labels, icons,
  spacing, and readable contrast.
- Support iPhone SE, large Android phones, tablet/desktop widths where this UI
  is shared, text scaling, screen readers, English, Spanish, French, regional
  dates, and keyboard navigation where relevant.
- Every secondary screen has a visible Back control and platform back gesture.

## Required tests

- Event ordering and actual-time/recorded-time labeling.
- Source deep-link routing.
- Filters and date navigation.
- Confirmed/proposed/review-required distinction.
- Duplicate-event and stale-revision suppression.
- Vehicle/profile isolation.
- Responsive/accessibility tests.
- Deterministic replay of identical event inputs.

## Git and coordination

- Work only in calendar/timeline presentation and shared read-only event
  contracts.
- Do not edit Dashboard, GPS, Invoice, Expense, Job, or Durable Storage source
  owners except for an explicitly coordinated minimal interface.
- New maintainable files must be 500 lines or fewer and start with an ownership
  header.
- Each commit is one coherent, tested capability or repair, with a descriptive
  `Calendar system:` subject and date/time. Major milestones may be tagged.
