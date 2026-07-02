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

## Non-Negotiable Edge-Case Rule

- Before implementing any feature, think through the likely failure modes, interruption cases, old-device constraints, security/privacy risks, data accuracy risks, audit/export needs, and navigation/back behavior. Either handle them in the implementation or call them out before coding.
- This app is a record-keeping tool first. If the user enters complete and correct information, Maintaniac must preserve it accurately, defensibly, and exportably for tax, audit, invoice, expense, mileage, inventory, maintenance, and payment records.
- Accuracy is mandatory. Money, mileage, dates, quantities, inventory counts, taxes, totals, cost-per-unit, cost-per-mile, profit/loss, and derived summaries must be calculated from source records and must not silently drift. If a value cannot be trusted, the UI must say so and require review.
- Security and user trust are top priorities. Keep private business records, receipts, locations, invoices, payments, and vehicle/work data local-first by default. Do not expose, sync, upload, log, or share sensitive user data unless the user explicitly enables that behavior and the app explains the tradeoff.
- User data belongs to the user, not the app. Do not design local records, receipts, images, PDFs, exports, or proof files so that uninstalling Maintaniac is the only practical way they can disappear or so the app holds data hostage.
- Final saved receipt proof and exported business records must have a user-controlled storage/export path. Working cache/draft files may be temporary while a flow is in progress, but the saved record system must let users keep, export, move, or back up their records outside the app when they choose.
- Temporary receipt camera/crop/optimization files are working files only. They are not the final saved proof. The app must not call a receipt fully saved until the record and its proof files have a durable user-controlled storage/export path or the user has accepted the storage mode.
- Export is not a later luxury. Year-end tax export, personal backup export, and audit packet export are core record-keeping behavior. Build records so they can be exported to CSV plus supporting receipt/proof files from source data.
- Demo or lab data must never be silently inserted into a real user database. Any seed/demo records must be opt-in and clearly separated from release-track user records.
- Offline-only users must be able to keep local records without Firebase or hosted backup. Future storage modes should include local-only/manual export, user-selected external/provider storage where the operating system allows it, bring-your-own cloud/provider storage, and hosted sync for users who opt in.
- The app must never delete user receipts, exports, external files, or provider files without explicit user approval and clear wording. Cleanup may only remove app-created temporary working files under a documented policy, and saved proof must not be silently destroyed.
- The app must work on older and lower-end phones, not only current flagship devices. Assume users may have older Android phones such as a Galaxy S9 Plus class device, older iPhones from roughly the 2017 era, prepaid/low-end Android phones, weak cameras, limited RAM, slower CPUs, and 32 GB or nearly-full storage.
- Device capability detection is a first-class runtime responsibility for the whole app. At startup and before heavy workflows, Maintaniac should use capability tiers instead of hardcoded phone models to scale camera capture, OCR, PDF parsing, receipt parsing, barcode scanning, catalog matching, cache sizes, animation/workload intensity, and cleanup behavior. Older or constrained devices get lighter local work and clear manual fallbacks; capable devices can use heavier local assistance.
- Do not raise Android `minSdk`, iOS deployment target, plugin platform floors, storage requirements, camera requirements, or hardware assumptions without explicit approval and clear evidence of what devices would be excluded.
- Every advanced feature must have a safe fallback. If OCR, document scanning, custom camera controls, cloud sync, file import, PDF parsing, torch, tap-to-focus, GPS, barcode scanning, or a storage provider is unavailable, the user must still have a clear manual/local path whenever the workflow can reasonably continue.
- Every secondary screen, detail screen, flow step, review screen, picker, catalog, add-supplies screen, receipt screen, and settings sub-screen must show a clear back control and must handle Android/iOS system back. Back goes to the previous step or previous screen, not randomly to a section home, unless the user is already on that section's primary home screen.
- Every form or capture flow must handle interruption. Phone calls, app switching, camera interruption, low-memory process death, screen lock, notification taps, accidental back, and OS permission dialogs must not destroy important in-progress user work. Save drafts or ask the user whether to save/leave when appropriate.
- Always check the edge-case checklist in `docs/edge_case_checklist.md` for non-trivial work. If the checklist reveals a known gap, document the gap instead of pretending the feature is complete.
- Follow `docs/data_export_storage_spec.md` for storage, export, draft, low-storage, and future sync decisions.
- Follow `docs/maintainiac_production_operating_directive.md` for production
  trust rules, QA discipline, and bug-to-regression requirements.
- Follow `docs/expense_release_one_blueprint.md` for the full expense app
  architecture, milestone gates, and safe two-Codex ownership split.
- Follow `docs/receipt_camera_release_one_blueprint.md` for release-one receipt
  camera architecture, scope boundaries, pass lanes, and readiness gates.

## Architecture

- Use screen-first folders: `screens/dashboard`, `screens/maintenance`, `screens/expenses`, and so on.
- The `screen_notes/` TXT files are product documentation. Each major screen/module has notes that explain how that screen/app is supposed to work, what features belong there, and what user-stated requirements must not be lost.
- Treat each major screen as an individual app under one roof. Before changing a screen, read the relevant `screen_notes/` TXT files and the exact-screen notes under `screen_notes/app_screens/` when present.
- When the user states a new app requirement, append it to the relevant TXT note with a source/date or batch label. Capture requirements, feature behavior, fields, workflows, safety rules, permissions, data rules, and UI/UX decisions. Do not capture unrelated personal rambling, repeated venting with no new requirement, or invented Codex assumptions.
- See `docs/screen_notes_usage.md` for the screen-note capture rules.
- Shared UI belongs in `shared/widgets`; shared app state belongs in `shared/state`.
- When the user says to clean up the project, folder structure, dead code, leftovers, or floating files, do the cleanup immediately and completely. Do not leave source files sitting loose at a section root when a clear `home`, `entry`, `settings`, `calendar`, `categories`, or similarly named purpose folder fits. Clean it before the user has to delete files manually.
- Keep folder and file names human-readable for someone who does not know the codebase. A person should be able to tell what a file is for from its path.
- When moving or deleting source files, update imports and run analyzer before calling the cleanup done.
- When replacing an old direction with a new one, remove or quarantine obsolete/unwired code before adding another implementation. Do not leave dead prototypes, duplicate flows, or confusing old screens sitting beside the new release-track path.
- Keep `main.dart` thin.
- File size rule number one: no source file may go over 500 lines without explicit user approval first.
- If a file truly needs to exceed 500 lines, ask before doing it and explain why splitting would make the code worse.
- Split large screens into focused layout, section, model, category, and helper files before they approach 500 lines.
- Do not create numbered catch-all files such as `category1.dart`, `section2.dart`, or vague names that hide what the file does. File and folder names must describe their actual responsibility.
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
- Export packages must be built from source records and supporting proof files, not from visible UI labels or summaries.
- Year-end exports must support at least CSV records, receipt/proof inclusion when available, date-range selection, destination choice, storage checks, progress feedback, and a clear completion summary before they are considered release-ready.
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
- PDF receipts are first-class receipt sources, not a throwaway attachment. The app must eventually render/read PDF receipts well enough to support receipt review, audit storage, and OCR/parsing where possible.
- Receipt file intake must support importing from the user's local device files, Google Drive, Apple iCloud, Microsoft/OneDrive-style storage when supported, and normal platform document providers.
- Receipt file intake must support documents beyond plain image capture where reasonable, including PDF receipts and document-style files that users receive from stores, vendors, email, or messaging apps.
- Users must be able to attach receipts received through email or messages. Future import paths should support platform share/open-in flows from Gmail, iCloud Mail, Yahoo, other mail apps, SMS/MMS, and similar sources rather than forcing users to manually move files first.
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
