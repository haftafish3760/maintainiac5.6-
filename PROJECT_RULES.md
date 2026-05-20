# Maintaniac Build Rules

Maintaniac is a professional-grade record keeping app for people and small crews who use vehicles for work. Treat every change as release-track work, even when a screen is still early.

## Product Scope

- Version 1 focuses on individual users and very small operations with one to several vehicles.
- Fleet administration, employee roles, and larger crew workflows must be designed so they can be added later without rewriting the main app.
- The app is mobile-first, but layouts must adapt cleanly from small phones through desktop screens.
- Do not store VIN numbers or license plate numbers. Vehicle profiles use nicknames or user-entered labels.

## Architecture

- Use screen-first folders: `screens/dashboard`, `screens/maintenance`, `screens/expenses`, and so on.
- Shared UI belongs in `shared/widgets`; shared app state belongs in `shared/state`.
- Keep `main.dart` thin.
- Avoid long files. Target roughly 500 lines unless a file has a clear reason to be longer.
- Do not hard-code layouts for one device. Use constraints, breakpoints, wrapping, and adaptive sizing.
- Do not lock orientation. Respect the user's device orientation preference.
- The app must never change the device auto-rotate/rotation-lock setting. Do not add `SystemChrome.setPreferredOrientations`, `android:screenOrientation`, `requestedOrientation`, or sensor-based orientation overrides unless the user explicitly reverses this rule.
- When launching a pushed Android build from Codex, use `adb shell am start ...` instead of `adb shell monkey ...`; on Samsung test devices, `monkey` reproduced a system rotation-lock toggle even though the app had no permission to write settings.

## UI Rules

- General navigation/open buttons are blue.
- Save, continue, next, OK, and positive commit buttons are green.
- Cancel, delete, destructive, and stop buttons are red.
- Buttons must be filled, readable, and consistent in shape.
- Border labels are compact structural labels. They do not scale as aggressively as primary content text.
- Body text and form content must respect device accessibility settings.
- Avoid black filled buttons.
- Avoid bright white form fields on dark/industrial screens.
- Every major screen uses the same app shell, global odometer header, hamburger menu, settings action, and bottom navigation.

## Data And Trust

- Local-first storage is the target. Hive is the intended local database.
- Firebase, Google Drive, iCloud, and other backup options are future backup layers, not the source of truth.
- User trust, safety, accuracy, and dependable record keeping are top priorities.
- Forms must preserve draft progress. A phone call or app switch must not destroy a partially completed workflow.
- Permissions should be requested only when the user takes the related action.

## Timeline And Back-Dated Edits

- The calendar is the operational timeline hub. Users must be able to add, edit, or correct records for today, future dates, and any past date.
- Back-dated edits are first-class behavior, not an edge-case shortcut. If a user adds or corrects a past trip, stop, expense, receipt, payment, invoice, maintenance event, material, note, or missed workday, every affected recap and metric from that date forward must be recalculated.
- Derived values must not be treated as permanent truth. Weekly recap, monthly recap, year-to-date recap, vehicle metrics, pay averages, cost-per-mile, profit, mileage totals, maintenance intervals, and dashboard alerts must be rebuilt from the underlying dated records whenever historical data changes.
- Every record must carry enough date context to support recalculation: event date, optional event time, created timestamp, updated timestamp, source screen, assigned vehicle when applicable, work profile when applicable, and business/personal classification when applicable.
- Edits must preserve audit history internally. A correction should update the current record while retaining enough change history to explain what changed, when it changed, and which downstream values were recalculated.
- Calendar edits must preserve the selected date automatically. If a user opens May 13 and adds a missed expense, receipt, trip, stop, payment, maintenance event, or note, the new record belongs to May 13 unless the user deliberately changes the date.
- Testing must include historical edit propagation. Test cases must verify adding, editing, and deleting past records updates all later recaps and averages without AI assistance or manual cleanup.

## Maintenance Rules

- Users can set up maintenance with or without a receipt.
- Do not ask "Do you have a receipt?" as a separate gate. Receipt sections are optional, and the flow branches based on whether receipt information is actually entered.
- Maintenance receipt entry, maintenance item setup, maintenance supplies, and maintenance reminders are related but distinct parts of the flow.
- The maintenance home screen must work as a simple professional maintenance dashboard: compact active vehicle selector, clear status/message area, vertical tracked-item list, and direct setup/log/quick-service actions.
- Maintenance tracked items must be sorted by attention level first and item importance second. A high-priority service that is closer to due belongs above low-priority items.
- Single-vehicle maintenance views can show one vertical list. Multi-vehicle maintenance views must remain understandable without a carousel dependency; vehicle grouping is allowed when it improves scanning.
- Registration and inspection are supported as time-only tracked items. They must not pretend mileage is relevant.
- Maintenance reminders are off by default.
- Reminder delivery choices are independent: in-app, push, and sound.
- Threshold colors:
  - Green: 901+ miles remaining.
  - Yellow: 600-900 miles remaining.
  - Orange: 300-599 miles remaining.
  - Red: 299 miles or less remaining.
- Do not use built-in branded or trademarked product names unless legally necessary. Users may type product names themselves.

## Receipts

- Receipt capture must be shared across the whole app.
- Receipt attachment choices: Take Photo, Upload Photo, Upload PDF.
- PDF/file import must eventually support system file pickers and storage providers.
- Image optimization must show a visible quality/space tradeoff. Users must not blindly guess compression levels.
- OCR should use offline raw text extraction first. Do not blindly trust OCR to understand receipts; parse conservatively and require user confirmation for money fields.
