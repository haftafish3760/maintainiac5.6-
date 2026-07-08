#!/usr/bin/env bash
set -euo pipefail

detached=false
print_mode=false
print_tests=false
while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --detached)
      detached=true
      shift
      ;;
    --print-mode)
      print_mode=true
      shift
      ;;
    --print-tests)
      print_tests=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -ne 0 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_camera_changed_gate.sh [--detached] [--print-mode]
       tool/receipt_camera_changed_gate.sh [--print-tests]

Runs the smallest safe receipt camera QA mode for tracked camera-lane changes.
Untracked files are intentionally ignored so unrelated handoff drafts do not
force camera QA. Use --detached to start the chosen gate without log streaming.
Use --print-mode for contract tests that prove mode routing without running QA.
Use --print-tests to print the exact targeted test pack for the selected mode.
USAGE
  exit 64
fi

if [[ -n "${RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST:-}" ]]; then
  changed_files="$RECEIPT_CAMERA_CHANGED_FILES_FOR_TEST"
else
  bash tool/receipt_camera_scope_gate.sh
  changed_files="$(
    git diff --name-only --diff-filter=ACMRTUXB HEAD --
    git diff --name-only --cached --diff-filter=ACMRTUXB --
  )"
fi

if [[ -z "${changed_files//[$'\n'[:space:]]/}" ]]; then
  echo "Receipt camera changed gate: no tracked camera changes; skipping QA rerun."
  exit 0
fi

mode="quick"
targeted_tests=()
exact_targeted=true
while IFS= read -r path; do
  [[ -z "$path" ]] && continue

  case "$path" in
    lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="phase2"
      fi
      targeted_tests+=(
        test/receipt_import_source_sheet_test.dart
      )
      ;;
    lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="phase2"
      fi
      targeted_tests+=(
        test/receipt_import_source_sheet_test.dart
      )
      ;;
    lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="phase2"
      fi
      targeted_tests+=(
        test/receipt_capture_flow_assist_opt_in_contract_test.dart
      )
      ;;
    lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart | \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart | \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart | \
    lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart | \
    lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart | \
    lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart | \
    lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart)
      targeted_tests+=(
        test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart
        test/receipt_camera_attachment_helper_parity_test.dart
      )
      ;;
    lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="phase2"
      fi
      targeted_tests+=(
        test/receipt_capture_flow_assist_opt_in_contract_test.dart
      )
      ;;
    docs/receipt_camera_ocr_master_pass_plan.md | \
    docs/receipt_camera_completion_map.md | \
    docs/receipt_camera_ocr_pipeline_handoff_report.md | \
    docs/receipt_camera_release_one_blueprint.md | \
    docs/receipt_camera_world_class_readiness.md | \
    docs/receipt_real_device_test_script.md | \
    docs/receipt_real_device_result_template.md | \
    docs/receipt_native_camera_service_spec.md | \
    docs/receipt_camera_ocr_product_standard.md | \
    docs/receipt_camera_roadmap.md | \
    PROJECT_RULES.md | \
    README.md | \
    tool/receipt_camera_real_device_snapshot.sh | \
    tool/receipt_real_device_matrix_gate.dart | \
    tool/receipt_real_device_result_gate.dart | \
    tool/receipt_real_device_result_start.sh | \
    test/receipt_real_device_matrix_gate_test.dart | \
    test/receipt_real_device_result_gate_test.dart | \
    test/receipt_real_device_result_start_script_test.dart | \
    test/receipt_camera_active_phase_docs_test.dart | \
    test/receipt_camera_completion_map_test.dart | \
    test/receipt_camera_pipeline_handoff_status_test.dart | \
    test/receipt_camera_release_one_blueprint_test.dart | \
    test/receipt_camera_release_control_priority_test.dart | \
    test/receipt_camera_native_baseline_policy_test.dart | \
    test/receipt_real_device_test_script_test.dart | \
    test/receipt_camera_world_class_readiness_test.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="phase9"
      fi
      targeted_tests+=(
        test/receipt_camera_active_phase_docs_test.dart
        test/receipt_camera_completion_map_test.dart
        test/receipt_camera_pipeline_handoff_status_test.dart
        test/receipt_camera_release_one_blueprint_test.dart
        test/receipt_camera_release_control_priority_test.dart
        test/receipt_camera_native_baseline_policy_test.dart
        test/receipt_real_device_matrix_gate_test.dart
        test/receipt_camera_real_device_snapshot_contract_test.dart
        test/receipt_real_device_result_gate_test.dart
        test/receipt_real_device_result_start_script_test.dart
        test/receipt_real_device_test_script_test.dart
        test/receipt_camera_world_class_readiness_test.dart
      )
      ;;
    lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart | \
    lib/shared/widgets/receipt_capture/receipt_capture_stitch_model_helpers.dart | \
    lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart | \
    lib/shared/widgets/receipt_capture/receipt_image_processor_storage_helpers.dart | \
    lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="phase6"
      fi
      targeted_tests+=(
        test/receipt_camera_phase6_stitching_handoff_contract_test.dart
      )
      ;;
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart | \
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart | \
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart | \
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart | \
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="phase3"
      fi
      targeted_tests+=(
        test/receipt_camera_phase3_viewer_contract_test.dart
      )
      ;;
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraUiChrome.kt | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControlReadiness.kt | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsLabels.kt | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPreviousSectionGuide.kt)
      if [[ "$mode" == "quick" ]]; then
        mode="phase3"
      fi
      targeted_tests+=(
        test/receipt_camera_phase3_viewer_contract_test.dart
        test/receipt_native_android_bridge_ui_contract_test.dart
      )
      ;;
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraFraming.kt | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraAnalysis.kt | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraLiveReadabilitySignals.kt)
      if [[ "$mode" == "quick" ]]; then
        mode="phase3"
      fi
      targeted_tests+=(
        test/receipt_native_android_guidance_policy_gate_test.dart
        test/receipt_native_android_bridge_false_positive_guard_test.dart
      )
      ;;
    ios/Runner/ReceiptCameraViewController.swift | \
    ios/Runner/ReceiptCameraViewControllerLayout.swift | \
    ios/Runner/ReceiptCameraViewControllerControls.swift | \
    ios/Runner/ReceiptCameraViewControllerLabels.swift | \
    ios/Runner/ReceiptCameraViewControllerPreviousSectionGuide.swift)
      if [[ "$mode" == "quick" ]]; then
        mode="phase3"
      fi
      targeted_tests+=(
        test/receipt_camera_phase3_viewer_contract_test.dart
        test/receipt_native_ios_bridge_ui_session_test.dart
      )
      ;;
    ios/Runner/ReceiptCameraViewControllerLiveFrameAnalysis.swift | \
    ios/Runner/ReceiptCameraViewControllerLiveReadability.swift)
      if [[ "$mode" == "quick" ]]; then
        mode="phase3"
      fi
      targeted_tests+=(
        test/receipt_native_ios_guidance_warning_gate_test.dart
      )
      ;;
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt)
      targeted_tests+=(
        test/receipt_native_android_bridge_settings_quality_test.dart
      )
      ;;
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraControls.kt)
      targeted_tests+=(
        test/receipt_native_android_bridge_close_controls_test.dart
      )
      ;;
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraFraming.kt)
      targeted_tests+=(
        test/receipt_native_android_bridge_settings_quality_test.dart
      )
      ;;
    ios/Runner/ReceiptCameraViewControllerSessionSettings.swift)
      targeted_tests+=(
        test/receipt_native_ios_bridge_settings_close_test.dart
      )
      ;;
    ios/Runner/ReceiptCameraViewControllerLabels.swift)
      targeted_tests+=(
        test/receipt_native_ios_bridge_ui_session_test.dart
      )
      ;;
    ios/Runner/ReceiptCameraViewControllerLiveFrameAnalysis.swift)
      targeted_tests+=(
        test/receipt_native_ios_bridge_analysis_exposure_test.dart
      )
      ;;
    *)
      exact_targeted=false
      ;;
  esac

  case "$path" in
    android/app/src/main/kotlin/com/maintainiac/MainActivity.kt | \
    ios/Runner/AppDelegate.swift)
      mode="full"
      break
      ;;
  esac

  case "$path" in
    tool/receipt_camera_qa_gate.sh | \
    tool/receipt_camera_changed_gate.sh | \
    tool/receipt_camera_scope_gate.sh | \
    tool/receipt_camera_changed_route_coverage_gate.dart | \
    tool/receipt_camera_qa_summary.sh | \
    tool/receipt_fast_guard_gate.sh | \
    tool/receipt_external_dataset_local_audit.dart | \
    tool/receipt_external_dataset_gate.dart | \
    tool/receipt_external_fixture_schema_gate.dart | \
    tool/receipt_start_camera_qa_gate.sh | \
    tool/receipt_quiet_batch.sh | \
    tool/receipt_quiet_batch_status.sh | \
    test/receipt_camera_changed_gate_contract_test.dart | \
    test/receipt_camera_dataset_qa_gate_contract_test.dart | \
    test/receipt_camera_changed_route_coverage_gate_test.dart | \
    test/receipt_camera_qa_gate_contract_test.dart | \
    test/receipt_camera_qa_gate_execution_test.dart | \
    test/receipt_camera_qa_gate_execution_runtime_test.dart | \
    test/receipt_external_dataset_local_audit_test.dart | \
    test/receipt_external_dataset_gate_test.dart | \
    test/receipt_external_fixture_schema_gate_test.dart | \
    test/receipt_fast_guard_gate_contract_test.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="milestone"
      fi
      ;;
  esac

  case "$path" in
    android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt | \
    ios/Runner/ReceiptCamera*.swift | \
    lib/shared/widgets/receipt_capture/*native* | \
    lib/shared/widgets/receipt_capture/*review* | \
    lib/shared/widgets/receipt_capture/*handoff* | \
    test/receipt_native_* | \
    test/receipt_camera_result_* | \
    test/receipt_camera_ocr_source_handoff_test.dart)
      if [[ "$mode" == "quick" ]]; then
        mode="milestone"
      fi
      ;;
  esac

  case "$path" in
    lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart | \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart | \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart | \
    lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart | \
    lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart | \
    lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart | \
    lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart | \
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt | \
    ios/Runner/ReceiptCameraViewControllerSessionSettings.swift | \
    ios/Runner/ReceiptCameraViewControllerSettingsCopy.swift | \
    test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart | \
    test/receipt_camera_phase8_storage_proof_timing_contract_test.dart | \
    test/receipt_camera_result_stitch_handoff_followthrough_test.dart | \
    test/receipt_camera_result_review_resume_test.dart | \
    test/receipt_ocr_source_* | \
    test/receipt_ocr_source_relationship_test.dart | \
    test/receipt_native_camera_phase8_storage_timing_test.dart)
      if [[ "$mode" == "quick" || "$mode" == "phase3" || "$mode" == "milestone" || "$mode" == "stitch" || "$mode" == "phase6" ]]; then
        mode="core_remaining"
      fi
      ;;
  esac

  case "$path" in
    lib/shared/widgets/receipt_capture/*stitch* | \
    lib/shared/receipts/*stitch* | \
    test/helpers/receipt_stitching_* | \
    test/receipt_stitching_* | \
    test/receipt_stitch_fallback_metadata_test.dart | \
    test/receipt_camera_result_stitch_scanner_test.dart | \
    test/receipt_ocr_source_* | \
    test/receipt_ocr_source_relationship_test.dart | \
    tool/receipt_camera_stitch_gate.sh)
      if [[ "$mode" == "quick" ]]; then
        mode="stitch"
      fi
      ;;
  esac
done <<< "$changed_files"

echo "Receipt camera changed gate: selected $mode for tracked camera changes."

if [[ "$print_mode" == "true" ]]; then
  exit 0
fi

if [[ "$print_tests" == "true" ]]; then
  if [[ "$exact_targeted" == "true" && "${#targeted_tests[@]}" -gt 0 ]]; then
    echo "mode=$mode"
    printf '%s\n' "${targeted_tests[@]}" | awk '!seen[$0]++ { print "targeted " $0 }'
    exit 0
  fi
  exec bash tool/receipt_camera_qa_gate.sh --print-plan "$mode"
fi

if [[ "$detached" == "true" ]]; then
  exec bash tool/receipt_start_camera_qa_gate.sh "$mode"
fi

exec bash tool/receipt_camera_qa_gate.sh "$mode"
