#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

mode="${1:-full}"

run_flutter_test() {
  local label="$1"
  shift
  local tmp
  tmp="$(mktemp -t maintainiac_receipt_stitch_${label//[^A-Za-z0-9]/_}.XXXXXX)"
  if flutter test "$@" -r compact > "$tmp" 2>&1; then
    if perl -pe 's/\r/\n/g' "$tmp" | grep -q 'Some tests failed'; then
      echo "Receipt stitch $label reported failed tests despite a zero exit code. Log tail:" >&2
      perl -pe 's/\r/\n/g' "$tmp" | tail -n 180 >&2
      rm -f "$tmp"
      return 1
    fi
    perl -pe 's/\r/\n/g' "$tmp" | grep -E 'All tests passed|Some tests failed' | tail -n 3
    rm -f "$tmp"
    return 0
  fi
  local exit_code=$?
  echo "Receipt stitch $label failed. Log tail:" >&2
  perl -pe 's/\r/\n/g' "$tmp" | tail -n 180 >&2
  rm -f "$tmp"
  return "$exit_code"
}

run_delayed_overlap() {
  echo "Receipt stitch delayed-overlap health"
  run_flutter_test delayed-overlap \
    test/receipt_stitching_variants_test.dart \
    --name 'delayed overlap'
  echo "Receipt stitch delayed-overlap health: PASS"
}

run_edge_cases() {
  echo "Receipt stitch edge-case health"
  run_flutter_test edge-case \
    test/receipt_stitching_variants_test.dart \
    test/receipt_stitching_scale_rotation_test.dart \
    test/receipt_stitching_horizontal_placement_test.dart \
    test/receipt_stitching_horizontal_drift_test.dart \
    test/receipt_stitching_worn_receipt_test.dart \
    test/receipt_stitching_weak_overlap_safety_test.dart \
    --name 'delayed overlap|stronger handheld rotation|combined scale rotation and drift|horizontal drift correction|auto-cropped sideways continuation|blurred continuation overlap|wider handheld horizontal drift|faded worn receipt sections|changed brightness|dimmed continuation|crops delayed-overlap top strip|continuation edge is clipped|severely cropped|vertical edges are clipped|faded receipt sections when continuation edge is clipped|missing middle section|middle section is missing|reverse order|boilerplate footer bands' \
    --concurrency=1
  echo "Receipt stitch edge-case health: PASS"
}

run_phone_windows() {
  echo "Receipt stitch phone-window health"
  run_flutter_test phone-window \
    test/receipt_stitching_long_stack_test.dart \
    test/receipt_stitching_phone_window_safety_test.dart \
    test/receipt_stitching_phone_window_edge_crop_test.dart \
    --name 'phone-window captures|mixed exposure and side crops|clipped vertical edges|skipped phone-window|out-of-order phone-window|dark display borders|status and nav bars|eleven-section|ugly seven-section|ragged phone-window' \
    --concurrency=1
  echo "Receipt stitch phone-window health: PASS"
}

run_phone_windows_fast() {
  echo "Receipt stitch phone-window fast health"
  run_flutter_test phone-window-fast \
    test/receipt_stitching_phone_window_safety_test.dart \
    --name 'skipped phone-window|out-of-order phone-window|dark display borders|status and nav bars' \
    --concurrency=1
  echo "Receipt stitch phone-window fast health: PASS"
}

run_long_stack() {
  echo "Receipt stitch long-stack health"
  run_flutter_test long-stack test/receipt_stitching_long_stack_test.dart
  echo "Receipt stitch long-stack health: PASS"
}

run_duplicates() {
  echo "Receipt stitch duplicate-section health"
  run_flutter_test duplicate-section test/receipt_stitching_duplicate_safety_test.dart
  echo "Receipt stitch duplicate-section health: PASS"
}

run_manual_overlap() {
  echo "Receipt stitch manual-overlap health"
  run_flutter_test manual-overlap test/receipt_stitching_manual_overlap_test.dart
  echo "Receipt stitch manual-overlap health: PASS"
}

run_handoff() {
  echo "Receipt stitch handoff health"
  run_flutter_test handoff \
    test/receipt_camera_phase5_long_receipt_contract_test.dart \
    test/receipt_camera_low_confidence_stack_handoff_test.dart \
    test/receipt_camera_oversized_stitch_handoff_test.dart \
    test/receipt_camera_phase6_stitching_handoff_contract_test.dart \
    test/receipt_camera_result_stitch_handoff_followthrough_test.dart \
    test/receipt_camera_stitch_candidate_metadata_test.dart \
    test/receipt_stitch_fallback_metadata_test.dart \
    test/receipt_stitching_ocr_source_contract_test.dart
  echo "Receipt stitch handoff health: PASS"
}

run_source_size() {
  echo "Receipt stitch source-size health"
  local max_lines=500
  local files=(
    lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart
    lib/shared/widgets/receipt_capture/receipt_capture_stitch_pair_models.dart
    lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart
    lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_helpers.dart
    lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_scoring_helpers.dart
    lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_transform_helpers.dart
  )
  local file
  for file in "${files[@]}"; do
    local lines
    lines="$(wc -l < "$file" | tr -d ' ')"
    if [[ "$lines" -gt "$max_lines" ]]; then
      echo "$file: $lines lines exceeds $max_lines-line stitch source cap." >&2
      exit 1
    fi
  done
  local test_files=(
    test/helpers/receipt_stitching_image_helpers.dart
    test/receipt_stitching_*_test.dart
    test/receipt_stitch_fallback_metadata_test.dart
    test/receipt_camera_low_confidence_stack_handoff_test.dart
    test/receipt_camera_oversized_stitch_handoff_test.dart
    test/receipt_camera_phase6_stitching_handoff_contract_test.dart
    test/receipt_camera_result_stitch_handoff_followthrough_test.dart
    test/receipt_camera_stitch_candidate_metadata_test.dart
  )
  for file in "${test_files[@]}"; do
    local lines
    lines="$(wc -l < "$file" | tr -d ' ')"
    if [[ "$lines" -gt "$max_lines" ]]; then
      echo "$file: $lines lines exceeds $max_lines-line stitch test cap." >&2
      exit 1
    fi
  done
  echo "Receipt stitch source-size health: PASS"
}

run_milestone() {
  run_source_size
  run_edge_cases
  run_phone_windows
  run_long_stack
  run_manual_overlap
  run_duplicates
  run_handoff
  echo "Receipt stitch milestone health: PASS"
}

run_full() {
  echo "Receipt stitch contract health"
  run_source_size
  run_flutter_test full \
    test/receipt_native_camera_session_limits_test.dart \
    test/receipt_capture_flow_shareability_test.dart \
    test/receipt_camera_phase5_long_receipt_contract_test.dart \
    test/receipt_stitching_test.dart \
    test/receipt_stitching_manual_overlap_test.dart \
    test/receipt_stitching_duplicate_safety_test.dart \
    test/receipt_stitching_ocr_source_contract_test.dart \
    test/receipt_stitching_scale_rotation_test.dart \
    test/receipt_stitching_horizontal_placement_test.dart \
    test/receipt_stitching_horizontal_drift_test.dart \
    test/receipt_stitching_worn_receipt_test.dart \
    test/receipt_stitching_long_stack_test.dart \
    test/receipt_stitching_phone_window_edge_crop_test.dart \
    test/receipt_stitching_variants_test.dart \
    test/receipt_stitching_weak_overlap_safety_test.dart \
    test/receipt_camera_result_stitch_scanner_test.dart \
    test/receipt_camera_low_confidence_stack_handoff_test.dart \
    test/receipt_camera_oversized_stitch_handoff_test.dart \
    test/receipt_camera_phase6_stitching_handoff_contract_test.dart \
    test/receipt_camera_result_stitch_handoff_followthrough_test.dart \
    test/receipt_camera_stitch_candidate_metadata_test.dart \
    test/receipt_stitch_fallback_metadata_test.dart
  echo "Receipt stitch contract health: PASS"
}

case "$mode" in
  delayed_overlap) run_delayed_overlap; exit 0 ;;
  edge_cases) run_edge_cases; exit 0 ;;
  phone_windows) run_phone_windows; exit 0 ;;
  phone_windows_fast) run_phone_windows_fast; exit 0 ;;
  long_stack) run_long_stack; exit 0 ;;
  manual_overlap) run_manual_overlap; exit 0 ;;
  duplicates) run_duplicates; exit 0 ;;
  handoff) run_handoff; exit 0 ;;
  source_size) run_source_size; exit 0 ;;
  milestone) run_milestone; exit 0 ;;
  full) run_full; exit 0 ;;
  *)
    echo "Usage: $0 [delayed_overlap|edge_cases|phone_windows|phone_windows_fast|long_stack|manual_overlap|duplicates|handoff|source_size|milestone|full]" >&2
    exit 64
    ;;
esac
