# Materials Catalog Intelligence Contract

Date: 2026-06-29

Scope: Maintainiac 5.6 Work Supplies / Materials / Inventory catalog and parser intelligence.

This document overrides any raw item-count mindset in older notes. The goal is not to create the biggest possible catalog. The goal is to create smart catalog rows that help the parser recognize messy residential, light-industrial, and commercial material language with high confidence.

Release one inventory priority is United States residential Plumbing, Electrical,
and HVAC in English (en-US) and Spanish (es-US). Core and Standard are the first
release-one priority cells. Professional and Complete can follow after the same
contract pattern is proven. Fasteners are included only as normal overlap/support
items inside those service-trade packs; they are not a separate release-one trade
pack.

## Hard Boundaries

Do not edit the camera, OCR, PDF, shared receipt-capture, image-prep, receipt-stitching, or Expenses receipt pipeline while working from this contract.

Those systems are being worked on separately and will eventually provide input to the materials parser. Materials work may define what kind of text or line-item input the parser can consume, and it may store OCR-like mistake patterns in parser fixtures, but it must not change how images, PDFs, camera capture, OCR extraction, or expense receipt capture work.

Allowed materials-side work:

- catalog metadata
- parser matching and scoring
- parser fixtures and neighbor tests
- item identity and barcode-ready aliases
- trade-pack manifests and install guards
- inventory destination and staging models
- Command One materials diagnostics contracts

Off-limits work:

- camera screens or native camera code
- OCR engines or OCR preprocessing
- receipt image stitching
- PDF rendering, importing, preview, or export systems
- Expenses receipt capture, OCR review, or expense parser pipeline
- shared receipt-capture widgets unless the user explicitly reassigns that work

## UI Independence

The catalog and parser must be UI-independent. Future Work Supplies UI/UX changes must not require rebuilding the catalog brain.

Rules:

- Parser, catalog, item identity, pack manifest, and diagnostics models should live in data/domain layers.
- UI screens may consume parser results, but parser results must not depend on widgets, routes, BuildContext, screen state, or current layout.
- Catalog records should store semantic values, not UI-only choices.
- UI labels, icons, colors, and card layouts can change without changing item identity, aliases, scoring, pack tier, scope tags, or diagnostics.
- Receipt/camera/OCR inputs should enter materials through a small text/line-item adapter later, not by coupling materials parser code to the capture UI.
- Tests for parser intelligence should run without pumping Flutter widgets unless the test is explicitly a UI test.

Current code note: some existing catalog/model files still import Flutter Material for presentation-friendly values. Do not make that coupling worse. Future cleanup should move display-only values behind adapters when safe.

## Product Direction

Work Supplies is a contractor inventory and material parser system, not a big-box-store browse catalog.

The catalog should prioritize:

- residential service work
- residential remodel and repair
- light industrial service work
- commercial work where it is useful to contractors
- service-truck, shop, and job-staging inventory
- receipt parsing, search, barcode linking, estimate/invoice material staging, and inventory suggestions

Avoid over-building into municipal, hospital, fire suppression, waterworks, manhole, or industrial process-piping catalogs unless the user explicitly opens that scope later.

## Scope Tags

Every catalog item should support market-scope tagging. A single item can belong to more than one scope.

Required scope tags:

- residential
- lightIndustrial
- commercial

Optional future scope tags:

- specialty
- legacy
- municipal
- fireSuppression
- hospital
- industrialProcess

The default current focus is residential plus light industrial. Commercial should be structured into the model now so the app does not need a painful migration later, but commercial breadth should not drown out residential parser quality.

## Pack Tiers

Each trade and market scope should support four tiers:

- Core Pack: everyday service-truck items. For residential plumbing, target roughly the top quarter of practical residential catalog rows, currently about 2,400 to 3,200 smart rows, and aim to cover about 75 to 90 percent of what an average residential service plumber, handyman, or small service company carries, buys, or estimates during ordinary day-to-day home/apartment work.
- Standard Pack: common broader field stock, still heavily biased toward real service use.
- Professional Pack: most residential and light-industrial situations, remodel work, uncommon fittings, repair parts, specialty valves, and less common sizes.
- Complete Pack: deep verified coverage for the selected trade and scope, including rare but still relevant residential/light-industrial/commercial items.

Residential plumbing complete target: roughly 12,000 to 15,000 smart items before heavy commercial expansion.

Whole catalog target for residential plus light industrial: roughly 65,000 to 90,000 smart items, with a practical target near 75,000 smart items.

Commercial expansions can raise those totals later, but should be separate by scope and tier rather than silently bloating residential packs.

## Size Budget

Pack size matters because users may be on older phones or limited storage.

Residential plumbing complete target:

- Preferred max: about 150 MB
- Hard review threshold: about 210 MB

If a residential pack approaches the preferred max, stop adding broad commercial material to that scope. Move commercial or light-industrial additions into the matching scope and continue with explicitly named passes such as:

- Residential Plumbing Pass 1
- Light Industrial Plumbing Pass 1
- Commercial Plumbing Pass 1

Do not run pack-size measurement after every tiny edit. Measure at meaningful pack milestones and before publish/export work.

## Local And Cloud Delivery

Inventory parser packs must support two delivery paths:

- Local pack mode: the user downloads gzipped pack chunks, the app unpacks them on-device, parsing is fastest, offline capable, and requires enough phone storage for the uncompressed pack plus safe install buffer.
- Cloud fallback mode: the user keeps catalog packs in the cloud, parsing requires internet, is slower than local parsing, may use carrier or Wi-Fi data, and should require the paid/ad-free subscription tier if enabled.

Cloud fallback is for users who do not want to store large packs locally or do not have enough device space. It must be presented as a space-saving but online-only option.

Cloud fallback guardrails:

- Do not implement cloud parsing as one read per catalog item.
- Batch/query by trade, market scope, pack tier, candidate tokens, and compact manifest/chunk indexes.
- Target no more than about 100 catalog reads per user per day.
- A large receipt with around 100 purchased items must not create 100 full-pack downloads or thousands of Firestore document reads.
- The UI must explain speed, offline, storage, data-plan, and subscription tradeoffs before the user chooses cloud mode.
- Firebase writes are still off-limits for catalog testing unless explicitly approved by the user.

## Smart Item Contract

Each catalog item should be a rich canonical record, not just a name.

Required metadata groups:

1. Canonical identity

- item ID
- clean display name
- trade category
- subcategory
- item family
- item type
- material
- size
- connection type
- angle, shape, or style
- unit type
- pack quantity
- consumable vs durable
- generic vs brand-specific
- market scope tags
- pack tier priority

2. Alias dictionary

- common trade names
- spoken names
- shorthand names
- misspellings
- regional names
- older trade names
- equivalent user wording

Example for a half-inch brass PEX crimp 90:

- PEX elbow
- PEX 90
- 1/2 PEX 90
- PEX crimp 90
- brass PEX ell
- PEX L
- PEX elb
- half inch PEX elbow
- .5 PEX 90

3. Receipt abbreviation patterns

- all-caps receipt text
- store-counter shorthand
- missing punctuation
- compressed sizes
- missing spaces
- abbreviations from big-box and supply-house receipts

Examples:

- 1/2 PEX CRMP ELL
- PEX ELB 1/2
- BR PEX 90
- PEX FIT 90D
- 1/2IN PEX ELL

4. OCR mistake patterns

The parser should expect imperfect OCR and image quality.

Examples:

- PEX read as PFX
- PVC read as PYC
- CPVC read as CPYG
- 1/2 read as I/2
- 0 read as O
- 5 read as S
- ELB read as E18

Do not store private receipt text in Command One diagnostics. OCR mistake patterns belong in catalog/parser metadata and test fixtures, not owner-visible raw receipt content.

This section does not authorize editing OCR. It only defines parser tolerance for imperfect text after another system has produced text.

5. Store and vendor mappings

The data model should support, when known:

- Home Depot SKU
- Lowes item number
- Menards SKU
- Ferguson code
- SupplyHouse ID
- manufacturer part number
- UPC / GTIN
- brand name
- private-label name
- store-specific short name

Not every item needs all mappings on day one. The structure must support them.

Do not scrape or misuse retailer databases or restricted data. User-linked barcode and SKU aliases remain local/user-owned unless a future explicit opt-in sharing system is approved.

Vendor and SKU evidence is parser evidence, not automatic truth. The parser may use vendorSku, manufacturerPartNumber, storeItemNumber, UPC, GTIN, brand, privateLabel, skuPattern, part-number, receipt short name, and vendor mappings to boost ranked candidates, but it must still stay review-only when there is not enough evidence or when conflict rule checks find ambiguous, cross-trade, wrong brand, or wrong material evidence.

Required vendor/SKU safety rules:

- sku_only_must_not_guess_trade
- sku_plus_merchant_can_boost
- sku_plus_brand_can_boost
- sku_plus_size_can_finalize
- part_number_collision_requires_review
- upc_collision_requires_review
- private_label_maps_to_canonical_item
- store_short_name_maps_to_alias_evidence
- missing_vendor_map_does_not_fail_item
- vendor_map_is_versioned

Vendor/SKU matrix axes must include:

- merchantAxis: Home Depot, Lowe's, Ace, Ferguson, Grainger, and unknown/local merchant
- identifierAxis: SKU, UPC, GTIN, part number, manufacturer part number, store item number, brand, private label, and receipt short name
- tradeAxis: plumbing, electrical, HVAC, and fastener overlap
- tierAxis: Core, Standard, Professional, and Complete
- localeAxis: en-US, es-US, Spanish, and future locale packs
- resultAxis: review, ranked, unknown, confidence, and false confident guardrails

These rules are required so a merchant identifier can help the parser without letting one vendor code silently create bad inventory, job, estimate, or invoice material records. Vendor/SKU evidence must do not auto-save any inventory, estimate, invoice, or job material action without review and user approval.

Required barcode/vendor provenance safety rules:

- user_item_id_does_not_replace_stable_catalog_id
- barcode_can_link_to_canonical_item
- barcode_collision_requires_review
- barcode_mapping_requires_user_confirmation
- unknown_barcode_stays_review_only
- barcode_evidence_never_bypasses_conflict_rules
- user_scanned_barcode_maps_to_private_inventory_memory_first
- vehicle_location_is_user_inventory_metadata
- bin_drawer_location_is_not_parser_identity
- fleet_vehicle_inventory_is_separate_from_catalog
- same_catalog_item_can_exist_on_multiple_vehicles
- user_custom_item_keeps_source_metadata
- barcode_scan_can_create_review_candidate
- barcode_missing_does_not_block_receipt_parser
- official_pack_mappings_require_licensed_or_public_source
- retailer_database_scraping_is_forbidden
- merchant_sku_mapping_requires_source_confidence
- barcode_receipt_disagreement_requires_review
- barcode_can_boost_confidence_only_with_corroborating_evidence

Barcode, UPC, GTIN, vendor SKU, and merchant item-number evidence may improve ranked candidates only when it agrees with receipt text, item metadata, trade context, pack scope, and conflict graph evidence. Unknown or colliding barcode evidence must stay review-only. User-scanned barcode links belong to private local inventory memory unless the user explicitly promotes them through a reviewed correction workflow. User item ID and internal item ID values never replace stable catalog identity. Vehicle location, bin number, drawer, truck, fleet, on hand, out of stock, purchased not in stock, job staging, vehicle inventory, shop inventory, employee, permission, and owner fields are user inventory metadata, not parser identity. Official parser packs must never be built from copied retailer databases or scraping; mappings need licensed, reviewed public, manual, or synthetic provenance with source confidence and version metadata. Retailer database scraping is forbidden.

6. Attribute tokens

Parser tokens should include:

- size tokens: 1/2, .5, half inch, 0.5 in
- material tokens: brass, copper, PVC, CPVC, PEX
- shape tokens: elbow, ell, 90, ninety
- connection tokens: crimp, slip, threaded, push-fit
- category tokens: fitting, adapter, valve, connector
- pack tokens: 1-pack, 2-pack, 10-pack, contractor pack

7. Negative match rules

Each item family needs "not this" signals to prevent bad neighbor matches.

Example: do not confuse these just because the receipt says 1/2 elbow:

- PEX elbow
- PVC elbow
- copper elbow
- SharkBite push elbow
- street elbow
- drop-ear elbow

When adding a new item family, add at least one nearby parser test that proves it does not steal a neighboring family.

8. Confidence scoring hints

Each item family should tell the parser what matters most.

Typical weights:

- size match: high
- material match: high
- connection type: high
- shape or angle: high
- brand: medium
- pack count: medium
- color: low unless color defines the item
- shelf/location/store aisle words: ignore

The parser should score "1/2 brass PEX crimp 90" much higher than "elbow."

9. Normalization rules

Before matching, normalize common format differences:

- 1/2, half inch, .5, and 0.5 inch
- 90, ninety, degree, and deg
- inch marks
- extra spaces
- case
- hyphens
- OCR-like substitutions when safe

10. Parser priority tier

Each item should have practical priority:

- everyday/core item
- common item
- occasional item
- rare/legacy item
- specialty item

If a receipt line is unclear, the parser should prefer common residential or selected-trade items over obscure commercial items.

11. Classification output

When the parser recognizes an item, it should know how to route it:

- inventory category
- expense category
- job material category
- tax/reporting category
- maintenance relevance, if any
- billable material yes/no
- default unit-cost behavior
- default markup behavior for estimates/invoices
- default destination options: company inventory, vehicle, job staging, estimate, invoice

12. Versioning and source tracking

Each item should support:

- catalog version
- parser version compatibility
- last updated date
- source confidence
- verified manually yes/no
- auto-generated yes/no
- needs review yes/no

Bad data should be fixable by version and item ID without replacing the whole pack.

## Command One Diagnostics Contract

Command One must diagnose parser health at item level without exposing private user content.

Allowed diagnostic fields:

- event ID
- trade
- market scope
- pack tier
- pack version
- parser version
- catalog item ID
- catalog item display name
- item family/type/category
- matched candidate ID, when safe
- confidence bucket
- failure reason code
- device class
- device model bucket
- OS major version
- parser depth
- candidate limit
- duration bucket
- retry/correction/abandonment counts

Blocked diagnostic fields:

- raw receipt text
- receipt photo
- card numbers, including last four
- customer name
- job address
- exact location
- employee private data
- user-private inventory notes
- full device serial or exact device identifier

If receipt-photo diagnostics are ever considered, they must require a separate privacy design with automatic redaction before any owner/admin visibility. That is not part of current parser/catalog work and must not touch the camera system.

## Testing Strategy

Do not brute-force the entire catalog after every edit.

Use pass-numbered testing:

- fast fixture tests for changed parser rules
- trade-specific receipt tests
- neighbor/collision tests for nearby families
- identity resolver tests
- pack install/device guard tests
- full-catalog or heavy fuzzy sweeps only at milestones

Normal parser test batches should aim to stay under 2 to 3 minutes. If a test takes 15 minutes, inspect whether it is doing unnecessary full-catalog work and split it into targeted fixtures or milestone-only sweeps.

## Pass Naming

Passes should be numbered and scoped.

Examples:

- Pass 4: Catalog intelligence contract
- Pass 5: Residential Plumbing PEX elbow metadata
- Pass 6: Residential Plumbing PEX elbow neighbor tests
- Pass 7: Light Industrial Plumbing valve metadata
- Pass 8: Commercial Plumbing large-diameter scope model

Do not mix unrelated trades and scopes in the same pass unless the change is shared infrastructure.

## Summary

World-class parser quality comes from rich rows, not dumb row count.

Every serious catalog item should know what it is, how people say it, how receipts mangle it, how OCR misreads it, what it must not be confused with, how confident the parser should be, where the item should route after recognition, and which pack/scope/version it belongs to.
