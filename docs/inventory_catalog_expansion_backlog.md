# Inventory Catalog Expansion Backlog

Purpose: durable backlog for inventory catalog expansion after the QA harness
and release gates are in place. This is not a scrape list and not a promise
that every item is already production-ready. It is the ordered expansion map for
controlled, evidence-backed batches.

## Release 1 Focus

- Market: United States residential.
- Trades: Plumbing, Electrical, HVAC.
- Languages: English (en-US) and Spanish (es-US).
- Tiers: Core first, Standard second.
- Rule: Core and Standard must cover everyday service-truck reality before
  Professional, Complete, commercial, or industrial long-tail expansion.
- Rule: each expansion batch must generate review-only item candidates, parser
  fixtures, regression locks, and release-readiness evidence before promotion.
- Rule: no retailer catalog scraping. SKU, UPC, GTIN, barcode, brand, and
  merchant mappings need licensed, public, user-confirmed, or manually reviewed
  provenance before official pack promotion.

## Batch Lifecycle

Each item expansion batch must move through this lifecycle:

1. Define the trade, scope, tier, locale, service family, and expected use case.
2. Generate or author review-only catalog candidates.
3. Validate candidate identity, aliases, receipt patterns, units, sizes,
   negative-match tokens, source confidence, and parser-pack version.
4. Generate matching synthetic receipt fixtures for named merchants, local
   merchants, regional merchants, supply houses, and unknown merchants.
5. Run focused parser fixtures for the changed family or cell.
6. Add regression locks for every fixed false match, missed common item, or
   dangerous ambiguity.
7. Promote only after manual review and release-readiness evidence.

## Plumbing Core Families

Plumbing Core should prioritize everyday home/apartment service items:

- PEX, copper, CPVC, PVC, and common supply repair fittings.
- Elbows, tees, couplings, adapters, bushings, reducers, caps, plugs, unions,
  and transition fittings.
- Shutoff valves, angle stops, ball valves, supply stops, washing machine
  valves, ice-maker valves, and common hose bibb repair parts.
- Toilet wax rings, wax-free seals, closet bolts, flange repair kits, fill
  valves, flush valves, flappers, tank levers, tank bolts, and supply lines.
- Sink and faucet repair basics: p-traps, tailpieces, trap adapters, slip-joint
  washers/nuts, basket strainers, pop-up drains, aerators, cartridges, stems,
  faucet repair kits, and braided supply lines.
- Water heater service basics: dielectric nipples/unions, water heater supply
  connectors, T&P valves, expansion tanks, drain pans, gas connectors where
  appropriate, pipe dope, tape, and sediment drain parts.
- Drain service basics: cleanout plugs, Fernco-style couplings, no-hub bands,
  PVC/ABS drain fittings, plungers, augers, and common drain cleaners/tools.
- Well service basics where residential hardware stores commonly stock them:
  well pumps, pressure switches, pressure gauges, pressure tanks, pitless
  adapters, well pipe, torque arrestors, and check valves.

## Plumbing Standard Families

Plumbing Standard expands Core into broader same-day service and remodel stock:

- Less-common PEX/copper/CPVC/PVC sizes and transitions.
- More valve variants, backflow/vacuum breaker parts, pressure regulators,
  thermal expansion accessories, and specialty shutoffs.
- Broader toilet, faucet, tub/shower, and sink repair families.
- Broader drain, DWV, disposal, dishwasher, washer, and utility sink parts.
- Additional service tools, blades, cutters, crimp/clamp rings, presses, pullers,
  thread sealants, primers, cements, and repair consumables.

## Electrical Core Families

Electrical Core should prioritize everyday residential service stock:

- NM-B cable, THHN/THWN conductors, UF-B cable, thermostat/control wire where
  common, and grounding/bonding wire.
- Old-work boxes, new-work boxes, junction boxes, device boxes, covers, plates,
  mud rings, clamps, connectors, and common box accessories.
- Switches, receptacles, GFCI receptacles, AFCI/GFCI common service parts,
  dimmers, wall plates, wire nuts, lever connectors, pigtails, and grounding
  screws.
- PVC conduit, EMT basics, conduit straps, couplings, connectors, elbows,
  bushings, locknuts, LB bodies, and raceway basics.
- Breakers, disconnect basics, panel accessories, grounding rods/clamps, staples,
  straps, fasteners, tape, testers, and service consumables.

## Electrical Standard Families

Electrical Standard expands Core into broader residential repair and remodel:

- More breaker families, disconnect variants, surge protectors, larger wire
  sizes, raceway systems, weatherproof boxes/covers, conduit bodies, and cable
  management.
- Light fixture repair stock, ceiling fan boxes, smoke/CO alarm basics, low
  voltage/doorbell/thermostat wiring accessories, and outdoor service parts.
- Broader electrical tools, bits, blades, hole saws, fish tape, labels, and
  testing accessories.

## HVAC Core Families

HVAC Core should prioritize everyday residential service stock:

- Common air filters and furnace filters, including frequent sizes and MERV
  language.
- Capacitors, contactors, relays, transformers, fuses, disconnect pullouts,
  thermostat wire, wire connectors, and electrical service consumables.
- Condensate drain basics: PVC condensate fittings, traps, pumps, tubing,
  float switches, drain pans, tablets, cleanout parts, primer/cement, and
  drain-line tools.
- Duct service basics: foil tape, mastic, duct sealant, sheet-metal screws,
  zip screws, straps, hangers, collars, takeoffs, boots, and common grille/
  register repair parts.
- Service tools and consumables: gauges/accessories where appropriate, blades,
  drill bits, insulation tape, zip ties, gloves, cleaner, and coil-cleaning
  consumables that are safe for inventory parsing.

## HVAC Standard Families

HVAC Standard expands Core into broader service, repair, and replacement:

- More capacitors/contactors/relays/transformers by rating, furnace service
  parts, blower and inducer support items, ignitors/sensors, pressure switches,
  flame sensors, and common thermostat/accessory families.
- Broader condensate pump/drain families, humidifier pads/parts, venting parts,
  refrigerant-line accessories, vibration pads, and service fasteners.
- Broader duct materials and repair hardware found in residential service and
  remodel jobs.

## Fixture Requirements For Every Batch

Every batch must include fixture coverage for:

- Named merchants such as Lowe's, Home Depot, Walmart, Ace, True Value, Menards,
  Ferguson, Grainger, and supply-house-style receipts.
- Unknown/local/regional merchant receipt lines.
- English and Spanish wording.
- Abbreviations, punctuation differences, plural/singular differences, OCR-like
  mistakes, quantities, package quantities, units, discounts, returns, subtotal
  noise, tax lines, and payment noise.
- Ambiguous overlap terms such as PVC, box, tape, filter, wire, conduit, elbow,
  coupling, adapter, valve, fitting, connector, cement, primer, black, and white.
- Mixed-trade receipts where Plumbing, Electrical, and HVAC candidates must stay
  ranked and review-safe.

## Promotion Rules

- Generated rows are candidates, not production catalog data.
- User-confirmed corrections can propose aliases, negative rules, merchant
  patterns, or regression fixtures, but cannot silently mutate official packs.
- Barcode evidence can strengthen identity only when the mapping has legal
  provenance and source confidence.
- Local Hive/user-confirmed data outranks parser suggestions and pack updates.
- Firebase/Firestore can host downloadable packs and mirror confirmed data, but
  parser tests must remain local/fake unless a separate live profile is approved.
