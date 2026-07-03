# Reminders For Later

This file is for product and workflow reminders that should not interrupt the current focused implementation lane, but must not be forgotten when the related screen, data model, or workflow is built.

Current active boundary: inventory parser and catalog work may reference these reminders for data-contract compatibility, but should not build invoice, estimate, job, dashboard, OCR, camera, or Expenses UI unless that work is explicitly reassigned.

## Estimate, Invoice, And Active Job Trade Sections

When building the estimate, invoice, and active-job material workflows, support multi-trade jobs as first-class records.

Many residential contractors and handyman-style businesses perform more than one trade on the same job, such as plumbing, electrical, HVAC, carpentry, drywall, painting, flooring, or general repairs. A single estimate, active job, or invoice must be able to contain multiple work categories/trade sections.

Future estimate/invoice/job screens should support:

- Add a trade section or work-category section.
- Suggested labels such as `Plumbing`, `Electrical`, `HVAC`, `Carpentry`, `Drywall`, `Painting`, `General`, or custom user-defined section names.
- Add inventory/catalog items into the correct section.
- Show line items grouped under each section.
- Show a subtotal for each trade/work category.
- Show a grand total for the entire estimate, active job, or invoice.
- Keep sections editable because active jobs often need added materials, removed materials, substitutions, and change-order-style adjustments.
- Allow a mixed-trade job to intentionally include overlapping items without forcing the parser to pick one trade silently.

Terminology can be decided later, but likely wording is `Add work category`, `Add trade section`, or `Add section`. The wording should feel natural to contractors and homeowners.

## Inventory Search Inside Estimate And Job Material Entry

Estimate, invoice, and active-job material entry must be able to search inventory trade-pack items and user inventory records.

Search must support:

- Canonical item names.
- Common aliases.
- Trade slang.
- Store and receipt abbreviations.
- Size and dimension tokens.
- Brand and manufacturer hints where legally and safely stored.
- SKU or part-number mappings when available.
- User-created item IDs or internal company item numbers.
- Barcode-linked inventory items when barcode support is added.

The search experience should not require the user to browse deep categories before adding an item. Search can suggest likely trade/category/section, but the user must be able to correct it.

## Ambiguous Cross-Trade Items

The parser and estimate/job material workflow must not assume that a term belongs to one trade just because it is common there.

Examples:

- `PVC 90` can mean plumbing fitting, electrical conduit elbow, HVAC condensate drain fitting, irrigation fitting, or other PVC product.
- `4 in PVC` can be plumbing pipe, conduit, drain, duct-related material, or another PVC product depending on context.
- `Elbow`, `adapter`, `coupling`, `tee`, and `reducer` appear across plumbing, electrical conduit, HVAC duct/condensate, irrigation, and other trades.
- `Tape` can mean electrical tape, foil HVAC tape, painter tape, drywall tape, packing tape, or measuring tape.
- `Filter` can mean HVAC air filter, water filter, paint filter, oil filter, or other filter.

When context is not strong enough, the system should return ranked possible matches and require review instead of silently forcing an item into the wrong trade.

Helpful ranking context can include:

- The selected estimate/job trade section.
- The user's enabled trade packs.
- The user's business profile and common trades.
- The merchant or supply house type.
- Existing vehicle inventory.
- Previous user corrections.
- Whether the current estimate/job already has a plumbing, electrical, HVAC, or mixed-work section.

## Inventory Parser Contract Reminder

The inventory parser should produce review-only material candidates that can later be attached to:

- Company inventory.
- Vehicle inventory.
- An estimate draft.
- An active job.
- A change order or added-material review.
- An invoice proof path.
- A non-inventory or ignored line.

The parser must preserve raw text and uncertainty. It must never auto-save materials to inventory or force a trade/category without review when the line is ambiguous.

See also:

- `docs/inventory_estimate_job_lifecycle_spec.md`
- `docs/materials_catalog_intelligence_contract.md`
- `docs/work_supplies_spec.md`
