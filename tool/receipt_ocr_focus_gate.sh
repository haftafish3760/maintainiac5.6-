#!/usr/bin/env bash

set -euo pipefail

flutter analyze \
  lib/shared/widgets/receipt_capture/receipt_attachment_duplicate_detector.dart \
  lib/shared/widgets/receipt_capture/receipt_ocr_service.dart \
  lib/shared/widgets/receipt_capture/receipt_ocr_warning_classification.dart \
  lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart \
  lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff.dart \
  lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_labels.dart \
  lib/screens/expenses/entry/expense_receipt_entry_screen.dart \
  lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart \
  lib/screens/expenses/entry/expense_receipt_parse_review_intro_panel.dart \
  lib/screens/expenses/entry/expense_receipt_entry_read_handoff_no_line_labels.dart \
  lib/screens/expenses/entry/expense_receipt_parse_review_ocr_review_row.dart \
  lib/screens/expenses/entry/expense_receipt_entry_core_helpers.dart \
  lib/screens/expenses/entry/expense_receipt_entry_read_handoff_helpers.dart \
  lib/screens/expenses/entry/expense_receipt_parse_review_ocr_readiness_helpers.dart

flutter test --reporter compact \
  test/receipt_attachment_duplicate_detector_test.dart \
	  test/receipt_ocr_layout_contract_test.dart \
	  test/receipt_ocr_field_candidates_test.dart \
	  test/expense_receipt_parse_result_copy_test.dart \
	  test/receipt_device_capability_tiers_test.dart \
	  test/expense_receipt_ocr_progress_deadline_test.dart \
	  test/expense_receipt_review_mode_totals_test.dart \
	  test/expense_receipt_faithful_display_and_split_test.dart \
  test/receipt_ocr_source_text_fidelity_test.dart \
  test/receipt_ocr_handoff_test.dart \
  test/expense_receipt_ocr_handler_integration_test.dart \
  test/receipt_ocr_timeout_recovery_test.dart \
  test/receipt_attachment_panel_recovery_contract_test.dart \
  test/expense_receipt_assisted_review_handoff_native_test.dart \
  test/expense_receipt_assisted_review_save_guardrails_test.dart \
  test/expense_receipt_assisted_review_overlap_native_test.dart \
  test/expense_receipt_assisted_review_handoff_test.dart \
  test/expense_receipt_assisted_review_parser_guidance_test.dart \
  test/receipt_camera_result_test.dart \
  test/receipt_camera_help_flow_test.dart \
  test/receipt_photo_review_controls_layout_test.dart \
  test/receipt_camera_result_coverage_totals_test.dart \
  test/receipt_camera_result_frozen_brain_install_test.dart \
  test/receipt_camera_result_frozen_metadata_routes_test.dart \
  test/receipt_camera_result_stitch_scanner_test.dart \
  test/receipt_ocr_source_review_risks_test.dart \
  test/receipt_camera_ocr_source_handoff_test.dart \
  test/receipt_native_camera_contract_test.dart \
  test/receipt_native_camera_shell_controls_test.dart \
  test/receipt_native_camera_privacy_diagnostics_test.dart \
  test/receipt_camera_result_focus_contract_test.dart \
  test/receipt_native_android_bridge_ui_contract_test.dart \
  test/receipt_native_ios_bridge_exposure_shutter_contract_test.dart \
  test/expense_receipt_assisted_review_flow_test.dart \
  test/expense_receipt_entry_start_guide_test.dart \
  test/receipt_automatic_fill_notice_test.dart \
  test/expense_receipt_assisted_review_recovery_state_test.dart \
  test/expense_receipt_parser_business_personal_test.dart \
  test/expense_receipt_line_record_test.dart \
  test/expense_receipt_user_review_merge_test.dart

git diff --check
