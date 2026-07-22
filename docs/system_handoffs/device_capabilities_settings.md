# Device Capabilities, Settings, And Operational Policy Living Handoff

## Current Status

`PRESENT / VERIFIED SUBSET / NEEDS RECONCILIATION`. Device capability models,
runtime service/scope, storage assessment, operational policy, system settings,
Dashboard settings, and trip settings exist.

## Implemented Evidence

- Capabilities: `lib/shared/device_capabilities/`
- Settings screens: `lib/screens/settings/`
- Related receipt policy: files matching `device_capability` under
  `lib/shared/widgets/receipt_capture/`

## Boundaries And Remaining

- Classify measured hardware/runtime signals, not model year. Capability advice
  must not silently weaken user review, privacy, or durable-storage boundaries.
- `VERIFIED SUBSET`: source-level capability contracts and focused tests exist;
  current physical-device coverage is not claimed.
- Reconcile source settings/policy differences and run targeted low-storage,
  permission, capability-refresh, and lifecycle tests.

## Rolling Log

- 2026-07-22: Created as the shared device/settings system record.
