# Expense Codex B Handoff

This is the operating brief for the second Codex worker assigned to the
Maintainiac expense app. The goal is to let two workers move fast without
editing the same files or breaking shared receipt/camera contracts.

## Starting Point

Repository:

```text
https://github.com/haftafish3760/maintainiac5.6-.git
```

Base branch:

```text
codex/expense-system-handoff
```

Recommended local setup:

```bash
git clone https://github.com/haftafish3760/maintainiac5.6-.git Maintainiac_5.6_expense_lane
cd Maintainiac_5.6_expense_lane
git checkout codex/expense-system-handoff
git switch -c codex/expense-app-lane
```

Before editing, read these files:

- `PROJECT_RULES.md`
- `docs/maintainiac_production_operating_directive.md`
- `docs/expense_release_one_blueprint.md`
- `docs/receipt_camera_release_one_blueprint.md`
- `docs/expense_screen_full_design.md`
- `docs/expense_command_center_ocr_contract.md`

## Mission

Own the expense app lane. Build the release-one expense system around the shared
receipt/camera handoff without rewriting the camera stack.

Primary focus:

- expense home and add-expense flow
- manual expense entry
- receipt-backed expense review
- simple vs detailed receipt review modes
- business, personal, and split classification
- fuel expense specialization
- PDF/file intake as expense sources
- expense records, drafts, ledgers, reports, and export readiness
- privacy-safe diagnostics and Command One/admin health summaries
- parser/review rules that consume shared receipt handoff data

## Owned Paths

Codex B may edit these paths without asking Codex A first:

- `lib/screens/expenses/**`
- expense-specific tests under `test/expense_*`
- expense telemetry tests under `test/maintainiac_firestore_expense_*`
- expense helper files under `test/helpers/expense_*`
- app-generated expense/PDF/export support when it is not shared camera code
- `docs/expense_release_one_blueprint.md`
- expense-specific docs and handoff notes

Codex B may add new files under these areas when names clearly describe their
responsibility.

## Do Not Touch Without A Contract Branch

Do not edit these paths unless a dedicated integration/contract branch is
created and Codex A is told about it:

- `lib/shared/widgets/receipt_capture/**`
- `lib/shared/receipts/**`
- Android receipt camera bridge files
- iOS receipt camera bridge files
- receipt camera cleanup logs
- receipt native camera tests
- receipt camera/stitching/source-handoff model files
- `docs/receipt_camera_release_one_blueprint.md`

These are Codex A's camera/shared-receipt ownership areas.

## Shared Contract Rule

If expense work needs a shared model change, pause feature work and make a small
contract branch first.

Shared contract examples:

- receipt capture result model
- OCR-source handoff model
- receipt proof/storage model
- parser result shape consumed by both camera and expenses
- telemetry redaction schema consumed by both lanes
- quality gate scripts used by both lanes

Contract branch name:

```text
codex/expense-contract-integration
```

Contract branch expectations:

- make the smallest possible shared change
- add or update regression tests
- run targeted checks
- merge or push before either lane builds on the new contract

## Branch Rules

- Work on `codex/expense-app-lane`.
- Do not push directly to `main`.
- Do not force-push over Codex A's branch.
- Rebase or merge from `codex/expense-system-handoff` only when needed.
- If conflict resolution touches camera-owned files, stop and ask for an
  integration pass.

## QA Rules

Never build on a failing analyzer, test, source audit, or quality gate.

During normal expense work, prefer targeted checks:

```bash
dart analyze lib/screens/expenses test/expense_release_one_blueprint_test.dart
flutter test test/expense_release_one_blueprint_test.dart -r compact
```

For parser/review work, add the focused tests that cover the touched behavior,
for example:

```bash
flutter test \
  test/expense_receipt_parser_test.dart \
  test/expense_receipt_parser_fuel_formats_test.dart \
  test/expense_receipt_assisted_review_flow_test.dart \
  -r compact
```

Before pushing a meaningful expense milestone, run:

```bash
bash -n tool/receipt_fast_guard_gate.sh
dart analyze lib/screens/expenses test/expense_release_one_blueprint_test.dart
flutter test test/expense_release_one_blueprint_test.dart test/receipt_fast_guard_gate_contract_test.dart -r compact
bash tool/receipt_doc_size_gate.sh
dart tool/maintainiac_source_audit.dart --max-line-length=220
git diff --check
```

Run broader gates only at milestone boundaries or when a contract change affects
shared receipt/camera behavior.

## Regression Rules

Every confirmed bug gets a regression test before the bug is considered fixed.

If a bug class can affect more than one case, add a family-level regression.
Examples:

- no receipt image crashes parser
- empty image
- corrupted image
- wrong file type
- huge image
- missing total
- duplicate total
- malformed subtotal
- mixed business/personal receipt
- parser tries to overwrite user-confirmed total

## Privacy Rules

Do not upload or log:

- receipt images
- raw OCR text
- item descriptions
- merchant/store names
- customer names
- addresses
- phone numbers
- notes
- file paths
- transaction/auth/card/terminal numbers

Admin/Command One data must stay summary-only with counts, rates, safe tokens,
and failure categories.

## First Good Work Slice

Recommended first Codex B slice:

1. Audit the current expense receipt review flow against
   `docs/expense_release_one_blueprint.md`.
2. Identify the smallest missing release-one behavior in expense-owned files.
3. Add or tighten regression tests first.
4. Implement only the expense-owned change.
5. Run targeted checks.
6. Push to `codex/expense-app-lane`.

Good first targets:

- simple vs detailed review mode enforcement
- business/personal/split line review state
- fuel receipt review fields
- draft recovery for receipt-backed expense entry
- PDF/file intake rejection messages
- expense diagnostics redaction guard

Avoid starting with a shared receipt camera change. Codex A owns that lane.

## Handoff Back To Codex A

When Codex B pushes work, include:

- branch name
- commit hash
- files changed
- tests added
- checks run
- any shared contract needs
- any failing or skipped checks

If Codex B discovers a camera/shared-receipt issue, document the bug and create
a failing or pending test in the expense lane only if it can be done without
editing camera-owned files. Otherwise, hand the issue back to Codex A.
