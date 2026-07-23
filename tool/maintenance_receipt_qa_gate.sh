#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

receipt_files=$(find \
  lib/screens/maintenance \
  lib/shared/maintenance \
  test \
  -type f \
  \( -name '*maintenance_receipt*.dart' -o \
     -path '*/maintenance_receipts/*.json' \))
for receipt_file in \
  $receipt_files \
  lib/screens/maintenance/maintenance_item_icon.dart \
  lib/screens/maintenance/maintenance_item_icon_body_painter.dart \
  lib/screens/maintenance/maintenance_item_icon_chassis_painter.dart \
  lib/screens/maintenance/maintenance_item_icon_engine_painter.dart \
  lib/screens/maintenance/maintenance_item_icon_painter.dart \
  lib/screens/maintenance/maintenance_models.dart \
  lib/shared/state/app_state.dart \
  lib/shared/state/app_state_maintenance_controller.dart \
  lib/shared/state/app_state_maintenance_models.dart \
  docs/maintenance_receipt_parser_pass_log.md \
  docs/maintenance_receipt_parser_roadmap.md \
  docs/maintenance_receipt_spark_handoff.md \
  tool/maintenance_receipt_qa_gate.sh; do
  line_count=$(wc -l < "$receipt_file")
  if [ "$line_count" -ge 500 ]; then
    echo "Receipt file must stay under 500 lines: $receipt_file ($line_count)"
    exit 1
  fi
done

dart format --output=none --set-exit-if-changed \
  lib/screens/maintenance/data/maintenance_receipt_parser.dart \
  lib/screens/maintenance/data/maintenance_receipt_parser_catalog.dart \
  lib/screens/maintenance/data/maintenance_receipt_parser_dates.dart \
  lib/screens/maintenance/data/maintenance_receipt_parser_engine.dart \
  lib/screens/maintenance/data/maintenance_receipt_parser_support.dart \
  lib/screens/maintenance/data/maintenance_receipt_application_service.dart \
  lib/screens/maintenance/data/maintenance_receipt_review.dart \
  lib/screens/maintenance/data/maintenance_receipt_review_commands.dart \
  lib/screens/maintenance/maintenance_draft_panel.dart \
  lib/screens/maintenance/maintenance_draft_store.dart \
  lib/screens/maintenance/maintenance_item_detail_screen.dart \
  lib/screens/maintenance/maintenance_item_detail_widgets.dart \
  lib/screens/maintenance/maintenance_item_icon.dart \
  lib/screens/maintenance/maintenance_item_icon_body_painter.dart \
  lib/screens/maintenance/maintenance_item_icon_chassis_painter.dart \
  lib/screens/maintenance/maintenance_item_icon_engine_painter.dart \
  lib/screens/maintenance/maintenance_item_icon_painter.dart \
  lib/screens/maintenance/maintenance_models.dart \
  lib/screens/maintenance/maintenance_receipt_apply_dialog.dart \
  lib/screens/maintenance/maintenance_receipt_review_item_card.dart \
  lib/screens/maintenance/maintenance_receipt_review_flow.dart \
  lib/screens/maintenance/maintenance_receipt_review_screen.dart \
  lib/shared/state/app_state.dart \
  lib/shared/state/app_state_maintenance_controller.dart \
  lib/shared/state/app_state_maintenance_models.dart \
  test/maintenance_draft_resume_test.dart \
  test/maintenance_draft_store_test.dart \
  test/maintenance_receipt_application_service_test.dart \
  test/maintenance_receipt_accuracy_gate_test.dart \
  test/maintenance_receipt_apply_dialog_test.dart \
  test/maintenance_receipt_catalog_contract_test.dart \
  test/maintenance_receipt_corpus_test.dart \
  test/maintenance_receipt_duplicate_application_test.dart \
  test/maintenance_receipt_dirty_text_test.dart \
  test/maintenance_receipt_layout_corpus_test.dart \
  test/maintenance_receipt_mixed_transaction_test.dart \
  test/maintenance_receipt_parser_test.dart \
  test/maintenance_receipt_parser_safety_test.dart \
  test/maintenance_receipt_schedule_date_test.dart \
  test/maintenance_receipt_temporal_safety_test.dart \
  test/maintenance_receipt_review_test.dart \
  test/maintenance_receipt_review_screen_test.dart \
  test/maintenance_receipt_spark_handoff_contract_test.dart \
  test/maintenance_tracking_selection_test.dart

dart analyze \
  lib/screens/maintenance/data/maintenance_receipt_parser.dart \
  lib/screens/maintenance/data/maintenance_receipt_application_service.dart \
  lib/screens/maintenance/data/maintenance_receipt_review.dart \
  lib/screens/maintenance/maintenance_screen.dart \
  lib/screens/maintenance/maintenance_draft_store.dart \
  lib/screens/maintenance/maintenance_item_detail_screen.dart \
  lib/screens/maintenance/maintenance_item_icon.dart \
  lib/screens/maintenance/maintenance_models.dart \
  lib/screens/maintenance/maintenance_receipt_apply_dialog.dart \
  lib/screens/maintenance/maintenance_receipt_review_flow.dart \
  lib/screens/maintenance/maintenance_receipt_review_screen.dart \
  lib/shared/state/app_state.dart \
  lib/shared/state/app_state_maintenance_controller.dart \
  lib/shared/state/app_state_maintenance_models.dart \
  test/maintenance_draft_resume_test.dart \
  test/maintenance_draft_store_test.dart \
  test/maintenance_receipt_application_service_test.dart \
  test/maintenance_receipt_accuracy_gate_test.dart \
  test/maintenance_receipt_apply_dialog_test.dart \
  test/maintenance_receipt_catalog_contract_test.dart \
  test/maintenance_receipt_corpus_test.dart \
  test/maintenance_receipt_duplicate_application_test.dart \
  test/maintenance_receipt_dirty_text_test.dart \
  test/maintenance_receipt_layout_corpus_test.dart \
  test/maintenance_receipt_mixed_transaction_test.dart \
  test/maintenance_receipt_parser_test.dart \
  test/maintenance_receipt_parser_safety_test.dart \
  test/maintenance_receipt_schedule_date_test.dart \
  test/maintenance_receipt_temporal_safety_test.dart \
  test/maintenance_receipt_review_test.dart \
  test/maintenance_receipt_review_screen_test.dart \
  test/maintenance_receipt_spark_handoff_contract_test.dart \
  test/maintenance_tracking_selection_test.dart

flutter test \
  test/maintenance_draft_resume_test.dart \
  test/maintenance_draft_store_test.dart \
  test/maintenance_receipt_application_service_test.dart \
  test/maintenance_receipt_accuracy_gate_test.dart \
  test/maintenance_receipt_apply_dialog_test.dart \
  test/maintenance_receipt_catalog_contract_test.dart \
  test/maintenance_receipt_corpus_test.dart \
  test/maintenance_receipt_duplicate_application_test.dart \
  test/maintenance_receipt_dirty_text_test.dart \
  test/maintenance_receipt_layout_corpus_test.dart \
  test/maintenance_receipt_mixed_transaction_test.dart \
  test/maintenance_receipt_parser_test.dart \
  test/maintenance_receipt_parser_safety_test.dart \
  test/maintenance_receipt_schedule_date_test.dart \
  test/maintenance_receipt_temporal_safety_test.dart \
  test/maintenance_receipt_review_test.dart \
  test/maintenance_receipt_review_screen_test.dart \
  test/maintenance_receipt_spark_handoff_contract_test.dart \
  -r compact
flutter test \
  test/maintenance_tracking_selection_test.dart \
  --plain-name "receipt-suggested setup values remain editable prefills" \
  --timeout 45s \
  -r compact
flutter test test/parser_qa_platform_domain_adapter_test.dart -r compact
flutter test \
  test/expense_receipt_parser_materials_maintenance_test.dart \
  --plain-name "extracts oil change maintenance hints without logging maintenance" \
  --timeout 45s \
  -r compact

echo "MAINTENANCE_RECEIPT_QA_PASS"
