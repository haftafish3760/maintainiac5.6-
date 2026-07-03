# Materials Parser Localization Roadmap

Date: 2026-06-29

Scope: Maintainiac 5.6 Work Supplies / Materials / Inventory catalog parser packs.

This spec exists so parser localization work does not drift. It extends the materials catalog intelligence contract and the trade pack roadmap. If this document conflicts with chat instructions from the user, the chat instructions win.

## Hard Boundaries

- Do not edit camera, OCR, PDF, Expenses capture, image preprocessing, receipt stitching, or shared receipt-capture widgets from this workstream.
- This workstream owns catalog metadata, parser matching, parser confidence, parser fixtures, language/country parser packs, trade-pack manifests, and diagnostics contracts.
- Do not push catalog data to Firebase during parser QA unless explicitly approved.
- Do not implement cloud parsing as one read per catalog item.
- Keep parser/catalog logic independent of the current Work Supplies UI.
- Work one active trade/localization lane at a time unless doing a planning-only audit.

## Definitions

- `Locale pack`: parser data for one language and country context, such as `en-US`, `es-US`, `en-CA`, or `fr-CA`.
- `Country pack`: the catalog rules, unit defaults, market vocabulary, and merchant wording for one country.
- `Language pack`: aliases, receipt phrases, abbreviations, morphology, and user-facing parser terms for one language within a country.
- `Core release target`: US English and US Spanish for the priority service trades, followed by Canada English and Canada French.
- `Pass`: one bundled implementation and verification cycle. A pass can include many tests and parser/catalog edits, but it must stay coherent and safe.

## Priority Order

1. Finish United States English first.
2. Add United States Spanish second.
3. Complete Canada English and Canada French third.
4. Expand to other English-speaking countries after US and Canada are stable.
5. Add additional US immigrant-language packs after the US English and Spanish baseline is production-grade.
6. Add broader global language/country packs in later releases.

## Release-One Country And Language Scope

### United States

Required for first serious release:

- `en-US`
- `es-US`

Future US language packs:

- `fr-US`
- `ht-US`
- `pt-US`
- `vi-US`
- `zh-US`
- `ko-US`
- `ar-US`
- `ru-US`

US Spanish must support regional wording common in the United States, especially Mexican, Puerto Rican, Cuban, Central American, and broad neutral Spanish contractor wording. These should be handled as regional term overlays on top of `es-US`, not as separate duplicate catalogs unless evidence proves that separate packs are needed.

### Canada

Required after US baseline:

- `en-CA`
- `fr-CA`

Canada must support metric-first wording, Canadian retailer/supply-house wording, and Quebec French construction terms. English Canada should still tolerate imperial sizes because many trades and product labels use mixed units.

### Mexico

Mexico is not part of the first hard release gate unless the user explicitly moves it up. It should be planned as:

- `es-MX`
- metric-first sizing
- Mexico-specific merchant/supply-house wording
- Spanish terms separated from US Spanish overlays where needed

## Priority Trades For US And Canada

The first high-quality localization target is service work, not every possible commercial catalog branch.

Priority trades:

- Plumbing
- Electrical
- HVAC
- Garage Doors and Openers
- Shared Fasteners, Anchors, Hangers, Tools, and Safety stock used by those trades

Secondary trades after priority trades:

- Appliance Installation and Repair
- Well, Septic, and Water Treatment
- Low Voltage and Data
- Masonry/Concrete service stock
- Carpentry repair stock

## Pass Estimates

These are planning estimates, not promises. The target is "cannot reasonably make it better" quality with about 99.9 percent parser success when OCR/text extraction gives usable line text.

### United States, English Only

Estimated remaining passes for priority release trades:

- Plumbing: 60 to 90 more passes
- Electrical: 110 to 150 passes
- HVAC: 110 to 155 passes
- Garage Doors and Openers: 45 to 70 passes
- Shared fasteners, anchors, tools, safety, and cross-trade neighbor tests: 55 to 85 passes
- US merchant/supply-house wording matrix across priority trades: 45 to 70 passes
- Pack manifest, locale manifest, diagnostics, and QA gates: 45 to 70 passes

Estimated US English subtotal: 470 to 690 passes.

### United States, Spanish

Estimated passes after US English priority trades are stable:

- Spanish parser-pack architecture and locale overlay structure: 25 to 40 passes
- Spanish plumbing aliases, abbreviations, receipt phrases, and tests: 70 to 105 passes
- Spanish electrical aliases, abbreviations, receipt phrases, and tests: 65 to 100 passes
- Spanish HVAC aliases, abbreviations, receipt phrases, and tests: 65 to 100 passes
- Spanish garage doors/openers and shared fasteners/tools/safety: 45 to 75 passes
- Regional US Spanish overlays and merchant receipt variants: 45 to 75 passes
- Spanish cross-language neighbor tests and QA gates: 55 to 85 passes

Estimated US Spanish subtotal: 370 to 580 passes.

### United States Total

Estimated total for US English plus US Spanish, priority release trades only:

- Best case with bundled passes: about 840 passes
- Realistic top-tier target: about 1,050 passes
- Heavy QA/high-variance case: about 1,270 passes

If the scope expands from priority service trades to every trade in the app before release, add roughly 450 to 750 more passes.

### Canada, English And French

Estimated passes after the US baseline:

- Canada locale architecture, unit defaults, metric/imperial normalization, and pack manifests: 35 to 55 passes
- Canada English merchant wording and mixed-unit parser overlays: 70 to 110 passes
- Canada French glossary, abbreviations, trade terms, and receipt phrases: 115 to 175 passes
- Canada plumbing/electrical/HVAC/garage priority trade tests: 90 to 140 passes
- Canada cross-locale QA and neighbor tests: 60 to 95 passes

Estimated Canada subtotal: 370 to 575 passes.

### United States Plus Canada Total

Estimated total for US English, US Spanish, Canada English, and Canada French:

- Best case with bundled passes: about 1,210 passes
- Realistic top-tier target: about 1,500 passes
- Heavy QA/high-variance case: about 1,850 passes

### Other English-Speaking Countries

After US and Canada:

- United Kingdom: 120 to 190 passes
- Ireland: 55 to 90 passes after UK baseline
- Australia: 110 to 175 passes
- New Zealand: 55 to 90 passes after Australia baseline
- South Africa: 80 to 130 passes
- Other English-first or English-common markets: 120 to 220 passes combined for initial support

Estimated other English-speaking country subtotal: 540 to 895 passes.

### Long-Term 50-Language/Country Program

A full 50 language/country matrix should be treated as a multi-release program.

Estimated total after US and Canada, depending on depth:

- Initial usable parser packs: 1,200 to 1,900 additional passes
- Top-tier broad localization: 2,200 to 3,400 additional passes
- Full near-99.9 percent QA across many trades and merchant ecosystems: 3,500+ additional passes

## Locale Pack Architecture

Each locale pack should contain:

- locale ID, such as `en-US`
- country code
- language code
- measurement defaults
- accepted alternate units
- trade-specific alias dictionaries
- receipt abbreviations
- regional terms
- merchant wording overlays
- parser normalization rules
- confidence hints
- negative-match rules
- test fixture groups
- pack-size estimate
- version and source-confidence metadata

The canonical catalog item should not be duplicated per language unless absolutely required. Locale packs should map localized terms back to canonical item IDs.

## Required Parser Metadata For Each Localized Item

Every localized parser record should support:

- canonical item ID
- localized display phrase if needed
- aliases
- abbreviations
- receipt phrase patterns
- likely OCR-output mistake patterns
- material tokens
- size tokens
- unit tokens
- connection tokens
- negative-match terms
- confidence weights
- market scope: residential, lightIndustrial, commercial
- pack tier: core, standard, professional, complete
- source confidence
- review flag

## Spanish Strategy

Do not mix English and Spanish into one large required parser pack for first release.

Use:

- canonical shared catalog
- `en-US` parser pack
- `es-US` parser pack
- optional fallback where English brand/product names appear on Spanish receipts

Spanish pack overlays should include:

- neutral Spanish trade terms
- Mexican Spanish terms common in US trades
- Cuban/Puerto Rican/Caribbean terms where they affect materials wording
- common Spanglish contractor wording
- US-store receipt English terms that still appear on Spanish receipts
- imperial size handling for US receipts
- Spanish metric handling for imported products and future Mexico/Latin America reuse

## Canada Strategy

Canada needs both language and unit handling.

English Canada:

- metric-first product text
- imperial tolerance
- Canadian merchant terms
- province-neutral wording

French Canada:

- Quebec French construction terms
- metric-first sizes
- English brand/product-name tolerance
- bilingual receipt tolerance where one line contains both French and English fragments

## Completion Gates

A locale/trade pack cannot be called done until:

- Core, Standard, Professional, and Complete tiers are monotonic and valid.
- The locale pack maps terms to canonical item IDs.
- Parser tests cover big-box, supply-house, online, and regional merchant wording.
- Neighbor tests prove similar materials do not steal each other.
- Vague lines do not get high confidence.
- Common abbreviations get high confidence.
- Common regional words get high confidence.
- Common unit variants are normalized.
- Pack size is reported.
- `needsReview` is zero or explicitly documented.
- All focused parser tests pass.
- Intelligence audit passes.
- The pack can be changed without touching UI, OCR, camera, or PDF code.

## Active No-Drift Work Plan

Current active lane:

- `en-US`
- Plumbing
- Residential/Core parser hardening

Parallel architecture lane:

- `es-US`
- Locale overlays only
- Canonical item IDs reused from the English catalog
- No duplicated Spanish catalog rows

Next lanes:

1. Finish `en-US` Plumbing Core and neighbor coverage.
2. Finish `en-US` Plumbing Standard/Professional/Complete parser edge cases.
3. Run pack-size and intelligence gates for Plumbing.
4. Move to `en-US` Electrical only after Plumbing is strong enough to leave.
5. Move to `en-US` HVAC.
6. Move to `en-US` Garage Doors and Openers.
7. Continue shared fastener/support/tool/safety locale overlays.
8. Expand `es-US` overlays by trade after each English trade pack is stable.
9. Add Canada English and Canada French.

Spanish implementation must remain overlay-based until there is a clear reason to split a canonical item by country or measurement system. Do not mix English and Spanish terms into one required download pack, and do not duplicate Spanish catalog rows when a locale alias can map back to the canonical item ID.

Current `es-US` checkpoint:

- Parser accepts `localePackId: 'es-US'`.
- Spanish accents are normalized before matching.
- Spanish aliases expand into canonical parser terms before fuzzy matching.
- Plumbing residential core overlay covers fittings, valves, toilet/faucet repair, appliance hookup, supports, and common fasteners.
- Electrical overlay covers common residential outlets, breakers, EMT, wire, alarms, and fan boxes.
- HVAC overlay covers common service-truck capacitor, filter, thermostat, condensate, tape, duct, register, line-set, and screw terms.
- Garage doors/openers overlay covers spring, cable, roller, hinge, track, opener, sensor, seal, and remote terms.
- Cross-trade Spanish fastener tests guard trade-scoped screw families.

## Acceleration Rules

The pass count only makes sense if each pass is bundled. Avoid tiny one-item passes unless fixing a regression that blocks the next batch.

Target pass shape:

- Plan passes should map 50 to 200 related receipt/item families at a time.
- Catalog creation passes should add or enrich 50 to 100 smart item records per pass where safe.
- Parser hardening passes should cover 25 to 75 receipt phrases per pass when the phrases share one domain family.
- Language-pack passes should cover 50 to 150 localized aliases/phrases per pass after the locale architecture is stable.
- Regression-fix passes should fix the blocking collision, rerun the smallest focused test, then return to bundled passes.

Testing strategy:

- Do not run all 56,000-plus catalog items against every neighbor after every change.
- Use targeted family tests first, such as Plumbing PEX, Plumbing DWV, Plumbing Hangers, or Spanish Plumbing Valves.
- Use neighbor sentinels for collision-prone families instead of exhaustive all-item comparisons.
- Run broader plumbing merchant/collision/audit tests after a bundled parser family pass.
- Run full catalog/audit/export tests only at meaningful milestones.

Speed strategy:

- Prefer table-driven fixtures over many one-off test bodies.
- Prefer parser term maps and locale overlays over repeated direct-match branches.
- Prefer canonical item IDs plus locale aliases over duplicated language-specific catalog rows.
- Track failures by item family, receipt phrase, locale, trade, and confidence reason so fixes can be batched.
- Keep each test file near the 500-line target by creating batch files instead of bloating one file.
