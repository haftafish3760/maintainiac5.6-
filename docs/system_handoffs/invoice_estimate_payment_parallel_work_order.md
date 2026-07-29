# Invoice, Estimate, and Payment Parallel Work Order

## Purpose

This file assigns the Invoice, Estimate, and Payment lane to one Codex model.
It owns financial records and their user interface. It does not own Dashboard,
GPS, trip capture, calendar projection, Jobs, or cloud storage implementation.

## Do not modify

- Dashboard screens, active workday, trip tracking, GPS, Bluetooth, odometer,
  vehicle-profile, or Dashboard calendar projection.
- Jobs records or job-completion ownership.
- The Durable Storage/Firebase implementation. Use its established interfaces
  only; do not add direct Firebase calls, collections, queues, or backups.
- Expenses, receipts, inventory, maintenance, or calendar source records.

## This lane owns

- Invoice screens and records.
- Estimate screens and records.
- Payment screens and records.
- Financial status, drafts, edits, voids, revisions, history, and audit UI.
- Responsive, accessible, professional UI/UX inside this financial lane.
- Deep links from the master calendar and Dashboard timeline into the correct
  financial detail screen.

## Immutable financial rules

1. Invoices reference Jobs where a job exists.
2. Invoices may reference confirmed service evidence through a Job or an
   explicit reviewed service record. They must never consume raw GPS events.
3. No invoice, estimate, payment, or billable service change is finalized by
   GPS, Bluetooth, a map, schedule proximity, AI, or automation alone.
4. Automated financial suggestions are proposals. The user reviews, edits, and
   explicitly approves them before a financial record changes.
5. Preserve prior revisions and audit history. Never silently rewrite a
   confirmed financial record.
6. Vehicle and work-profile attribution must be visible and intentionally
   changeable before a consequential save.

## Required proposal behavior

When a future Dashboard/Jobs workflow suggests a financial update, this lane
must accept a proposal only with these fields:

- proposal ID;
- evidence ID(s);
- source Job/service ID when applicable;
- customer reference;
- proposed financial action;
- human-readable explanation;
- evidence summary and strength;
- recommendation confidence;
- exact expected result if accepted;
- created timestamp;
- user decision state;
- audit history.

The financial lane owns the final record. It may reject an incomplete,
duplicate, stale, unauthorized, or already-applied proposal.

## Master calendar/timeline event contract

Every final or reviewable invoice, estimate, or payment must expose a
read-only timeline item for the Dashboard master calendar. The Dashboard
projects this item; it does not store or edit the financial record.

Required fields:

- immutable event ID;
- source module: invoice, estimate, or payment;
- source record ID;
- event date;
- actual event time when known;
- recorded-at timestamp when actual time is unknown;
- actual-time-versus-recorded-time flag;
- vehicle ID and work-profile ID when applicable;
- customer/job reference when applicable;
- title and concise detail;
- amount/currency summary where safe;
- status: draft, proposed, confirmed, voided, rejected, or needs review;
- evidence ID and proposal ID when applicable;
- evidence summary, evidence strength, recommendation confidence, and
  explanation for proposals;
- revision/audit reference;
- deep-link destination into this lane.

Rules:

- A calendar tap must open the financial record detail/review screen.
- The Dashboard must never edit a financial record directly.
- Unknown actual time must be visibly labeled as recorded/entered time.
- Do not create a second calendar database.

## Required screens and flows

- Invoice home/command center.
- Estimate home/command center.
- Payment history and payment detail.
- Financial record detail with visible status, vehicle/profile, job/customer
  context, attachments/references where supported, revision/audit history, and
  calendar deep-link behavior.
- Proposed update review screen or reusable proposal panel.
- Clear empty, error, offline, and storage-unavailable states.

## UI/UX rules

- Use the shared Maintainiac layout system when it is published; do not invent
  a competing design system.
- Prefer hierarchy and clear grouping over flat lists of identical cards.
- Use screen-owned contextual settings; global System Settings belongs in the
  hamburger/menu system.
- Every secondary screen has a visible Back control and platform back gesture.
- Support narrow phones, large phones, text scaling, keyboard flow, screen
  readers, English, Spanish, French, miles/kilometers where relevant, and
  regional currency/date formatting.
- Explain ambiguous concepts in plain English. Do not use unexplained labels.

## Required testing

- Record creation/edit/void/revision/audit tests.
- Proposal acceptance/rejection/idempotency tests.
- Timeline-event contract tests.
- Deep-link tests from calendar/dashboard into the correct record.
- Vehicle/profile attribution and conflict tests.
- Offline/durable-storage interface tests.
- Accessibility/responsive widget tests.

## Git and coordination

- Work only in this lane.
- Do not change Dashboard, Calendar, GPS, Jobs, or Durable Storage code unless
  the owner explicitly coordinates a narrow interface change.
- New maintainable files must be 500 lines or fewer and start with an ownership
  header.
- Each commit is one coherent, tested capability or repair, with a descriptive
  `Invoice system:` subject and date/time. Major milestones may be tagged.
