import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active workday blocks silent work-profile replacement', () {
    final screen = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();
    final contextBar = File(
      'lib/screens/dashboard/active_workday_context_bar.dart',
    ).readAsStringSync();

    expect(screen, contains('onOpenWorkProfiles: _openWorkProfiles'));
    expect(
      screen,
      contains('workday != null || tripTracking?.isTracking == true'),
    );
    expect(
      screen,
      contains('End the current workday before switching work profiles.'),
    );
    expect(screen, contains('const ExpenseWorkProfileScreen()'));
    expect(contextBar, contains('onTap: onOpen'));
    expect(contextBar, isNot(contains('void _openWorkProfiles(BuildContext')));
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
