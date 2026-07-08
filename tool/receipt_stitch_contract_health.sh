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
      test/receipt_stitching_horizontal_placement_test.dart \
      test/receipt_stitching_horizontal_drift_test.dart \
      test/receipt_stitching_worn_receipt_test.dart \
      test/receipt_stitching_weak_overlap_safety_test.dart \
      --name 'delayed overlap|horizontal drift correction|auto-cropped sideways continuation|blurred continuation overlap|wider handheld horizontal drift|faded worn receipt sections|continuation edge is clipped|severely cropped|faded receipt sections when continuation edge is clipped|missing middle section|middle section is missing|reverse order' \
      --concurrency=1 \
      -r compact
    echo "Receipt stitch edge-case health: PASS"
    ;;
  long_stack)
    echo "Receipt stitch long-stack health"
    flutter test \
      test/receipt_stitching_long_stack_test.dart \
      -r compact
    echo "Receipt stitch long-stack health: PASS"
    ;;
  handoff)
    echo "Receipt stitch handoff health"
    flutter test \
      test/receipt_camera_phase5_long_receipt_contract_test.dart \
      test/receipt_camera_low_confidence_stack_handoff_test.dart \
      test/receipt_camera_oversized_stitch_handoff_test.dart \
      test/receipt_camera_phase6_stitching_handoff_contract_test.dart \
      test/receipt_camera_result_stitch_handoff_followthrough_test.dart \
      -r compact
    echo "Receipt stitch handoff health: PASS"
    ;;
  duplicates)
    echo "Receipt stitch duplicate-section health"
    flutter test \
      test/receipt_stitching_duplicate_safety_test.dart \
      -r compact
    echo "Receipt stitch duplicate-section health: PASS"
    ;;
  milestone)
    "$0" edge_cases
    "$0" long_stack
    "$0" duplicates
    "$0" handoff
    echo "Receipt stitch milestone health: PASS"
    ;;
  full)
    echo "Receipt stitch contract health"
    flutter test \
      test/receipt_native_camera_session_limits_test.dart \
      test/receipt_capture_flow_shareability_test.dart \
      test/receipt_camera_phase5_long_receipt_contract_test.dart \
      test/receipt_stitching_test.dart \
      test/receipt_stitching_manual_overlap_test.dart \
      test/receipt_stitching_duplicate_safety_test.dart \
      test/receipt_stitching_scale_rotation_test.dart \
      test/receipt_stitching_horizontal_placement_test.dart \
      test/receipt_stitching_horizontal_drift_test.dart \
      test/receipt_stitching_worn_receipt_test.dart \
      test/receipt_stitching_long_stack_test.dart \
      test/receipt_stitching_variants_test.dart \
      test/receipt_stitching_weak_overlap_safety_test.dart \
      test/receipt_camera_result_stitch_scanner_test.dart \
      test/receipt_camera_low_confidence_stack_handoff_test.dart \
      test/receipt_camera_oversized_stitch_handoff_test.dart \
      test/receipt_camera_phase6_stitching_handoff_contract_test.dart \
      test/receipt_camera_result_stitch_handoff_followthrough_test.dart \
      -r compact
    echo "Receipt stitch contract health: PASS"
    ;;
  *)
    echo "Usage: $0 [delayed_overlap|edge_cases|long_stack|handoff|duplicates|milestone|full]" >&2
    exit 64
    ;;
esac
