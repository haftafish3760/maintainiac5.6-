# Maintaniac

Maintaniac is a local-first Flutter record-keeping app for drivers,
contractors, small crews, vehicles, expenses, mileage, invoices, inventory,
maintenance, employees, and related business records.

## Project Documentation

- Build rules: `PROJECT_RULES.md`
- Production/QA directive: `docs/maintainiac_production_operating_directive.md`
- Expense release-one blueprint: `docs/expense_release_one_blueprint.md`
- Expense Codex B handoff: `docs/expense_codex_b_handoff.md`
- Maintainiac 5.7 living handoff index:
  `docs/maintainiac_5_7_living_handoff_index.md`
- Per-system living handoffs: `docs/system_handoffs/`
- Current Expenses/OCR/Camera living handoff:
  `docs/expense_ocr_camera_living_handoff.md`
- Expense receipt storage, draft, proof, and duplicate contract:
  `docs/expense_receipt_storage_and_duplicate_contract.md`
- Receipt camera release-one blueprint:
  `docs/receipt_camera_release_one_blueprint.md`
- Screen/module requirement notes: `screen_notes/`
- How to use those notes: `docs/screen_notes_usage.md`

The screens in this app often behave like individual apps under one roof. Before
changing a screen or module, read the matching TXT notes in `screen_notes/`.
Those files capture app requirements and feature decisions from prior
conversation. They should not include unrelated rambling or duplicated venting.

## Flutter

Use the normal Flutter toolchain for analysis, tests, builds, and device runs.
