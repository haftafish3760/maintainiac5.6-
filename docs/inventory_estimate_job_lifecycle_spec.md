# Inventory, Estimate, Job, And Receipt Lifecycle Spec

Date: 2026-06-29

Scope: Maintainiac 5.6 Work Supplies / Inventory parser output and its future handoff into estimates, jobs, invoices, vehicles, employees, and Firebase sync.

This document captures product behavior and data architecture only. It does not authorize edits to camera, OCR, PDF, Expenses receipt capture, shared receipt-capture widgets, image preprocessing, or receipt stitching.

## Product Intent

Work Supplies is not only a receipt parser and not only an expense helper. It is the materials intelligence layer for contractor inventory, estimates, jobs, invoices, receipts, fleet stock, and cost history.

The parser must feel smart without requiring AI at runtime. When OCR or manual receipt text gives usable lines, the materials parser should recognize the item, package, quantity, unit cost, tax allocation, destination, job/estimate context, and review confidence as much as possible from deterministic catalog and parser intelligence.

Mainteniac's long-term goal is a complete contractor workstation and eventually a customer/contractor ecosystem. The contractor side must work first: inventory, receipts, estimates, jobs, invoices, calendar, route planning, vehicles, employees, permissions, customer records, and financial/tax export records. Customer-facing contractor discovery, public profiles, job photos/videos, and marketplace-style features are future layers after the contractor foundation is reliable.

The app must scale from one person with one truck to a company with many vehicles. A solo operator should not be forced into enterprise complexity, and a 20-truck company should not be limited by one-truck assumptions.

## Business Growth Ladder

Mainteniac must be designed so a contractor can grow inside the app instead of outgrowing it.

Expected account stages:

- One owner/operator, one truck, no employees.
- Owner plus one helper who may need time tracking but limited business visibility.
- Owner plus helper plus a second technician or second vehicle.
- Several employees, assigned vehicles, role-based permissions, job assignments, and inventory visibility by vehicle.
- Fleet/company mode with company stock, per-vehicle inventory, manager/admin roles, employee hours, job scheduling, route planning, and reporting.

Each stage should unlock more capability without making the earlier stage feel complicated. Data models should include optional org, employee, vehicle, permission, and job fields early so later fleet features do not require rewriting inventory, receipt, estimate, or job history.

## Lifecycle Summary

1. A contractor creates an estimate.
2. Estimate lines can be added manually, from inventory, from catalog search, from saved cost history, or later from parsed receipt lines.
3. The customer receives the estimate by email, text link, or print.
4. The customer accepts and signs the estimate.
5. The accepted estimate can become a job.
6. The user schedules the job on a calendar with start date/time and optional completion window.
7. During the job, the user may buy materials from one or many stores.
8. Receipt lines can be parsed and assigned to inventory, job cost, estimate update, invoice proof, expense, or non-business/personal buckets.
9. Job material cost rolls into job profitability and eventual invoice generation.
10. The invoice can reference estimate lines, job usage, inventory usage, receipt lines, payments, and proof rules.
11. Scheduled jobs should feed the user's calendar and future route optimizer.
12. The next-day workflow should let a contractor open the app and see planned jobs, route order, assigned vehicle, needed materials, and unresolved receipt/inventory review items.

## Receipt-To-Inventory And Receipt-To-Job Flow

Receipt review must support multiple user intents:

- Add all parsed lines to one vehicle, company inventory, job staging location, or custom location.
- Split parsed lines across several vehicles, company inventory, job staging, and personal/non-business use.
- Add selected receipt lines directly to an active job without requiring the user to open the job first.
- Add selected receipt lines to an existing estimate or change-order draft.
- Save selected lines as non-inventory job materials that are billable or non-billable.
- Save selected lines as expenses only when they are not stock/material inventory.
- Ignore personal or unrelated receipt lines while preserving original receipt proof according to privacy rules.

The user must always be able to override parser output before saving.

## Estimate Lifecycle

Estimate records should support:

- draft status
- sent status
- viewed status when available
- accepted/signed status
- rejected/expired status
- converted-to-job status
- converted-to-invoice status

Estimate lines should support:

- manual line
- catalog item line
- inventory-backed line
- receipt-backed line
- labor line
- fee/permit line
- discount/adjustment line
- taxable flag
- tax rate snapshot
- cost basis
- markup rule
- customer-facing price
- source inventory record id when applicable
- source receipt line ids when applicable
- source job id when applicable

## Job Lifecycle

A job begins when an estimate is accepted or when the user creates a time-and-materials job directly.

Job records should support:

- job id
- customer id
- estimate id if created from estimate
- invoice id when invoiced
- scheduled start date/time
- scheduled end date/time or window
- active/completed/cancelled status
- assigned vehicle ids
- assigned employee/member ids
- inventory location or job staging location
- receipt line ids
- inventory transaction ids
- material cost rollup
- labor cost rollup
- expense rollup
- tax rollup
- profit/loss rollup

Jobs belong to the contractor/work-profile and invoice side of the app. Work Supplies provides material and inventory records to jobs but should not own the whole job command center.

## Calendar And Route Planning Contract

Calendar and route planning are future workflow consumers of job, customer, vehicle, and inventory data.

Required future behavior:

- Accepted estimates can become scheduled jobs.
- Jobs can appear on the calendar with start date, start time, end window, assigned vehicle, assigned employee, customer address, and job status.
- The route optimizer should eventually read the next day's scheduled jobs and plan an efficient route.
- The user's daily view should show planned jobs, route order, material readiness, job notes, and unresolved receipt/inventory review tasks.
- Inventory should be able to tell a job or daily plan whether needed materials are already in a vehicle, in company stock, staged for the job, or still need to be purchased.
- GPS and route planning are separate heavy workstreams, but inventory/job records must already carry enough stable ids and location context for those systems to consume later.
- Route planning must support solo users first and then expand to multiple vehicles, assigned employees, helpers, job windows, and vehicle-specific material readiness.
- Calendar and route planning must not depend on parser UI. They should consume stable job ids, customer ids, vehicle ids, inventory transaction ids, and material action records.

## Tax Allocation Rules

Receipt tax must be allocated to item cost when the receipt line is used for inventory, estimate, job cost, or invoice pricing.

Example:

- A box costs `$100.00`.
- Sales tax is `5%`, or `$5.00`.
- The box contains `10` items.
- True post-tax package cost is `$105.00`.
- True post-tax unit cost is `$10.50`.

Required stored values:

- pre-tax line subtotal
- receipt tax rate when known
- allocated tax amount
- post-tax line total
- package quantity
- units per package
- unit cost before tax
- unit tax allocation
- unit cost after tax
- tax jurisdiction/source snapshot

Tax rules must be snapshot-based. If a tax rate changes later, old receipt/job/invoice records must not silently change.

## Inventory Ownership And Fleet Mode

Inventory must be prepared for solo users and fleet accounts.

Inventory ownership context should support:

- org/company id
- owner user id
- employee/member id
- vehicle id
- job id
- company inventory location
- job staging location
- custom location
- inside-location detail such as bin, drawer, shelf, tray, trailer compartment, or truck section

Fleet mode requirements:

- One account owner may have many vehicles.
- Vehicles may be assigned to employees.
- Employees may only see or edit records allowed by their permissions.
- A receipt can include items for several vehicles or jobs.
- Vehicle cost history and stock levels must stay separate.
- Company-wide inventory must be able to see totals across vehicles when permission allows.
- The data model must not assume one active vehicle is the only inventory destination. A contractor may have multiple vehicles, trailers, employee vehicles, job staging areas, and shop/company stock.
- Users should be able to locate an item inside a vehicle or shop with bin, drawer, shelf, compartment, tray, trailer section, or other location detail.

## Permission Model Requirements

Inventory permissions must separate:

- owner access
- admin access
- manager access
- helper/employee access
- viewer access
- financial visibility
- vehicle visibility
- job visibility
- receipt proof visibility
- inventory count edit permission
- estimate/invoice pricing permission

Helpers should not automatically see company-wide profit, invoice totals, all expenses, or unrelated vehicles.

Employee and helper requirements:

- A helper may need hour tracking without full inventory, estimate, invoice, or financial access.
- A technician may need assigned job visibility, assigned vehicle inventory, receipt upload/review permissions, and limited customer/job notes.
- A manager may need scheduling, vehicle assignment, inventory transfer, and employee oversight without owner-only billing/account controls.
- The owner must be able to decide what each user can see, create, edit, approve, export, and delete.
- Permission checks must apply consistently across inventory, receipts, jobs, estimates, invoices, calendar, GPS/route planning, and diagnostics.

## Parser Output Contract

The materials parser should output enough structured data for downstream workflows:

- canonical item id
- locale pack id
- trade
- market scope
- pack tier
- item family
- material
- size
- connection/type/style
- package quantity
- quantity purchased
- unit type
- matched receipt phrase
- confidence score
- confidence reason
- negative-match notes when relevant
- candidate alternatives
- merchant name if known from receipt metadata
- tax allocation fields when receipt totals are available
- suggested destination: inventory, job, estimate, expense, personal, or review
- suggested inventory location if context exists
- source receipt line id

The parser must not depend on the current UI.

The parser should support these downstream actions without requiring the user to manually re-enter the same material:

- Add to vehicle inventory.
- Add to company inventory.
- Add to a job staging location.
- Add directly to an active job.
- Add to an estimate draft.
- Create or update an estimate line.
- Support a change order when actual materials differ from the original estimate.
- Support invoice proof and job cost rollup.
- Preserve personal/non-business/split-use decisions for mixed receipts.

## UI-Independence Rule

Inventory, estimate, job, invoice, and receipt review screens may be redesigned later without breaking parser behavior.

Required separation:

- Catalog item identity lives in catalog/parser data, not widget labels.
- Parser result objects must be plain workflow data that can be consumed by inventory, jobs, estimates, invoices, admin diagnostics, Firebase sync, or tests.
- UI screens may choose how to present confidence, alternatives, destinations, and corrections, but they must not own the matching rules.
- Receipt-line corrections should save back as parser/correction data, not as screen-specific state.
- Jobs and estimates should reference stable item ids, receipt line ids, inventory transaction ids, and tax snapshots instead of copied UI strings.
- Future inventory UI changes must not require rebuilding catalog packs or parser language packs.

## Material Handoff Contract

When receipt text is parsed, the downstream handoff should be able to create one or more material actions without opening a specific page first:

- Add to vehicle inventory.
- Add to company inventory.
- Add to a job staging location.
- Add directly to an active job as billable material.
- Add to an estimate or change-order draft.
- Record as an expense-only material line.
- Split one receipt across several destinations.

Each handoff action should preserve:

- canonical item id
- original receipt line id
- selected destination type and destination id
- quantity and package breakdown
- pre-tax, tax, and post-tax unit cost snapshot
- markup rule snapshot when used for estimate, job, or invoice pricing
- user confirmation or override status
- parser confidence and candidate alternatives at the time of review

## Firebase Shape Notes

Do not store parser packs as one Firestore item document per catalog row for normal app reads.

Recommended hosted pattern:

- Firestore stores pack manifests and metadata.
- Cloud Storage stores compressed parser/catalog chunks.
- User inventory, jobs, estimates, invoices, receipt metadata, and transactions sync as user/org records.
- Receipt proof files live in Cloud Storage with permissioned metadata in Firestore.
- Diagnostics and admin summaries must use aggregated counts, not raw receipt text or receipt images.

Read/write budget guidance:

- Local simulations first.
- No live Firebase cost tests without explicit approval.
- Normal catalog pack download should be one manifest read plus chunk downloads.
- Avoid per-line, per-item, or per-candidate Firestore reads during parsing.
- Batch writes and use summaries for diagnostics.

Pack delivery and cost-control requirements:

- Pack manifests can live in Firestore.
- Pack payloads should live as compressed Cloud Storage chunks.
- The app should download only the packs the user selected.
- Parsing should be local-first when the pack is installed.
- Cloud-assisted parsing can exist for users who cannot or do not want to store packs locally, but it must be opt-in and cost-controlled.
- Do not perform per-candidate Firestore reads during receipt parsing.
- Admin diagnostics should be aggregated and batched instead of writing one noisy diagnostic record per candidate comparison.
- No live Firebase cost/load testing is allowed without explicit approval.

## Device Capability And Storage Edge Cases

The app must handle low-end and high-end devices differently where practical.

Required edge cases:

- Not enough free storage to download a pack.
- User tries to download several large packs on a limited-storage phone.
- User has no internet but needs to parse with installed local packs.
- User has internet but no installed pack and chooses future cloud-assisted mode.
- User is on a slower/older phone and needs smaller batches, lower memory pressure, and safer background work.
- User is on a newer phone and can use larger local packs and faster parsing.
- Download interrupted halfway through a pack.
- Pack manifest downloaded but one or more chunks fail.
- Pack version mismatch between local cache and hosted manifest.
- User deletes a pack but must keep their saved inventory, receipt, barcode, job, estimate, and cost history records.

Device detection should classify capability broadly, for example low, mid, high, and flagship, rather than hardcoding behavior only for one model. A Galaxy S9-class device should not be treated the same as a Galaxy S24/S25 Ultra-class device.

## Customer-Facing Ecosystem Later

Customer-facing features are future scope, not release-one scope.

Future customer-facing capabilities may include:

- Public contractor profile.
- Service area.
- Trade specialties.
- Photos and videos of completed work.
- Customer contact/request flow.
- Customer ability to find contractors for small jobs, service calls, odd jobs, and full projects.
- Profile and marketplace safety, moderation, permission, and privacy controls.

The contractor workstation must be stable before customer-facing discovery is built.

## Admin And Diagnostics Requirements

Admin/Command One diagnostics should help identify parser problems without exposing private receipt content.

Useful fields:

- app version
- parser pack version
- locale
- country
- trade
- item id
- item family
- confidence bucket
- failure category
- device class
- device model when allowed
- offline/local/cloud mode
- receipt source type, such as photo/PDF/manual text, when available from shared capture
- blurry/image-quality bucket when available from shared capture
- counts by merchant family without raw private receipt text

Do not store card numbers, customer private data, raw receipt images, or raw receipt text in owner/admin diagnostics unless a separate privacy-reviewed support workflow is explicitly approved.

## Non-Goals For This Workstream

- Do not build the camera system here.
- Do not change OCR extraction here.
- Do not build signature capture here.
- Do not build full invoice UI here.
- Do not build full jobs UI here.
- Do not run live Firebase load tests here.

This workstream should make sure the parser, catalog, pack, and data contracts are ready for those systems.
