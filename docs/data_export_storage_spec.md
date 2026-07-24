# Data Export And Storage Spec

Maintaniac is local-first record keeping software. The user owns every record, receipt, photo, PDF, export, and proof file created through the app.

## Source Of Truth

- Hive is the intended local database for app records.
- Firebase, Google Drive, iCloud, Microsoft storage, and other providers are backup or sync layers only. They are not the default source of truth.
- Saved app records must be exportable from Hive-backed source records, not from screen text or temporary UI state.
- Demo data must be opt-in only. A real user database must not silently seed fake inventory, expenses, invoices, or trips.
- Temporary camera, crop, compression, and file-import outputs are working files. A receipt is not fully saved until the final record points to durable proof according to the user's selected storage mode.

## Storage Modes

Maintaniac should eventually support these modes:

- Local only: Records stay on the device. The user exports manually when needed.
- Local plus user-controlled files: Records stay local, and receipt proof/export packages can be written to a user-selected file location when the platform allows it.
- Bring-your-own provider: The user connects Google Drive, iCloud, Microsoft storage, or another document provider and chooses what syncs.
- Hosted backup: Maintaniac-managed cloud storage is opt-in with clear plan limits, such as a small free storage allowance.

No storage mode may delete user proof files, provider files, or export packages without explicit confirmation.

## Year-End Export Flow

The app needs a guided export flow for tax and audit work:

1. Choose export purpose: taxes, audit packet, accountant copy, personal backup, or custom export.
2. Choose date range: current tax year, previous tax year, month, custom range, or all records.
3. Choose record types: trips, mileage, expenses, receipts, inventory, maintenance, invoices, payments, jobs, and notes when those systems exist.
4. Choose proof files: include receipt images, PDF receipts, imported documents, or records-only CSV.
5. Choose destination: local files, SD/external storage where supported, USB/flash drive where supported, Google Drive, iCloud, Microsoft storage, email/share sheet, or hosted backup when enabled.
6. Show storage estimate before export starts.
7. Warn if destination space or device temp space is too low.
8. Build the export without deleting originals.
9. Verify that the package was written before calling the export successful.
10. Show the user where it went, what was included, and how many records/proof files were exported.

## Export Package

The export package should be boring, readable, and accountant-friendly.

- CSV files for tabular records.
- A manifest JSON file describing the app version, export time, date range, included record types, file counts, and checksums when implemented.
- Receipt proof folders grouped by year/category/record type when useful.
- Original or optimized proof files according to the user's storage settings.
- Human-readable filenames that avoid unsafe characters.
- No sensitive records in logs.

For Work Supplies inventory, the first export layer is:

- `work_supply_inventory.csv`: current inventory records and item metadata.
- `work_supply_stock_events.csv`: stock-added, count-adjusted, consumed, transfer, and seed/import events.
- Manifest entries with record counts and file names.

## Drafts And Interruptions

- Drafts must survive phone calls, app switches, screen locks, and reasonable app restarts.
- If the OS kills the app mid-flow, the user should be able to resume or discard the draft from the relevant section.
- Draft receipt photos may live in temporary app-controlled storage while the flow is in progress.
- Final saved receipt proof needs a durable accepted storage mode before the app treats it as audit proof.

## Low Storage

- Before capture, compression, PDF import, or export package creation, the app should check available space when the platform can report it.
- If space is too low, show a plain warning with the approximate minimum space needed.
- Maintaniac must not delete user files to make room.
- Cleanup may remove documented app-created temporary working files only.
- Trip tracking and durable storage must not overwrite, reorganize, or assume
  ownership of a user's existing folder style on the phone or provider storage.
  If local storage is too low and backup is off, the app must explain that trip
  history capacity will be limited and offer user-controlled cleanup/export or
  backup setup rather than silently failing.

## Future Cloud Sync

Cloud sync must be opt-in and explain what leaves the device.

- Sync should queue safely when the user is offline or has poor signal.
- Failed sync should retry without duplicating records.
- Conflicts need a review path.
- Free hosted limits must be visible before the user hits the wall.
- Users who bring their own storage provider should control sync frequency within provider and plan limits.
