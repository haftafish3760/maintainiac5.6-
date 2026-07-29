# Calendar Source-Owner Integration Contract

## Purpose

Calendar is a read-only chronological projection. A source owner publishes
records and its own detail or review route; Calendar adapts and opens them.
Calendar must not read Hive/Firebase boxes directly, create a parallel record
store, or substitute a generic editor when an owner route is unavailable.

## Required owner surface

Each source that appears in Dashboard Calendar must publish all of the
following:

1. a listenable/read-only in-memory history surface above Calendar's widget
   tree, scoped to the active vehicle and work profile where the source has
   that information;
2. stable source record IDs and source-owned revisions;
3. actual, recorded, and scheduled timestamps as applicable, plus a retained
   timezone ID and offset when the source has them;
4. a source detail or review route accepting the source record ID;
5. an explicit record state and evidence/review explanation for non-confirmed
   material.

## Current Calendar adapters

| Source owner | Calendar adapter | Live Dashboard composition | Owner route |
| --- | --- | --- | --- |
| Active workday | active-workday and workday-context adapters | available | available |
| Expenses/reminders | expense and reminder adapters | available | available |
| Jobs/appointments | job adapter | available | available |
| Invoices/estimates/payments | invoice adapter | available | available |
| Maintenance | maintenance and interval adapters | available | available |
| Employee work time | work-time adapter | available | available |
| Trip review/stops | trip-review and stop adapters | needs published review history | needs review route |
| Inventory transactions | inventory adapter | needs published transaction scope | needs transaction-detail route |
| Odometer history | odometer adapter | needs owner detail route before emission | needs reading/correction route |

## Handoff rules

- An owner may add a narrow, read-only getter/scope and a route callback.
- Calendar may import that published interface, but not the source's storage
  implementation or cloud bridge.
- A pending GPS proposal remains proposed or review-required. It never becomes
  a confirmed trip, stop, job, expense, or service record in Calendar.
- If an owner route is absent, Calendar must not emit that source into the live
  master projection until it can route the user to the actual owner flow.
- A source change must add an adapter regression for date placement, revision
  suppression, vehicle/profile isolation, and deep-link identity.
