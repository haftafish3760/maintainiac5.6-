# Maintainiac Document Engine Operating Directive

This PDF work builds Maintainiac's reusable Document Engine. It is not a generic
PDF generator and not a generic PDF viewer.

## Scope

- Generate professional business documents for Maintainiac now and in the
  future: receipt PDFs, invoice PDFs, estimate PDFs, expense reports, daily
  recap reports, extended recap reports, inventory reports, job packets, and
  future document types.
- Build shared infrastructure, not one-off document generators.
- Treat this subsystem as read-only. It must never modify source records.
- Read confirmed data only.
- Never export OCR suggestions that were not confirmed by the user.
- Keep this PDF work out of inventory/work-supplies, camera/native capture, OCR
  engines, and parser behavior unless the user explicitly reopens that scope.

## Core Requirements

- Use decimal-safe money calculations.
- Support offline generation.
- Support sharing, printing, and exporting.
- Use reusable templates.
- Generate deterministic output: the same input data must always generate the
  same document.
- Avoid random layout behavior.
- Avoid clipping, overlapping elements, broken pagination, and orphaned table
  rows.

## Shared Architecture

Everything should flow through shared components:

- Layout engine
- Table renderer
- Header renderer
- Footer renderer
- Pagination engine
- Image renderer
- Typography system
- Currency formatter
- Date formatter
- Export manager

Rendering logic should not be duplicated between receipt, invoice, estimate,
report, or future document paths.

## Document Features

- Professional layouts
- Automatic pagination
- Intelligent page breaks
- Repeating table headers
- Header and footer support
- Page numbering
- Logo and branding support
- Receipt image embedding
- Optional searchable OCR text where appropriate
- Multiple paper sizes
- Portrait and landscape support where appropriate
- Print-safe formatting
- High-resolution output

## Receipt Support

- Single receipts
- Multi-page receipts
- Camera stitched receipts
- Shared receipt proof flow for expenses, inventory/material receipts,
  vendor invoices, job proof, maintenance proof, and future app modules.
- PDF receipt handling must prepare, validate, store, preview, and hand off
  proof to the existing app flow without changing parser, OCR, inventory, or
  expense classification logic.
- OCR metadata attachment
- Receipt thumbnails where appropriate
- Proper scaling without clipping
- Portrait, landscape, mixed-orientation, rotated, and cropped receipt pages
  must stay attachable as proof and must be scaled without clipping.

## Invoice And Estimate Support

- Customer information
- Job information
- Labor
- Materials
- Mileage
- Taxes
- Discounts
- Totals
- Outstanding balances
- Professional appearance suitable for business use
- Estimate support must use the same engine as invoices.
- Estimates and invoices must share layouts and line-item rendering.
- The design must preserve future estimate-to-invoice conversion compatibility.

## Report Support

- Daily recap
- Weekly recap
- Monthly recap
- Expense reports
- Inventory reports
- Job summaries
- Future reports built on the same engine

## QA Requirements

Use the shared Maintainiac QA backbone wherever possible for fake users, fake
Hive, fake Firebase mirror, regression registry, privacy and security
assertions, artifact reports, performance logs, fixture loading, and surgical
reruns. Do not create duplicate fakes, builders, or reporting.

Add PDF-specific suites covering:

- Multi-page invoices
- Extremely long receipts
- Large inventory reports
- Missing images
- Missing optional fields
- Large tables
- Taxes
- Discounts
- Refunds
- Negative values
- Decimal precision
- Currency rounding
- Logo missing
- Print output
- Share output
- Offline generation
- Malformed PDFs
- Huge PDFs
- Encrypted PDFs
- Image-only PDFs
- Text-layer PDFs
- Rotated and cropped PDF pages
- Import ownership
- Storage cleanup
- No private text in logs
- PDF-to-receipt review transfer
- Golden snapshot tests
- Regression tests for every discovered layout bug

Do not rely on fragile UI tests until the PDF UI is stable. Every confirmed PDF
bug fix must get a regression test immediately.

## Security Requirements

The Document Engine must never export:

- VINs
- License plates
- Passenger data
- Patient information
- Unconfirmed OCR suggestions
- Private source paths
- Payment fragments
- Internal IDs unless explicitly required

Security and privacy rules apply to generated PDFs, imported PDFs, logs,
warnings, QA reports, fixture reports, and export/share paths.

## Support And Debugging Privacy Boundary

Maintainiac is a trust-first app. User PDFs, receipt images, invoices, job
packets, OCR text, and extracted document text are private user content.

Human access rules:

- The owner/developer must not see raw user PDFs, receipt images, invoice text,
  receipt text, job notes, customer messages, patient information, passenger
  information, VINs, license plates, addresses, phone numbers, email addresses,
  exact locations, or any other identifying user content during normal support,
  admin review, QA review, or Command 1 monitoring.
- Human-visible support surfaces may show only non-identifying operational
  evidence such as file type, size, page count, hash, app version, platform,
  storage state, import/export step, failure code, safe warning label, timing,
  retry count, and redacted fixture category.
- If a user voluntarily provides a PDF or screenshot for support, it must be
  treated as private support evidence. The default handling is still to redact
  or summarize it before any human review.

Codex/AI debugging rules:

- Codex may inspect user-provided PDFs or extracted text only when that access
  is required to diagnose or fix Maintainiac behavior, the user has opted in or
  explicitly provided the file for support, and the work is limited to fixing
  the app.
- Codex must not store, publish, quote, train on, summarize for unrelated use,
  or expose personal information from those files. Any regression created from
  a real issue must use synthetic or redacted fixtures unless the user
  explicitly provides a safe non-identifying fixture.
- Debug artifacts, logs, QA reports, Command 1 records, Git commits, tests, and
  documentation must not contain raw private PDF text or identifying content.
- If private content is accidentally exposed during debugging, stop and replace
  it with a redacted or synthetic fixture before continuing.

Command 1 boundary:

- Command 1 may monitor PDF health and failure patterns, but it must not become
  a private PDF viewer for the owner.
- Command 1 PDF diagnostics should use counters, hashes, sizes, page counts,
  status labels, failure buckets, safe action labels, and redacted examples.
- Any future owner/developer review workflow must preserve the rule that humans
  see non-identifying evidence by default, while Codex-assisted repair access is
  tightly scoped to fixing confirmed app problems.

## Operating Rules

- Number PDF passes.
- Bundle related changes when possible.
- Keep user progress updates terse.
- Commit and push to GitHub at real milestones or roughly every 30 minutes.
- Stop on any failing analyze, test, build, quality gate, render gate, or device
  QA result.
- Fix failures properly before continuing feature work.
