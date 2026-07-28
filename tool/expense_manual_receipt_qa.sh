#!/usr/bin/env bash
set -euo pipefail

sources=(
  lib/screens/expenses/data/expense_receipt_draft_record.dart
  lib/shared/state/expense_settings_store.dart
  lib/screens/expenses/entry/expense_receipt_entry_screen.dart
  lib/screens/expenses/entry/expense_receipt_entry_draft_actions.dart
  lib/screens/expenses/entry/expense_receipt_entry_line_mode_helpers.dart
  lib/screens/expenses/entry/expense_receipt_entry_split_percent_actions.dart
  lib/screens/expenses/entry/expense_receipt_detail_level_panel.dart
  lib/screens/expenses/entry/expense_receipt_category_picker.dart
  lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart
  lib/screens/expenses/entry/expense_receipt_line_actions.dart
)

hive_tests=(
  test/expense_draft_store_test.dart
)

manual_receipt_tests=(
  test/expense_settings_store_test.dart
  test/expense_receipt_review_mode_totals_test.dart
  test/expense_receipt_assisted_review_flow_test.dart
  test/expense_receipt_assisted_review_save_guardrails_test.dart
  test/expense_split_allocation_test.dart
  test/expense_receipt_category_rules_test.dart
  test/expense_receipt_custom_category_entry_contract_test.dart
)

dart format "${sources[@]}" "${hive_tests[@]}" "${manual_receipt_tests[@]}" >/dev/null
git diff --check -- "${sources[@]}" "${hive_tests[@]}" "${manual_receipt_tests[@]}"
dart analyze "${sources[@]}"
flutter test --concurrency=1 --reporter compact "${hive_tests[@]}"
flutter test --reporter compact "${manual_receipt_tests[@]}"

echo 'Manual receipt pipeline QA: PASS (Hive serial; UI/contracts bundled)'
