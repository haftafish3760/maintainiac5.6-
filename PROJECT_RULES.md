# Maintaniac Build Rules

Maintaniac is a professional-grade record keeping app for people and small crews who use vehicles for work. Treat every change as release-track work, even when a screen is still early.

## Product Identity

- Maintaniac is one app under one roof that contains several connected record keeping tools: trip tracking, expense tracking, invoices, payments, maintenance, materials/inventory, receipts, reports, and related workflows.
- The app is for anyone who needs dependable business and vehicle records, including solo workers, small crews, handymen, contractors, delivery drivers, mobile service workers, and people who use the same vehicle for both personal and business miles.
- Support users with dedicated business vehicles, mixed personal/business vehicles, or multiple vehicles. Do not assume one operating model.
- The app must be IRS audit ready at all times. Records, dates, classifications, receipts, mileage, payments, invoices, expenses, and corrections must be designed around trust, traceability, and defensible reporting.
- This folder is currently focused on laying out the UI correctly. Do not rush into backend complexity when the active goal is screen structure, flow clarity, and professional layout.

## Product Scope

- Version 1 focuses on individual users and very small operations with one to several vehicles.
- Fleet administration, employee roles, and larger crew workflows must be designed so they can be added later without rewriting the main app.
- The app is mobile-first, but layouts must adapt cleanly from small phones through desktop screens.
- Do not store VIN numbers or license plate numbers. Vehicle profiles use nicknames or user-entered labels.

## Architecture

- Use screen-first folders: `screens/dashboard`, `screens/maintenance`, `screens/expenses`, and so on.
- Shared UI belongs in `shared/widgets`; shared app state belongs in `shared/state`.
- Keep `main.dart` thin.
- Avoid long files. Target roughly 500 lines per file whenever possible.
- A little over 500 lines is acceptable when it keeps a coherent screen or component together.
- 1500 lines is the strict maximum for any source file. Do not exceed it.
- 2000 lines is an absolute emergency ceiling for non-source generated or exceptional files only, and must not become normal project practice.
- Split large screens into focused layout, section, model, and helper files before they approach the hard limit.
- Do not hard-code layouts for one device. Use constraints, breakpoints, wrapping, and adaptive sizing.
- Do not lock orientation. Respect the user's device orientation preference.
- The app must never change the device auto-rotate/rotation-lock setting. Do not add `SystemChrome.setPreferredOrientations`, `android:screenOrientation`, `requestedOrientation`, or sensor-based orientation overrides unless the user explicitly reverses this rule.
- When launching a pushed Android build from Codex, use `adb shell am start ...` instead of `adb shell monkey ...`; on Samsung test devices, `monkey` reproduced a system rotation-lock toggle even though the app had no permission to write settings.

## UI Rules

- All readable text must respect the user's device accessibility text settings. Do not disable text scaling for labels, form fields, buttons, instructions, dialogs, lists, receipt rows, or settings rows. If text becomes tight, redesign the container, wrapping, or layout instead of cutting off words.
- General navigation/open buttons are blue.
- Save, continue, next, OK, and positive commit buttons are green.
- Cancel, delete, destructive, and stop buttons are red.
- Buttons must be filled, readable, and consistent in shape.
- Border labels are compact structural labels. They do not scale as aggressively as primary content text.
- Body text and form content must respect device accessibility settings.
- Avoid black filled buttons.
- Avoid bright white form fields on dark/industrial screens.
- Every major screen uses the same app shell, global odometer header, hamburger menu, settings action, and bottom navigation.

## Workflow Expectations

- Build complete workflow slices, not high-level placeholders. When implementing a flow, include the obvious supporting states, helper text, actions, validation, review points, and visual polish needed for a release-track user experience.
- Polish as each feature is built. Do not defer normal UI polish, button press feedback, route transitions, spacing, hierarchy, accessibility behavior, or visual consistency to a later cleanup pass unless the user explicitly asks for a rough placeholder.
- If the requested flow is likely to slow users down, confuse them, or conflict with professional app behavior, stop and explain the better workflow before building. Do not silently implement a weaker flow just because it was mentioned first.
- Receipt capture should prioritize fast entry while preserving structure. Do not force users through broad category taxonomies during line-item entry when a faster line-item form plus later review/classification would be clearer.
- Build flows like normal professional record keeping apps. When the user names a common workflow, infer the standard required pieces instead of forcing every obvious field to be restated.
- Trip tracking must support GPS-assisted mileage workflows, business and personal miles, vehicle assignment, dates, corrections, and audit-friendly history.
- Expense tracking must support all the normal features a normal enterprise grade expense app has with all categories, dates, payment context, receipts, notes, vehicle/work profile links where applicable, and reporting.
- Invoice workflows must support generating invoices, recording payments, tracking status, and tying records back to work and dates.
- Materials must behave like an inventory/materials screen for workers who buy, track, consume, or bill supplies.
- Receipt capture flows must include a clear photo/PDF attachment path, a live preview after capture, immediate retake options, and an explicit save/continue step followed by compression ofthe phooto the user must be able to preview the photo live with the compression level.. there are 4 levels of image compression after compression is selected automatic OCR extration of the recept contents must be properly parsed and the user must be able to review and edit/correct any mistakes. each recipt category must have the appropriate UI to properly enter the recept information examples  for a fuel recept there shall be aproper UI for fuel type Gas, diesel or electric then the app must provide the proper evtry fields to select wether its gallonsor KW hours dso the UI changes autoomatically based on previous selection. a fuel recept is not the same asother recipts. the UI must contain the proper fields to properly be able to fil the category of the recipt and the fields must be approprate for that specific category all recipt categories must have a section below the recipt details section so that any aditional items can be recorded as required
- Receipt capture must support multiple photos for one receipt because long or two-sided receipts may not fit in a single image.
- Fuel receipts must at minimum account for required date, optional time, receipt image/photo upload, live preview, retake, save/continue, and later image compression/confirmation steps.
- Receipt flows should follow a proper structure across all receipt types: classification, vehicle/work context, merchant/location, primary purchase details, optional additional line items, confirmation preview of all recept details the review screen must be laid out in a way it appears like a regular store recept with line items in a list vieww With product name/details quanty, price peER ITEM/EACH , total cost for that line item. the preview shout appear the same as a normal recipt in the preview window
- Expense and receipt records must classify whether the charge is business, personal, or split when that is eventually supported. Vehicle assignment must be available at all times if the user has more than 1 vehicle so the user is able to keep all expenses assigned to the proper vehicle so therefore the active vehicle block must be present.
- Fuel receipt details must include fuel/energy type, quantity purchased, unit price when applicable, and fuel/energy subtotal. Fuel/energy types must support gasoline, diesel, electric charging, and future additions.
- Fuel entry starts by asking for the current odometer reading. That reading ties into the global odometer and must be draft-saved if the user is interrupted.
- Fuel receipts do not ask the user to mark the fuel as business or personal. The app calculates business vs personal fuel use from business and personal trip mileage.
- Fuel receipts must clearly ask whether the tank/charge was topped off or only a partial fill. The control must be noticeable without taking over the screen.
- Partial fuel fills must be saved and accumulated without recalculating final tank MPG until the user records a topped-off fill.
- When a topped-off fill is recorded, MPG and fuel cost-per-mile calculations must use the miles driven and fuel/energy purchased since the previous topped-off fill, including any partial fills in between.
- Average MPG is important across all driving, business and personal. Business vs personal fuel use should be estimated from mileage share against the user's average MPG unless more precise data is available.
- Vehicle expenses should support categories such as fuel, vehicle payment, insurance, maintenance, materials, tolls, parking, registration, inspection, and other professional categories as needed.
- Receipts must support additional line items after the primary receipt section. Additional items need item name, optional description, quantity, unit price, total price, and category when applicable.
- Receipts with multiple items must have a review step before final save so the user can confirm category, merchant, photos, totals, and line items.
- Expense categories must be first-class so the app can report and filter by category across receipts, manual expenses, calendar views, recaps, and audit exports.
- The expense home screen must make business vs personal spending easy to scan without depending on a two-column layout on small phones.
- Calendar expense views must show business and personal context clearly, but must adapt for phone width using tabs, filters, segmented controls, grouped sections, or another responsive pattern instead of forcing cramped side-by-side columns.

## Data And Trust

- Local-first storage is the target. Hive is the intended local database.
- Firebase, Google Drive, iCloud, and other backup options are future backup layers, not the source of truth.
- Users may bring their own storage providers for backup/sync. Expected options include Google storage, Apple iCloud, Firebase, and possibly Microsoft storage.
- Sync frequency must be user controlled within sensible plan/provider limits. Paid or bring-your-own-storage users can have more frequent sync options than free hosted storage users.
- Free hosted storage limits must be explicit and understandable. If Firebase-backed free storage is offered, the app must clearly communicate storage and sync constraints.
- User trust, safety, accuracy, and dependable record keeping are top priorities.
- Forms must preserve draft progress. A phone call or app switch must not destroy a partially completed workflow.
- Receipt and expense drafts must be visible from the expense screen so users can resume unfinished work.
- Unfinished receipt drafts older than 24 hours must create an in-app reminder, and later should respect the user's configured reminder channels.
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
- Receipt image compression must let the user choose how much compression to apply and preview the result before accepting it.
- Image compression exists to save local device space and cloud storage space. The UI must make that tradeoff clear without hiding quality loss.
- Receipt storage must favor fast loading and space savings: keep optimized display versions for regular viewing and preserve enough original/source data for audit needs according to the user's storage settings.
- OCR should use offline raw text extraction first. Do not blindly trust OCR to understand receipts; parse conservatively and require user confirmation for money fields.
- Premium OCR may use higher-quality services such as Google ML Kit or another strong provider, but extracted values still require user confirmation for important fields.
- Receipt parsing should be as helpful as possible: detect likely merchant name, date, time, address, phone, totals, taxes, payment hints, fuel quantity, unit price, and line items where available.
- Store name/merchant name is required for receipt entry after capture. Street address, phone number, and other merchant details are optional unless a later compliance rule requires them.

## Visual Asset Consistency

- If one level of a category uses professional rendered bitmap artwork, every sibling and deeper category level in that same workflow must use the same visual standard. Do not switch from rendered artwork to silhouettes, initials, generic icons, text-only tiles, or CustomPainter/code-drawn placeholder graphics.
- Materials and Expenses category art must share one consistent rendered style across top-level categories, subcategories, and final item tiles where a picture is useful. If real artwork is not ready, show the user the proposed image set first before wiring it into the app.
- Do not use CustomPainter as a substitute for requested category/item artwork. CustomPainter is allowed only for simple structural UI decoration, charts, or controls where the user has not requested rendered asset artwork.

## Navigation

- Main navigation buttons always go to that section's home screen. This applies even when the user is already inside that section on a deeper detail page. Do not require the user to tap another section and come back just to reset to the section home.
- In-flow Back behavior must go to the previous step, not the section home. If a user is inside a receipt flow, material picker, category drill-down, form, preview, or review screen, Back must preserve the flow and step backward one level so a wrong tap does not force the user to restart.
- Screens with internal drill-down state must intercept header Back and Android system Back to move up one internal level before popping the route.
