# Receipt OCR Ownership Boundary

This lane owns the evidence-producing portion of receipt handling. It stops at
an editable, user-reviewable handoff and does not create or mutate downstream
business records.

## Owned here

- Capture and import: native camera, gallery, file, PDF, and supported text.
- Image quality evaluation, crop/rotation/perspective correction, and useful
  OCR-ready variants.
- OCR pages, blocks, lines, tokens, bounds, reading order, confidence, source
  provenance, engine identity, and processing version.
- Receipt-row reconstruction after the shared long-receipt system returns its
  reconstructed document.
- Candidate merchant/date/subtotal/tax/total fields, document type, detail
  mode, and an editable review handoff.
- Safe routing to Fuel, Inventory, both when ambiguous, or fallback review.

## Explicitly not owned here

- Long-receipt stitching, overlap detection, ordering, or duplicate-region
  removal.
- Fuel interpretation or direct fuel-record writes.
- Inventory interpretation or direct inventory-record writes.
- Tax calculations, expense calculations, accounting decisions, or direct
  writes into confirmed expenses.
- Final business/personal decisions. This lane may preserve a user-selected
  classification and collect allocation evidence for review.

## Evidence preservation contract

Every extracted value keeps separate source text, display text, normalized text,
optional interpretation, interpretation confidence, and review state. Display
text remains faithful to the printed receipt unless the user edits it; source
text and provenance remain traceable after edits. Abbreviations and missing
descriptions are never silently expanded or invented.

## Handoff contract

Before stitching, each segment retains its source reference, corrected-image
reference, capture order, dimensions, orientation, crop data, quality scores,
OCR blocks/lines/tokens/bounds/confidence, processing version, and warnings.
After stitching, this lane consumes the reconstructed document and resumes with
field candidates, classification, routing, and the editable review handoff.

