#!/usr/bin/env bash
set -euo pipefail

print_plan=false
if [[ "${1:-}" == "--print-plan" ]]; then
  print_plan=true
  shift
fi

mode="${1:-milestone}"

case "$mode" in
  phase2 | phase3 | phase4 | phase5 | phase6 | phase7 | phase8 | phase9 | core_remaining | quick | stitch | milestone | full) ;;
  *)
    echo "Usage: tool/receipt_camera_qa_gate.sh [--print-plan] [phase2|phase3|phase4|phase5|phase6|phase7|phase8|phase9|core_remaining|quick|stitch|milestone|full]" >&2
    exit 64
    ;;
esac

camera_source_roots=(
  lib/shared/widgets/receipt_capture
  lib/shared/receipts
  android/app/src/main/kotlin/com/maintainiac/MainActivity.kt
  android/app/src/main/kotlin/com/maintainiac/ReceiptCamera*.kt
  ios/Runner/AppDelegate.swift
  ios/Runner/ReceiptCamera*.swift
)

phase2_tests=(
  test/receipt_import_source_sheet_test.dart
  test/receipt_capture_flow_assist_opt_in_contract_test.dart
  test/receipt_camera_capture_layout_test.dart
  test/receipt_capture_flow_handoff_order_test.dart
)

phase3_tests=(
  test/receipt_camera_phase3_viewer_contract_test.dart
  test/receipt_native_camera_shell_test.dart
  test/receipt_native_camera_shell_controls_test.dart
  test/receipt_native_ios_settings_guidance_contract_test.dart
  test/receipt_native_ios_camera_session_capability_test.dart
  test/receipt_native_ios_capture_format_test.dart
  test/receipt_native_android_guidance_policy_gate_test.dart
  test/receipt_native_ios_guidance_warning_gate_test.dart
  test/receipt_native_android_bridge_false_positive_guard_test.dart
  test/receipt_native_ios_bridge_false_positive_guard_test.dart
)

phase4_tests=(
  test/receipt_camera_phase4_review_contract_test.dart
  test/receipt_photo_review_exit_completion_test.dart
  test/receipt_photo_review_quality_handoff_test.dart
  test/receipt_photo_review_controls_layout_test.dart
  test/receipt_photo_review_crop_controls_layout_test.dart
  test/receipt_photo_review_continuation_copy_test.dart
  test/receipt_photo_section_labels_test.dart
)

phase5_tests=(
  test/receipt_camera_phase5_long_receipt_contract_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_photo_review_retake_order_test.dart
  test/receipt_photo_review_section_order_ops_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
)

phase6_tests=(
  test/receipt_camera_phase6_stitching_handoff_contract_test.dart
  test/receipt_stitch_fallback_metadata_test.dart
  test/receipt_stitching_manual_overlap_test.dart
  test/receipt_stitching_result_contract_test.dart
  test/receipt_stitching_variants_test.dart
)

phase7_tests=(
  test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_camera_attachment_helper_parity_test.dart
  test/receipt_capture_flow_ocr_source_count_test.dart
  test/receipt_image_ocr_source_guard_test.dart
  test/receipt_ocr_source_relationship_test.dart
  test/receipt_ocr_source_review_risks_test.dart
  test/receipt_ocr_source_section_order_handoff_test.dart
  test/receipt_camera_result_stitch_handoff_followthrough_test.dart
  test/receipt_camera_result_review_resume_test.dart
  test/receipt_image_source_prep_test.dart
  test/receipt_image_data_saver_test.dart
)

phase8_tests=(
  test/receipt_camera_phase8_storage_proof_timing_contract_test.dart
  test/receipt_native_camera_phase8_storage_timing_test.dart
)

phase9_tests=(
  test/receipt_camera_active_phase_docs_test.dart
  test/receipt_camera_completion_map_test.dart
  test/receipt_camera_pipeline_handoff_status_test.dart
  test/receipt_camera_release_one_blueprint_test.dart
  test/receipt_camera_release_control_priority_test.dart
  test/receipt_camera_native_baseline_policy_test.dart
  test/receipt_camera_real_device_snapshot_contract_test.dart
  test/receipt_real_device_matrix_gate_test.dart
  test/receipt_real_device_result_gate_test.dart
  test/receipt_real_device_result_start_script_test.dart
  test/receipt_real_device_test_script_test.dart
  test/receipt_camera_world_class_readiness_test.dart
)

core_remaining_tests=(
  "${phase6_tests[@]}"
  "${phase7_tests[@]}"
  "${phase8_tests[@]}"
)

phase2_audit_paths=(
  lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart
  lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart
  lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart
  test/receipt_import_source_sheet_test.dart
  test/receipt_capture_flow_assist_opt_in_contract_test.dart
  test/receipt_camera_capture_layout_test.dart
  test/receipt_capture_flow_handoff_order_test.dart
)

phase3_audit_paths=(
  lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart
  lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart
  lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart
  lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart
  lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart
  ios/Runner/ReceiptCameraViewControllerLabels.swift
  test/receipt_camera_phase3_viewer_contract_test.dart
  test/receipt_native_camera_shell_controls_test.dart
  test/receipt_native_ios_settings_guidance_contract_test.dart
  test/receipt_native_ios_camera_session_capability_test.dart
  test/receipt_native_android_guidance_policy_gate_test.dart
  test/receipt_native_ios_guidance_warning_gate_test.dart
  test/receipt_native_android_bridge_false_positive_guard_test.dart
  test/receipt_native_ios_bridge_false_positive_guard_test.dart
)

phase4_audit_paths=(
  lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_crop_controls.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_surface_controls.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_surfaces.dart
  lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart
  test/receipt_camera_phase4_review_contract_test.dart
  test/receipt_photo_review_exit_completion_test.dart
  test/receipt_photo_review_quality_handoff_test.dart
  test/receipt_photo_section_labels_test.dart
  test/receipt_photo_review_controls_layout_test.dart
  test/receipt_photo_review_crop_controls_layout_test.dart
  test/receipt_photo_review_continuation_copy_test.dart
)

phase5_audit_paths=(
  lib/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart
  lib/shared/widgets/receipt_capture/receipt_native_camera_session_ghost_guide.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart
  test/receipt_camera_phase5_long_receipt_contract_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_photo_review_retake_order_test.dart
  test/receipt_photo_review_section_order_ops_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
)

phase6_audit_paths=(
  lib/shared/widgets/receipt_capture/receipt_capture_models.dart
  lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart
  lib/shared/widgets/receipt_capture/receipt_capture_stitch_model_helpers.dart
  lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart
  lib/shared/widgets/receipt_capture/receipt_image_processor_storage_helpers.dart
  lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart
  test/receipt_camera_phase6_stitching_handoff_contract_test.dart
  test/receipt_stitch_fallback_metadata_test.dart
  test/receipt_stitching_manual_overlap_test.dart
  test/receipt_stitching_result_contract_test.dart
  test/receipt_stitching_variants_test.dart
)

phase7_audit_paths=(
  lib/shared/receipts/receipt_ocr_contract.dart
  lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart
  lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_continuation_signals.dart
  lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_continuation_flags.dart
  lib/shared/widgets/receipt_capture/receipt_image_processor.dart
  lib/shared/widgets/receipt_capture/receipt_image_processor_models.dart
  lib/shared/widgets/receipt_capture/receipt_image_processor_scan_helpers.dart
  test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_camera_attachment_helper_parity_test.dart
  test/receipt_capture_flow_ocr_source_count_test.dart
  test/receipt_image_ocr_source_guard_test.dart
  test/receipt_ocr_source_relationship_test.dart
  test/receipt_ocr_source_review_risks_test.dart
  test/receipt_ocr_source_section_order_handoff_test.dart
  test/receipt_camera_result_stitch_handoff_followthrough_test.dart
  test/receipt_camera_result_review_resume_test.dart
  test/receipt_image_source_prep_test.dart
  test/receipt_image_data_saver_test.dart
)

phase8_audit_paths=(
  lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart
  lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart
  android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt
  ios/Runner/ReceiptCameraViewControllerSessionSettings.swift
  ios/Runner/ReceiptCameraViewControllerSettingsCopy.swift
  test/receipt_camera_phase8_storage_proof_timing_contract_test.dart
  test/receipt_native_camera_phase8_storage_timing_test.dart
)

phase9_audit_paths=(
  docs/receipt_camera_ocr_master_pass_plan.md
  docs/receipt_camera_completion_map.md
  docs/receipt_camera_ocr_pipeline_handoff_report.md
  docs/receipt_camera_release_one_blueprint.md
  docs/receipt_camera_world_class_readiness.md
  docs/receipt_real_device_test_script.md
  docs/receipt_real_device_result_template.md
  tool/receipt_camera_real_device_snapshot.sh
  tool/receipt_real_device_matrix_gate.dart
  tool/receipt_real_device_result_gate.dart
  tool/receipt_real_device_result_start.sh
  docs/receipt_native_camera_service_spec.md
  docs/receipt_camera_ocr_product_standard.md
  PROJECT_RULES.md
  README.md
  test/receipt_camera_active_phase_docs_test.dart
  test/receipt_camera_completion_map_test.dart
  test/receipt_camera_pipeline_handoff_status_test.dart
  test/receipt_camera_release_one_blueprint_test.dart
  test/receipt_camera_release_control_priority_test.dart
  test/receipt_camera_native_baseline_policy_test.dart
  test/receipt_camera_real_device_snapshot_contract_test.dart
  test/receipt_real_device_test_script_test.dart
  test/receipt_real_device_result_gate_test.dart
  test/receipt_real_device_result_start_script_test.dart
  test/receipt_camera_world_class_readiness_test.dart
)

core_remaining_audit_paths=(
  docs/receipt_camera_completion_map.md
  "${phase6_audit_paths[@]}"
  "${phase7_audit_paths[@]}"
  "${phase8_audit_paths[@]}"
)

quick_tests=(
  test/receipt_camera_coverage_decision_test.dart
  test/receipt_attachment_panel_recovery_contract_test.dart
  test/receipt_native_shell_recovery_contract_test.dart
  test/receipt_native_android_bridge_settings_quality_test.dart
  test/receipt_native_android_bridge_capture_quality_contract_test.dart
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_capture_flow_assist_opt_in_contract_test.dart
  test/receipt_import_source_sheet_test.dart
  test/receipt_photo_review_exit_completion_test.dart
  test/receipt_photo_review_quality_handoff_test.dart
  test/receipt_external_dataset_local_audit_test.dart
  test/receipt_external_dataset_gate_test.dart
  test/receipt_external_fixture_schema_gate_test.dart
  test/receipt_photo_section_labels_test.dart
  test/receipt_camera_ios_native_asset_preflight_contract_test.dart
  test/receipt_camera_real_device_snapshot_contract_test.dart
  test/receipt_camera_changed_gate_script_contract_test.dart
  test/receipt_camera_changed_gate_contract_test.dart
  test/receipt_camera_changed_gate_native_contract_test.dart
  test/receipt_camera_changed_route_coverage_gate_test.dart
  test/receipt_camera_dataset_qa_gate_contract_test.dart
  test/receipt_camera_qa_gate_contract_test.dart
  test/receipt_camera_qa_gate_stitch_contract_test.dart
  test/receipt_camera_qa_gate_execution_test.dart
  test/receipt_camera_qa_gate_plan_coverage_test.dart
  test/receipt_camera_qa_gate_scope_and_failure_contract_test.dart
  test/receipt_camera_qa_gate_execution_runtime_test.dart
)

milestone_only_tests=(
  test/receipt_camera_capture_layout_test.dart
  test/receipt_camera_phase3_viewer_contract_test.dart
  test/receipt_camera_phase4_review_contract_test.dart
  test/receipt_camera_phase5_long_receipt_contract_test.dart
  test/receipt_camera_phase6_stitching_handoff_contract_test.dart
  test/receipt_camera_phase7_ocr_source_handoff_contract_test.dart
  test/receipt_camera_attachment_helper_parity_test.dart
  test/receipt_camera_phase8_storage_proof_timing_contract_test.dart
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
  test/receipt_camera_result_saved_photo_warning_test.dart
  test/receipt_camera_result_stitch_scanner_test.dart
  test/receipt_camera_result_stitch_handoff_followthrough_test.dart
  test/receipt_camera_result_review_resume_test.dart
  test/receipt_camera_fixture_matrix_test.dart
  test/receipt_capture_flow_barcode_handoff_test.dart
  test/receipt_capture_flow_ocr_source_count_test.dart
  test/receipt_image_ocr_source_guard_test.dart
  test/receipt_ocr_source_relationship_test.dart
  test/receipt_native_android_import_hygiene_test.dart
  test/receipt_native_android_bridge_capture_flow_test.dart
  test/receipt_native_android_bridge_false_positive_guard_test.dart
  test/receipt_native_android_bridge_close_controls_test.dart
  test/receipt_native_android_bridge_diagnostics_storage_test.dart
  test/receipt_native_android_bridge_ui_contract_test.dart
  test/receipt_native_android_guidance_policy_gate_test.dart
  test/receipt_native_android_source_size_test.dart
  test/receipt_native_camera_contract_test.dart
  test/receipt_native_camera_phase8_storage_timing_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
  test/receipt_native_camera_privacy_diagnostics_test.dart
  test/receipt_native_camera_result_rejection_test.dart
  test/receipt_native_camera_service_basics_test.dart
  test/receipt_native_camera_session_limits_test.dart
  test/receipt_native_camera_shell_test.dart
  test/receipt_native_camera_shell_controls_test.dart
  test/receipt_native_camera_storage_contract_test.dart
  test/receipt_native_capture_staging_cleanup_test.dart
  test/receipt_native_capture_staging_test.dart
  test/receipt_native_ghost_warning_contract_test.dart
  test/receipt_native_ios_bridge_app_delegate_test.dart
  test/receipt_native_ios_bridge_exposure_shutter_contract_test.dart
  test/receipt_native_ios_bridge_false_positive_guard_test.dart
  test/receipt_native_ios_bridge_long_receipt_quality_test.dart
  test/receipt_native_ios_settings_guidance_contract_test.dart
  test/receipt_native_ios_bridge_settings_close_test.dart
  test/receipt_native_ios_bridge_storage_contract_test.dart
  test/receipt_native_ios_bridge_ui_session_test.dart
  test/receipt_native_ios_guidance_warning_gate_test.dart
  test/receipt_photo_review_retake_order_test.dart
  test/receipt_stitch_fallback_metadata_test.dart
  test/receipt_stitching_manual_overlap_test.dart
  test/receipt_stitching_result_contract_test.dart
  test/receipt_stitching_test.dart
  test/receipt_stitching_variants_test.dart
)

stitch_tests=(
  test/receipt_camera_long_receipt_guidance_test.dart
  test/receipt_camera_ocr_source_handoff_test.dart
  test/receipt_camera_phase5_long_receipt_contract_test.dart
  test/receipt_camera_low_confidence_stack_handoff_test.dart
  test/receipt_camera_oversized_stitch_handoff_test.dart
  test/receipt_camera_phase6_stitching_handoff_contract_test.dart
  test/receipt_camera_fixture_matrix_test.dart
  test/receipt_camera_result_frozen_handoff_counts_test.dart
  test/receipt_camera_result_insert_invalid_context_test.dart
  test/receipt_camera_result_manual_reorder_order_test.dart
  test/receipt_camera_result_removal_order_test.dart
  test/receipt_camera_result_stitch_handoff_followthrough_test.dart
  test/receipt_camera_stitch_candidate_metadata_test.dart
  test/receipt_camera_result_stitch_scanner_test.dart
  test/receipt_capture_flow_shareability_test.dart
  test/receipt_capture_flow_barcode_handoff_test.dart
  test/receipt_capture_flow_ocr_source_count_test.dart
  test/receipt_ocr_source_relationship_test.dart
  test/receipt_native_camera_session_limits_test.dart
  test/receipt_native_camera_previous_section_channel_test.dart
  test/receipt_photo_section_labels_test.dart
  test/receipt_photo_review_retake_order_test.dart
  test/receipt_stitch_contract_health_script_test.dart
  test/receipt_stitch_fallback_metadata_test.dart
  test/receipt_stitching_artifact_copy_contract_test.dart
  test/receipt_stitching_bad_input_test.dart
  test/receipt_stitching_duplicate_safety_test.dart
  test/receipt_stitching_exception_fallback_contract_test.dart
  test/receipt_stitching_extreme_aspect_ratio_test.dart
  test/receipt_stitching_horizontal_drift_test.dart
  test/receipt_stitching_horizontal_placement_test.dart
  test/receipt_stitching_long_stack_test.dart
  test/receipt_stitching_manual_overlap_test.dart
  test/receipt_stitching_ocr_source_contract_test.dart
  test/receipt_stitching_passenger_seat_test.dart
  test/receipt_stitching_phone_window_edge_crop_test.dart
  test/receipt_stitching_phone_window_safety_test.dart
  test/receipt_stitching_real_fixture_probe_test.dart
  test/receipt_stitching_result_contract_test.dart
  test/receipt_stitching_scale_rotation_test.dart
  test/receipt_stitching_size_cap_test.dart
  test/receipt_stitching_store_receipt_shape_test.dart
  test/receipt_stitching_test.dart
  test/receipt_stitching_transformed_phone_window_test.dart
  test/receipt_stitching_ugly_long_receipt_test.dart
  test/receipt_stitching_uploaded_screenshot_test.dart
  test/receipt_stitching_variants_test.dart
  test/receipt_stitching_weak_overlap_safety_test.dart
  test/receipt_stitching_worn_receipt_test.dart
)

full_only_tests=(
  test/receipt_camera_backup_staging_contract_test.dart
  test/receipt_camera_capture_loss_contract_test.dart
  test/receipt_camera_import_staging_contract_test.dart
  test/receipt_camera_permission_contract_test.dart
  test/receipt_camera_review_actions_contract_test.dart
  test/receipt_camera_single_photo_handoff_contract_test.dart
  test/receipt_camera_storage_threshold_policy_test.dart
  test/receipt_camera_user_language_contract_test.dart
  test/receipt_camera_active_phase_docs_test.dart
  test/receipt_camera_completion_map_test.dart
  test/receipt_camera_footprint_audit_test.dart
  test/receipt_camera_help_flow_test.dart
  test/receipt_camera_import_staging_contract_test.dart
  test/receipt_camera_native_baseline_policy_test.dart
  test/receipt_camera_pipeline_handoff_status_test.dart
  test/receipt_real_device_matrix_gate_test.dart
  test/receipt_real_device_test_script_test.dart
  test/receipt_camera_world_class_readiness_test.dart
  test/receipt_camera_ocr_source_attachment_read_test.dart
  test/receipt_camera_permission_contract_test.dart
  test/receipt_camera_preference_mapper_test.dart
  test/receipt_camera_release_control_priority_test.dart
  test/receipt_camera_release_one_blueprint_test.dart
  test/receipt_camera_result_auto_capture_contract_test.dart
  test/receipt_camera_qa_gate_plan_coverage_test.dart
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
  test/receipt_camera_result_section_order_follow_through_test.dart
  test/receipt_camera_result_section_order_invalid_context_test.dart
  test/receipt_camera_result_section_order_test.dart
  test/receipt_camera_result_test.dart
  test/receipt_camera_review_actions_contract_test.dart
  test/receipt_camera_saved_photo_warning_diagnostics_test.dart
  test/receipt_camera_settings_handoff_test.dart
  test/receipt_capture_settings_store_test.dart
  test/receipt_camera_single_photo_handoff_contract_test.dart
  test/receipt_camera_user_language_contract_test.dart
  test/receipt_photo_review_controls_layout_test.dart
  test/receipt_photo_review_crop_controls_layout_test.dart
  test/receipt_photo_review_continuation_copy_test.dart
  test/receipt_image_data_saver_test.dart
  test/receipt_image_source_prep_test.dart
  test/receipt_native_android_bridge_auto_capture_test.dart
  test/receipt_native_android_analysis_executor_test.dart
  test/receipt_native_android_camera_startup_resilience_test.dart
  test/receipt_native_android_capture_watchdog_test.dart
  test/receipt_native_android_bridge_test.dart
  test/receipt_native_android_diagnostics_payload_test.dart
  test/receipt_native_camera_result_path_validation_test.dart
  test/receipt_native_capture_blocked_feedback_test.dart
  test/receipt_native_camera_session_contract_test.dart
  test/receipt_native_capture_old_cleanup_test.dart
  test/receipt_native_capture_recovery_store_test.dart
  test/receipt_native_pinch_zoom_contract_test.dart
  test/receipt_native_quality_guidance_contract_test.dart
  test/receipt_native_capture_recovery_index_test.dart
  test/receipt_native_capture_recovery_record_test.dart
  test/receipt_native_ios_bridge_close_capture_test.dart
  test/receipt_native_ios_capture_watchdog_test.dart
  test/receipt_native_ios_orientation_contract_test.dart
  test/receipt_native_ios_session_recovery_test.dart
  test/receipt_native_ios_bridge_test.dart
  test/receipt_native_ios_diagnostics_payload_test.dart
  test/receipt_native_ios_project_membership_test.dart
  test/receipt_native_pinch_zoom_contract_test.dart
  test/receipt_native_quality_guidance_contract_test.dart
  test/receipt_native_android_bridge_analysis_exposure_test.dart
  test/receipt_native_ios_bridge_analysis_exposure_test.dart
  test/receipt_ocr_source_completion_test.dart
  test/receipt_ocr_source_text_fidelity_test.dart
  test/receipt_ocr_source_review_risks_test.dart
  test/receipt_ocr_source_section_order_handoff_test.dart
  test/receipt_photo_review_continuation_crop_contract_test.dart
  test/receipt_camera_ios_full_screen_settings_test.dart
  test/receipt_camera_reset_opt_in_contract_test.dart
  test/receipt_stitching_mixed_encoding_test.dart
  test/receipt_stitching_high_overlap_test.dart
  test/receipt_stitching_orientation_mismatch_test.dart
  test/receipt_stitching_stained_overlap_test.dart
  test/receipt_stitching_torn_edge_test.dart
  test/receipt_stitching_weak_overlap_safety_test.dart
)

line_cap_paths=(
  "${camera_source_roots[@]}"
  "${quick_tests[@]}"
  "${milestone_only_tests[@]}"
  "${stitch_tests[@]}"
  "${full_only_tests[@]}"
)

run_flutter_tests() {
  flutter test --no-pub "$@" -r compact
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
    phase2)
      print_test_pack phase2 "${phase2_tests[@]}"
      ;;
    phase3)
      print_test_pack phase3 "${phase3_tests[@]}"
      ;;
    phase4)
      print_test_pack phase4 "${phase4_tests[@]}"
      ;;
    phase5)
      print_test_pack phase5 "${phase5_tests[@]}"
      ;;
    phase6)
      print_test_pack phase6 "${phase6_tests[@]}"
      ;;
    phase7)
      print_test_pack phase7 "${phase7_tests[@]}"
      ;;
    phase8)
      print_test_pack phase8 "${phase8_tests[@]}"
      ;;
    phase9)
      print_test_pack phase9 "${phase9_tests[@]}"
      ;;
    core_remaining)
      print_test_pack core_remaining "${core_remaining_tests[@]}"
      ;;
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
        print_test_pack stitch "${stitch_tests[@]}"
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

run_phase2_stale_contract_scan() {
  local scan_roots=(
    lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart
    lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart
    lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart
  )
  local pattern='Receipt Camera Setup|Open Receipt Settings|Clear Photo First|Continue To Camera|Before Next|tap Next|Icons.play_arrow_rounded'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 2 receipt-entry wording or retired control contract found." >&2
    return 1
  fi
}

run_phase3_stale_contract_scan() {
  local scan_roots=(
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_top_controls.dart
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraActivity.kt
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraUiChrome.kt
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraFraming.kt
    ios/Runner/ReceiptCameraViewController.swift
    ios/Runner/ReceiptCameraViewControllerLayout.swift
    ios/Runner/ReceiptCameraViewControllerLiveFrameAnalysis.swift
  )
  local pattern='Icons\.play_arrow_rounded|wrench|Tap text to focus|warningCarousel|guidanceMessages|randomGuidance|Continue To Camera|Open Receipt Settings'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 3 viewer wording or retired control contract found." >&2
    return 1
  fi
}

run_phase4_stale_contract_scan() {
  local scan_roots=(
    lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart
  )
  local pattern='Preparing receipt details\.\.\.|Next if complete|Next: Review Details|Leave Without Reading|Back To Receipt Form|Save Photo For Later|Save Photos For Later|Keep Photo Saved For Later|Keep Photos Saved For Later'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 4 review wording or retired review-flow contract found." >&2
    return 1
  fi
}

run_phase5_stale_contract_scan() {
  local scan_roots=(
    lib/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart
    lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart
    lib/shared/widgets/receipt_capture/receipt_native_camera_session_ghost_guide.dart
  )
  local pattern='Choose The Best Receipt Photo|Use This Photo|Open Receipt Camera|Prepare Receipt Review|Leave Without Saving'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 5 long-receipt wording or retired long-receipt contract found." >&2
    return 1
  fi
}

run_phase6_stale_contract_scan() {
  local scan_roots=(
    lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart
    lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart
    lib/shared/widgets/receipt_capture/receipt_capture_stitch_models.dart
    lib/shared/widgets/receipt_capture/receipt_capture_stitch_model_helpers.dart
  )
  local pattern='Save Photo For Later|Save Photos For Later|Leave Without Saving|Prepare Receipt Review|Choose The Best Receipt Photo'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 6 stitching wording or retired stitch-handoff contract found." >&2
    return 1
  fi
}

run_phase7_stale_contract_scan() {
  local scan_roots=(
    lib/shared/receipts/receipt_ocr_contract.dart
    lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart
    lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart
    lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart
  )
  local pattern='ocr_is_truth|parser_is_truth|overwrite_confirmed_user_value|silent_overwrite_confirmed_value'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 7 OCR-source handoff contract found." >&2
    return 1
  fi
}

run_phase8_stale_contract_scan() {
  local scan_roots=(
    lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart
    lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart
    android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt
    ios/Runner/ReceiptCameraViewControllerSessionSettings.swift
    ios/Runner/ReceiptCameraViewControllerSettingsCopy.swift
  )
  local pattern='Saved proof size.*before.*capture|compression.*before.*capture|storage lecture|data saver setup first'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 8 storage-proof timing contract found." >&2
    return 1
  fi
}

run_phase9_stale_contract_scan() {
  local scan_roots=(
    docs/receipt_camera_ocr_master_pass_plan.md
    docs/receipt_camera_completion_map.md
    docs/receipt_camera_ocr_pipeline_handoff_report.md
    docs/receipt_camera_release_one_blueprint.md
    docs/receipt_camera_world_class_readiness.md
    PROJECT_RULES.md
  )
  local pattern='Current active phase: Phase 8|Current active phase: Phase 9, Milestone validation|Active roadmap focus: Phase 2 receipt entry flow verification|Active roadmap focus: Phase 6 through Phase 9 non-UI hardening and|Active roadmap focus: Phase 9 milestone validation|1,500-2,500|4,000-pass camera-app|tap-to-focus|tap to focus'

  if rg -n "$pattern" "${scan_roots[@]}"; then
    echo "Stale Phase 9 milestone-validation contract found." >&2
    return 1
  fi
}

run_phase2() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart \
    "${phase2_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase2_audit_paths[@]}" \
    --max-line-length=220
  run_phase2_stale_contract_scan
  run_flutter_tests "${phase2_tests[@]}"
  git diff --check
}

run_phase3() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart \
    test/helpers/receipt_native_android_bridge_source_readers.dart \
    test/helpers/receipt_native_ios_bridge_source_readers.dart \
    "${phase3_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase3_audit_paths[@]}" \
    --max-line-length=220
  run_phase3_stale_contract_scan
  run_flutter_tests "${phase3_tests[@]}"
  git diff --check
}

run_phase4() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart \
    test/helpers/receipt_camera_capture_layout_source_readers.dart \
    "${phase4_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase4_audit_paths[@]}" \
    --max-line-length=220
  run_phase4_stale_contract_scan
  run_flutter_tests "${phase4_tests[@]}"
  git diff --check
}

run_phase5() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture/receipt_photo_review_retake_order.dart \
    lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart \
    test/helpers/receipt_long_guidance_sources.dart \
    test/helpers/receipt_native_camera_previous_section_channel_expectations.dart \
    test/helpers/receipt_native_camera_previous_section_diagnostics_expectations.dart \
    "${phase5_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase5_audit_paths[@]}" \
    --max-line-length=220
  run_phase5_stale_contract_scan
  run_flutter_tests "${phase5_tests[@]}"
  git diff --check
}

run_phase6() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture/receipt_capture_models.dart \
    lib/shared/widgets/receipt_capture/receipt_image_processor.dart \
    test/helpers/receipt_camera_source_readers.dart \
    test/helpers/receipt_stitching_image_helpers.dart \
    "${phase6_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase6_audit_paths[@]}" \
    --max-line-length=220
  run_phase6_stale_contract_scan
  run_flutter_tests "${phase6_tests[@]}"
  git diff --check
}

run_phase7() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/receipts/receipt_ocr_contract.dart \
    lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart \
    test/helpers/receipt_camera_source_readers.dart \
    "${phase7_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase7_audit_paths[@]}" \
    --max-line-length=220
  run_phase7_stale_contract_scan
  run_flutter_tests "${phase7_tests[@]}"
  git diff --check
}

run_phase8() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart \
    lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart \
    test/helpers/receipt_native_android_bridge_source_readers.dart \
    test/helpers/receipt_native_ios_bridge_source_readers.dart \
    "${phase8_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase8_audit_paths[@]}" \
    --max-line-length=220
  run_phase8_stale_contract_scan
  run_flutter_tests "${phase8_tests[@]}"
  git diff --check
}

run_phase9() {
  bash tool/receipt_camera_scope_gate.sh
  bash -n tool/receipt_real_device_result_start.sh
  dart analyze \
    tool/receipt_real_device_result_gate.dart \
    tool/receipt_real_device_matrix_gate.dart \
    "${phase9_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${phase9_audit_paths[@]}" \
    --max-line-length=220
  run_phase9_stale_contract_scan
  run_flutter_tests "${phase9_tests[@]}"
  git diff --check
}

run_core_remaining() {
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture/receipt_capture_models.dart \
    lib/shared/widgets/receipt_capture/receipt_image_processor.dart \
    lib/shared/receipts/receipt_ocr_contract.dart \
    lib/shared/widgets/receipt_capture/receipt_ocr_source_handoff.dart \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart \
    lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart \
    lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart \
    lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart \
    test/helpers/receipt_camera_source_readers.dart \
    test/helpers/receipt_stitching_image_helpers.dart \
    test/helpers/receipt_native_android_bridge_source_readers.dart \
    test/helpers/receipt_native_ios_bridge_source_readers.dart \
    "${core_remaining_tests[@]}"
  dart tool/maintainiac_source_audit.dart \
    "${core_remaining_audit_paths[@]}" \
    --max-line-length=220
  run_phase6_stale_contract_scan
  run_phase7_stale_contract_scan
  run_phase8_stale_contract_scan
  run_flutter_tests "${core_remaining_tests[@]}"
  git diff --check
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
    tool/receipt_real_device_result_start.sh \
    tool/receipt_camera_scope_gate.sh \
    tool/receipt_camera_stitch_gate.sh \
    tool/receipt_start_camera_qa_gate.sh
  bash tool/receipt_camera_scope_gate.sh
  dart analyze \
    lib/shared/widgets/receipt_capture \
    lib/shared/receipts \
    tool/receipt_external_dataset_local_audit.dart \
    tool/receipt_external_dataset_gate.dart \
    tool/receipt_external_fixture_schema_gate.dart \
    tool/receipt_camera_changed_route_coverage_gate.dart \
    tool/receipt_bug_regression_ledger_gate.dart
  dart tool/receipt_bug_regression_ledger_gate.dart
  dart tool/receipt_camera_changed_route_coverage_gate.dart
  dart tool/receipt_external_dataset_gate.dart
  dart tool/receipt_external_dataset_local_audit.dart
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
  run_stitch
  run_flutter_tests "${full_only_tests[@]}"
  bash tool/receipt_camera_real_device_snapshot.sh
  bash tool/android_receipt_camera_compile_gate.sh
  bash tool/ios_receipt_camera_compile_gate.sh
}

case "$mode" in
  phase2) run_phase2 ;;
  phase3) run_phase3 ;;
  phase4) run_phase4 ;;
  phase5) run_phase5 ;;
  phase6) run_phase6 ;;
  phase7) run_phase7 ;;
  phase8) run_phase8 ;;
  phase9) run_phase9 ;;
  core_remaining) run_core_remaining ;;
  quick) run_quick ;;
  stitch) run_stitch ;;
  milestone) run_milestone ;;
  full) run_full ;;
esac
