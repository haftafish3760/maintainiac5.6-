import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Expense handoff protects the receipt lifecycle contract', () {
    final readme = File('README.md').readAsStringSync();
    final blueprint = File(
      'docs/expense_release_one_blueprint.md',
    ).readAsStringSync();
    final handoff = File('docs/expense_codex_b_handoff.md').readAsStringSync();
    final contract = File(
      'docs/expense_receipt_storage_and_duplicate_contract.md',
    ).readAsStringSync();

    const contractPath =
        'docs/expense_receipt_storage_and_duplicate_contract.md';
    expect(readme, contains(contractPath));
    expect(blueprint, contains(contractPath));
    expect(handoff, contains(contractPath));
    expect(contract, contains('User Review Is Mandatory'));
    expect(contract, contains('Never modify, overwrite, or delete.'));
    expect(contract, contains('Never delete solely because it is old.'));
    expect(contract, contains('Duplicate detection is a warning system'));
    expect(contract, contains('account-wide duplicate-warning behavior'));
  });

  test('Expense save retains mandatory duplicate review choices', () {
    final save = File(
      'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
    ).readAsStringSync();
    final dialog = File(
      'lib/screens/expenses/entry/expense_receipt_duplicate_dialog.dart',
    ).readAsStringSync();

    expect(save, contains('ledger.checkDuplicatesFor(receipt)'));
    expect(save, contains('_showDuplicateReceiptDialog(duplicateCheck)'));
    expect(dialog, contains('View Existing'));
    expect(dialog, contains('Edit Current'));
    expect(dialog, contains('Save Anyway'));
  });
}
