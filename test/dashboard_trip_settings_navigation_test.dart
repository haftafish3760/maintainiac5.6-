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
    expect(source, contains("child: const Text('PHONE LOCATION SETTINGS')"));
    expect(
      source,
      contains('onOpenSettings: () => Navigator.of(context).push('),
    );
  });

  test('dashboard settings exposes the complete GPS settings surface', () {
    final source = File(
      'lib/screens/settings/dashboard_settings.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'GPS-Assisted Trip Tracking'"));
    expect(source, contains('const TripTrackingSettingsScreen()'));
    expect(
      source,
      contains(
        'Location permission, battery profile, low-speed equipment mode, and walking-review preferences.',
      ),
    );
  });

  test('trip settings retain separate GPS and motion consent switches', () {
    final source = [
      'lib/screens/settings/trip_tracking_settings_screen.dart',
      'lib/screens/settings/trip_tracking_settings_labels.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    expect(source, contains("title: 'Enable GPS-assisted tracking'"));
    expect(source, contains('value: settings.activityRecognitionEnabled'));
    expect(
      source,
      contains('settings.copyWith(activityRecognitionEnabled: value)'),
    );
    expect(source, contains("title: 'Accuracy and battery use'"));
    expect(source, contains("'High accuracy (2 sec)'"));
    expect(source, contains("const _SettingsSectionTitle('Vehicle recognition')"));
    expect(source, contains("'Paid feature'"));
    expect(
      source,
      contains("'Automatically start GPS for the linked vehicle'"),
    );
    expect(
      source,
      contains(
        'Confirmed odometer mileage is never changed without your review.',
      ),
    );
  });
}
