# Materials Trade Pack Completion Audit

Date: 2026-06-28

Scope: Maintainiac 5.6 materials/inventory trade packs only. Maintainiac 5.5 is not part of this work.

## Current Catalog Snapshot

Source: `flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m`

Total current items: 56,221

| Trade | Current items | Readiness | Current priority |
| --- | ---: | --- | --- |
| Plumbing | 11,827 | Strong | Active service trade |
| Electrical | 11,244 | Strong | Major service trade, parked until Plumbing is finished |
| HVAC | 6,559 | Strong | Major service trade, parked until Plumbing is finished |
| Tile | 8,180 | Strong | Project trade, not active |
| Landscaping | 1,319 | Strong | Secondary service trade |
| Windows and Doors | 1,296 | Strong | Secondary service trade |
| Low Voltage and Data | 1,278 | Strong | Project trade |
| Fencing | 1,236 | Strong | Project trade |
| Flooring | 1,166 | Strong | Project trade |
| Insulation | 1,162 | Strong | Project trade |
| Carpentry | 1,123 | Strong | Project trade |
| Painting | 1,047 | Strong | Project trade |
| Tools and Safety | 1,020 | Strong | Support pack |
| Drywall | 1,017 | Strong | Project trade |
| Roofing | 1,012 | Strong | Project trade |
| Appliance Installation and Repair | 996 | Strong | Secondary service trade |
| Cabinets and Countertops | 981 | Strong | Project trade |
| Garage Doors and Openers | 966 | Strong | Secondary service trade |
| Siding and Exterior | 867 | Strong | Project trade |
| Well Septic and Water Treatment | 551 | Strong | Secondary service trade |
| Masonry and Concrete | 1,374 | Strong | Project trade |

## Target Model

The completion model is service-priority aware instead of using one flat number for every trade. It is also superseded by the smart-row direction in `docs/materials_catalog_intelligence_contract.md`: residential/light-industrial quality and metadata depth matter more than chasing the largest possible raw count.

Catalog rows should now be planned by trade, market scope, and pack tier:

- market scope: residential, lightIndustrial, commercial
- pack tier: Core, Standard, Professional, Complete
- priority: everyday/core, common, occasional, rare/legacy, specialty

Residential plumbing complete target is roughly 12,000 to 15,000 smart items before broad commercial expansion. Whole residential/light-industrial catalog target is roughly 65,000 to 90,000 smart items, with a practical target near 75,000 smart items.

| Priority | Target items |
| --- | ---: |
| Active service trade | 15,000 |
| Major service trade | 15,000 |
| Secondary service trade | 5,000 |
| Project trade | 3,000 |
| Support pack | 2,500 |

The active trade is Plumbing. Do not move to the next trade until the active trade has the pack, parser, receipt-to-inventory, receipt-to-estimate, and Command One diagnostics in acceptable shape.

## Current Targeted Remaining Work

Approximate remaining catalog items by the targeted model: 57,737

Approximate generation passes at 1,500 quality items per pass: 39

This number covers catalog buildout only. It does not fully cover workflow hardening. A realistic end-to-end materials completion estimate is:

| Work area | Pass estimate |
| --- | ---: |
| Remaining catalog items by targeted model | 39 |
| Plumbing parser and alias polishing | 4-8 |
| Receipt-to-inventory staging | 6-10 |
| Receipt-to-estimate staging | 6-10 |
| Pack download/install edge cases | 3-6 |
| Command One diagnostics and privacy guards | 4-8 |
| Employee inventory permissions and security model | 8-14 |
| Older-device performance tuning | 4-8 |
| Final QA and regression passes | 8-12 |

Practical total estimate: 82-115 passes for a professional materials system from the current state.

## Non-Negotiable Edge Cases

- Low storage: block installation when the phone cannot safely download, unpack, and recover the pack. The current guard uses the larger of a 3x compressed-size buffer or 25 MB.
- Unknown storage: block installation when free storage cannot be verified instead of assuming the phone has room.
- Metered data: warn before any optional pack download and show the estimated download size before the user commits. Live metered-network detection still needs a network service; the UI now labels that state as not verified instead of pretending it checked.
- Older devices: limit heavy matching on older or low-capability phones and keep professional/complete packs off devices that should stay on smaller parser limits.
- Firebase cost: use one manifest plus bundled storage chunks, not one Firestore document per item.
- Privacy: Command One must not receive receipt text, receipt images, customer names, job addresses, locations, or user-private inventory details.
- Permissions: employee roles must control view, create, adjust, remove, assign-to-job, attach-to-estimate, and manage-inventory actions.
- Offline-first: downloaded packs must work locally after install.
- One trade at a time: Plumbing remains first.

## Pass Log

### Plumbing service truck stock pass

Added focused Plumbing service-truck stock instead of starting another trade:

- stop valve repair hardware
- water heater service parts and install accessories
- tubular drain service stock
- toilet tank, flange, and seal parts
- faucet aerators and repair assortments
- sump pump discharge/control support stock

Validation:

- `flutter test test/work_supply_plumbing_receipt_parser_test.dart --timeout 2m`
- `flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m`
- `flutter test test/work_supply_trade_pack_completion_audit_test.dart --timeout 2m`

Result:

- Plumbing increased from 11,288 to 11,566 items.
- Total catalog increased from 55,680 to 55,958 items.
- Plumbing remains Strong in the current catalog audit.

Parser-polish follow-up completed:

- Water-heater anode and element receipt lines now get specific service-truck ranking before generic water-heater connector, drain, dielectric, or relief-valve matches.
- Pump-control receipt lines now separate check valves, high-water alarms, and float switches so broad sump-pump matches do not steal the line.
- The existing relief-valve, drain-valve, and pump-check tests were kept, but their assertions now accept the newer service-truck catalog labels when the item itself is correct.

Validation:

- `flutter test test/work_supply_plumbing_receipt_parser_test.dart --timeout 2m`
- `flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m`
- `flutter test test/work_supply_trade_pack_completion_audit_test.dart --timeout 2m`
- `flutter test test/work_supply_trade_pack_install_guard_test.dart test/work_supply_parser_device_profile_test.dart --timeout 2m`

Result:

- Plumbing targeted parser test: 12 passing tests.
- Catalog snapshot: 55,958 total items; Plumbing 11,566 items; Plumbing readiness Strong.
- Completion audit: passing.
- Install/device guard tests: low storage blocked, metered data warned, older phones kept on smaller packs.

### Pack install edge-case pass

Replaced the materials pack settings UI's fake `500 MB free / high-capacity phone` check with runtime device/storage context from `ReceiptDeviceCapabilityService`.

Covered edge cases:

- real free-storage value is used when the device can report it.
- unknown free storage blocks install instead of assuming success.
- older/light devices are still routed to smaller packs.
- pack rows show device parser class and whether network cost has actually been verified.
- metered-network detection is not faked; it remains a follow-up service so the UI can honestly warn once live network state is available.

Validation:

- `flutter analyze lib/screens/work_supplies/work_supply_settings_screen.dart lib/screens/work_supplies/work_supply_settings_pack_panels.dart lib/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart`
- `flutter test test/work_supply_trade_pack_install_guard_test.dart test/work_supply_parser_device_profile_test.dart --timeout 2m`

Result:

- targeted analysis: no issues.
- install/device guard test: 6 passing tests.

### Plumbing drain and finish service-stock pass

Added focused Plumbing stock for residential service vehicles without moving to another trade:

- sink basket strainers and disposal flanges
- dishwasher drain hose, air gaps, branch tailpieces, and disposal connection kits
- tubular trap adapters, wall bends, trap arms, slip-joint trim hardware, and escutcheons
- cleanout plugs/covers and floor-drain finish parts
- closet-flange repair hardware and toilet finish trim

Validation:

- `flutter test test/work_supply_plumbing_receipt_parser_test.dart --timeout 2m`
- `flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m`
- `flutter test test/work_supply_trade_pack_completion_audit_test.dart --timeout 2m`
- `dart analyze lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_drain_finish_catalog.dart lib/screens/work_supplies/data/work_supply_catalog.dart lib/screens/work_supplies/data/catalog/plumbing/plumbing_catalog.dart test/work_supply_plumbing_receipt_parser_test.dart`

Result:

- Plumbing increased from 11,566 to 11,711 items.
- Total catalog increased from 55,958 to 56,103 items.
- Plumbing now has 14 categories, 35 systems, 163 item types, 60,744 aliases, and 132,563 parser terms.
- Plumbing targeted parser test: 13 passing tests.
- Completion audit: passing.
- Targeted analysis: no issues.

### Plumbing seals, packing, and thread service-stock pass

Verified the in-progress Pass 54 coverage for:

- faucet washers, bib washers, and seat kits
- O-rings, stem packing, valve packing, and bonnet packing
- toilet tank seals, flush seals, closet seals, and wax-free seals
- hose bibb washers, sillcock repair seals, and vacuum breaker repair parts
- pipe joint compound, thread sealant, PTFE/Teflon tape, and gas tape

Validation:

- `dart format lib/screens/work_supplies/data/catalog/plumbing/generated_plumbing_seals_service_catalog.dart lib/screens/work_supplies/data/work_supply_catalog.dart lib/screens/work_supplies/data/catalog/plumbing/plumbing_catalog.dart lib/screens/work_supplies/data/work_supply_receipt_parser_trade_scores_core.dart test/work_supply_plumbing_receipt_parser_test.dart`
- `flutter test test/work_supply_plumbing_receipt_parser_test.dart --timeout 2m`
- `flutter test test/work_supply_catalog_scale_test.dart --plain-name "materials catalog scale snapshot for pass planning" --timeout 2m`
- `flutter test test/work_supply_trade_pack_completion_audit_test.dart --timeout 2m`

Result:

- Plumbing increased from 11,711 to 11,827 items.
- Total catalog increased from 56,103 to 56,221 items.
- Plumbing now has 15 categories, 39 systems, 169 item types, 61,715 aliases, and 134,579 parser terms.
- Plumbing targeted parser test: 14 passing tests.
- Completion audit: passing.

Active Plumbing gap:

- Current target: 15,000 Plumbing items.
- Current count: 11,827 Plumbing items.
- Remaining to target: 3,173 Plumbing items, plus parser, receipt-to-inventory, receipt-to-estimate, Command One diagnostics, permissions, and final QA work.
