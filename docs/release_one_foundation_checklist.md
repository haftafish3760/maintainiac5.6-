# Release One Foundation Checklist

Maintaniac should be treated as a local-first record keeping system with several app modules under one roof. Release one should prioritize correct source data, clear ownership, and reliable editing before advanced export, sync, ads, or fleet automation.

## Release One Priorities

1. Define the core records before expanding UI.
   - Vehicle profile
   - Work profile
   - Employee or user profile
   - Odometer event
   - Trip or workday event
   - Expense receipt
   - Expense line item
   - Inventory item
   - Inventory transaction
   - Maintenance event
   - Invoice or job record

2. Make Hive/local storage the first source of truth.
   - Every screen should read and write durable records, not temporary UI state.
   - Demo data must stay separate from real user data.
   - Backdated edits must recalculate affected totals from the edited date forward.

3. Keep the active vehicle and context visible.
   - The active vehicle block belongs near the top of every major screen.
   - Screen settings are contextual to that screen.
   - Dashboard settings are the master app/work profile control area.

4. Finish odometer and mileage integrity before release.
   - Each vehicle needs its own odometer timeline.
   - Odometer edits must handle lower readings, unusually high jumps, fat-finger mistakes, skipped days, personal miles, business miles, split miles, corrections, and replacements.
   - Fuel MPG and expense allocation cannot be trusted until odometer rules are reliable.

5. Define ownership and linking.
   - A record should know whether it belongs to company scope, a vehicle, a work profile, a job, an employee, or personal use.
   - Fleet mode must not leak owner-only financial data to helpers or employees.
   - Exports and reports must match the same context the app is showing.

6. Keep manual entry first-class.
   - OCR, parsing, barcode, GPS, and AI assistance are helpers.
   - The user must always be able to manually enter, review, edit, and correct records.

7. Bridge overlapping workflows instead of making the user repeat work.
   - Maintenance and repair receipts should be saved as expenses and offered as maintenance events in the same flow.
   - Material receipts should be saved as expenses and optionally added to inventory in the same flow.
   - Fuel receipts should be saved as expenses and tied to odometer/fuel-mileage records in the same flow.
   - The user should not have to enter the same receipt twice in separate modules.

8. Defer advanced export until the data is trustworthy.
   - Local export can be unlimited.
   - Backed-up data export can be limited later because it may use paid backend reads.
   - Export packages must be generated from source records, not visible screen summaries.
   - Export should use the phone's familiar share/save system on Android and iOS.

## Definitions To Lock Down

- Vehicle: The physical car, truck, van, service vehicle, or company vehicle.
- Work profile: The operating context, such as gig driving, contractor work, a company role, or a specific employee/work setup.
- Employee/user profile: The person using the app or assigned to a vehicle/job.
- Company scope: Records that belong to the business overall rather than one vehicle.
- Personal scope: Records kept for the user but not counted as business.
- Shared use: Records that must split between business and personal based on explicit user entry or mileage/time allocation.

## Senior-Developer Guardrails

- Ask what source record powers a screen before building the UI.
- Ask what happens when the user edits the record later.
- Ask whether the record is local-only, backed up, or synced.
- Ask whether the record belongs to a vehicle, work profile, employee, job, company, or personal scope.
- Ask whether the user can recover after interruption, phone call, app kill, provider failure, or bad input.
- Ask whether the calculation can be audited from saved records.
