# Receipt OCR Competitive Benchmark

Updated: 2026-07-13

This benchmark defines receipt-capture and OCR behaviors Maintainiac should
match or exceed. It does not authorize accounting decisions, parser ownership,
or long-receipt stitching changes.

## Proven Product Behaviors

### Expensify SmartScan

- Automatically fills amount, date, and merchant.
- Fails explicitly when required fields cannot be read instead of pretending a
  scan succeeded.
- Offers retake/manual recovery for blurry, cropped, faded, shadowed, or
  glare-obscured receipts.
- Detects likely duplicates and requires review.

Source: https://help.expensify.com/articles/expensify-classic/expenses/Troubleshoot-SmartScan-Issues

### Dext

- Keeps capture, processing, extracted-data review, and publishing as separate
  states.
- Supports single-document, multiple-document, and combined-page capture modes.
- Extracts supplier/date/amount and offers optional line-item extraction for
  names, quantities, prices, and tax details.
- Lets users review and edit before downstream publication.

Sources:

- https://help.dext.com/en/articles/105670-how-to-scan-and-upload-documents-in-the-dext-mobile-app
- https://dext.com/us/business/products/line-item-extraction

### QuickBooks

- Supports camera, file upload, and emailed receipt acquisition.
- Extracts vendor, amount, date, and payment method.
- Keeps the receipt attached to the resulting record and offers transaction
  matching.

Source: https://quickbooks.intuit.com/ca/receipt-scanner/

### Zoho Expense

- Exposes visible processing and failed-scan queues.
- Supports camera, gallery, files, sharing, and multiple receipt modes.
- Extracts merchant, date, amount, currency, payment method, and line items.
- Provides manual creation when scanning fails and flags likely duplicates.

Sources:

- https://www.zoho.com/uk/expense/help/expenses/autoscan-receipts/
- https://www.zoho.com/ca/expense/receipt-scanner-app/

### SAP Concur ExpenseIt

- Creates, categorizes, and itemizes entries from receipt photos.
- Queues captures offline and processes them when connectivity returns.
- Keeps receipt images attached for human review and audit.

Source: https://www.concur.com/products/expenseit

## Maintainiac Release Contract

Maintainiac should combine the strongest behaviors while preserving stricter
evidence boundaries:

1. Capture or import must never lose the accepted source image.
2. Processing must have explicit queued, reading, review-ready, failed, and
   manual-recovery outcomes; no indefinite spinner is acceptable.
3. OCR must preserve exact source wording, coordinates, reading order, source
   identity, engine/version identity, and uncertainty.
4. Basic, Simple, and Detailed modes use the same OCR evidence and differ only
   in review depth.
5. Every populated field must retain source evidence, confidence, competing
   candidates, and a review reason.
6. Empty OCR is a failure, never success.
7. User edits change display values without destroying original source text.
8. User-selected category is routing context; OCR must not override it.
9. Duplicate evidence is flagged for review, never silently deleted.
10. Older devices receive bounded image sizes, analysis frequency, attachment
    counts, and parser depth; newer devices may use heavier local processing.
11. Every failure must preserve the proof and offer retry, retake, or manual
    continuation.
12. OCR stops before fuel, inventory, tax, accounting, or confirmed-record
    business logic.

## Accuracy Gate

The 90-95% target must be measured separately for readable-receipt character,
word, numeric, merchant, date, subtotal, tax, total, line reconstruction, and
routing accuracy. A single blended score may not hide weak numeric or total
accuracy. Real-device fixture results remain release evidence, not optional
polish.

For a release benchmark gate, run
`RECEIPT_EXTERNAL_DATASET_REQUIRE_PRESENT=true dart tool/receipt_external_dataset_local_audit.dart`.
It intentionally fails when no licensed local receipt dataset is available.
