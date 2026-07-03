# Maintainiac Operating Directive

This repo is a production-grade commercial app. Users may trust it with
mileage, expenses, receipts, estimates, invoices, inventory, jobs, and business
records. Treat the codebase like long-term production infrastructure, not a
prototype.

## Core Rules

- Do not build on a failing analyzer, failing QA runner, failing source audit,
  or failing quality gate.
- If anything fails, stop adding features and fix the failure first.
- Every confirmed bug fix must include a regression test.
- Do not silently suppress warnings or weaken tests to make checks pass.
- Do not create giant files. Keep files modular and under the project line-count
  cap unless there is no safer functional alternative.
- Do not wander into unrelated modules unless the current dependency requires
  it.
- Do not mutate source-of-truth data through side effects.
- Hive/local storage is the immediate source of truth.
- Firestore/cloud sync is a mirror or backup, not the brain.
- Recap, notifications, exports, and invoices must read source data; they must
  not mutate trips, expenses, inventory, or odometer records.
- User-confirmed data outranks OCR, parser, and automation suggestions.
- OCR/parser output is suggestion data until the user confirms it.
- Never overwrite user-confirmed financial data silently.
- Never store VINs, license plates, passenger data, or patient data.
- NEMT is not a separate driver type or category for this app. It is only an
  example of a possible user context. Do not model patient data.

## QA Rules

- Treat the QA harness as permanent production infrastructure.
- Build tests that prove behavior, not shallow object-exists tests.
- Every financial calculation needs deterministic tests.
- Every parser rule needs fixtures.
- Every sync rule needs offline, restart, and conflict tests.
- Every bug fixed gets a regression test before the issue is considered closed.
- For long-running commands, run non-interactively: wait for completion, then
  summarize only final actionable results.
- Do not continuously monitor or narrate QA/build output unless it fails,
  stalls, or asks for input.
- Run targeted tests during development.
- Run the full quality gate only at logical milestones or final handoff, not
  after every tiny edit.

## Release-Quality Goals

- Protect user records from loss.
- Preserve audit trails.
- Keep source records stable.
- Make derived outputs reproducible.
- Make failures recoverable.
- Make sync safe.
- Make tests strong enough to prevent known bugs from coming back.

## Bug Policy

Bugs are expected in a system this large. The standard is not to pretend bugs
will never happen; the standard is to make each bug hard to repeat.

When a confirmed bug is found:

- Stop feature work in the affected area.
- Reproduce the bug with the smallest targeted test or fixture possible.
- Fix the root cause, not only the visible symptom.
- Add or update the regression test before considering the issue closed.
- Run the targeted check that proves the fix.
- Record remaining risk if the fix cannot fully cover every related edge case.

## Final Handoff Requirements

Before final handoff, provide:

- What changed.
- Files changed.
- Tests added.
- Regression cases added.
- Checks run.
- What passed.
- Remaining risks.
- Next recommended hardening step.

Do not optimize for speed. Optimize for trust, correctness, and maintainability.
