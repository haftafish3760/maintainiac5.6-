# Maintainiac Production Operating Directive

Maintainiac is a production-grade commercial record-keeping app. Users may
trust it with mileage, expenses, receipts, estimates, invoices, inventory, jobs,
payments, maintenance, and business records. Treat every change as long-term
production infrastructure, not a prototype.

## Core Rules

- Do not build on a failing analyzer, failing QA runner, failing source audit,
  or failing quality gate. If anything fails, stop adding features and fix the
  failure first.
- Every confirmed bug fix must include a regression test before the issue is
  considered closed. The regression should cover the whole failure family when
  practical, not only the single example that exposed the bug.
- Do not silently suppress warnings, weaken tests, delete assertions, or lower
  quality thresholds just to make checks pass.
- Keep files modular and under the project line-count cap. Split by real
  responsibility before a file becomes a catch-all.
- Do not wander into unrelated modules unless the current dependency requires
  it. Keep receipt-camera work on capture, review, stitching, source
  preservation, OCR handoff contracts, and the parser contracts needed to prove
  camera output. Keep implementation work inside the explicit camera/OCR lane
  unless the user explicitly authorizes otherwise.
- Do not mutate source-of-truth data through recap, notification, export,
  invoice, OCR, parser, telemetry, or sync side effects.
- Hive/local storage is the immediate source of truth. Firestore/cloud sync is a mirror or backup, not the brain.
- Recaps, notifications, exports, invoices, and admin summaries must read source
  records. They must not mutate trips, expenses, inventory, odometer records, or
  user-confirmed receipt data.
- User-confirmed data outranks OCR, parser, camera, automation, and cloud
  suggestions. OCR/parser output is suggestion data until the user confirms it.
- Never overwrite user-confirmed financial data silently.
- Never store VINs, license plates, passenger data, or patient data. NEMT is not a separate driver type or category; it is only a possible user context.

## QA And Regression Rules

- Treat the QA harness as permanent production infrastructure.
- Build tests that prove behavior, not shallow object-exists checks.
- Every financial calculation needs deterministic tests.
- Every parser rule needs fixtures.
- Every sync rule needs offline, restart, and conflict tests before it is called
  release-ready.
- Every user-reported or agent-confirmed bug becomes a regression case. If the
  root cause can affect other modules, add a generalized regression test for the
  bug family.
- Long-running commands must run non-interactively: start the command, wait for
  completion, inspect final exit code/logs, and summarize only actionable
  results. Do not continuously monitor or narrate build/test output unless the
  process fails, stalls, becomes interactive, or requests input.
- Run targeted checks during development. Run full quality gates only at logical
  milestones or final handoff.

## Receipt Camera Release-One Direction

- The release-one priority is the camera system: clear photo capture,
  multi-photo long receipt capture, segment ordering, retake context,
  ghost/overlap guidance, stitching/overlap handling, source preservation, and
  recoverable review flow.
- Do not try to out-Google Google. Google ML Kit is the primary local OCR engine;
  Google Cloud Vision or another premium provider may be a later optional
  engine. Maintainiac owns the capture quality, handoff contracts,
  source preservation, user review, and parser placement rules around those OCR
  engines.
- Preserve original receipt captures. Cropped, compressed, stitched,
  OCR-ready, and review images are derived artifacts and must not destroy or
  silently replace the source capture.
- Support simple and detailed receipt review modes. Simple mode may care mainly
  about receipt total or item prices. Detailed mode must preserve line-item
  descriptions, quantities, unit prices, totals, and categories when available.
- Receipts may be all business, all personal, or split. Multi-line receipts must
  support per-line business/personal classification and line numbering so the user
  can confirm what belongs where.
- Low-confidence OCR/parser results must require user review. The parser must
  not invent values.

## Release Quality Goals

- Protect user records from loss.
- Preserve audit trails.
- Keep source records stable.
- Make derived outputs reproducible.
- Make failures recoverable.
- Make sync safe.
- Make tests strong enough to prevent known bugs from coming back.

## Handoff Standard

Before final handoff for a meaningful change, report:

- What changed.
- Files changed.
- Tests added.
- Regression cases added.
- Checks run.
- What passed.
- Remaining risks.
- Next recommended hardening step.
