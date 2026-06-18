# Firebase Sync And Trade Pack Schema Spec

Maintaniac is local-first. Firebase is an optional hosted sync, backup, account, fleet, and trade-pack delivery layer. Hive-backed local records remain the first source of truth on the device until a user explicitly enables hosted sync.

## Goals

- Keep offline-only users fully supported.
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

Firestore stores manifests only:

```text
tradePacks/{packId}
```

Fields:

- `packId`
- `trade`
- `displayName`
- `version`
- `status`
- `minAppVersion`
- `storagePath`
- `compressedSizeBytes`
- `uncompressedSizeBytes`
- `checksum`
- `recordCount`
- `dependsOnPackIds`
- `companionPackIds`
- `createdAt`
- `updatedAt`

Cloud Storage stores pack files:

```text
trade-packs/{packId}/{version}/pack.json.gz
trade-packs/{packId}/{version}/pack.sqlite.gz
trade-packs/{packId}/{version}/manifest.json
```

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
