        # Work Supplies Spec

## Purpose

Work Supplies is a lightweight supply, inventory, receipt, and cost-reference app for people who work from a vehicle or small shop. It helps a user record what they bought, what it cost, where it belongs, and how that cost can later support estimates, invoices, and job records.

This is not only a record-keeping app and not only a small receipt helper. The long-term product is a contractor workstation: inventory, materials parsing, estimates, accepted jobs, invoices, calendar planning, route planning, fleet inventory, employee permissions, customer records, and eventually a customer-facing contractor marketplace/profile ecosystem.

This is not meant to become a blind copy of a big-box-store catalog. The app should cover common supplies that a person keeps in a work vehicle, at a small shop, or across all company vehicles, then let the user add anything missing. The catalog must be practical for real service work first, especially residential and light-industrial contractors.

Work Supplies is still a real inventory system. It must help users find an item, add that item to their own inventory, track what they paid, track how many they have, and reuse that information later for invoices, estimates, job records, receipt parsing, barcode lookup, and cost history.

The full inventory-to-estimate-to-job lifecycle is defined in `docs/inventory_estimate_job_lifecycle_spec.md`. Parser and catalog work must stay compatible with that lifecycle even when the estimate, invoice, job, camera, and OCR systems are implemented elsewhere.

## Long-Term Product Vision

Mainteniac should eventually feel like enterprise-grade contractor technology that solo operators, small companies, and growing fleets can afford.

The contractor side should support:

- Solo owner/operator workflows for one person and one vehicle.
- Small company workflows for several vehicles and employees.
- Fleet workflows for many vehicles, company stock, assigned employees, permissions, jobs, and manager/owner visibility.
- A growth path where a user can start with one person and one truck, add a helper, add employee hour tracking, add a second truck, assign a technician/helper team, and eventually manage vehicles, employees, permissions, inventory, jobs, and schedules across the company.
- Customer records, addresses, job history, estimates, invoices, signed approvals, payments, job profitability, and tax/export records.
- Daily planning with a calendar, route optimizer, scheduled jobs, active jobs, vehicle assignments, and material readiness.
- Inventory-aware estimating so a user can build estimates from stocked items, receipt-backed purchases, catalog intelligence, and saved cost history.
- Receipt-to-job workflows where a store receipt can add materials to inventory, an active job, an estimate draft, a change order, or an invoice proof path.

The app must grow with the business instead of forcing the user to switch systems later. A one-truck operator should see simple tools. A small company should unlock employee, helper, vehicle, and permission tools. A larger fleet should be able to manage company stock, vehicle stock, assignments, routes, reports, and role-based access without replacing the app.

The future customer-facing side should support:

- A contractor profile visible to customers when that marketplace feature is approved.
- Customer-facing contractor details such as service area, trade specialties, photos, videos, previous work examples, contact options, and trust/profile information.
- A way for customers to find contractors for small jobs, service work, odd jobs, and full projects.

Customer-facing marketplace work is not part of the first release. First release priority is a reliable contractor-side foundation.

## Release Priority

Release one must focus on contractor-side correctness before marketplace expansion.

Highest priority:

- Residential service work.
- United States English parser/catalog behavior.
- United States Spanish parser/catalog behavior after English is solid.
- Core packs for service-truck workflows.
- Inventory, receipt-line parsing, estimate/job handoff data contracts, and local-first operation.
- Data contracts that do not block later employee hours, helper workflows, permissions, vehicle assignment, GPS routing, and fleet mode.

Next priority:

- Standard, Professional, and Complete packs for residential.
- Light-industrial packs where they overlap practical service work.
- Canada English and Canada French parsing support.
- Hosted pack delivery through Firebase/Cloud Storage without expensive per-item Firestore reads.

Later priority:

- Commercial depth.
- More countries and languages.
- Customer-facing contractor profiles and marketplace discovery.
- Advanced fleet management and route optimization UI.

## Product Rules

- The visible name is Work Supplies.
- Work Supplies is the inventory and material cost source of truth. It should not become the owner of jobs, invoice state, or dashboard profile behavior.
- Work Supplies settings are section-specific settings. Tapping settings while inside Work Supplies should open inventory/material settings, including future receipt assistance defaults, storage preferences, catalog/knowledge-pack choices, barcode behavior, and export settings for inventory records.
- Jobs belong to the contractor/work-profile and invoice side of the app, because jobs combine billing, active/completed status, expenses, inventory used, vehicles on site, receipts, profit, and loss.
- Work profile type controls which dashboard workflow is active. A user cannot run two active profile types at once. Examples include gig driver, delivery driver, and contractor.
- Contractor profiles can expose jobs on the dashboard and invoice side. Inventory should link to a job when needed, but it should not own the job command center.
- The invoice system must be treated as a top-priority, ironclad record system. Inventory must preserve clean cost data so invoice lines can import materials accurately.
- Do not use the word "rig" anywhere in visible app copy. Use vehicle, work vehicle, truck, van, SUV, company vehicle, or shop depending on context.
- Do not reuse old Materials screens or receipt layouts.
- There is one Work Supplies source path: `lib/screens/work_supplies/`.
- Generated APK artifacts must not be treated as source truth.
- Every flow must be understandable to a first-time user.
- The primary inventory action should be adding items to inventory. Do not make catalog browsing a primary action; the preload knowledge layer should assist typed entry and suggestions in the background.
- The first time a user opens Work Supplies, show a short intro explaining that inventory displays saved stock and trade packs only assist search, receipt review, and add-item suggestions.
- Trade packs are user-selected local data sets, not a visible UI catalog. The UI adapts to saved inventory records and pack words/paths only when that flow needs them.
- Work Supplies settings must let the user add, enable, disable, hide, and eventually delete trade packs from the device. Deleting a trade pack must not delete the user's saved inventory, receipt, barcode, cost, or transaction records.
- Trade packs must support both local download and future cloud-assisted parsing. Local packs are fastest and best for offline use. Cloud-assisted parsing can support users with limited device storage, but it must be opt-in, clearly explained, subscription-aware if needed, and designed to avoid runaway reads/writes.
- If a device does not have enough free space for a selected pack, the app must warn the user before download, offer smaller packs where possible, and offer cloud-assisted mode when available.
- The app must detect device capability/class where practical and avoid pushing old phones as hard as newer phones. A Galaxy S9-class device should not be treated like a Galaxy S24/S25 Ultra-class device.
- Search may exist as a supporting tool, but it must not force a deep category browse before entry.
- A user must always be able to add a receipt line even if the item is not in the preload catalog.
- Browse/search only identifies the item. Packaging, quantity, barcode, receipt, and cost details belong in the add-item form after the item is selected.
- Receipt basics and receipt line entry are separate concerns.
- Store information opens a full store form, not a single text field.
- Work Supplies supports invoice and estimate cost lookup later.
- Accuracy applies to every item in the inventory system, not only Plumbing. Icons, material composition, item names, unit options, and receipt behavior must match the selected item.
- Work Supplies now uses Hive-backed local persistence as the release-track direction. OCR, sync, cloud backup, push notifications, and hosted storage remain future layers unless explicitly approved.
- Inventory records and stock events must be exportable from source data for taxes, accountant review, audits, and personal backup.

## Main User Jobs

- Find a common supply quickly.
- Add stock or cost information for a supply.
- Add a selected catalog item to the user's own inventory.
- Link one or more barcodes to a specific inventory item.
- Scan a barcode later to find the item, view quantity on hand, cost history, and item image/details.
- Log a receipt with one or more supply lines.
- Log a receipt line that is not in the preload catalog.
- Create a new supply/category when the preload catalog does not fit.
- See recent/frequent supplies so repeated purchases are faster.
- Keep enough cost detail to support invoice/estimate pricing later.
- Use saved inventory cost data to prefill future invoice and estimate material lines.

## Inventory Ownership

Inventory must know where stock belongs before it saves an item. Valid destinations include company inventory, the active vehicle, a named vehicle, job staging when a job context launches the flow, and a custom location. Vehicle assignment matters because work vehicles can carry different stock, and company inventory may be distributed later by the owner or manager.

Inventory records may carry a job reference for invoice/job cost rollups, but job status, job detail screens, active/completed job lists, and profit/loss command views belong outside Work Supplies.

## Receipt Item Assignment

Receipt entry must support both same-destination and per-item assignment.

- The add-items screen should use one unified intake flow. Receipt proof is optional inside that flow: if the user has a receipt, they attach it; if not, they still record the inventory lines. Receipt assistance is a preference configured during onboarding and in Work Supplies settings, not a separate action button shown every time.
- The date selected for a receipt must become the inventory record date and must show on the Inventory home calendar. Inventory calendar data should be designed so the dashboard/jobs calendar can later read the same receipt/job/inventory events instead of rebuilding a separate calendar truth.
- User-facing wording should call it assisted receipt entry or app assistance. Do not use OCR as the visible feature name because users care about faster entry and review, not the technical extraction method.
- Camera, OCR, PDF, shared receipt capture, image prep, receipt stitching, and Expenses receipt capture are separate shared systems. Do not modify those systems while working on the Work Supplies parser/catalog unless the user explicitly reassigns that work.
- Work Supplies parser/catalog work may define the text/line-item input it expects later, but it must not change how receipt images, PDFs, camera capture, OCR extraction, or expense receipt review are performed.
- Per-item assignment is the safer default when the user has multiple vehicles because one store receipt can include supplies for several vehicles, company stock, or job staging.
- In manual entry, the first receipt screen chooses the assignment method only. When per-item assignment is selected, the destination picker belongs inside the add-item line screen, not on the first receipt screen.
- Same-destination assignment is a shortcut for receipts where every line belongs to one vehicle, company inventory, job staging location, or custom location.
- The app must never force the user to use custom location just to split a receipt across normal vehicle destinations.
- The first receipt screen must also ask whether the receipt is all business, all personal, or mixed. All-business and all-personal are shortcuts. Mixed receipts must show business/personal/split controls on each line.
- The first receipt screen must ask destination in plain terms: all items to one vehicle/company/job location, or mixed vehicles/company/job locations. The one-place flow must show company inventory, each saved vehicle, job staging when available, and custom location.
- If the needed vehicle is missing, the user must have a path to create or add that vehicle instead of being forced to misuse custom location. The actual vehicle-create flow should live in the shared vehicle/profile area and return to the receipt afterward.
- Inventory assignment must support both the vehicle/company/job destination and an optional inside-location detail such as bin, drawer, shelf, tray, trailer compartment, or shop shelf. Fleet inventory needs both levels: where the item lives and where inside that place the worker can find it.
- Every receipt line must also track business, personal, or split use. Mixed business/personal receipts are expected, not edge-case data. This decision belongs on each line because one store receipt can contain company inventory, job materials, vehicle supplies, and personal purchases.
- Split-use lines must preserve the business percentage so future exports, invoice proof, and tax reports can separate business value from personal value without destroying the original receipt record.
- Future OCR receipt review must show parsed receipt lines in a review list before saving. The user must be able to assign parsed line groups to destinations, for example lines 1-5 to Work Truck 1, lines 6-8 to Backup Truck 1, and the remaining lines to company inventory.
- OCR may prefill all lines with one destination and business-use value when the user chooses same-destination mode, but mixed receipts must keep per-line or grouped line assignment before final save.
- Assisted receipt review must treat each parsed line as its own editable card. Each card needs decisions for inventory vs expense, inventory destination or expense category, business/personal/split use, quantity/package math, and review confidence. Non-inventory lines must use the shared expense category source instead of inventing a Work Supplies-only category list.
- Receipt lines are future invoice feeders. Invoices should be able to reference specific receipt line ids, not only the whole receipt. When a customer-facing proof is generated, the app should be able to show the original receipt image while blocking or cropping out unrelated lines, totals, and personal/company-private purchases.

## Current Clean Slate

The current Work Supplies build is intentionally stripped down.

Allowed on screen:

- Active vehicle / odometer row at the top.
- Bottom app navigation from the shared shell.
- A single horizontal button row below the vehicle row.

Current buttons:

- Log expense with receipt.
- Log expense only.
- Add supplies only.

Not allowed in the current clean slate:

- Old Materials UI.
- Catalog browser.
- Search database.
- Calendar.
- Receipt form.
- Category files.
- Generated material icons.
- Nested supply cards or stacked button columns.

Primary screen rules:

- Work Supplies home is a primary screen.
- It must not show a back button.
- It must not show a separate title bar that pushes the content down.
- The odometer/active vehicle row is the first visible content row.
- The page itself may say "Welcome to Work Supplies" below the vehicle row.

## Catalog Model

Each supply item must carry enough metadata to drive the UI without guessing.

The detailed catalog intelligence contract is in `docs/materials_catalog_intelligence_contract.md`. That document is the source of truth for residential/light-industrial/commercial scope tags, pack tier targets, smart item metadata, parser aliases, OCR mistake handling, negative match rules, confidence hints, classification output, and Command One diagnostics.

Core pack definition:

- Core is the service-truck pack, not merely the smallest pack.
- Core should represent roughly the top quarter of catalog rows where practical, but the real product target is coverage: roughly 75-90% of what a normal residential service technician touches during ordinary day-to-day work.
- For plumbing, Core means the common fittings, valves, pipe/tubing, supply lines, toilet/faucet repair parts, water-heater service parts, drain/finish service parts, supports, consumables, and fasteners a residential plumber or handyman would reasonably carry, buy often, or need to estimate common home/apartment work.
- Core should stay compact enough for budget phones and limited data plans, but it must not be so skinny that a normal Lowe's/Home Depot/Ace/Ferguson receipt misses common residential items.
- Standard, Professional, and Complete expand outward from Core. They should not be dumping grounds caused by bad tier logic.

The catalog and parser must be UI-independent. Future changes to Work Supplies screens, cards, navigation, dashboard layout, or review UI must not require rewriting catalog identity, parser rules, pack tiers, aliases, or diagnostics. UI can consume parser results, but parser logic must not depend on widgets, routes, BuildContext, or current layout.

The preload knowledge layer is not meant to become a full SKU catalog or a forced browse tree. Its main job is to recognize typed item language, receipt abbreviations, sizes, materials, and common trade names, then suggest classification. Users must still be able to type an item in plain language and save it when the app does not know the exact item.

Cross-trade items must be treated carefully. A physical item such as a copper 90 can be valid for plumbing and HVAC refrigerant work. The app may suggest a likely classification from typed text and onboarding/work-profile context, but it must not silently force the item into the wrong trade when the same part can be used in multiple work contexts. User work profiles and selected trades should influence suggestions, not block correction.

The app should avoid shipping a massive all-trades SKU database locally. Local preload data should stay compact and focus on recognition terms, category paths, common items, aliases, and receipt abbreviations. Future Firebase or provider-backed catalog storage should support optional trade knowledge packs so users can download only the trades they selected during onboarding or work-profile setup. The app must keep a manual/offline path even when hosted catalog data is unavailable.

Required item fields:

- Item ID.
- Display name.
- Trade: Plumbing, Electrical, HVAC, Carpentry, Custom.
- Market scope tags: residential, lightIndustrial, commercial.
- Pack tier priority: core, standard, professional, complete.
- Category path.
- Synonyms and common names.
- Receipt abbreviations and known store-counter shorthand.
- Common misspellings and safe OCR mistake patterns.
- Search keywords.
- Attribute tokens for size, material, shape, connection, category, and package words.
- Negative match hints for nearby item families.
- Confidence scoring hints.
- Normal purchase style.
- Allowed units.
- Required receipt fields.
- Optional receipt fields.
- Image asset or user photo.
- Barcode aliases linked by the user.
- Store-specific receipt aliases or abbreviations when known.
- Whether the item can be stocked.
- Whether cost per unit, cost per foot, or cost per package matters.
- Classification output for inventory, expense, job material, tax/reporting, billable status, and estimate/invoice defaults.
- Catalog version, source confidence, manual verification flag, generated flag, and needs-review flag.

Examples:

- `14/2 NM-B Cable`: purchase style roll/spool/foot, unit foot, cost per foot.
- `Copper Standard 90`: purchase style each/package, unit each.
- `PVC Primer`: purchase style can, unit ounce/quart/gallon as needed.
- `Air Filter`: purchase style each/package, dimensions required.

## Search

Search must work across:

- Official item names.
- Common names.
- Nicknames.
- Trade shorthand.
- Sizes.
- Materials.
- User-linked barcodes.
- Store receipt aliases and abbreviated item names.
- Regional names and older trade names when practical.

Examples:

- `romex` finds NM-B cable.
- `half inch copper 90` finds copper 1/2 inch standard 90.
- `pipe dope` finds pipe thread sealant.
- `teflon tape` finds PTFE thread seal tape.

Search results must show:

- Item name.
- Trade and path.
- Small image.
- Primary action: Add to receipt or Add stock depending on context.
- Secondary action: View details.

If the search does not find a strong match, the user must be offered a clear path to add a new item and optionally link the search wording or scanned barcode to that new item.

## Barcode and Item Linking

Barcode scanning is part of the inventory foundation.

- A user may scan a barcode while adding an item.
- A user may link multiple barcodes to the same item because different stores, package sizes, and brands may use different barcodes for equivalent supplies.
- Barcode data is an identifier linked by the user to the real item. Maintaniac does not claim ownership of manufacturer, retailer, UPC, EAN, QR, or package barcode data.
- Do not scrape or misuse Lowe's, Home Depot, Ace, True Value, or any retailer database or terms-restricted data.
- A scanned barcode should find the matching inventory item when already linked.
- If a scanned barcode is unknown, the app should let the user search/browse to the item and then link that barcode.
- Barcode lookup should support future workflows: add to inventory, add to receipt, count stock on a job, view truck quantity, view company-wide quantity, view which vehicles carry the item, view last purchase/cost history, and support invoice/estimate material entry.
- Barcode or QR scanning should support receipt line review: after a receipt is parsed, the user should be able to scan the product/package code to confirm or correct the matched line item.
- Custom Maintaniac-generated barcodes are not part of the current plan. Reuse existing item/package barcodes where possible and store them only as user-linked identifiers.
- Do not pre-seed manufacturer or retailer barcode databases into the app. Barcode links are created by the user on their device unless a future explicit opt-in sharing feature is approved.
- If hosted backup or Firebase sync is enabled later, barcode aliases remain user-owned records by default. Sharing aliases to improve community matching must be a separate opt-in with review, abuse protection, and a way to remove contributions.
- Future low-stock reorder assistance may suggest reordering, but it must require explicit user approval before any purchase action. The app must not blindly reorder supplies.

## Item Identity and Package Aliases

The app needs an item identity layer separate from the visible catalog UI. This layer lets manual entry, barcode scan, receipt review, and future assisted parsing agree on the same item without forcing users through a giant browse tree.

Required local identity behavior:

- Store user-linked product, package, barcode, QR, or shelf codes as aliases for an inventory item.
- Preserve the original scanned value and a normalized lookup value.
- Normalize lookup by ignoring spaces and hyphens and by treating letters case-insensitively.
- Allow several barcodes to point to the same item because stores, brands, pack sizes, and package formats differ.
- Re-saving the same normalized barcode updates the alias instead of creating duplicate identity records.
- Store package context with the alias: package label, purchase type, units per package, unit, merchant name when known, source, and created/updated dates.
- Keep this data local-first in Hive and exportable later with the rest of the user's records.

Identity aliases are not global claims about UPC ownership or retailer catalog data. They are user-controlled pointers that help this user's inventory find the right item again.

## Parser Correction Feedback

User corrections are valuable parser evidence, but they must not silently mutate official catalog packs.

Required correction behavior:

- A corrected parser line may create a local correction record tied to the user, item ID, parser version, pack version, merchant bucket when known, trade context, and review outcome.
- Corrections may propose a new alias, negative-match rule, merchant abbreviation, fixture case, confidence adjustment, or category-routing hint.
- Corrections must preserve privacy-safe evidence only. Do not store raw receipt text, receipt photos, card numbers, customer names, job addresses, employee private data, exact location, or exact device identifiers in parser feedback visible to the owner/admin.
- Local correction memory can improve that user's future suggestions after explicit review, but official packs require a manual promotion gate before any correction becomes shared catalog intelligence.
- Community or hosted correction sharing must be opt-in, abuse-protected, reviewable, versioned, and removable by the contributor where practical.
- A proposed correction must be regression-tested before promotion so it does not break existing aliases, dangerous-word ambiguity rules, cross-trade separation, or known merchant fixtures.
- Rejected corrections must remain isolated from official packs and should be tracked only as privacy-safe diagnostic counts.

## Add Item Form

After browse/search identifies the exact item, the user lands on an add form. This is not a wizard inside the browse tree.

The form must already know the selected item and its normal metadata.

Required form behavior:

- Show the selected item name, category path, and item image/details.
- Let the user add quantity on hand.
- Let the user choose whether they bought each items or a package/box/bag/multi-pack.
- If each, ask quantity.
- If package, ask packages bought and items per package, then calculate total item count.
- Let the user enter cost, receipt association, store, and date when applicable.
- Let the user scan or link a barcode to make the item easier to find next time.
- Let the user add without a receipt or add with a receipt.
- Save enough information for future invoice and estimate material pricing.

## Browse Flow

Browse is for users who do not know what to search for.

Top level:

- Plumbing
- Electrical
- HVAC
- Carpentry
- Custom

Plumbing example:

- Plumbing > Fittings
- Plumbing > Pipe and Tubing
- Plumbing > Valves
- Plumbing > Supply Lines
- Plumbing > Toilets and Toilet Repair
- Plumbing > Sinks and Sink Repair
- Plumbing > Drainage
- Plumbing > Consumables
- Plumbing > O-rings, Washers, and Seals
- Plumbing > Hangers and Supports

Plumbing preload scope:

- Include everyday service supplies, not just pipe and fittings.
- Include toilets and toilet repair supplies such as wax rings, closet bolts, flappers, fill valves, flush valves, handles, tank-to-bowl kits, and toilet supply lines.
- Include sinks and sink repair supplies such as basket strainers, pop-up assemblies, tailpieces, P-traps, faucet connectors, sink supply lines, washers, and common repair seals.
- Supply lines may be a shared plumbing category because toilet and sink supply lines overlap.
- Users must be able to add their own item under an existing preload category.
- Users must be able to create a brand-new category when the preload structure does not fit.

For Plumbing > Fittings:

- The next decision is material first.
- Material options appear before fitting options.
- Material selection controls what fitting types are shown.

Plumbing fitting materials:

- PVC
- CPVC
- Copper
- PEX
- Iron
- PVC DWV

Fitting examples:

- Standard 90
- Street 90
- Reducing 90
- Standard 45
- Tee
- Reducing Tee
- Coupling
- Reducer
- Adapter
- Union
- Cap
- Plug
- Y fitting for valid drainage materials only
- Cleanout for valid drainage materials only

Invalid combinations must not appear. PEX must not show copper fittings. Copper must not show PVC DWV cleanouts.

## Receipt Flow

The receipt flow is not a wizard, but it must have clear sections.

Top-level receipt sections:

- Receipt header.
- Store information.
- Date and time.
- Receipt photo/import placeholder.
- Receipt totals.
- Receipt items.
- Review and save.

Receipt photo and document intake:

- The manual camera/photo flow remains the first implementation priority.
- PDF receipts must become a supported receipt source, not just a placeholder attachment.
- PDF receipt support must include importing a PDF, rendering/previewing it, keeping it attached for audit proof, and later reading/parsing it where possible.
- Import sources must include local device files, Google Drive, Apple iCloud, Microsoft/OneDrive-style document providers when supported, and normal Android/iOS file picker providers.
- Receipt intake should support documents and files received from email, text messages, and share/open-in flows. Expected sources include Gmail, iCloud Mail, Yahoo, other mail apps, SMS/MMS, and similar apps.
- Users should not have to move an emailed or texted receipt into a special folder before attaching it when the operating system can hand the file to Maintaniac.

Store information:

- Opens a full form.
- Store name required.
- Street address.
- City.
- State selector.
- ZIP code, 5 digits for US mode.
- Phone, 10 digits formatted as `(###) ###-####` for US mode.
- Email.
- Website.
- Notes.
- Buttons: Cancel, Save and Continue.

Receipt items section actions:

- Add from Work Supplies.
- Add item not listed.
- Create new supply.

Add from Work Supplies:

- Opens search first.
- Also offers browse catalog.
- If the user selects a preload item, the receipt line form is prefilled from item metadata.

Add item not listed:

- Fast manual entry.
- Name required.
- Description optional.
- Category/path optional but recommended.
- Purchase style.
- Quantity.
- Unit.
- Unit cost or package cost.
- Line total.

Create new supply:

- Name required.
- Trade/category path.
- Optional photo or icon.
- Synonyms.
- Normal purchase style.
- Allowed units.
- Then allow adding it to the current receipt.

## Receipt Line Rules

Receipt line fields must be contextual.

Each or package item:

- Quantity bought.
- Package count if packaged.
- Items per package if packaged.
- Price each or price per package.
- Computed cost per item.
- Line total.

Length item:

- Roll/spool/foot purchase option.
- Total length.
- Package or roll count when relevant.
- Total cost.
- Computed cost per foot.

Liquid or measured item:

- Container count.
- Amount per container.
- Unit of measure.
- Total cost.
- Computed cost per unit.

Totals:

- Subtotal.
- Tax.
- Grand total.
- App validates receipt item totals against receipt total and warns when they do not match.

## Images

Images must be authentic enough that a trade user does not immediately distrust the app.

Rules:

- No double labels.
- No double containers.
- One clear label per item.
- Image should represent the actual item type and material.
- Copper looks copper.
- PVC looks white PVC.
- CPVC looks CPVC.
- PEX looks like PEX.
- Iron looks like black iron or galvanized when specified.
- NM-B/Romex looks like flat sheathed residential cable.
- Breakers look like breakers and show amperage where useful.

## Navigation Rules

- Bottom navigation to Work Supplies always returns to the Work Supplies home.
- Back inside a selection flow returns to the previous step, not straight home.
- Receipt item selection preserves receipt context.
- If the user entered from a receipt, selecting an item returns to that receipt line entry.
- If the user entered from browse/add stock, selecting an item opens stock/details actions.

## Build Order

1. Stabilize project cleanup and naming.
2. Build the Work Supplies spec.
3. Build the data model and metadata rules.
4. Build search-first catalog UI.
5. Build browse UI using the same catalog data.
6. Build receipt shell.
7. Build full store form.
8. Build contextual receipt line forms.
9. Build add item not listed.
10. Build create new supply.
11. Build receipt preview and total validation.
12. Add images only after data paths are stable.
13. Run analyze and tests.
14. Build and install only a freshly generated APK.
