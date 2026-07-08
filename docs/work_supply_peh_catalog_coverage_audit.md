# PEH Catalog Coverage Audit

Last updated: 2026-07-08 16:57 EDT

Scope: Work supply inventory/catalog/parser readiness for residential Plumbing,
Electrical, and HVAC. This audit is intentionally catalog-first. Generated
receipt/parser scale runs should not resume until catalog coverage remains
stable.

## Verified Residential Pack Counts

Evidence command:

```powershell
C:\src\flutter\flutter\bin\flutter.bat test test\work_supply_peh_catalog_count_report_test.dart --reporter expanded
```

Result: passed, 2026-07-08.

| Trade | Core | Standard | Professional | Complete | Core Download | Complete Download |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Plumbing | 1,198 | 1,835 | 12,344 | 12,480 | 70.6 KB | 627.7 KB |
| Electrical | 1,902 | 2,200 | 11,458 | 11,464 | 117.6 KB | 742.2 KB |
| HVAC | 2,694 | 2,797 | 6,082 | 6,739 | 179.1 KB | 462.2 KB |

## Coverage Checkpoints

Plumbing coverage currently includes:
- PEX, CPVC, PVC pressure, PVC DWV, ABS DWV, copper, brass, push-fit, black
  iron, galvanized, cast/no-hub, valves, angle stops, supply lines, tubular
  drains, toilet repair, faucet/sink repair, shower/tub repair, water heater
  repair/install stock, pumps, well service, water treatment, softener salt,
  hangers/supports, thread sealants, PVC/CPVC cement, hand tools, and legacy
  repair bridges.

Electrical coverage currently includes:
- NM-B, THHN/THWN, MC/BX, low-voltage cable, breakers, AFCI/GFCI/dual-function
  protection, disconnects, boxes, covers, plates, old-work repair stock,
  devices, GFCI receptacles, wire connectors, pigtails, staples, conduit,
  grounding/bonding, panel repair parts, fuses, surge protection, lampholders,
  photocells, smoke/CO alarms, lighting repair, and service consumables.

HVAC coverage currently includes:
- Air filters, capacitors, contactors, transformers, low-voltage fuses,
  thermostat wire, thermostats, C-wire/common-wire adapters, condensate pipe,
  fittings, pumps, float switches, tablets/cleaners, ductwork, flex duct,
  takeoffs, boots, grilles, dampers, access doors, zip screws, duct strap,
  foil tape, mastic, coil cleaner, motors, blower wheels, ignitors, flame
  sensors, pressure switches, gas heat service stock, refrigerant line sets,
  service caps, Schrader cores, brazing alloys, disconnects, whips, pads, and
  common service-truck repair stock.

## Current Decision

No obvious major residential service-truck catalog bucket is missing from the
three PEH complete catalogs based on the current local catalog and common
service-truck stock references. The next work should not be broad item creation
unless a specific missing family is proven.

External sanity-check references used:
- Carrier Totaline cooling-season truck stock list:
  https://www.shareddocs.com/hvac/docs/1006/Public/02/TotalineTruckStock-Cooling.pdf
- Johnstone Supply service truck stock categories:
  https://www.johnstonesupply.com/store5/service-truck-stock
- ServiceTitan HVAC truck inventory guidance:
  https://www.servicetitan.com/blog/hvac-truck-inventory-list
- RevLink plumbing truck stocking guide:
  https://rev-link.com/plumbers-how-to-stock-your-truck-like-a-pro-stop-losing-time/
- RevLink electrician van stocking guide:
  https://rev-link.com/electricians-the-ultimate-van-stocking-guide-to-save-time-money/
- eLocal electrician van materials overview:
  https://www.elocal.com/resources/home-improvement/electricians/faq/what-is-in-electrician-van/

Allowed next steps:
- Lock PEH residential catalog counts with regression tests.
- Fix known parser specificity failures found by the 100-receipt generated
  plumbing run.
- Add mixed-trade synthetic receipt fixtures after Plumbing, Electrical, and
  HVAC core receipt-language checks are stable.

Deferred:
- Commercial and light-industrial pack expansion.
- Receipt stitching, OCR, camera, PDF, expenses, and UI work.
