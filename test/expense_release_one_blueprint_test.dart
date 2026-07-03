import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'expense blueprint preserves release-one architecture and work split',
    () {
      final blueprint = File(
        'docs/expense_release_one_blueprint.md',
      ).readAsStringSync();
      final handoff = File(
        'docs/expense_codex_b_handoff.md',
      ).readAsStringSync();
      final readme = File('README.md').readAsStringSync();
      final projectRules = File('PROJECT_RULES.md').readAsStringSync();

      const blueprintPath = 'docs/expense_release_one_blueprint.md';
      const handoffPath = 'docs/expense_codex_b_handoff.md';

      expect(readme, contains(blueprintPath));
      expect(readme, contains(handoffPath));
      expect(projectRules, contains(blueprintPath));
      expect(blueprint, contains(handoffPath));
      expect(
        blueprint,
        contains('Hive/local storage is the immediate source of truth'),
      );
      expect(
        blueprint,
        contains('Firestore/cloud sync is a mirror or backup, not the brain'),
      );
      expect(
        blueprint,
        contains(
          'User-confirmed financial data must never be silently overwritten',
        ),
      );
      expect(blueprint, contains('Two-Codex Work Split'));
      expect(
        blueprint,
        contains('Codex A - Camera And Shared Receipt Infrastructure'),
      );
      expect(blueprint, contains('Codex B - Expense App And Derived Outputs'));
      expect(blueprint, contains('Shared Contract Boundary'));
      expect(blueprint, contains('PDF And File Intake'));
      expect(blueprint, contains('Fuel Expense Specialization'));
      expect(blueprint, contains('Spanish release-one support'));
      expect(blueprint, contains('Every bug fixed gets a regression test'));
      expect(handoff, contains('codex/expense-app-lane'));
      expect(handoff, contains('Do not edit these paths'));
      expect(handoff, contains('lib/screens/expenses/**'));
      expect(handoff, contains('lib/shared/widgets/receipt_capture/**'));
      expect(handoff, contains('codex/expense-contract-integration'));
      expect(handoff, contains('Every confirmed bug gets a regression test'));
    },
  );
}
