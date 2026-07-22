# Work Supplies, Materials, And Inventory Living Handoff

## Current Status

`PRESENT / NEEDS RECONCILIATION`. These names identify one system, never three
parallel modules. Catalogs, receipt parsers, inventory, calendar, jobs bridge,
settings, and add-items flows exist.

## Screens And Implemented Evidence

- Root/home: `lib/screens/work_supplies/work_supply_screen.dart` and
  `lib/screens/work_supplies/home/`
- Add items and receipt parsing: `lib/screens/work_supplies/entry/` and
  `lib/screens/work_supplies/data/inventory_parser.dart`
- Catalog and trade packs: `lib/screens/work_supplies/catalog/` and
  `lib/screens/work_supplies/data/catalog/`
- Inventory/calendar/jobs/settings: `lib/screens/work_supplies/inventory/`,
  `calendar/`, `jobs/`, and `work_supply_settings_screen.dart`
- Requirements: `screen_notes/inventory_materials.txt` and
  `docs/inventory_trade_pack_handoff_spec.md`

## Product Boundaries

- Receipt parsing proposes items; the user reviews before inventory changes.
- Confirmed items preserve exact after-tax per-item cost and exact-cent receipt
  reconciliation for inventory, estimates, jobs, and invoices.
- Do not duplicate code or create a second inventory owner.

## Verified / Deferred / Remaining

- `PRESENT`: extensive trade catalogs, parsers, QA harnesses, and screen flows.
- `VERIFIED SUBSET`: the Jobs screen now consumes the shared durable Jobs owner
  and no longer displays `_demoJobs()`. Creating a job preserves the active work
  profile and vehicle; the Jobs/context gate passed 9 tests.
- `VERIFIED SUBSET`: receipt precedence now preserves exact HVAC Wi-Fi
  thermostat, heat-pump defrost-board, MERV filter, masonry concrete-screw
  dimensions/color, landscaping detail, and plumbing stem-packing/backwater
  valve identities. Generic ambiguous connector and plumbing lines remain
  review-only instead of being globally relaxed.
- `UNVERIFIED`: no fresh system-wide inventory acceptance run is recorded here.
- `NEEDS RECONCILIATION`: inspect all source repositories by content/history,
  including unexpectedly named folders, for unique inventory/material behavior.

## Rolling Log

- 2026-07-22: Created; existing code is recorded without falsely treating file
  presence as release QA.
- 2026-07-22: Replaced demo Jobs data with the single shared durable directory;
  no inventory owner or parser behavior was duplicated.
- 2026-07-22: Corrected exact catalog-item precedence for HVAC, masonry,
  landscaping, and plumbing receipt lines. These are focused repairs, not proof
  that every catalog item or Core Pack row has completed release QA.
