import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active workday keeps its work profile read only', () {
    final screen = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();
    final contextBar = File(
      'lib/screens/dashboard/active_workday_context_bar.dart',
    ).readAsStringSync();

    expect(screen, contains('workProfileName: widget.workProfileName'));
    expect(contextBar, contains("label: 'WORK PROFILE'"));
    expect(contextBar, contains('Icons.lock_outline_rounded'));
    expect(contextBar, isNot(contains('ActiveVehicleDrawer')));
    expect(contextBar, isNot(contains('onTap:')));
  });

  test('GPS trip and learned patterns bind to the active work profile', () {
    final screen = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('profileId: activeSession.workProfileId'));
    expect(screen, contains('profileId: activeWorkday.workProfileId'));
    expect(screen, isNot(contains('profileId: settings.defaultProfile.name')));
  });
}
