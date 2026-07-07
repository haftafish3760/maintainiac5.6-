#!/usr/bin/env bash
set -euo pipefail

print_plan=false
if [[ "${1:-}" == "--print-plan" ]]; then
  print_plan=true
  shift
fi

mode="${1:-milestone}"

case "$mode" in
  quick | stitch | milestone | full) ;;
  *)
    echo "Usage: tool/receipt_camera_qa_gate.sh [--print-plan] [quick|stitch|milestone|full]" >&2
    exit 64
    ;;
esac

camera_source_roots=(
  lib/shared/widgets/receipt_capture
  lib/shared/receipts
  android/app/src/main/kotlin/com/maintainiac
  ios/Runner
)

quick_tests=(
  test/receipt_camera_coverage_decision_test.dart
  test/receipt_attachment_panel_recovery_contract_test.dart
  test/receipt_native_shell_recovery_contract_test.dart
  test/receipt_native_android_bridge_settings_quality_test.dart
  test/receipt_native_android_bridge_capture_quality_contract_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_external_dataset_gate_test.dart
  test/receipt_photo_section_labels_test.dart
  test/receipt_camera_real_device_snapshot_contract_test.dart
  test/receipt_camera_qa_gate_contract_test.dart
  test/receipt_camera_qa_gate_execution_test.dart
)

milestone_only_tests=(
  test/receipt_camera_capture_layout_test.dart
  test/receipt_camera_native_bridge_layout_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_camera_quality_guidance_test.dart
  test/receipt_camera_result_best_shot_ocr_test.dart
  test/receipt_camera_result_completion_coverage_test.dart
  test/receipt_camera_result_coverage_totals_test.dart
  test/receipt_camera_result_native_close_settings_test.dart
  test/receipt_camera_result_native_quality_test.dart
  test/receipt_camera_result_native_ui_health_test.dart
  test/receipt_camera_result_recovery_handoff_test.dart
  test/receipt_camera_result_stitch_scanner_test.dart
  test/receipt_camera_fixture_matrix_test.dart
  test/receipt_capture_flow_barcode_handoff_test.dart
  test/receipt_image_ocr_source_guard_test.dart
  test/receipt_ocr_source_relationship_test.dart
  test/receipt_native_android_import_hygiene_test.dart
  test/receipt_native_android_bridge_capture_flow_test.dart
  test/receipt_native_android_bridge_close_controls_test.dart
  test/receipt_native_android_bridge_diagnostics_storage_test.dart
  test/receipt_native_android_bridge_ui_contract_test.dart
  test/receipt_native_android_source_size_test.dart
  test/receipt_native_camera_contract_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
  test/receipt_native_camera_privacy_diagnostics_test.dart
  test/receipt_native_camera_result_rejection_test.dart
  test/receipt_native_camera_service_basics_test.dart
  test/receipt_native_camera_session_limits_test.dart
  test/receipt_native_camera_shell_test.dart
  test/receipt_native_camera_storage_contract_test.dart
  test/receipt_native_capture_staging_cleanup_test.dart
  test/receipt_native_capture_staging_test.dart
  test/receipt_native_ghost_warning_contract_test.dart
  test/receipt_native_ios_bridge_app_delegate_test.dart
  test/receipt_native_ios_bridge_exposure_shutter_contract_test.dart
  test/receipt_native_ios_bridge_long_receipt_quality_test.dart
  test/receipt_native_ios_bridge_settings_close_test.dart
  test/receipt_native_ios_bridge_storage_contract_test.dart
  test/receipt_native_ios_bridge_ui_session_test.dart
  test/receipt_photo_review_retake_order_test.dart
  test/receipt_stitch_fallback_metadata_test.dart
  test/receipt_stitching_manual_overlap_test.dart
  test/receipt_stitching_result_contract_test.dart
  test/receipt_stitching_test.dart
)

stitch_tests=(
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_camera_fixture_matrix_test.dart
  test/receipt_camera_result_stitch_scanner_test.dart
  test/receipt_capture_flow_barcode_handoff_test.dart
  test/receipt_ocr_source_relationship_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
  test/receipt_photo_section_labels_test.dart
  test/receipt_photo_review_retake_order_test.dart
  test/receipt_stitch_fallback_metadata_test.dart
  test/receipt_stitching_manual_overlap_test.dart
  test/receipt_stitching_result_contract_test.dart
  test/receipt_stitching_test.dart
)

full_only_tests=(
  test/receipt_camera_completion_map_test.dart
  test/receipt_camera_footprint_audit_test.dart
  test/receipt_camera_help_flow_test.dart
  test/receipt_camera_native_baseline_policy_test.dart
  test/receipt_camera_ocr_source_attachment_read_test.dart
  test/receipt_camera_release_control_priority_test.dart
  test/receipt_camera_release_one_blueprint_test.dart
  test/receipt_camera_result_auto_capture_contract_test.dart
  test/receipt_camera_result_continuation_handoff_test.dart
  test/receipt_camera_result_focus_contract_test.dart
  test/receipt_camera_result_frozen_brain_install_test.dart
  test/receipt_camera_result_frozen_handoff_counts_test.dart
  test/receipt_camera_result_frozen_metadata_brain_test.dart
  test/receipt_camera_result_frozen_metadata_counts_test.dart
  test/receipt_camera_result_frozen_metadata_routes_test.dart
  test/receipt_camera_result_frozen_metadata_tail_test.dart
  test/receipt_camera_result_native_ui_ready_test.dart
  test/receipt_camera_result_quality_test.dart
  test/receipt_camera_result_recovery_metadata_test.dart
  test/receipt_camera_result_retired_control_contract_test.dart
  test/receipt_camera_result_saved_photo_warning_test.dart
  test/receipt_camera_result_section_order_follow_through_test.dart
  test/receipt_camera_result_section_order_invalid_context_test.dart
  test/receipt_camera_result_section_order_test.dart
  test/receipt_camera_result_test.dart
  test/receipt_camera_saved_photo_warning_diagnostics_test.dart
  test/receipt_native_android_bridge_auto_capture_test.dart
  test/receipt_native_android_bridge_test.dart
  test/receipt_native_android_diagnostics_payload_test.dart
  test/receipt_native_android_guidance_policy_gate_test.dart
  test/receipt_native_camera_result_path_validation_test.dart
  test/receipt_native_camera_session_contract_test.dart
  test/receipt_native_capture_old_cleanup_test.dart
  test/receipt_native_capture_recovery_index_test.dart
  test/receipt_native_capture_recovery_record_test.dart
  test/receipt_native_ios_bridge_close_capture_test.dart
  test/receipt_native_ios_bridge_test.dart
  test/receipt_native_ios_diagnostics_payload_test.dart
  test/receipt_native_ios_guidance_warning_gate_test.dart
  test/receipt_native_ios_project_membership_test.dart
  test/receipt_native_android_bridge_analysis_exposure_test.dart
  test/receipt_native_ios_bridge_analysis_exposure_test.dart
  test/receipt_ocr_source_completion_test.dart
  test/receipt_ocr_source_section_order_handoff_test.dart
)

line_cap_paths=(
  "${camera_source_roots[@]}"
  "${quick_tests[@]}"
  "${milestone_only_tests[@]}"
  "${full_only_tests[@]}"
)

run_flutter_tests() {
  flutter test "$@" -r compact
}

print_test_pack() {
  local pack_name="$1"
  shift
  local test_path

  for test_path in "$@"; do
    printf '%s %s\n' "$pack_name" "$test_path"
  done
}

print_plan_for_mode() {
  echo "mode=$mode"
  case "$mode" in
    quick)
      print_test_pack quick "${quick_tests[@]}"
      ;;
    stitch)
      print_test_pack stitch "${stitch_tests[@]}"
      ;;
    milestone | full)
      print_test_pack quick "${quick_tests[@]}"
      print_test_pack milestone "${milestone_only_tests[@]}"
      if [[ "$mode" == "full" ]]; then
        print_test_pack full "${full_only_tests[@]}"
      fi
      ;;
  esac
}

if [[ "$print_plan" == "true" ]]; then
  print_plan_for_mode
  exit 0
fi

run_source_audit() {
  dart tool/maintainiac_source_audit.dart \
    "${camera_source_roots[@]}" \
    --max-line-length=220
}

run_line_cap_gate() {
  local failed=0
  local checked=0
  local path
  local file
  local line_count

  for path in "${line_cap_paths[@]}"; do
    if [[ -d "$path" ]]; then
      while IFS= read -r file; do
        line_count="$(wc -l < "$file" | tr -d ' ')"
        checked=$((checked + 1))
        if [[ "$line_count" -gt 500 ]]; then
          printf 'LINE_CAP_FAIL %s %s\n' "$line_count" "$file" >&2
          failed=1
        fi
      done < <(find "$path" -type f \( -name '*.dart' -o -name '*.kt' -o -name '*.swift' \) | sort)
      continue
    fi

    [[ -f "$path" ]] || continue
    line_count="$(wc -l < "$path" | tr -d ' ')"
    checked=$((checked + 1))
    if [[ "$line_count" -gt 500 ]]; then
      printf 'LINE_CAP_FAIL %s %s\n' "$line_count" "$path" >&2
      failed=1
    fi
  done

  echo "Camera line-cap gate checked $checked files."
  return "$failed"
}

run_stale_contract_scan() {
  local scan_roots=(
    lib/shared/widgets/receipt_capture
  )
  local pattern='Next will review|Next Reviews Top To Bottom|Before Next|Check Photo Before Next|tap Next|tapping Next|Icons.play_arrow_rounded|Use focus assist only if|continuous autofocus/readability guidance'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale camera wording or retired control contract found." >&2
    return 1
  fi
}

run_quick() {
  bash -n \
    tool/android_receipt_camera_compile_gate.sh \
    tool/ios_receipt_camera_compile_gate.sh \
    tool/receipt_camera_pipeline_gate.sh \
    tool/receipt_camera_changed_gate.sh \
    tool/receipt_camera_failure_to_regression.sh \
    tool/receipt_camera_qa_gate.sh \
    tool/receipt_camera_qa_summary.sh \
    tool/receipt_camera_real_device_snapshot.sh \
    tool/receipt_camera_scope_gate.sh \
    tool/receipt_camera_stitch_gate.sh \
    tool/receipt_start_camera_qa_gate.sh
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture \
    lib/shared/receipts \
    tool/receipt_external_dataset_gate.dart \
    tool/receipt_external_fixture_schema_gate.dart \
    tool/receipt_bug_regression_ledger_gate.dart
  dart tool/receipt_bug_regression_ledger_gate.dart
  dart tool/receipt_external_dataset_gate.dart
  dart tool/receipt_external_fixture_schema_gate.dart
  run_source_audit
  run_line_cap_gate
  run_stale_contract_scan
  run_flutter_tests "${quick_tests[@]}"
  git diff --check
}

run_stitch() {
  bash tool/receipt_camera_scope_gate.sh
  dart tool/receipt_bug_regression_ledger_gate.dart

  dart analyze \
    lib/shared/widgets/receipt_capture \
    lib/shared/receipts \
    tool/receipt_bug_regression_ledger_gate.dart \
    test/helpers/receipt_stitching_* \
    "${stitch_tests[@]}"
  run_flutter_tests "${stitch_tests[@]}"
  git diff --check
}

run_milestone() {
  run_quick
  run_flutter_tests "${milestone_only_tests[@]}"
}

run_full() {
  run_milestone
  run_flutter_tests "${full_only_tests[@]}"
  bash tool/receipt_camera_real_device_snapshot.sh
  bash tool/android_receipt_camera_compile_gate.sh
  bash tool/ios_receipt_camera_compile_gate.sh
}

case "$mode" in
  quick) run_quick ;;
  stitch) run_stitch ;;
  milestone) run_milestone ;;
  full) run_full ;;
esac
