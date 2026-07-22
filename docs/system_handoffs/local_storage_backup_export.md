# Local Storage, Backup, And Export Living Handoff

## Current Status

`PRESENT / VERIFIED SUBSET / NEEDS RECONCILIATION`. Local-first record stores,
Hive-backed data, storage guards, export policy, app-generated files, and master
export surfaces exist.

## Implemented Evidence

- Storage and records: `lib/shared/storage/` and `lib/shared/records/`
- Backup/export: `lib/shared/backup/`, `lib/shared/data_export/`, and
  `lib/screens/settings/master_export_screen.dart`
- Receipt ownership contract: `docs/expense_receipt_storage_and_duplicate_contract.md`
- Export specification: `docs/data_export_storage_spec.md`

## Product Boundaries

- Local/Hive is immediate truth; cloud is a mirror/backup.
- Never delete external originals. App-private temporary artifacts can be
  cleaned only at the documented lifecycle boundary.

## Verified / Remaining

- `VERIFIED SUBSET`: checkpoint `16ef2f82` exercised receipt recovery and
  app-private cleanup boundaries with 38 focused tests.
- `VERIFIED SUBSET`: export privacy regression expectations now use the current
  `sensitive_field` vocabulary and continue to reject raw receipt text and card
  data from export output.
- `NEEDS RECONCILIATION`: durable records, migrations, backup/restore, export,
  storage pressure, and non-receipt systems still require source comparison and
  broader validation.

## Rolling Log

- 2026-07-22: Created; receipt evidence must not be generalized as full storage QA.
- 2026-07-22: Revalidated the export privacy contract against the current
  sanitizer vocabulary; no privacy rule was weakened.
