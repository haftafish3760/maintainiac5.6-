#!/usr/bin/env bash
set -euo pipefail

dart analyze \
  lib/shared/widgets/receipt_capture \
  lib/shared/receipts

dart tool/maintainiac_source_audit.dart \
  lib/shared/widgets/receipt_capture \
  lib/shared/receipts \
  android/app/src/main/kotlin/com/maintainiac \
  ios/Runner \
  --max-line-length=220

flutter test \
  test/receipt_camera_capture_layout_test.dart \
  test/receipt_camera_coverage_decision_test.dart \
  test/receipt_camera_long_receipt_guidance_test.dart \
  test/receipt_camera_native_bridge_layout_test.dart \
  test/receipt_camera_ocr_source_handoff_test.dart \
  test/receipt_camera_quality_guidance_test.dart \
  test/receipt_camera_result_best_shot_ocr_test.dart \
  test/receipt_camera_result_completion_coverage_test.dart \
  test/receipt_camera_result_coverage_totals_test.dart \
  test/receipt_camera_result_native_close_settings_test.dart \
  test/receipt_camera_result_native_quality_test.dart \
  test/receipt_camera_result_native_ui_health_test.dart \
  test/receipt_camera_result_recovery_handoff_test.dart \
  test/receipt_camera_result_stitch_scanner_test.dart \
  test/receipt_image_ocr_source_guard_test.dart \
  test/receipt_native_android_import_hygiene_test.dart \
  test/receipt_native_android_bridge_analysis_exposure_test.dart \
  test/receipt_native_android_bridge_capture_flow_test.dart \
  test/receipt_native_android_bridge_close_controls_test.dart \
  test/receipt_native_android_bridge_diagnostics_storage_test.dart \
  test/receipt_native_android_bridge_settings_quality_test.dart \
  test/receipt_native_android_bridge_ui_contract_test.dart \
  test/receipt_native_android_source_size_test.dart \
  test/receipt_native_camera_contract_test.dart \
  test/receipt_native_camera_previous_section_channel_test.dart \
  test/receipt_native_camera_privacy_diagnostics_test.dart \
  test/receipt_native_camera_result_rejection_test.dart \
  test/receipt_native_camera_service_basics_test.dart \
  test/receipt_native_camera_session_limits_test.dart \
  test/receipt_native_camera_shell_test.dart \
  test/receipt_native_camera_storage_contract_test.dart \
  test/receipt_native_capture_staging_cleanup_test.dart \
  test/receipt_native_capture_staging_test.dart \
  test/receipt_native_ghost_warning_contract_test.dart \
  test/receipt_native_ios_bridge_analysis_exposure_test.dart \
  test/receipt_native_ios_bridge_app_delegate_test.dart \
  test/receipt_native_ios_bridge_long_receipt_quality_test.dart \
  test/receipt_native_ios_bridge_settings_close_test.dart \
  test/receipt_native_ios_bridge_storage_contract_test.dart \
  test/receipt_native_ios_bridge_ui_session_test.dart \
  test/receipt_native_shell_recovery_contract_test.dart \
  test/receipt_stitching_test.dart \
  -r compact

bash tool/android_receipt_camera_compile_gate.sh
bash tool/ios_receipt_camera_compile_gate.sh
