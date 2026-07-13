#!/usr/bin/env bash

set -euo pipefail

flutter analyze \
  lib/shared/widgets/receipt_capture/receipt_attachment_duplicate_detector.dart \
  lib/shared/widgets/receipt_capture/receipt_ocr_service.dart \
  lib/shared/widgets/receipt_capture/receipt_ocr_warning_classification.dart \
  lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart \
  lib/screens/expenses/entry/expense_receipt_entry_screen.dart \
  lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart

flutter test --reporter compact \
  test/receipt_attachment_duplicate_detector_test.dart \
  test/receipt_ocr_layout_contract_test.dart \
  test/receipt_ocr_handoff_test.dart \
  test/expense_receipt_ocr_handler_integration_test.dart \
  test/receipt_ocr_timeout_recovery_test.dart \
  test/receipt_attachment_panel_recovery_contract_test.dart \
  test/expense_receipt_assisted_review_handoff_native_test.dart

git diff --check
