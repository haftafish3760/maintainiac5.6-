# Invoices And Payments Living Handoff

## Current Status

`PRESENT / UNVERIFIED / NEEDS RECONCILIATION`. Invoice home, workspace, forms,
items, company/client information, payments, templates, preview, day view, and
settings screens exist.

## Screens And Implemented Evidence

- Main screens and forms: `lib/screens/invoices/home/`
- Settings: `lib/screens/invoices/settings/`
- PDF renderer/preview: `lib/screens/invoices/data/`
- Requirements: `screen_notes/invoices_estimates.txt` and
  `screen_notes/app_screens/invoice_form_screen.txt`

## Remaining

- Compare every source for unique invoice, estimate, payment, customer, tax,
  inventory-line, template, and PDF behavior.
- Preserve the shared PDF engine; do not create a parallel invoice-only export
  architecture without a documented reason.
- Run targeted invoice/payment tests before any completion claim.

## Rolling Log

- 2026-07-22: Created from current screen inventory; QA remains unverified.
