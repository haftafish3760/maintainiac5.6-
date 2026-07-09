# Receipt QA Backbone

This file defines the canonical reusable QA entrypoints for the receipt lane.
Pass logs are evidence, not executable QA.

## Shared Entry Point

- `tool/receipt_shared_quality_gate.sh fast`
  Use for cheap guardrails and QA contract smoke coverage.
- `tool/receipt_shared_quality_gate.sh pure-dart`
  Use for reusable parser, fixture, and summary-json QA without camera/native
  capture phases.
- `tool/receipt_shared_quality_gate.sh fuel`
  Use for fuel-only parser hardening. This owns the 500-case synthetic fuel
  milestone and related compact summary-json coverage.
- `tool/receipt_shared_quality_gate.sh camera <mode>`
  Use for camera-lane QA. This delegates to `tool/receipt_camera_qa_gate.sh`.
- `tool/receipt_shared_quality_gate.sh full`
  Use for the expensive top-level shared receipt quality gate.

## Lane Ownership

- Fuel parser lane:
  `tool/receipt_shared_quality_gate.sh fuel`
- Pure parser and fixture lane:
  `tool/receipt_shared_quality_gate.sh pure-dart`
- Camera and stitching lane:
  `tool/receipt_shared_quality_gate.sh camera milestone`
- Full shared receipt lane:
  `tool/receipt_shared_quality_gate.sh full`

## Rules

- Do not create one-off QA scripts when an existing shared entrypoint can own
  the check.
- Add regression tests for each confirmed bug and keep the bug ledger current.
- Keep executable QA in `tool/` and `test/`.
- Keep pass logs in `docs/`, but do not treat them as the QA system itself.
