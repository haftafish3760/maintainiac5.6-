# Maintainiac 5.7 Living Handoff Index

This index routes future Codex workers to current system-specific decisions.

## Standing Handoff Rule

Whenever the product owner adds, changes, or clarifies a requirement that is
not implemented during the current work:

1. record it in the living handoff for the system that owns it;
2. label it implemented, verified, deferred, blocked, or undecided;
3. distinguish a product decision from current code behavior;
4. include safety boundaries, dependencies, and validation still required;
5. update this index when a new system handoff is created;
6. never rely on conversation history as the only record.

## Current System Handoffs

- Expenses, OCR, receipt camera, long receipts, receipt drafts, and duplicate
  review: `docs/expense_ocr_camera_living_handoff.md`
- PDF Document Engine: `docs/pdf_document_engine_handoff_from_codex_2026_07_06.md`
- Inventory/Work Supplies trade packs:
  `docs/inventory_trade_pack_handoff_spec.md`
- Inventory parser QA: `docs/reusable_parsing_qa_handoff_index.md`
- Long-receipt cross-platform stitching:
  `docs/long_receipt_stitching_cross_platform_handoff_2026_07_15.md`

Create a dedicated living handoff when a newly deferred requirement belongs to
a system not represented above. Do not bury unrelated requirements in the
Expenses handoff.
