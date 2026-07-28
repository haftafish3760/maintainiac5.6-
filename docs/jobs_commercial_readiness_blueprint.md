# Jobs Commercial Readiness Blueprint

Date: 2026-07-25

Scope: residential and light-industrial contractor Jobs. This blueprint does
not authorize edits to the contractor dashboard, GPS trip tracking, invoice
rendering, calendar ownership, Firebase, or the app-wide notification service.

## Product Outcome

Jobs is the operational source of truth between an accepted estimate and a
finished, invoiced, paid service visit. It must work manually and offline before
GPS, automation, or an AI agent is allowed to assist it.

The core path is:

1. Create a direct job or select a saved estimate.
2. Review the client, service address, scope, price/source references, and
   materials before conversion.
3. Schedule the job, recurrence, arrival window, vehicle, and assigned people.
4. Prepare materials, permits, notes, and customer access instructions.
5. Perform the work while recording time, material usage, expenses, photos,
   changes, signatures, and completion notes.
6. Confirm completion. Never infer completion from GPS alone.
7. Create an invoice from confirmed source records, review it, and let the user
   choose how to send it.
8. Preserve the job, estimate, invoice, payment, and audit links without
   silently rewriting any source record.

## Jobs Home Information Architecture

The mature Jobs home should prioritize the contractor's day:

- Today: ordered scheduled visits, arrival windows, status, address, contact,
  assigned vehicle/technician, and material readiness.
- Staged arrivals: GPS-assisted candidates that require explicit confirmation.
- Unscheduled: accepted estimates and direct jobs waiting for a date.
- Upcoming: jobs grouped by date and route-ready address.
- Waiting: customer response, parts, permit, change-order approval, or payment.
- Completed: closed work with invoice and payment state.
- Search/filter: client, address, job number, status, technician, vehicle, date,
  trade, estimate, invoice, and balance state.

Empty states must explain the next useful action. Buttons must never silently do
nothing; unavailable connections must say what is missing and confirm that no
record was changed.

## Job Record

The shared job record should grow through versioned, backward-compatible fields:

- stable job id and human-facing job number
- contractor/work-profile id and optional organization id
- lifecycle status and reason
- client id plus a client snapshot for historical accuracy
- client name, phone, email, preferred contact method, and access notes
- normalized service address plus geocoding confidence and user confirmation
- scope, internal notes, customer-facing notes, trade, priority, and tags
- estimate id/revision and invoice id/revision
- scheduled start, end/arrival window, timezone, recurrence rule, and exceptions
- assigned vehicle, technicians/helpers, and permission snapshot
- planned and actual labor, materials, expenses, mileage references, photos,
  documents, signatures, change orders, and completion checklist
- reminder preferences and delivery history
- created, updated, completed, cancelled, and archived timestamps
- append-only audit events for meaningful changes

Client records should be reusable, but a job must retain the client/address
snapshot that was actually used. Updating a client later must not silently
rewrite old jobs or invoices.

## Estimate Import Contract

Jobs may read estimates from the existing durable invoice ledger; it must not
create a second estimate store. Selecting an estimate opens a reviewable job
form and preserves the estimate id. Estimate lines remain source records and
should be referenced or snapshot deliberately, not copied invisibly.

Before completing conversion, show:

- estimate status and signature/approval state
- client and service address
- quoted scope, labor, materials, tax, discounts, and total
- unavailable or insufficient inventory
- scheduling and assignment
- what will be copied, referenced, or left unchanged

Draft or unapproved estimates may be converted only after a clear warning and
explicit user choice. Converting an accepted estimate must be idempotent so a
double tap cannot create duplicate jobs.

## Scheduling And Calendar Contract

The job owns its schedule fields. The shared calendar reads those fields; it
does not keep an unrelated duplicate job date.

Required scheduling behavior:

- scheduled and unscheduled jobs
- exact start/end or arrival window
- all-day and multi-day work
- weekly, biweekly, monthly, and custom recurrence with per-occurrence changes
- timezone and daylight-saving-safe storage/display
- conflict warnings for the same technician or vehicle
- reschedule reason and audit history
- past-date correction with downstream recaps recalculated
- offline edits that remain visible and reconcile safely later

## Reminder And Phone Notification Contract

Reminder delivery choices are independent and off until the user enables them:

- in-app reminder
- phone notification
- audible phone notification
- lead time and optional repeat/escalation

The job stores user intent. A shared notification service schedules delivery
from source data and records success/failure without mutating the job. Request
notification permission only when the user enables phone delivery.

The phone notification settings action must open Maintainiac's operating-system
notification settings. Sound selection must follow platform notification
channel/category behavior, respect silent/focus modes, and offer a silent
choice. The UI must not claim a custom tone is active until the OS confirms the
channel/category configuration. In-app reminders must still work when phone
permission is denied.

## GPS Arrival Staging Contract

GPS and Bluetooth may suggest that the user arrived at a scheduled service
address. They must not mark a job completed, consume inventory, create an
invoice, send a document, or alter confirmed mileage.

Arrival staging requires:

- a user-confirmed service address and geocode confidence
- a configurable dwell/radius rule with accuracy checks
- a plausible time window and assigned vehicle/user match
- protection against adjacent properties, apartment buildings, drive-bys,
  weak GPS, tunnels, and repeated visits
- an explicit `Did you complete this job today?` decision
- a dismiss/not-this-job path with no record mutation

## Job Execution And Closeout

A job detail screen should provide quick, auditable actions:

- call/message client and open directions
- check in/out manually
- start/pause/finish labor timers with manual correction
- reserve, consume, return, or add materials
- attach expenses and receipts
- before/during/after photos and documents
- notes, checklist, measurements, permits, equipment/model/serial context
- change order with customer approval
- customer and contractor completion signatures when required
- incomplete/return-visit/warranty/cancel states

Closeout produces a review, not an automatic invoice. The review shows confirmed
labor, materials, expenses, taxes, discounts, estimate changes, and proof. The
user decides whether to create/send an invoice and chooses the delivery method.

## Trial And Premium Boundary

Entitlement is a separate app-wide service. The intended premium automation may
have a two-week introductory period, but trial start/end, offline grace,
restoration, cancellation, and plan changes must be tamper-resistant and tested.
Core manual job creation, editing, history, and export must not become unusable
when automation is unavailable.

## Security, Privacy, And Audit

- Local storage is the source of truth; hosted sync is opt-in.
- Customer addresses, phone numbers, job notes, photos, routes, and payment
  context must not enter logs or analytics payloads.
- Roles gate financials, customer details, scheduling, editing, export, and
  deletion separately.
- Archive/tombstone records rather than silently deleting history.
- Export must include source ids and linked estimate/invoice/payment references.
- GPS, notification, contacts, calendar, camera, and file permissions are
  requested at the action that needs them, with manual fallbacks.

## File Size And Ownership Rule

Every Jobs source file must remain at or below 500 lines. Split by real
responsibility: home orchestration, form, form sections, estimate picker, job
detail, schedule, reminder preferences, models, store, and integrations. Do not
use numbered catch-all files.

Pre-existing files elsewhere in the app that exceed 500 lines require staged,
owner-coordinated refactors with characterization tests before movement. A
green Jobs pass does not authorize a broad parser, dashboard, invoice renderer,
trip tracking, or Firebase rewrite.

## Delivery Order

1. Crash-free direct job creation, client/contact/address, scheduling,
   recurrence, reminder intent, and focused regression tests.
2. Safe estimate picker and reviewed conversion into the one shared job store.
3. Job detail, lifecycle states, edit/reschedule, unscheduled queue, and search.
4. Calendar projection and app-wide notification delivery/settings bridge.
5. Inventory reservation/usage, expense/receipt links, labor, photos, and change
   orders.
6. Confirmed closeout to invoice creation and user-selected delivery.
7. GPS/Bluetooth arrival staging after manual workflows and field evidence pass.
8. Premium entitlement/trial gating around automation, never around data access.

Security-suite execution is intentionally deferred at the user's request. Each
delivery stage still requires focused correctness, navigation, storage, and
regression tests before the next stage starts.
