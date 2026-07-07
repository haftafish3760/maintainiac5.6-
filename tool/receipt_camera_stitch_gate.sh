#!/usr/bin/env bash
set -euo pipefail

bash tool/receipt_camera_scope_gate.sh
bash -n tool/receipt_camera_stitch_gate.sh
dart tool/receipt_bug_regression_ledger_gate.dart

dart analyze \
  lib/shared/widgets/receipt_capture \
  lib/shared/receipts \
  tool/receipt_bug_regression_ledger_gate.dart \
  test/helpers/receipt_stitching_* \
  test/receipt_camera_long_receipt_guidance_test.dart \
  test/receipt_camera_ocr_source_handoff_test.dart \
  test/receipt_camera_fixture_matrix_test.dart \
  test/receipt_camera_result_stitch_scanner_test.dart \
  test/receipt_capture_flow_barcode_handoff_test.dart \
  test/receipt_ocr_source_relationship_test.dart \
  test/receipt_native_camera_previous_section_channel_test.dart \
  test/receipt_photo_section_labels_test.dart \
  test/receipt_photo_review_retake_order_test.dart \
  test/receipt_stitch_fallback_metadata_test.dart \
  test/receipt_stitching_manual_overlap_test.dart \
  test/receipt_stitching_result_contract_test.dart \
  test/receipt_stitching_test.dart

flutter test \
  test/receipt_camera_long_receipt_guidance_test.dart \
  test/receipt_camera_ocr_source_handoff_test.dart \
  test/receipt_camera_fixture_matrix_test.dart \
  test/receipt_camera_result_stitch_scanner_test.dart \
  test/receipt_capture_flow_barcode_handoff_test.dart \
  test/receipt_ocr_source_relationship_test.dart \
  test/receipt_native_camera_previous_section_channel_test.dart \
  test/receipt_photo_section_labels_test.dart \
  test/receipt_photo_review_retake_order_test.dart \
  test/receipt_stitch_fallback_metadata_test.dart \
  test/receipt_stitching_manual_overlap_test.dart \
  test/receipt_stitching_result_contract_test.dart \
  test/receipt_stitching_test.dart \
  -r compact

git diff --check
