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
  local timeout_seconds="${RECEIPT_STITCH_TEST_TIMEOUT_SECONDS:-600}"
  flutter test "$@" -r compact > "$tmp" 2>&1 &
  local test_pid=$!
  (
    sleep "$timeout_seconds"
    if kill -0 "$test_pid" 2>/dev/null; then
      echo "Receipt stitch $label timed out after ${timeout_seconds}s." >> "$tmp"
      kill "$test_pid" 2>/dev/null || true
    fi
  ) &
  local watchdog_pid=$!
  set +e
  wait "$test_pid"
  local exit_code=$?
  set -e
  kill "$watchdog_pid" 2>/dev/null || true
  wait "$watchdog_pid" 2>/dev/null || true
  if [[ "$exit_code" -eq 0 ]]; then
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
    test/receipt_stitching_size_cap_test.dart \
    test/receipt_stitching_horizontal_placement_test.dart \
    test/receipt_stitching_horizontal_drift_test.dart \
    test/receipt_stitching_worn_receipt_test.dart \
    test/receipt_stitching_weak_overlap_safety_test.dart \
    --name 'delayed overlap|stronger handheld rotation|rough handheld rotation|combined scale rotation and drift|mixed handheld transforms|output dimensions|output pixel cap|horizontal drift correction|auto-cropped sideways continuation|blurred continuation overlap|wider handheld horizontal drift|cumulative horizontal drift|faded worn receipt sections|changed brightness|dimmed continuation|wrinkled receipt sections|multi-section wrinkled long receipt|crops delayed-overlap top strip|continuation edge is clipped|severely cropped|vertical edges are clipped|faded receipt sections when continuation edge is clipped|missing middle section|middle section is missing|reverse order|boilerplate footer bands' \
    --concurrency=1
  echo "Receipt stitch edge-case health: PASS"
}

run_size_caps() {
  echo "Receipt stitch size-cap health"
  run_flutter_test size-cap test/receipt_stitching_size_cap_test.dart
  echo "Receipt stitch size-cap health: PASS"
}

run_phone_windows() {
  echo "Receipt stitch phone-window health"
  run_flutter_test phone-window \
    test/receipt_stitching_long_stack_test.dart \
    test/receipt_stitching_phone_window_safety_test.dart \
    test/receipt_stitching_uploaded_screenshot_test.dart \
    test/receipt_stitching_phone_window_edge_crop_test.dart \
    --name 'phone-window captures|mixed exposure and side crops|clipped vertical edges|tight-overlap phone windows with alternating vertical edge clips|skipped phone-window|out-of-order phone-window|dark display borders|status and nav bars|uploaded long-receipt screenshots|eleven-section|ugly seven-section|ragged phone-window|tight-overlap phone-window' \
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

run_transformed_phone_windows() {
  echo "Receipt stitch transformed-phone-window health"
  run_flutter_test transformed-phone-window \
    test/receipt_stitching_transformed_phone_window_test.dart
  echo "Receipt stitch transformed-phone-window health: PASS"
}

run_long_stack() {
  echo "Receipt stitch long-stack health"
  run_flutter_test long-stack test/receipt_stitching_long_stack_test.dart
  echo "Receipt stitch long-stack health: PASS"
}

run_extreme_aspect_ratio() {
  echo "Receipt stitch extreme-aspect-ratio health"
  run_flutter_test extreme-aspect-ratio \
    test/receipt_stitching_extreme_aspect_ratio_test.dart
  echo "Receipt stitch extreme-aspect-ratio health: PASS"
}

run_duplicates() {
  echo "Receipt stitch duplicate-section health"
  run_flutter_test duplicate-section test/receipt_stitching_duplicate_safety_test.dart
  echo "Receipt stitch duplicate-section health: PASS"
}

run_ugly_long_receipts() {
  echo "Receipt stitch ugly-long-receipt health"
  run_flutter_test ugly-long-receipt \
    test/receipt_stitching_ugly_long_receipt_test.dart \
    test/receipt_stitching_store_receipt_shape_test.dart
  echo "Receipt stitch ugly-long-receipt health: PASS"
}

run_transformed_ugly_receipts() {
  echo "Receipt stitch transformed-ugly-receipt health"
  run_flutter_test transformed-ugly-receipt \
    test/receipt_stitching_ugly_long_receipt_test.dart \
    --plain-name 'stitches dark-framed receipt photos with scale and rotation drift'
  echo "Receipt stitch transformed-ugly-receipt health: PASS"
}

run_store_receipt_shape() {
  echo "Receipt stitch store-receipt-shape health"
  run_flutter_test store-receipt-shape \
    test/receipt_stitching_store_receipt_shape_test.dart
  echo "Receipt stitch store-receipt-shape health: PASS"
}

run_uploaded_screenshots() {
  echo "Receipt stitch uploaded-screenshot health"
  run_flutter_test uploaded-screenshot \
    test/receipt_stitching_uploaded_screenshot_test.dart
  echo "Receipt stitch uploaded-screenshot health: PASS"
}

run_section_order() {
  echo "Receipt stitch section-order health"
  run_flutter_test section-order \
    test/receipt_photo_review_retake_order_test.dart \
    test/receipt_camera_result_section_order_test.dart \
    test/receipt_camera_result_section_order_follow_through_test.dart \
    test/receipt_camera_result_section_order_invalid_context_test.dart
  echo "Receipt stitch section-order health: PASS"
}

run_bad_inputs() {
  echo "Receipt stitch bad-input health"
  run_flutter_test bad-input test/receipt_stitching_bad_input_test.dart
  echo "Receipt stitch bad-input health: PASS"
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
    test/receipt_continuation_ghost_handoff_contract_test.dart \
    test/receipt_stitch_fallback_metadata_test.dart \
    test/receipt_stitching_artifact_copy_contract_test.dart \
    test/receipt_stitching_result_contract_test.dart \
    test/receipt_stitching_ocr_source_contract_test.dart
  echo "Receipt stitch handoff health: PASS"
}

run_ghost_handoff() {
  echo "Receipt stitch ghost-handoff health"
  run_flutter_test ghost-handoff \
    test/receipt_continuation_ghost_handoff_contract_test.dart \
    test/receipt_camera_result_continuation_handoff_test.dart \
    test/receipt_capture_flow_shareability_test.dart
  echo "Receipt stitch ghost-handoff health: PASS"
}

run_synthetic_dataset() {
  echo "Receipt stitch synthetic-dataset health"
  run_flutter_test synthetic-dataset \
    test/receipt_synthetic_stitch_dataset_audit_test.dart
  echo "Receipt stitch synthetic-dataset health: PASS"
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
    tool/receipt_synthetic_stitch_dataset_audit.dart
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
    test/receipt_synthetic_stitch_dataset_audit_test.dart
    test/receipt_stitch_fallback_metadata_test.dart
    test/receipt_camera_low_confidence_stack_handoff_test.dart
    test/receipt_camera_oversized_stitch_handoff_test.dart
    test/receipt_camera_phase6_stitching_handoff_contract_test.dart
    test/receipt_camera_result_stitch_handoff_followthrough_test.dart
    test/receipt_camera_stitch_candidate_metadata_test.dart
    test/receipt_native_camera_session_limits_test.dart
    test/receipt_photo_review_retake_order_test.dart
    test/receipt_camera_result_section_order_test.dart
    test/receipt_camera_result_section_order_follow_through_test.dart
    test/receipt_camera_result_section_order_invalid_context_test.dart
    test/receipt_continuation_ghost_handoff_contract_test.dart
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
  run_size_caps
  run_phone_windows
  run_transformed_phone_windows
  run_long_stack
  run_ugly_long_receipts
  run_section_order
  run_bad_inputs
  run_manual_overlap
  run_duplicates
  run_handoff
  echo "Receipt stitch milestone health: PASS"
}

run_fast() {
  run_source_size
  run_bad_inputs
  run_phone_windows_fast
  echo "Receipt stitch fast health: PASS"
}

run_core_stitch() {
  run_source_size
  run_long_stack
  run_ugly_long_receipts
  run_transformed_phone_windows
  run_uploaded_screenshots
  run_size_caps
  run_bad_inputs
  run_manual_overlap
  run_duplicates
  run_section_order
  run_ghost_handoff
  run_handoff
  echo "Receipt stitch core health: PASS"
}

run_full() {
  echo "Receipt stitch contract health"
  run_source_size
  run_flutter_test full \
    test/receipt_native_camera_session_limits_test.dart \
    test/receipt_capture_flow_shareability_test.dart \
    test/receipt_camera_phase5_long_receipt_contract_test.dart \
    test/receipt_photo_review_retake_order_test.dart \
    test/receipt_camera_result_section_order_test.dart \
    test/receipt_camera_result_section_order_follow_through_test.dart \
    test/receipt_camera_result_section_order_invalid_context_test.dart \
    test/receipt_stitching_test.dart \
    test/receipt_stitching_artifact_copy_contract_test.dart \
    test/receipt_stitching_result_contract_test.dart \
    test/receipt_stitching_manual_overlap_test.dart \
    test/receipt_stitching_duplicate_safety_test.dart \
    test/receipt_stitching_ocr_source_contract_test.dart \
    test/receipt_stitching_scale_rotation_test.dart \
    test/receipt_stitching_size_cap_test.dart \
    test/receipt_stitching_horizontal_placement_test.dart \
    test/receipt_stitching_horizontal_drift_test.dart \
    test/receipt_stitching_worn_receipt_test.dart \
    test/receipt_stitching_ugly_long_receipt_test.dart \
    test/receipt_stitching_store_receipt_shape_test.dart \
    test/receipt_stitching_long_stack_test.dart \
    test/receipt_stitching_phone_window_edge_crop_test.dart \
    test/receipt_stitching_uploaded_screenshot_test.dart \
    test/receipt_stitching_variants_test.dart \
    test/receipt_stitching_weak_overlap_safety_test.dart \
    test/receipt_camera_result_stitch_scanner_test.dart \
    test/receipt_camera_low_confidence_stack_handoff_test.dart \
    test/receipt_camera_oversized_stitch_handoff_test.dart \
    test/receipt_camera_phase6_stitching_handoff_contract_test.dart \
    test/receipt_camera_result_stitch_handoff_followthrough_test.dart \
    test/receipt_camera_stitch_candidate_metadata_test.dart \
    test/receipt_continuation_ghost_handoff_contract_test.dart \
    test/receipt_stitch_fallback_metadata_test.dart
  echo "Receipt stitch contract health: PASS"
}

case "$mode" in
  delayed_overlap) run_delayed_overlap; exit 0 ;;
  edge_cases) run_edge_cases; exit 0 ;;
  size_caps) run_size_caps; exit 0 ;;
  phone_windows) run_phone_windows; exit 0 ;;
  phone_windows_fast) run_phone_windows_fast; exit 0 ;;
  transformed_phone_windows) run_transformed_phone_windows; exit 0 ;;
  long_stack) run_long_stack; exit 0 ;;
  extreme_aspect_ratio) run_extreme_aspect_ratio; exit 0 ;;
  ugly_long_receipts) run_ugly_long_receipts; exit 0 ;;
  transformed_ugly_receipts) run_transformed_ugly_receipts; exit 0 ;;
  store_receipt_shape) run_store_receipt_shape; exit 0 ;;
  uploaded_screenshots) run_uploaded_screenshots; exit 0 ;;
  section_order) run_section_order; exit 0 ;;
  bad_inputs) run_bad_inputs; exit 0 ;;
  manual_overlap) run_manual_overlap; exit 0 ;;
  duplicates) run_duplicates; exit 0 ;;
  handoff) run_handoff; exit 0 ;;
  ghost_handoff) run_ghost_handoff; exit 0 ;;
  synthetic_dataset) run_synthetic_dataset; exit 0 ;;
  source_size) run_source_size; exit 0 ;;
  fast) run_fast; exit 0 ;;
  core) run_core_stitch; exit 0 ;;
  milestone) run_milestone; exit 0 ;;
  full) run_full; exit 0 ;;
  *)
    echo "Usage: $0 [delayed_overlap|edge_cases|size_caps|phone_windows|phone_windows_fast|transformed_phone_windows|long_stack|extreme_aspect_ratio|ugly_long_receipts|transformed_ugly_receipts|store_receipt_shape|uploaded_screenshots|section_order|bad_inputs|manual_overlap|duplicates|handoff|ghost_handoff|synthetic_dataset|source_size|fast|core|milestone|full]" >&2
    exit 64
    ;;
esac
