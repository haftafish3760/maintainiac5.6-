# Contractor Dashboard Commercial Readiness Audit

Audit date: 2026-07-25

Scope: contractor dashboard only. Jobs, invoice-form, notification, shared
calendar, and active-workday changes require coordination with their owning
work lanes.

## Verified Baseline

- The contractor-dashboard source is split into eight purpose-named production
  files. All eight pass the 500-line source limit. The largest is
  `contractor_dashboard_sections.dart` at 454 lines.
- The dashboard reads local job, expense, invoice, vehicle, odometer, and active
  workday controllers. Its current summary values are not hard-coded.
- Start Day, optional GPS assistance, stops, notes, receipts, expenses, fuel,
  materials, invoices, estimates, payments, helpers, and the contractor calendar
  are represented in the current screen.
- Focused analyzer and contractor-dashboard regression checks pass.
- The dashboard now exposes Jobs directly in both pre-day and active-day quick
  actions. The Today Work Queue also has a View All Jobs control and appears
  before secondary operating metrics.
- Open Jobs, Jobs Today, receipt review, unpaid invoices, weekly payments, and
  weekly expenses are now actionable metrics rather than display-only tiles.
- Weekly expenses use the real local expense ledger, group Monday through
  Sunday, show saved categories and daily totals, and open the existing daily
  recap/detail/date-specific Add Expense flow.
- Weekly payments use payment dates from real saved invoice records, group the
  current week by day, exclude deleted and voided invoices, and open the linked
  saved invoice from each payment row.

## Crash Trace Clarification

The reported `framework.dart` assertion at line 6268 is a Flutter framework
source location, not the line count or source location of a Maintainiac app
file. In the current Flutter SDK, that assertion checks that an inherited
widget has no remaining dependents when it is deactivated. The repeatable Jobs
Create/Cancel/Back sequence is therefore a real widget-lifecycle or navigation
bug in the Jobs flow, but the framework line number does not mean a Maintainiac
file contains 6,268 lines.

## Release-Blocking Gaps

1. The contractor calendar still presents demo markers, demo recaps, and dummy
   contractor timeline entries. It is not a trustworthy operational calendar.
2. The dashboard has no explicit active-job selection. The Active Contractor
   Day panel treats the first scheduled job as the current job, which can be
   wrong when several jobs exist or the schedule changes.
3. Dashboard actions do not yet carry an explicitly selected job. Receipts,
   expenses, materials, invoices, payments, mileage, notes, and helper time
   therefore cannot yet form one dependable job-cost and daily-work record from
   this screen.
4. Create Job currently opens the Jobs home rather than starting a dedicated
   create-job flow. The Jobs lane owns that correction and its reported back
   navigation assertion.

## Important Commercial Gaps

1. Dashboard Layout, Quick Action Tiles, Telemetry Readouts, and reset-to-default
   settings are visible placeholders rather than working customization.
2. Helpers opens permissions management; it does not provide daily helper
   assignment, time tracking, job association, or active-helper status.
3. Attention rows and job rows are informational only. Users cannot open the
   exact overdue invoice, receipt review, or scheduled job from the row.
4. The screen has no next-appointment block, schedule conflict warning, overdue
   task/reminder summary, unscheduled-job queue, or material-readiness signal.
5. Fixed three-column quick-action grids and several horizontal rows still need
   proof on small/older phones, landscape, tablets, and high accessibility text
   sizes. The contractor-only text-scale clamp was removed in this pass.
6. Shared `active_workday_screen.dart` and `active_workday_store.dart` are over
   the 500-line rule at 1,688 and 726 lines. They are direct dependencies but
   belong to the shared workday/trip lane, not the contractor-dashboard folder.

## Recommended Build Order

1. Finish the Jobs lifecycle fix and define a stable dashboard-to-job route
   contract in the Jobs lane.
2. Replace contractor calendar demo data with dated source records from Jobs,
   workday/trips, expenses, materials, invoices, payments, and reminders.
3. Add explicit active-job selection and carry that job context through every
   dashboard action.
4. Make job and attention rows open their exact records, with honest empty,
   loading, unavailable, and recovery states.
5. Add independent-contractor helper assignment/timekeeping, then expose crew
   metrics only when helpers exist.
6. Build persistent dashboard customization with add, remove, reorder, and
   reset-to-default behavior.
7. Validate the complete command center on a small older Android profile, the
   S24 Ultra, high text scaling, landscape, and iOS before commercial signoff.

## Ownership Boundary

- Contractor-dashboard lane: hierarchy, dashboard commands, job-context
  presentation, actionable dashboard rows, metrics, customization, and adaptive
  layout.
- Jobs lane: job/customer/address/date forms, scheduling, create/cancel/back
  lifecycle, job details, and stable job route contracts.
- Shared reminder/calendar lane: local reminders, push channels, sound behavior,
  operating-system notification settings, and real cross-module calendar data.
- Invoice lane: invoice/customer records, job linkage, payment workflow, and
  invoice-specific forms.
