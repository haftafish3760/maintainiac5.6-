# Maintainiac Dashboard Workspace Enterprise Blueprint

Status: authoritative design and implementation contract  
Scope: Dashboard workspace, role views, operational context, recap, review queues,
navigation, and access enforcement  
Implementation state: blueprint first; existing UI is evidence, not authority

## 1. Product Standard

Maintainiac is a local-first operational record system for a solo contractor,
small crew, or fleet organization. The dashboard must remain understandable for
one person while scaling safely to hundreds of employees and vehicles.

The product is consumer-usable and enterprise-disciplined:

- the first useful action is obvious without training;
- every displayed value comes from an identified source record;
- role and permission checks apply to reads, actions, routes, exports, and sync;
- company, employee, vehicle, work-profile, job, and date scopes never blur;
- suggestions never silently become confirmed financial or mileage records;
- failures are explicit, recoverable, and auditable;
- layouts support phone, tablet, desktop, large text, keyboard, and screen reader;
- derived dashboards and recaps never mutate source records.

## 2. Non-Negotiable Architecture

### 2.1 One dashboard workspace

The Dashboard bottom-navigation destination opens one `DashboardWorkspace`.
It does not push a second dashboard route and does not show a Back button.

The workspace owns three views:

1. Technician
2. Admin
3. Recap

Availability and default selection are permission-derived:

- owner: Admin by default; Technician and Recap available;
- admin with company visibility: Admin by default; permitted alternatives;
- working owner who chooses Technician: Technician persists until changed;
- technician: Technician by default; Recap only for permitted scope;
- dispatcher/office/estimator: purpose view derived from permissions, not title;
- a user never sees a mode whose data contract they cannot satisfy.

Role names provide defaults. Permissions remain the enforcement authority.

### 2.2 One context model

Every dashboard query receives an immutable `OperationalViewContext`:

- organization/account ID;
- signed-in member ID;
- viewed member ID or company scope;
- active vehicle ID or all-permitted-vehicles scope;
- active work-profile ID;
- selected local calendar date;
- timezone;
- permission snapshot/version;
- context revision ID.

Changing employee, vehicle, work profile, company scope, or date creates a new
context revision and reloads every section from that same revision. Sections
must not independently retain stale context.

### 2.3 Source-of-truth hierarchy

1. User-confirmed local source records
2. Locally persisted system events
3. Confirmed imported/provider records
4. Unconfirmed assistance suggestions
5. Derived projections and summaries

Recap, dashboard, notifications, assistance, export, and sync are consumers.
They cannot overwrite confirmed source records as a rendering side effect.

### 2.4 Authorization is not a widget decision

Hiding a button is presentation, not security. Each protected operation must be
checked by a central authorization service before:

- querying records;
- returning counts or totals;
- opening a record route;
- creating or changing a record;
- assigning or reassigning work;
- sharing, exporting, or syncing data.

Every decision uses:

- organization membership;
- actor status;
- resource ownership/scope;
- action verb;
- explicit permission;
- target employee/vehicle/job restrictions;
- record state;
- subscription/capability only after authorization.

Default result is deny. Owner override is explicit and auditable.

## 3. Shared Workspace Shell

### 3.1 Persistent contextual header

The existing contextual vehicle/employee header remains the first product
surface. It must show the context being viewed, not merely a decorative label.

Required behavior:

- hamburger: global navigation and app-wide settings;
- gear: settings for the current dashboard view only;
- context selector: company, permitted employee, vehicle, and work profile;
- odometer: canonical active-vehicle value only;
- no Back button on the root Dashboard destination;
- context selection persists across allowed modules;
- invalid or revoked context falls back safely and explains the change;
- an active workday prevents incompatible vehicle switching;
- company scope never presents a single vehicle odometer as a company value.

### 3.2 View selector

Immediately below the header, render a segmented selector:

- Admin View
- Technician View
- Recap

Rules:

- show only authorized views;
- never disable an unauthorized view while revealing its existence;
- switching views preserves compatible context and selected date;
- incompatible context is resolved before data loads;
- selection is keyboard and screen-reader operable;
- selection persists per user, not globally for the company.

### 3.3 Responsive contract

Layout is driven by available width, not platform name:

- compact: under 700 logical pixels;
- medium: 700 through 1099;
- desktop: 1100 and above.

Compact:

- one page scroll owner;
- bottom navigation;
- full-width primary work sections;
- 48-pixel minimum touch targets;
- operational rows target 56-64 pixels but grow for accessibility text;
- no horizontal information carousel for required content.

Medium:

- two-column workspace when content relationships justify it;
- navigation may become rail;
- schedule and attention can appear side by side.

Desktop:

- persistent side or top navigation;
- constrained readable workspace, not a stretched phone;
- primary operational column plus context/inspection column;
- tables or grids for large employee sets;
- resizable window behavior at every breakpoint transition.

No fixed height may clip content at supported text scaling. No text-scale clamp
may hide an accessibility defect.

## 4. Technician View

### 4.1 Purpose

Answer, in order:

1. Am I in the correct vehicle and work context?
2. Is my workday active?
3. What needs my attention?
4. What am I doing now and next?
5. What records am I permitted to add or correct?
6. What happened today?

### 4.2 Section order

1. Contextual header
2. View selector
3. Workday control
4. Needs Attention
5. Current job / next job
6. Today's assigned schedule
7. Permission-derived personal operating summary
8. Permission-derived contextual actions
9. Calendar

### 4.3 Workday control

Before start:

- compact `Start Day` action;
- active vehicle and work profile confirmation;
- manual vehicle fallback;
- optional Bluetooth suggestion requiring confirmation;
- canonical starting odometer review;
- lower-reading, high-jump, unit, reset/replacement, and wrong-vehicle handling;
- optional GPS assistance choice after workday confirmation.

During day:

- elapsed work time;
- confirmed and projected mileage distinguished visibly;
- pause/resume/open workday;
- active job, if explicitly selected;
- GPS/Bluetooth evidence state without presenting it as proof.

After day:

- no duplicate active controls;
- completion summary links to the saved workday and Recap.

### 4.4 Needs Attention

This is an actionable review queue, not a decorative count.

Possible item families:

- OCR receipt fields require confirmation;
- receipt or expense needs business/personal classification;
- expense needs a job, category, vehicle, employee, or work-profile link;
- suspected duplicate receipt;
- odometer is lower, implausibly high, stale, or conflicts with another event;
- suggested trip, stop, arrival, departure, or purpose needs confirmation;
- job lacks completion note, material usage, customer approval, or signature;
- schedule conflict or overdue assigned job;
- estimate change requires customer or authorized staff approval;
- invoice/payment follow-up the user is permitted to see;
- offline write, sync, attachment, or provider recovery needs action.

Every queue item includes:

- plain-language issue;
- affected source/suggestion record;
- scope and occurred-at time;
- source of suggestion;
- confidence only when meaningful and calibrated;
- required action;
- safe dismiss/defer behavior;
- audit outcome after resolution.

The queue returns only authorized records. A count must not leak hidden coworker
or company information.

### 4.5 Current and next work

The current job is explicit state, never "the first scheduled job."

Each job row shows only operationally necessary information:

- time window;
- customer/site label when permitted;
- job summary;
- status;
- readiness/attention marker;
- vehicle/crew only when needed and permitted.

Tapping a row opens that exact job ID. `View All` opens a job list already
filtered to the same authorized context. A technician with assigned-job-only
access cannot discover unassigned or coworker jobs through counts, search,
deep links, calendar markers, or stale navigation state.

### 4.6 Expenses and actions

Technician expense content is permission-derived:

- `viewOwnExpenses`: show own selected-day expense summary;
- `addOwnExpenses`: allow manual expense creation;
- `uploadOwnReceipts`: allow receipt capture/import;
- `editOwnExpenses`: allow editing eligible own records;
- `deleteOwnExpenses`: allow policy-compliant deletion/correction;
- team or owner-only data requires separate explicit permissions.

Actions are generated from capabilities and current state, not a fixed tile
grid. Examples: add receipt, fuel, use material, add stop, job note, arrival,
complete job. Navigation destinations such as Jobs or Expenses remain in main
navigation and are not repeated as giant dashboard actions.

## 5. Admin View

### 5.1 Purpose

Answer:

1. Who is working, where, and on what permitted context?
2. What is late, blocked, unassigned, or awaiting approval?
3. Where can workload be safely rebalanced?
4. What company records require authorized action?

### 5.2 Priority sections

1. Contextual header and view selector
2. Company Needs Attention
3. Employee/crew operational status
4. Unassigned, late, conflicting, or at-risk work
5. Approval queues
6. Fleet/vehicle exceptions when permitted
7. Calendar

### 5.3 Employee status collection

Use real employee directory and assignment records. Never invent employee
names or activity.

Each compact employee item can show:

- employee name and role label;
- assigned/confirmed vehicle;
- workday state;
- current job;
- remaining assigned jobs;
- attention count;
- last confirmed activity time;
- evidence state labeled as suggested, not confirmed.

Behavior by scale:

- up to roughly ten visible employees on phone: priority-sorted compact list;
- larger teams: search, status filter, pagination/virtualized list;
- tablet/desktop: table or responsive grid with stable columns;
- never load hundreds of live employee detail streams simultaneously.

Tap opens an employee operational inspector using the selected employee context.
The inspector exposes only fields/actions authorized for the actor.

### 5.4 Reassignment

Reassignment requires all of:

- permission to view both jobs and target employees;
- `assignJobs` or equivalent explicit action permission;
- eligible job state;
- conflict and capacity review;
- confirmed save;
- audit event containing actor, before, after, reason, and timestamp.

Never infer reassignment solely because another technician appears available.

### 5.5 Approval queues

Queues are separate by responsibility:

- receipt/OCR review;
- expense approval;
- estimate approval;
- invoice/payment exception;
- odometer/mileage correction;
- sync/provider recovery.

Counts and records are filtered before aggregation. Admin title alone does not
grant financial access.

## 6. Recap View

### 6.1 Purpose and immutability

Recap is a read-only projection of source records for the selected date and
context. It cannot create, repair, reclassify, or synchronize records merely by
being opened.

### 6.2 Layout

1. Contextual header
2. View selector
3. Selected-date navigator and calendar
4. Source-backed at-a-glance summary
5. Awaiting-review summary when authorized
6. Chronological source-record timeline
7. Export/share entry only when authorized

Remove from Recap:

- Start/Resume Day;
- Fast Record;
- duplicate vehicle/work-profile selectors;
- GPS settings/readiness presented as a recap metric;
- navigation shortcut grids;
- weekly totals mislabeled as selected-day totals.

### 6.3 Selected-day summary

Display only metrics supported by source records and permission:

- workday start/end/duration;
- confirmed business/personal/other mileage;
- starting and ending odometer for a single vehicle context;
- scheduled/completed/incomplete jobs;
- confirmed payments received;
- confirmed expenses;
- fuel cost, quantity, and economy only when inputs are trustworthy;
- confirmed material usage/cost;
- awaiting-review item count.

Do not label cash flow as profit. Do not sum mixed currencies or units without
an explicit conversion contract. Corrections recalculate the projection.

### 6.4 Timeline

Normalize dated references without copying source data into a parallel record:

- workday lifecycle events;
- confirmed trips and stops;
- jobs and status changes;
- receipts and expenses;
- material usage;
- maintenance events;
- estimates, approvals, invoices, and payments;
- user-confirmed assistance outcomes.

Every row carries source type and source ID and opens the canonical detail
route. Deleted/voided/corrected records follow their module's audit policy.

## 7. Permission And Isolation Matrix

The implementation must produce a machine-readable matrix for every dashboard
section and action with:

- resource;
- own/team/company scope;
- view/create/edit/delete/approve/assign/share/export verb;
- allowed roles as defaults;
- explicit grants/denials;
- target employee/role restrictions;
- route guard;
- query guard;
- action guard;
- audit requirement.

Mandatory negative scenarios:

- technician cannot see coworker expenses, totals, or review counts;
- technician cannot open coworker job by guessed ID;
- technician cannot switch header context to an unauthorized employee;
- technician cannot infer hidden company totals from zero/nonzero states;
- dispatcher without financial permission cannot see invoice/expense data;
- bookkeeper without fleet permission cannot see location/mileage details;
- disabled employee loses access on the next authorization check;
- stale offline grants cannot authorize high-impact actions after revocation;
- cross-company IDs always fail closed;
- UI hiding and backend/data-layer denial agree.

## 8. State, Loading, And Recovery

Every section defines:

- loading;
- loaded with data;
- honest empty;
- permission unavailable;
- source unavailable;
- offline with cached timestamp;
- partial data;
- stale context discarded;
- recoverable error;
- permanently unavailable/deleted record.

No section displays zero when the true state is unavailable. No error erases a
previously confirmed record. Retries are idempotent.

## 9. Assistance Contract

Assistance may correlate schedule, GPS, motion, Bluetooth, receipts, job events,
and user actions to propose review items.

It must not:

- silently start/end a workday;
- silently switch active vehicle or employee;
- finalize a trip/stop/purpose;
- change odometer history;
- post an expense, invoice, payment, or material transaction;
- expose one employee's evidence to another without permission.

Suggestion records preserve evidence references, algorithm/version, confidence,
creation time, expiry, resolution, resolver, and resulting source record ID.

## 10. Navigation Contract

- Dashboard bottom-navigation always selects the root workspace.
- Root workspace has no Back button.
- Section rows open canonical source-detail routes.
- Back returns to the same dashboard view, context, date, and scroll anchor.
- Deep links run authorization before loading or revealing record existence.
- View switching does not add duplicate dashboard routes to the stack.
- Start Day uses the existing canonical odometer/workday workflow until that
  workflow is separately replaced by an approved specification.

## 11. Responsive And Accessibility Acceptance

Required proof matrix:

- narrow Android phone;
- Galaxy S25 Ultra at user's current display/text settings;
- iPhone compact width;
- phone landscape;
- tablet portrait/landscape;
- macOS/web at 700, 1100, 1440, and resized intermediate widths;
- text scales 1.0, 1.3, 1.6, and 2.0 where platform supports them;
- screen reader traversal;
- keyboard-only desktop use;
- reduced motion and high contrast.

Acceptance:

- no clipped labels or controls;
- no essential horizontal scrolling on phone;
- focus order matches visual order;
- semantic labels include state and context;
- color is never the only status signal;
- touch targets meet platform minimums;
- dynamic content announcements are restrained and meaningful.

## 12. Test Strategy

Existing tests are evidence, not authority. Requirements and independent source
records define expected behavior.

Test layers:

1. authorization decision-table unit tests;
2. context reducer and stale-revision tests;
3. source-to-projection deterministic recap tests;
4. widget tests for every view/state/permission combination;
5. route and deep-link authorization tests;
6. cross-user and cross-company isolation tests;
7. offline/restart/conflict tests;
8. accessibility and responsive golden/semantic tests;
9. real-device workflow tests;
10. migration and rollback tests.

Independent oracle examples:

- construct source records and independently calculate expected selected-day
  totals rather than calling production summary helpers;
- attempt direct route access with denied IDs;
- compare authorized query results against an explicit fixture matrix;
- mutate a source record and prove Recap recalculates without writing back;
- revoke permission while cached data exists and prove protected content closes.

## 13. Observability And Audit

Record privacy-safe operational telemetry for:

- authorization denials by rule identifier, without sensitive payload;
- failed source projections;
- stale context results discarded;
- route failures;
- review queue resolution latency;
- offline conflict/retry outcomes;
- rendering/performance thresholds for large teams.

Audit sensitive successful changes as well as denied attempts. Never log raw
receipt images, addresses, financial details, precise location, or secrets.

## 14. Migration Plan

### Phase 0: freeze and evidence

- stop ad-hoc dashboard implementation;
- preserve the current root dashboard and contractor screen as comparison
  fixtures;
- inventory routes, controllers, data ownership, and current failures;
- classify current uncommitted dashboard edits as prototype changes requiring
  blueprint review.

### Phase 1: foundation

- introduce central dashboard authorization policy;
- introduce immutable operational view context;
- introduce root workspace and view selector;
- preserve canonical header, calendar, and Start Day workflow.

### Phase 2: Technician vertical slice

- assigned jobs only;
- workday control;
- exact job routing;
- permission-filtered Needs Attention;
- selected-day own expense summary;
- negative isolation tests.

### Phase 3: Recap vertical slice

- calendar-selected date;
- source-backed workday/jobs/expense projection;
- canonical timeline routes;
- no mutation and correction recalculation tests.

### Phase 4: Admin vertical slice

- real employee directory records;
- permission-filtered status collection;
- employee inspector;
- assignment workflow and audit;
- large-team performance tests.

### Phase 5: expansion

- invoice/payment, materials, maintenance, assistance evidence, exports;
- tablet/desktop composition;
- full isolation and real-device matrix.

## 15. Definition Of Done

A dashboard phase is complete only when:

- requirements and permission matrix are approved;
- source ownership is identified;
- UI, routes, query guards, and action guards agree;
- positive and negative scenarios pass;
- accessibility/responsive proof passes;
- source records survive interruption and restart;
- no derived view mutates sources;
- migration and rollback are proven;
- real-device evidence is captured;
- known gaps and deferred risks are documented.

Passing compilation or existing tests alone is not completion.

## 16. Immediate Preserve / Refactor / Replace Decisions

Preserve pending verification:

- `GlobalOdometerHeader` contextual header;
- shared calendar component;
- canonical Start Day odometer confirmation;
- active workday source records;
- canonical job detail route;
- expense, invoice, payment, and employee source stores.

Refactor:

- root Dashboard routing into one workspace;
- contractor snapshot into permission/context-aware projections;
- Needs Attention into a shared actionable review service;
- calendar demo projection into source-backed dated entries;
- employee directory into an app-scoped authorized source.

Replace:

- duplicate dashboard routes and Back-button launcher pattern;
- fixed command grids that repeat navigation;
- unguarded aggregate counts;
- first-scheduled-job-as-current-job behavior;
- weekly/gig metrics used as a contractor selected-day recap;
- UI-only permission assumptions.

