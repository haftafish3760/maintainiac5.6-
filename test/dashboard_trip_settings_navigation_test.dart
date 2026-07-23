import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active trip dashboard links directly to GPS and motion opt-ins', () {
    final source = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(
      source,
      contains("import '../settings/trip_tracking_settings_screen.dart'"),
    );
    expect(source, contains('const TripTrackingSettingsScreen()'));
    expect(source, contains("child: const Text('GPS & MOTION SETTINGS')"));
    expect(
      source,
      contains('onOpenSettings: () => Navigator.of(context).push('),
    );
  });

  test('trip settings retain separate GPS and motion consent switches', () {
    final source = File(
      'lib/screens/settings/trip_tracking_settings_screen.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'Enable GPS-assisted tracking'"));
    expect(source, contains('value: settings.activityRecognitionEnabled'));
    expect(
      source,
      contains('settings.copyWith(activityRecognitionEnabled: value)'),
    );
  });
}
