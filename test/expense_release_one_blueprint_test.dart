import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'expense blueprint preserves release-one architecture and work split',
    () {
      final blueprint = File(
        'docs/expense_release_one_blueprint.md',
      ).readAsStringSync();
      final readme = File('README.md').readAsStringSync();
      final projectRules = File('PROJECT_RULES.md').readAsStringSync();

      const blueprintPath = 'docs/expense_release_one_blueprint.md';

      expect(readme, contains(blueprintPath));
      expect(projectRules, contains(blueprintPath));
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
    },
  );
}
