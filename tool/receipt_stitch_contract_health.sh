#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "Receipt stitch contract health"
flutter test \
  test/receipt_stitching_test.dart \
  test/receipt_stitching_variants_test.dart \
  test/receipt_camera_phase6_stitching_handoff_contract_test.dart \
  test/receipt_camera_result_stitch_handoff_followthrough_test.dart \
  -r compact
echo "Receipt stitch contract health: PASS"
