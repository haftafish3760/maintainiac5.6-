import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard renders driver patterns as review-only suggestions', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(source, contains('controller.driverPatternDecision('));
    expect(source, contains('profileId: settings.defaultProfile.name'));
    expect(source, contains('driverPattern?.dashboardSuggestion != null'));
    expect(source, isNot(contains('driverPattern.apply')));
  });
}
