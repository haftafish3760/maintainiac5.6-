# Localization And Measurement Units Living Handoff

## Current Status

`PRESENT / UNVERIFIED`. Shared localization code and requirements for unit-aware
behavior exist. Complete locale and measurement coverage is not claimed.

## Implemented Evidence

- Localization owner: `lib/shared/localization/maintaniac_localizations.dart`
- Requirements: `screen_notes/batch_003_localization_units.txt`
- Fuel, inventory, receipt, PDF, date, and currency systems are consumers.

## Remaining

- Verify locale text, currency, tax, dates, decimal separators, measurement
  units, fuel/energy units, inventory quantities, and PDF/export rendering.
- Avoid feature-local formatters that conflict with the shared owner.

## Rolling Log

- 2026-07-22: Created; current file presence is not locale QA.
