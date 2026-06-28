# Expense Screen Full Design

This document is the planning source of truth for the Maintainiac expense app.
No expense screen rebuild should begin until this document is reviewed and agreed
to. The expense area is treated as a full app inside Maintainiac, not as a small
feature panel.

## 1. Feature Purpose

The expense app exists to help users record money spent for personal, business,
or mixed-use activity. It must be simple on the surface and structured enough
underneath to support receipts, mileage context, business/personal allocation,
reminders, exports, OCR, cloud backup, and later AI-assisted classification.

The target users include drivers, contractors, delivery workers, tradespeople,
 traveling nurses, small business owners, and anyone who uses vehicles, tools,
equipment, inventory, or a home office for personal and business purposes.

The app must help users keep accurate records without forcing them to understand
the internal accounting structure.

## 1.1 Expense Diagnostics And Privacy

The expense screen is not complete unless it saves expenses correctly, handles
errors, logs diagnostics, queues offline telemetry, and exposes summary metrics
for the future Command Center.

Expense telemetry must be local-first. The app writes privacy-safe events to
Hive first, then uploads summarized telemetry later when sync allows. Telemetry
is for health and reliability only: average time on screen, save failures,
validation errors, OCR success, correction rates, attachment problems, storage
mode issues, sync state, and abandonment rate.

The cloud shape for Expense screen telemetry is one privacy-safe summary
document, not one Firestore write per local event. The summary lives at
`orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` and includes aggregate
counts, rates, platform/device buckets, and capped failure breakdowns. Raw
receipt text, receipt images, store names, item descriptions, customer data,
addresses, notes, and line item content must never be uploaded in this summary.

Expense telemetry summary queueing is throttled. The first implementation uses
a 15-minute minimum interval and replaces any pending summary for the same
Firestore path before adding a newer one. That keeps Command 1 health data fresh
without turning frequent screen activity into repeated Firestore writes.

Expense receipt diagnostics must also expose Command Center summary rates for
OCR readable rate, OCR fail rate, parser success rate, parser problem rate,
catalog match rate, correction rate, and review rate. These rates are computed
from privacy-safe counts and quality buckets. They must not include raw receipt
text, item descriptions, store names, customer data, addresses, notes, or
receipt images.

Expense OCR Command Center health may be attached to the same
`orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` document as
`commandCenterOcrContract`. It must pass the OCR contract privacy audit before
queueing. This preserves the single-summary-document cost shape: no per-receipt
admin health writes, no Firestore read per receipt, and no raw receipt content
in Command 1. The uploaded summary keeps `uploadShape` as
`single_summary_document`.
Rule: no per-receipt admin health writes.

Expense telemetry may track:

- screen opened, screen closed, and time spent on screen.
- add expense started, completed, or abandoned.
- manual expense created and receipt expense created.
- edit opened/saved and delete requested/confirmed.
- category selected or changed.
- validation errors, save failures, image attach success/failure.
- OCR started, completed, failed, correction opened, and safe correction field
  names such as vendor/date/tax/total/category.
- storage mode used, local image removed, cloud backup success/failure, and
  sync pending/synced/failed.
- app version, platform, device tier, profile type, storage mode, plan status,
  and online/offline status.

Expense telemetry must never track receipt images, receipt text, customer names,
addresses, phone numbers, notes, full item descriptions, or other private user
content. If a telemetry event attempts to include private content, the event
must be rejected before storage.

Expense diagnostics must be built into each meaningful workflow step so Command
1 can explain failures in plain English. A failure event is not complete unless
it can say:

- what feature failed
- which workflow step failed
- where in the process it failed
- confirmed cause when the app has evidence
- cause not confirmed when the app does not have enough evidence
- exact missing evidence needed to confirm the cause
- retry count
- abandonment status
- app version, platform, device tier, profile type, storage mode, plan status,
  and online/offline status

Command 1 must never guess. It may show `Confirmed cause` only when the app
diagnostic proves the cause. Otherwise it must show `Cause not confirmed` and
list the missing diagnostic evidence.

## 2. Exact Screen Structure

### Expense Home Screen

Top to bottom:

1. Global odometer block.
   - Must be the same shared odometer system used by the dashboard.
   - Must be at the very top of the expense screen.
   - Updating the odometer must update everywhere in the app.

2. Active vehicle block.
   - Shows only if the user has more than one saved vehicle.
   - Shows the current active vehicle.
   - The active vehicle is the last active vehicle from the user's workflow.
   - If the user ended the day on Truck 3, Truck 3 remains active.

3. Expense totals strip.
   - Shows weekly total.
   - Shows monthly total.
   - Later versions may break totals into business, personal, and mixed use.

4. Message center.
   - Shows expense messages, reminders, and alerts.
   - Must connect to the main dashboard message system.
   - The bottom navigation icon must eventually show a badge when expense
     messages exist.

5. Quick action category grid.
   - Shows 12 home-screen-style category buttons.
   - Buttons use rounded app-icon shapes with labels underneath.
   - No horizontal scrolling.
   - Buttons can be tapped, long pressed, moved, removed, or inspected.
   - The 12 buttons are user-configurable.
   - The app may optionally auto-manage the top 12 categories based on usage.

6. Add expense FAB.
   - Primary action for logging any expense.
   - Opens the full category picker.

7. Expense calendar.
   - Must visually match the dashboard calendar layout and colors.
   - Must be its own expense calendar, not the dashboard calendar flow.
   - Tapping a day opens the expense day screen for that date.

Important layout decision:

- The expense home screen does not switch into separate business and personal
  screens.
- The home screen stays stable.
- Business and personal are chosen when logging the receipt or expense.
- Calendar entries, day totals, and recap displays show the business/personal
  colors after entries exist.

### Add Expense Category Picker

Top to bottom:

1. Back button.
   - Reusable app back button.
   - Goes to the previous screen, not always to dashboard or expense home.

2. Title.
   - Working title: "Add Expense".

3. Current quick categories section.
   - Shows the same 12 categories currently shown on the expense home screen.
   - Uses the same icon/button style as the expense home screen.
   - Section title must explain that these are the user's quick categories.
   - Section has a top and bottom divider or border.

4. Auto-manage toggle.
   - Lets the user allow Maintainiac to keep the most-used 12 expense
     categories on the expense home screen.
   - Text must explain the behavior clearly.
   - User can turn this off at any time.
   - User can still manually rearrange quick categories.

5. Other categories section.
   - Shows at least 38 additional categories.
   - Categories are alphabetical.
   - Tapping any category opens the correct expense entry form.
   - Long pressing any category opens category actions, including information.

### Expense Day Screen

Top to bottom:

1. Reusable Back button with arrow and text.
2. Date title.
3. Previous day and next day controls.
4. Vehicle context.
   - If no vehicle profile exists, this area is blank.
   - If one vehicle profile exists, show that vehicle under the date.
   - If multiple vehicles exist, show Active Vehicle under the date with a
     selector.
5. Day totals.
   - Business total on the left.
   - Personal total on the right.
   - Each total uses its assigned color profile.
6. Entries for that day.
   - Each entry shows whether it is business or personal through its border,
     title label, or container color.
   - Normal users may have only a few entries per day.
   - Heavy users must still be able to scan 10-20 entries without the screen
     becoming confusing.
7. Add expense action for that date.
8. Reminder actions for that date.

The day screen must not use placeholder button stacks as the primary layout.

### Category Information Sheet

Shown from long pressing a category.

Must show:

1. Category name.
2. Weekly total.
3. Monthly total.
4. Business total.
5. Personal total.
6. Mixed or neutral total when applicable.
7. Entry count.
8. Notification count if this category has reminders or alerts.
9. Actions:
   - Log expense.
   - Move to another slot.
   - Remove from quick actions.
   - Open full information screen.

### Category Information Screen

Must show:

1. Category name.
2. Weekly, monthly, and yearly totals.
3. Business, personal, and mixed-use breakdown.
4. Entry list.
5. Reminder list.
6. Export-ready detail later.

## 3. Exact File Structure

Expense files must be split for maintainability. The target is roughly 500 lines
per file. Files may exceed that only when there is a strong reason.

Required structure:

```text
lib/screens/expenses/
  expenses_screen.dart
  expense_home_layout.dart
  expense_fab_category_picker.dart
  expense_calendar.dart
  expense_day_screen.dart
  expense_entry_screen.dart
  expense_reminder_screen.dart
  expense_settings_screen.dart
  expense_message_center.dart
  expense_action_icons.dart
  categories/
    expense_category.dart
    expense_categories.dart
    fuel_category.dart
    repair_category.dart
    insurance_category.dart
    loan_lease_category.dart
    parking_category.dart
    tolls_category.dart
    meals_category.dart
    tools_category.dart
    supplies_category.dart
    registration_category.dart
    utilities_category.dart
    reminder_category.dart
    other category files as needed
```

## 4. What Each File Is Allowed To Contain

### expenses_screen.dart

Allowed:

- Screen shell.
- High-level routing to expense home.
- No large widget bodies.
- No category definitions.
- No receipt form logic.
- No calendar internals.

### expense_home_layout.dart

Allowed:

- Expense home vertical layout.
- Odometer placement.
- Conditional active vehicle block.
- Totals strip.
- Message center placement.
- Quick actions placement.
- FAB placement.
- Calendar placement.

### expense_fab_category_picker.dart

Allowed:

- Add Expense screen opened from FAB.
- Top 12 quick category section.
- Auto-manage toggle UI.
- Other categories list/grid.
- Category tap and long-press routing.

### expense_calendar.dart

Allowed:

- Expense calendar visual layout.
- Expense-specific day tap behavior.
- No dashboard day flow imports.

### expense_day_screen.dart

Allowed:

- Selected date view.
- Previous and next day behavior.
- Date-specific entries.
- Date-specific reminders.
- Add expense for selected date.

### expense_entry_screen.dart

Allowed:

- Shared receipt form shell.
- Date, time, odometer, vehicle, receipt attachment, merchant fields.
- Delegation to category-specific form sections.

### categories/*.dart

Allowed:

- One category definition per file.
- Category labels.
- Icon identity.
- Search synonyms.
- Required fields.
- Optional fields.
- Whether the category supports business/personal/mixed allocation.

## 5. What Each Widget Does

### Global Odometer Header

Shows and edits the shared odometer. It is global across Maintainiac.

### Active Vehicle Block

Appears only when there are multiple saved vehicles. Shows the active vehicle
used by the user's most recent workflow.

Every expense created while a vehicle is active must keep an explicit ownership
context: selected vehicle, employee/person when applicable, work profile, and
company/fleet scope when applicable. In single-vehicle mode this can default
quietly. In multi-vehicle, employee, contractor, or fleet-style accounts the
user must be able to confirm or change which vehicle and person the expense
belongs to before saving, so vehicle cost, employee activity, business/personal
split reporting, and future fleet permissions all stay accurate.

### Expense Totals Strip

Shows weekly and monthly totals. Later expands to business, personal, and mixed
breakdowns without crowding the home screen.

### Expense Message Center

Summarizes reminders, alerts, and expense-specific messages. Must connect to the
dashboard message system.

### Quick Action Grid

Shows 12 user-selected quick expense categories. It behaves like a phone home
screen: tap opens, long press shows actions, move changes slot.

### Add Expense FAB

Opens the category picker. This is the universal add-expense entry point.

### Category Picker

Shows the 12 quick categories first, then other available categories
alphabetically. Lets users log an expense from any category.

### Expense Calendar

Shows expense-related day activity and opens the expense day screen.

### Expense Classification Selector

Appears in the receipt or expense entry flow. It lets the user mark the entry as
Business or Personal. Mixed/shared allocation can be added later for vehicle
costs such as fuel, repairs, insurance, loan/lease, and registration.

The selector does not change the entire expense home screen. It controls how the
entry is stored and how the calendar/day recap presents that entry.

## 6. User Actions

### Tap Quick Category

Opens the expense entry form for that exact category.

### Long Press Quick Category

Opens a category action sheet with move, remove, information, and log actions.

### Tap FAB

Opens the Add Expense category picker.

### Tap Category In Picker

Opens the expense entry form for that category.

### Long Press Category In Picker

Opens category actions and information.

### Toggle Auto-Manage Top 12

When enabled, Maintainiac tracks category usage and updates the home screen's
top 12 quick categories. When disabled, the user's manual order remains in
place.

### Tap Calendar Day

Opens expense day screen for that date.

### Select Business Or Personal In Entry Form

Stores the expense with that classification. Calendar day totals and entry cards
must use the matching color profile.

### Tap Previous Or Next Day

Moves the expense day screen one day backward or forward.

### Tap Back

Returns to the previous screen in the stack.

## 7. Data Flow Rules

1. Odometer is global.
2. Active vehicle is shared app state.
3. Expense calendar is independent from dashboard calendar but may report
   summary data to dashboard.
4. Dashboard can summarize expense activity, but expense workflows own expense
   entry behavior.
5. Category usage counts drive auto-managed quick categories.
6. Business and personal classification must be stored with each expense entry.
7. Fuel allocation eventually depends on mileage, MPG, duty state, and
   business/personal mileage split.
8. Receipt images must eventually support compression levels and storage choice.
9. OCR and AI classification come after manual forms are correct.
10. Exports must be planned from the start, even if built later.

### Business And Personal Color Rules

- Business and Personal use consistent colors across the expense app.
- The full expense home screen does not change background color when logging
  different classifications.
- Color appears on entry forms, calendar markers, day totals, and entry cards.
- Suggested starting point:
  - Business: teal or green-blue.
  - Personal: blue or amber.
- Final colors must remain readable in dark mode and later light mode.

## 8. Codex Is Forbidden To Do

1. Do not build new expense UI before this spec is approved.
2. Do not put every widget into one giant file.
3. Do not create receipt or payment as expense categories.
4. Do not use placeholder category forms for every category.
5. Do not make the expense calendar open dashboard calendar flows.
6. Do not place the odometer anywhere except the top.
7. Do not show the vehicle block when there is only one or zero saved vehicles.
8. Do not use horizontal scrolling for the 12 quick actions.
9. Do not use generic white-only icons.
10. Do not make settings screens empty.
11. Do not hide required user actions behind unclear labels.
12. Do not claim the app is IRS audit-ready in user-facing text.

## 9. Step-By-Step Build Order

1. Finalize and approve this design document.
2. Delete or archive the current experimental expense implementation if needed.
3. Create the final expense folder and file structure.
4. Build category model and category registry.
5. Define the first 50 expense categories.
6. Build expense home skeleton.
7. Add global odometer at top.
8. Add conditional active vehicle block.
9. Add totals strip.
10. Add message center placeholder wired for future dashboard messages.
11. Build 12 quick category grid.
12. Build long-press category action sheet.
13. Build Add Expense FAB.
14. Build category picker with top 12 and other categories.
15. Build auto-manage top 12 toggle UI and state placeholder.
16. Build expense calendar with dashboard-matching visuals.
17. Build expense day screen.
18. Build shared expense entry form shell.
19. Add Business/Personal selector to the expense entry flow.
20. Build fuel category form.
21. Build remaining category form sections.
22. Add receipt capture placeholder.
23. Add reminder flow placeholder.
24. Add settings screen.
25. Run analyzer and tests.
26. Build APK and install on S24.
27. Screenshot and review actual device layout.

## 10. Acceptance Checklist

- [ ] Expense screen has one approved source-of-truth spec.
- [ ] Odometer is at the top.
- [ ] Vehicle block appears only for multiple saved vehicles.
- [ ] Vehicle block shows active vehicle.
- [ ] Expense save records vehicle/person/work-profile ownership context.
- [ ] Multi-vehicle and employee accounts can confirm or change expense owner.
- [ ] Weekly and monthly totals are visible.
- [ ] Message center is visible.
- [ ] 12 quick categories are visible.
- [ ] Quick categories have home-screen-style icons.
- [ ] Quick categories do not scroll horizontally.
- [ ] Long press opens action sheet.
- [ ] FAB exists.
- [ ] FAB opens category picker.
- [ ] Category picker shows top 12 first.
- [ ] Category picker shows at least 38 other categories.
- [ ] Other categories are alphabetical.
- [ ] Category picker has auto-manage top 12 toggle.
- [ ] Calendar visually matches dashboard calendar.
- [ ] Calendar opens expense day screen.
- [ ] Expense day screen has Back, previous day, and next day.
- [ ] Expense day screen has business total and personal total.
- [ ] Expense entry flow has Business/Personal selector.
- [ ] Calendar/day entries show business/personal color coding.
- [ ] Expense forms are category-specific.
- [ ] Fuel form changes fields based on gas, diesel, or electric.
- [ ] Receipt capture exists as part of forms, not as a category.
- [ ] Reminder opens a reminder workflow, not a receipt form.
- [ ] Expense diagnostics are logged locally without private user content.
- [ ] Offline telemetry can be queued for later summarized upload.
- [ ] Command Center summary metrics can report expense health.
- [ ] Command Center summary metrics can report OCR readable rate, OCR fail
      rate, parser success rate, parser problem rate, and average time on
      Expense screen.
- [ ] Files stay maintainable and split by responsibility.
- [ ] Analyzer passes.
- [ ] Tests pass.
- [ ] APK builds.
- [ ] S24 install succeeds.
- [ ] Device screenshot is reviewed before accepting UI.
