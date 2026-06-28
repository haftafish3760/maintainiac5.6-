# Firebase Sync And Trade Pack Schema Spec

Maintaniac is local-first. Firebase is a required release capability for hosted
sync, backup, account, fleet, customer portal, and trade-pack delivery. The
user can still choose local-only operation, and Hive-backed local records remain
the first source of truth on the device until hosted sync is enabled.

## Goals

- Keep offline-only users fully supported.
- Back up every enabled app module, not only receipt proof files.
- Let users download only the trade packs they need.
- Keep parser knowledge packs cheap to read and update.
- Support solo users first without blocking future fleet accounts.
- Preserve audit history for inventory, expenses, receipts, vehicles, invoices, payments, jobs, and timeline edits.
- Keep helpers from seeing owner-only financial, profit, invoice, or company-wide records unless their role allows it.
- Avoid expensive Firestore read patterns for large catalog/trade data.

## Firebase Products

- Firebase Auth: account identity for users who enable hosted sync.
- Firestore: small metadata documents, user/org records, sync manifests, roles, vehicle metadata, and transaction ledgers.
- Cloud Storage: receipt proof files, export packages, compressed trade-pack files, and larger parser data files.
- Firebase App Check: future protection against unauthorized app clients.
- Cloud Functions: future server-side validation, pack publishing, export assembly, invite handling, and billing/account tasks.

## Source Of Truth Layers

Local source:

- Hive stores current working records, drafts, inventory counts, receipt lines, transaction ledgers, and user settings.
- The app must work without Firebase.
- Export is built from local source records unless the user is restoring from hosted sync.

Hosted source:

- Firestore stores synced record envelopes, metadata, role grants, and audit pointers.
- Cloud Storage stores proof files and downloadable pack files.
- Sync must be append-friendly and conflict-aware. It must not silently overwrite local records.

First-release hosted backup scope:

- Mileage and trip records.
- Expenses, receipt metadata, and proof files.
- Jobs, estimates, invoices, payments, and customer-visible job progress.
- Inventory items, material usage, transfers, adjustments, and trade-pack state.
- Maintenance records and vehicle metadata.
- Employee profiles, role templates, permission grants, and invite state.
- Calendar timeline records, app settings, audit events, and export requests.

## Account Model

Solo users and fleet users share the same base shape.

```text
users/{uid}
```

Fields:

- `displayName`
- `email`
- `createdAt`
- `lastSeenAt`
- `defaultOrgId`
- `localOnlyUntilEnabled`
- `acceptedTermsVersion`
- `settingsSummary`

```text
orgs/{orgId}
```

Fields:

- `name`
- `ownerUid`
- `plan`
- `createdAt`
- `updatedAt`
- `syncEnabled`
- `storageMode`
- `freeHostedStorageLimitBytes`
- `usedHostedStorageBytes`
- `activeTradePackIds`

```text
orgs/{orgId}/members/{uid}
```

Fields:

- `uid`
- `role`
- `status`
- `displayName`
- `invitedBy`
- `createdAt`
- `updatedAt`
- `assignedVehicleIds`
- `allowedModules`

Roles:

- `owner`: full access.
- `admin`: company operation access, configurable financial visibility.
- `manager`: can view assigned vehicles/jobs and approve records.
- `helper`: can log records for assigned vehicles/jobs only.
- `viewer`: read-only access to permitted records.

## Permission Principles

- Helpers should not see company-wide profit, all expenses, invoice totals, or owner-only settings by default.
- A member can only read/write records for allowed orgs.
- A member can only see vehicles assigned to them unless their role grants wider visibility.
- Financial visibility is separate from operational visibility.
- Receipt proof visibility must be tied to the receipt lines and roles, not just the full receipt image.
- Every write must carry `createdByUid`, `updatedByUid`, `deviceId`, and timestamps.

## Vehicle And Location Schema

```text
orgs/{orgId}/vehicles/{vehicleId}
```

Fields:

- `nickname`
- `type`
- `status`
- `assignedMemberIds`
- `createdAt`
- `updatedAt`
- `hidden`

Do not store VIN numbers or license plate numbers.

```text
orgs/{orgId}/inventoryLocations/{locationId}
```

Fields:

- `kind`: `company`, `vehicle`, `jobStaging`, `custom`
- `label`
- `vehicleId`
- `jobId`
- `parentLocationId`
- `active`
- `createdAt`
- `updatedAt`

Inside-location details such as bin, drawer, tray, shelf, or trailer compartment are stored on inventory records and transaction lines.

## Trade Pack Delivery

Large trade/catalog/parser data should not be stored as thousands of Firestore documents for normal app reads.

Firestore stores pack metadata and manifests only:

```text
catalogPacks/{packId}
catalogPacks/{packId}/manifests/{versionId}
```

Fields:

- `packId`
- `packVersion`
- `trade`
- `displayName`
- `status`
- `minAppVersion`
- `storagePrefix`
- `itemCount`
- `tradeCount`
- `chunkCount`
- `firestoreManifestReadCount`
- `firestoreItemDocumentReadCount`
- `estimatedCompressedBytes`
- `chunks`: Storage chunk metadata only, never item bodies
- `dependsOnPackIds`
- `companionPackIds`
- `createdAt`
- `updatedAt`

Cloud Storage stores chunk files:

```text
catalog-packs/work-supplies/{version}/{trade}/{chunkId}.json.gz
```

Normal app catalog download should read one Firestore manifest document, then download the referenced Storage chunks. It must not read one Firestore document per catalog item.

Recommended pack split:

- `shared-core`: units, sizes, common parser rules, generic templates.
- `plumbing`: plumbing category paths, aliases, parser terms, item templates.
- `electrical`: electrical category paths, aliases, parser terms, item templates.
- `hvac`: HVAC category paths, aliases, parser terms, item templates.
- `cross-trade`: shared item mappings and ambiguity rules.

## Trade Pack Data Shape

Pack files should contain compact structured data:

```json
{
  "packId": "plumbing",
  "version": 1,
  "items": [],
  "templates": [],
  "aliases": [],
  "categoryPaths": [],
  "crossTradeMappings": [],
  "parserRules": []
}
```

Canonical item identity must be separate from trade context.

Example:

```json
{
  "canonicalTemplate": "90 Elbow",
  "material": "Copper",
  "size": "1/2 in",
  "unit": "each",
  "contexts": [
    {
      "trade": "Plumbing",
      "path": ["Fittings", "Copper", "90 Elbows"]
    },
    {
      "trade": "HVAC",
      "path": ["Refrigerant Lines", "Copper Fittings", "90 Elbows"]
    }
  ],
  "aliases": ["copper 90", "copper ell", "sweat 90", "refrigeration elbow"]
}
```

The physical item stays one item. Plumbing/HVAC are usage contexts.

## Current Pack Size Baseline

Measured from the local de-duplicated Plumbing starter pack on June 9, 2026:

- Item count: 11,288.
- Raw compact JSON: 3,426,681 bytes, about 3.27 MB.
- Gzipped JSON: 119,291 bytes, about 0.11 MB.
- Raw bytes per item: about 304.
- Gzipped bytes per item: about 10.6.
- Projected 50,000 item pack at the same compression ratio: about 0.50 MB gzipped.
- Projected 100,000 item pack at the same compression ratio: about 1.01 MB gzipped.

These projections are estimates, not guarantees. Compression stays strong because trade-pack data repeats the same field names, category paths, units, sizes, and aliases. Real future packs may grow if they include richer parser rules, images, barcode mappings, store-specific aliases, or multilingual terms. Images should not live inside the JSON pack; use separate Cloud Storage assets or app assets.

## Cross-Trade Ambiguity

If one item maps to multiple enabled trades, the parser returns:

- canonical item identity
- possible trade contexts
- confidence per context
- ambiguity flag
- review guidance

Rules:

- If only one relevant trade pack is enabled, default to that trade context.
- If multiple enabled trades match and the receipt line lacks enough context, require review.
- User work profile and selected job category may bias the suggestion, but must not silently force the wrong trade.
- Confirmed user corrections become local learning records and may later sync as user-private aliases.

## Local Pack Cache

Downloaded packs are cached locally:

- pack id
- version
- checksum
- installed date
- selected/enabled state
- source storage path
- last parser index rebuild time

The app can use cached packs offline. Failed pack updates must not break existing local matching.

Trade pack cache rules:

- Trade packs are reference data sets for matching, search, add-item suggestions, and receipt review. They are not user inventory records.
- Users must be able to add, enable, disable, and delete trade packs from their device.
- Deleting a trade pack removes local reference data and parser indexes only. It must not delete saved inventory items, receipts, barcode aliases, cost history, transactions, or exports.
- Inventory review should read saved inventory and transaction records first. It may consult trade-pack data only when the user enters a lookup, add-item, parser, or settings flow that needs reference data.
- Pack downloads should be manifest-driven and lazy. Selecting Plumbing should not require downloading Electrical, HVAC, or other unrelated packs unless a dependency is explicitly listed.

## Barcode Alias Sharing

Barcode aliases are local, user-owned identity records by default.

Rules:

- Do not preload large manufacturer, retailer, UPC, EAN, QR, or store barcode databases into the shipped app.
- Hosted backup may sync the user's own barcode aliases as private org/user records.
- Community barcode contribution is a future separate opt-in, not part of normal backup.
- Shared barcode contribution must require clear consent, moderation or confidence scoring, abuse protection, and a removal path.
- Clients cannot publish official barcode mappings directly. Any shared/public mapping path must be server-reviewed before it affects other users.

## Inventory Records

Inventory should be transaction-ledger based. Current counts are derived from transactions or stored as cached summaries.

```text
orgs/{orgId}/inventoryItems/{itemId}
```

Fields:

- `canonicalKey`
- `displayName`
- `tradeContexts`
- `primaryTrade`
- `categoryPath`
- `unit`
- `userCreated`
- `createdByUid`
- `createdAt`
- `updatedAt`
- `hidden`

```text
orgs/{orgId}/inventoryTransactions/{transactionId}
```

Fields:

- `type`: `stockAdded`, `consumed`, `countAdjusted`, `transferred`, `returned`, `correction`
- `itemId`
- `canonicalKey`
- `quantityChange`
- `quantityBefore`
- `quantityAfter`
- `sourceLocationId`
- `sourceStorageDetail`
- `destinationLocationId`
- `destinationStorageDetail`
- `receiptId`
- `receiptLineId`
- `jobId`
- `vehicleId`
- `occurredAt`
- `createdAt`
- `createdByUid`
- `deviceId`
- `replacesTransactionId`
- `reversedTransactionId`

```text
orgs/{orgId}/inventoryBalances/{balanceId}
```

Cached summary, rebuildable from transactions:

- `itemId`
- `canonicalKey`
- `locationId`
- `storageDetail`
- `onHand`
- `threshold`
- `lastUnitCost`
- `updatedAt`

## Receipt Records

```text
orgs/{orgId}/receipts/{receiptId}
```

Fields:

- `source`: `manualWithReceipt`, `manualWithoutReceipt`, `photoAssist`, `pdfImport`
- `merchantName`
- `receiptDate`
- `businessUse`
- `destinationMode`
- `proofStoragePaths`
- `subtotal`
- `taxTotal`
- `total`
- `createdAt`
- `updatedAt`
- `createdByUid`
- `deviceId`

```text
orgs/{orgId}/receipts/{receiptId}/lines/{lineId}
```

Fields:

- `lineNumber`
- `rawReceiptText`
- `displayName`
- `kind`: `inventory`, `expense`, `personal`, `ignored`
- `itemId`
- `canonicalKey`
- `expenseCategoryId`
- `quantity`
- `unitsPerPackage`
- `purchaseType`
- `unit`
- `subtotal`
- `taxRate`
- `confidence`
- `confidenceLevel`: `good`, `okay`, `poor`
- `reviewStatus`: `confirmed`, `needsReview`
- `businessUse`
- `businessPercent`
- `locationId`
- `storageDetail`
- `vehicleId`
- `jobId`
- `invoiceProofMode`
- `proofCrop`
- `createdAt`
- `updatedAt`

## Receipt Proof Storage

Cloud Storage paths:

```text
orgs/{orgId}/receipts/{receiptId}/proofs/source/{proofId}.jpg
orgs/{orgId}/receipts/{receiptId}/proofs/optimized/{proofId}.jpg
orgs/{orgId}/receipts/{receiptId}/proofs/pdf/{proofId}.pdf
```

Rules:

- Upload only if the user enables hosted backup/sync.
- Local-only users keep proof locally/export manually.
- Optimized versions may sync without source originals if user settings choose space saving.
- Proof files must never be deleted silently.

## Expenses, Jobs, And Invoices

These modules need their own full specs later, but inventory/receipt schema must already leave hooks:

- `expenseCategoryId`
- `jobId`
- `invoiceId`
- `invoiceLineId`
- `receiptLineId`
- `vehicleId`
- `businessUse`
- `businessPercent`

Invoices should reference receipt line ids, not only whole receipt ids, so customer proof can show only relevant lines.

Expense receipt backups use one Firestore document per receipt:

```text
orgs/{orgId}/expenses/{expenseId}
```

The expense document embeds bounded receipt lines and stores money values in
cents. It can include the user's private merchant, receipt number, notes,
categories, and line descriptions because this is the user's own backed-up
record behind org membership rules. It must not include raw OCR text, imported
receipt text, local device file paths, proof image bytes, PDF bytes, VINs,
license plates, passenger data, or patient data. Receipt proof files use Cloud
Storage and Firestore keeps only proof pointers, hashes, sizes, and storage
state.

Expense recap settings use one member-scoped settings document:

```text
orgs/{orgId}/settings/expenses_{uid}
```

Default recap behavior is show every tile. User-hidden recap tiles are stored
as `hiddenRecapTiles` so a restored device can reproduce the user's recap
layout without reading multiple settings documents.

Expense OCR health for Command 1 is not a per-receipt admin collection. When
available, the privacy-safe OCR contract is embedded as
`commandCenterOcrContract` in the existing summary document:

```text
orgs/{orgId}/expenseTelemetrySummaries/{summaryId}
```

The summary document keeps `uploadShape` set to `single_summary_document` and
`rawEventUploadCount` set to `0`. The OCR contract must pass
`ExpenseExportSnapshot.commandCenterOcrContractFindingsFor` before queueing.
If that audit reports any findings, the app must reject the summary upload
instead of sending private receipt content to Command 1.

Receipt camera, OCR, parser, and expense diagnostics are local-first telemetry.
Local Hive can keep detailed events for debugging, but Command 1 Firestore
health must use summarized documents. The default 15-minute scheduler interval
allows at most 96 scheduled expense telemetry summary writes per org per day
before retries or manual force-queue actions. The working safety target is
20,000 Firestore writes per day across the project, so receipt diagnostics must
not become per-capture, per-failure, per-retry, per-line, or per-receipt writes.
`ExpenseTelemetryFirestoreBridge.queueHealthSummary` must replace the pending
draft for the same summary path instead of stacking duplicate writes. High-volume
local camera/OCR telemetry bursts must still queue one bounded Firestore summary
with `rawEventUploadCount: 0`.
Guard phrase: 96 scheduled expense telemetry summary writes per org per day,
20,000 Firestore writes per day, and no per-capture, per-failure, per-retry, per-line, or per-receipt writes.

The expense telemetry summary builder sanitizes the local Command Center
health map before Firestore queueing. Any new top-level field added to
`ExpenseTelemetryHealthSnapshot.toCommandCenterMap()` must be reviewed against
the Firestore summary sanitizer. If Command 1 needs that field, it must remain
in `orgs/{orgId}/expenseTelemetrySummaries/{summaryId}` and must be covered by
the parity regression named `keeps every Command Center telemetry field in Firestore summary`.
Fields must not be moved into per-event, per-receipt, or
separate admin collections just to make them visible.

Telemetry schema changes must follow the expense telemetry schema change checklist
in `docs/expense_command_center_ocr_contract.md`: compute locally,
allowlist and sanitize in `_sanitizeExpenseTelemetryMap`, keep the field in
`expenseTelemetrySummaries/{summaryId}`, update
`test/helpers/expense_telemetry_schema_expectations.dart`, update docs, and
keep the parity and doc guard tests passing.

Firestore wrapper metadata such as `summaryId`, `summaryScope`, `uploadShape`,
`rawEventUploadCount`, and `commandCenterOcrContract` is added by the Firestore
document builder, not by `ExpenseTelemetryHealthSnapshot.toCommandCenterMap()`.
Those metadata keys must stay out of the local Command Center telemetry schema
helper.

The summary sanitizer accepts only nonnegative counts, finite nonnegative
rates, safe tokens, short readable labels, nonnegative count maps, and sanitized
nested failure maps. It must reject negative scalar counts, negative rates,
`NaN`, infinite rates, and unsupported scalar values before queueing the
Firestore summary.

Failure drill-down arrays are bounded inside the same summary document:
`failureBreakdowns` defaults to 20 entries with a hard cap of 50, and
`recentFailureDetails` defaults to 50 entries with a hard cap of 100. These
arrays are samples for Command 1, not raw event history. Nested failure objects
must follow the documented `Expense Failure Drill-Down Object Schemas`, including
`missingEvidence` as `none` when nothing is missing. Nested failure objects must
include `actionSummary` as a bounded plain-language explanation of the failed
workflow and next safe check without requiring Command 1 to read private
evidence. Firestore drift guards must prove `actionSummary` stays readable after
summary sanitization instead of becoming a lowercase token, while still
scrubbing store names, exact totals, auth numbers, receipt numbers, and source
tokens. The phrase "source tokens" is intentional here so doc guards can prove
this privacy boundary stays documented. Nested failure objects must not carry raw private receipt content,
including `payload`, `metadata`,
`receiptText`, `rawOcrText`, `merchantName`, `itemDescription`, `proofPath`,
`orgId`, `userId`, or other private receipt values.
Nested OCR failure objects include `ocrFailureSource` and
`ocrFailureSourceAction` so Command 1 drill-downs can show the safe source
bucket and repair path without rereading raw evidence. Non-OCR failures must use
`ocrFailureSource` as `not_ocr` so parser/save/sync drill-down rows do not look
like camera, PDF, or OCR-source problems. The `none` bucket is reserved for
OCR-step failures that started without a usable photo, PDF, or imported text
source.
Firestore regression coverage must stress OCR and non-OCR drill-down rows
together with poisoned source labels, store names, exact totals, auth codes,
transaction numbers, invoice numbers, and barcode-like values.
Failure diagnostic machine-token fields must also scrub common private receipt
hints before the summary is queued for Command 1. Known merchant names become `merchant`,
common receipt locations become `location`, money-like values become `amount`,
receipt/auth/transaction-length numbers can become `number`, and
note/name/receipt-number style references can become `private_reference`.
Machine-token fields such as `failedAt`, `confirmedCause`, `evidence`,
`missingEvidence`, `topOcrFailureCause`, `topOcrFailureStage`, and
`ocrFailureSourceAction` are for grouping, filtering, and action routing; they
are not display copy.
Visible drill-down fields such as `failedAtLabel`, `causeLabel`,
`evidenceLabel`, `missingEvidenceLabel`, `recommendedAction`, and
`actionSummary` must stay readable, bounded, and free of raw snake-case tokens.
In Command 1 wording, this means free of raw snake-case diagnostic tokens.
Command 1 should map machine tokens to UI copy instead of showing them directly.
The Firestore guard must include fuel, retail, and auto-service stress examples
such as Shell, Walmart, Home Depot, Jiffy Lube, UPC/barcode-like numbers, auth
codes, terminal numbers, transaction numbers, invoice numbers, and
underscore-separated totals such as `45_67` or `109_23`.
It also guards regional fuel, truck stop, contractor retail, and auto-service
examples such as Pilot/Flying J, Love's, Casey's, Kwik Trip, Tractor Supply,
Harbor Freight, Valvoline, Take 5, and Firestone.
The helper boundary is `_ExpenseTelemetryFirestoreRedactor`; it owns redaction
for failure token fields and failure count-map fields while preserving normal
operational tokens such as `platform`, `deviceTier`, `appVersion`,
`topOcrFailureSource`, and `appVersionCounts`.
OCR failure source fields are source-isolated before Firestore upload:
`ocrFailureSourceCounts` and `topOcrFailureSource` may only contain `photo`,
`pdf`, `importedtext`, `mixed`, `none`, or `unknown`. Unknown `source_*` labels
must stay `unknown`, not merchant names, file names, user notes, receipt text, or
private evidence labels.
Nested drill-down source fields may contain those same safe buckets plus
`not_ocr` for parser, save, sync, and other non-OCR workflow failures.
Each allowed source bucket must have a matching `topOcrFailureSourceAction`
that tells Command 1 what to inspect next: camera focus/exposure/crop/order for
photo, safety/size/render/page extraction for PDF, imported text cleanup for
`importedtext`, source selection/order/duplicate suppression for `mixed`,
missing proof for `none`, and safe source tagging for `unknown`.
The final Firestore sanitizer must keep those source-action tokens bounded and
actionable without preserving store names, exact totals, receipt numbers, file
names, or user-entered notes.
Source-action regression coverage must include edge aliases such as
`source_camera`, `source_image`, `source_document`, `source_pasted_text`,
`source_combined`, `source_missing`, malformed private source labels, and
non-OCR drill-down rows so action strings stay useful after Firestore
tokenization.
The redacted token fields are `failedAt`, `confirmedCause`, `evidence`,
`missingEvidence`, `topOcrFailureCause`, and `topOcrFailureStage`. The redacted
count-map fields are `ocrFailureCauseCounts`, `ocrFailureStageCounts`, and
`expenseSummaryOcrContractSkippedReasonCounts`.

Scheduled expense telemetry uploads use
`ExpenseTelemetrySummaryScheduler.queueIfDue` to build the same
`commandCenterOcrContract` from a rolling local-ledger receipt window before
queueing the summary document. The scheduler must keep
`includeLedgerOcrContract` available so a non-OCR health summary can be queued
without attaching receipt OCR health.

When a summary is queued, `ExpenseScreenTelemetryRecorder` may add one local
`syncPending` trace with `syncState: expense_summary_queued`,
`summaryStatus`, `ocrContractQueued`, `ocrContractSource`, and optional
`ocrContractSkippedReason`. That trace must not contain the Firestore path,
org id, receipt images, raw OCR text, merchant names, item descriptions, or
private receipt values. Throttled scheduler checks must not create trace
events.

The Firestore summary document also includes aggregate scheduled OCR trace
metrics: `expenseSummaryQueuedCount`,
`expenseSummaryOcrContractQueuedCount`,
`expenseSummaryOcrContractSkippedCount`,
`expenseSummaryOcrContractSourceCounts`,
`topExpenseSummaryOcrContractSource`,
`expenseSummaryOcrContractSkippedReasonCounts`, and
`topExpenseSummaryOcrContractSkippedReason`. These fields are safe counts and
tokens only. They must remain in
`orgs/{orgId}/expenseTelemetrySummaries/{summaryId}`. These metrics must not create a separate scheduler trace collection. They also must not create a per-event Command 1 read path.

## Sync Envelopes

Every synced record should include:

- `id`
- `orgId`
- `schemaVersion`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `createdByUid`
- `updatedByUid`
- `deviceId`
- `localRevision`
- `cloudRevision`
- `syncStatus`

Deletes should be soft deletes first so accidental sync or offline conflicts can be reviewed.

## Conflict Handling

- Same record edited on two devices: preserve both revisions and require review for important money, mileage, inventory count, receipt, or invoice conflicts.
- Inventory transaction conflicts: never silently drop a transaction. Add corrective transactions when needed.
- Receipt proof conflicts: keep both files until user resolves.
- Trade pack update conflict: keep old pack active until new pack verifies checksum and parser index builds successfully.

## Security Rule Intent

Firestore rules should enforce:

- User can read own user profile.
- User can read org only if member exists and status is active.
- Owner/admin can manage org settings and members.
- Helper can create operational records only in assigned vehicles/jobs/modules.
- Helper cannot read owner-only financial summaries unless explicitly granted.
- Members cannot write `createdByUid` as another user.
- Client cannot publish official trade packs.
- Trade pack manifests are public/readable or app-readable, but writes are admin/server only.

Cloud Storage rules should enforce:

- Receipt proof files require active org membership and module permission.
- Helper access to proof files should be scoped to assigned vehicles/jobs/receipt lines.
- Trade pack files are read-only to clients.
- Export packages are readable only by the requesting user or owner/admin role.

## Development Order

1. Finish local Hive models and ledgers first.
2. Keep building local trade pack files in the repo.
3. Add local pack manifest format and parser index rebuild path.
4. Add Firebase project and SDK only after local schema names stabilize.
5. Create Firestore/Storage security rules before uploading real user data.
6. Add hosted sync behind an explicit setting.
7. Add fleet role behavior only after solo sync is stable.

## Open Questions

- Exact free hosted storage limit.
- Whether official trade packs are public read or Auth-required read.
- Whether large packs ship as compressed JSON, SQLite, or another local database format.
- Which modules helpers can use in the first fleet release.
- Whether owner/admin can remotely wipe synced helper device data after removing access.
