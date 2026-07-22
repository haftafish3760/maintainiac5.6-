# Maintainiac 5.7 Living Handoff Index

This index routes future Codex workers to current system-specific decisions.
Do not begin with a broad source-code scan. Open this index, then only the
handoff for the assigned system and its listed start-here evidence.

## Standing Handoff Rule

Whenever the product owner adds, changes, or clarifies a requirement that is
not implemented during the current work:

1. record it in the living handoff for the system that owns it;
2. label it implemented, verified, deferred, blocked, or undecided;
3. distinguish a product decision from current code behavior;
4. include safety boundaries, dependencies, and validation still required;
5. update this index when a new system handoff is created;
6. never rely on conversation history as the only record.

## Current System Handoffs

| System | Current evidence state | Living handoff |
| --- | --- | --- |
| App shell, Dashboard, vehicles | Present; reconciliation required | `docs/system_handoffs/app_shell_dashboard_vehicles.md` |
| Expenses | Verified subset; reconciliation required | `docs/system_handoffs/expenses.md` |
| Receipt capture, OCR, long receipts | Consolidated; device and final QA pending | `docs/system_handoffs/receipt_capture_ocr_long_receipt.md` |
| Fuel and vehicle energy | Present; reconciliation required | `docs/system_handoffs/fuel_energy.md` |
| Work Supplies / Materials / Inventory | Present; reconciliation required | `docs/system_handoffs/work_supplies_materials_inventory.md` |
| Jobs and Estimates | Shared durable Jobs owner implemented; Estimates pending | `docs/system_handoffs/jobs_estimates.md` |
| Invoices and Payments | Present; unverified | `docs/system_handoffs/invoices_payments.md` |
| PDF Document Engine | Present; reconciliation required | `docs/system_handoffs/pdf_document_engine.md` |
| GPS Trip Tracking, Trip Log, Odometer | Consolidated; field QA pending | `docs/system_handoffs/trip_tracking_odometer.md` |
| Maintenance | Present; unverified | `docs/system_handoffs/maintenance.md` |
| Calendars | Present; unverified | `docs/system_handoffs/calendars.md` |
| Maps and Mapbox | Present; unverified | `docs/system_handoffs/maps_mapbox.md` |
| Profiles, Employees, Permissions | Present; unverified | `docs/system_handoffs/profiles_employees_permissions.md` |
| Local Storage, Backup, Export | Verified subset; reconciliation required | `docs/system_handoffs/local_storage_backup_export.md` |
| Firebase, Firestore, Storage, Cloud Sync | Verified subset; reconciliation required | `docs/system_handoffs/firebase_cloud_sync.md` |
| Device Capabilities, Settings, Policy | Verified subset; reconciliation required | `docs/system_handoffs/device_capabilities_settings.md` |
| Localization and units | Present; unverified | `docs/system_handoffs/localization_units.md` |
| Administration and security | Documented; partially present | `docs/system_handoffs/admin_security.md` |
| Monetization and AI assistant | Documented; unverified | `docs/system_handoffs/monetization_ai_assistant.md` |
| Customer portal, marketplace, website | Documented; unverified | `docs/system_handoffs/customer_portal_website.md` |

The status is deliberately conservative. `PRESENT` means code evidence exists;
it does not mean the system passed complete QA. Update the owning handoff after
every implementation, decision, comparison, test, build, or newly found gap.

Historical specialist documents remain supporting evidence and are linked from
their current system handoff. They do not replace the living handoff.
