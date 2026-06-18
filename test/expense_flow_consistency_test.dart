import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense screens use the contextual app odometer header', () {
    final expenseFiles = Directory('lib/screens/expenses')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in expenseFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains("shared/odometer/global_odometer_header.dart")),
        reason:
            '${file.path} should use the contextual app header, not the legacy generic odometer header.',
      );
      if (source.contains('GlobalOdometerHeader(')) {
        expect(
          source,
          contains('section: AppSection.expenses'),
          reason:
              '${file.path} uses GlobalOdometerHeader and must label it as the expenses context.',
        );
      }
    }
  });
}
