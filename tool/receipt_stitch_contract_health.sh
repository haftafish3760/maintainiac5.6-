#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

mode="${1:-full}"

case "$mode" in
  delayed_overlap)
    echo "Receipt stitch delayed-overlap health"
    flutter test \
      test/receipt_stitching_variants_test.dart \
      --name 'delayed overlap' \
      -r compact
    echo "Receipt stitch delayed-overlap health: PASS"
    ;;
  edge_cases)
    echo "Receipt stitch edge-case health"
    flutter test \
      test/receipt_stitching_variants_test.dart \
      test/receipt_stitching_weak_overlap_safety_test.dart \
      --name 'delayed overlap|blurred continuation overlap|continuation edge is clipped|faded receipt sections when continuation edge is clipped|missing middle section' \
      -r compact
    echo "Receipt stitch edge-case health: PASS"
    ;;
  full)
    echo "Receipt stitch contract health"
    flutter test \
      test/receipt_native_camera_session_limits_test.dart \
      test/receipt_capture_flow_shareability_test.dart \
      test/receipt_camera_phase5_long_receipt_contract_test.dart \
      test/receipt_stitching_test.dart \
      test/receipt_stitching_variants_test.dart \
      test/receipt_stitching_weak_overlap_safety_test.dart \
      test/receipt_camera_result_stitch_scanner_test.dart \
      test/receipt_camera_phase6_stitching_handoff_contract_test.dart \
      test/receipt_camera_result_stitch_handoff_followthrough_test.dart \
      -r compact
    echo "Receipt stitch contract health: PASS"
    ;;
  *)
    echo "Usage: $0 [delayed_overlap|edge_cases|full]" >&2
    exit 64
    ;;
esac
