# Firestore Data Model

Maintainiac Firestore is configured for the `NAM7` multi-region. Keep this
region choice stable unless there is a deliberate migration plan.

## Hard Safety Rules

- Never use Firestore test mode for beta or production.
- Never seed production.
- Never deploy rules, indexes, or functions without explicit approval.
- Always run emulator tests before live deploy.
- Keep workspace/org isolation as the primary data boundary.
- Enforce employee permissions in rules and server functions, not only UI.
- Do not store VINs.
- Do not store license plate or tag numbers.
- Do not store passenger data.
- Do not store patient data.
- Non-emergency medical transport workflows must not store patient names,
  phone numbers, addresses, dates of birth, medical record numbers, diagnosis,
  appointment reasons, or other health details.

## Region

```text
NAM7
```

Firestore location is selected in Firebase Console and cannot be changed for an
existing database without a migration. The repo keeps this as a documented
deployment invariant.

## Top-Level Collections

```text
users/{uid}
usage/{uid}/months/{yyyyMM}
abuseSignals/{signalId}
aiAbuseSecurityEvents/{eventId}
aiEnforcementActions/{actionId}
accountAbuseInstalls/{installHash}
accountAbuseIpWindows/{ipWindowHash}
accountCreationReviews/{reviewId}
orgs/{orgId}
tradePacks/{packId}
```

Abuse and usage collections are server-managed. Client reads and writes are
denied unless a rule explicitly allows a narrow read.

AI abuse/security collections are not normal anonymous analytics. They are
server-managed enforcement records and may include account ID, anonymous
analytics ID, hashed app installation/device signal, app version, platform,
rough region, server request timestamp, AI task type, abuse reason, action
taken, attempt count, and risk bucket. They must not include raw prompts,
receipt text, OCR text, customer content, invoice text, notes, addresses, phone
numbers, or emails.

## Org Subcollections

```text
orgs/{orgId}/members/{uid}
orgs/{orgId}/invites/{inviteId}
orgs/{orgId}/vehicles/{vehicleId}
orgs/{orgId}/mileageRecords/{recordId}
orgs/{orgId}/expenses/{expenseId}
orgs/{orgId}/jobs/{jobId}
orgs/{orgId}/estimates/{estimateId}
orgs/{orgId}/invoices/{invoiceId}
orgs/{orgId}/inventoryItems/{itemId}
orgs/{orgId}/inventoryTransactions/{transactionId}
orgs/{orgId}/maintenanceRecords/{recordId}
orgs/{orgId}/settings/{settingsId}
orgs/{orgId}/uploadGrants/{grantId}
orgs/{orgId}/exports/{exportId}
orgs/{orgId}/auditEvents/{eventId}
orgs/{orgId}/syncManifests/{manifestId}
orgs/{orgId}/expenseTelemetrySummaries/{summaryId}
orgs/{orgId}/financialSummaries/{summaryId}
orgs/{orgId}/records/{recordId}
```

## Required Record Envelope

Most user-created org records should include:

- `createdByUid`
- `updatedByUid`
- `createdAt`
- `updatedAt`
- `deviceId`
- `schemaVersion`

Financial summaries, usage counters, abuse counters, upload grants, exports,
official trade packs, expense telemetry summaries, and audit events are
server-managed.

## Expense Backup Scope

Expense receipt backup records live at:

```text
orgs/{orgId}/expenses/{expenseId}
```

The document is one receipt/expense envelope with receipt lines embedded so a
single receipt restore does not require one Firestore read per line. It may
contain the user's private merchant, receipt number, note, category, and line
description fields because those are the actual backed-up expense record. It
must not contain raw OCR text, imported receipt text, local device file paths,
VINs, plates, passenger data, or patient data. Receipt proof images and PDFs
belong in Cloud Storage; Firestore stores proof metadata and storage pointers.

Expense recap preferences live at:

```text
orgs/{orgId}/settings/expenses_{uid}
```

This is a single per-member settings document. Recap tile visibility is backed
up as `hiddenRecapTiles`; default behavior is still show everything.

## Invoice And Estimate Backup Scope

Invoice and estimate records live at:

```text
orgs/{orgId}/invoices/{invoiceId}
orgs/{orgId}/estimates/{estimateId}
```

Invoice and estimate documents are structured business records, not stored PDF
files. They may contain the customer snapshot, line items, terms, payment
records, status, totals, and bounded PDF delivery metadata because that is the
record the user is backing up. They must not contain generated PDF bytes,
temporary file paths, local device paths, raw rendered PDF text, share-sheet
body text, or unbounded delivery logs.

Generated invoice and estimate PDFs are derived artifacts. Permanent proof
copies belong in document storage/Cloud Storage with Firestore storing only
metadata such as storage pointer, byte size, content hash, linked module,
linked record id, original file name, and retention state.

Invoice PDF delivery history is embedded on the invoice record as a bounded
`pdfEvents` list. Each event stores action type, timestamp, PDF kind, source
record id, safe file name, byte size, content hash when available, and a reason
code for failures. It must not store customer names, addresses, phone numbers,
emails, notes, PDF body text, receipt text, OCR text, or local file paths.

## Forbidden Field Names

Rules reject these sensitive fields where user writes are allowed:

```text
vin
VIN
vehicleIdentificationNumber
licensePlate
plate
plateNumber
tagNumber
passengerName
passengerPhone
passengerAddress
patientName
patientPhone
patientAddress
medicalRecordNumber
diagnosis
dateOfBirth
dob
```

If a future feature needs transportation context, store non-identifying
operational data only, such as `pickupZone`, `dropoffZone`, `appointmentWindow`,
or `tripPurposeCategory`, after review.

## Indexes

Index definitions live in:

```text
firestore.indexes.json
```

Indexes must support bounded, filtered operational queries. Avoid collection
scans and listeners that pull entire org collections.

## Seed Data

Seed data is emulator-only and must live under:

```text
firebase_emulator_tests/seed/
```

Production seed scripts are forbidden.
