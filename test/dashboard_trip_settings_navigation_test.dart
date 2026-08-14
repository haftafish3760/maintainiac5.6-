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
    expect(source, contains('case WorkdayQuickActionKind.gpsSettings:'));
    expect(source, contains('ActiveWorkdayTrackingStatusLine('));
  });

  test('dashboard settings exposes the complete GPS settings surface', () {
    final source = File(
      'lib/screens/settings/dashboard_settings.dart',
    ).readAsStringSync();

    expect(source, contains("title: 'GPS, Bluetooth, and trip tracking'"));
    expect(source, contains('const TripTrackingSettingsScreen()'));
    expect(
      source,
      contains(
        'Location permissions, vehicle recognition, battery protection, accuracy, and walking review.',
      ),
    );
  });

  test('trip settings retain separate GPS and motion consent switches', () {
    final source = [
      'lib/screens/settings/trip_tracking_settings_screen.dart',
      'lib/screens/settings/trip_tracking_settings_labels.dart',
      'lib/screens/settings/trip_tracking_settings_bluetooth_panel.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    expect(source, contains("title: 'Enable GPS-assisted tracking'"));
    expect(source, contains('value: settings.activityRecognitionEnabled'));
    expect(
      source,
      contains('settings.copyWith(activityRecognitionEnabled: value)'),
    );
    expect(source, contains("title: 'Accuracy and battery use'"));
    expect(source, contains("'High accuracy (2 sec)'"));
    expect(
      source,
      contains("const _SettingsSectionTitle('Vehicle recognition')"),
    );
    expect(source, contains("title: 'Monthly App Assistant allowance'"));
    expect(
      source,
      contains('Four kept reviews are included each calendar month.'),
    );
    expect(source, contains("'Let App Assistant suggest possible drives'"));
    expect(source, contains('requestAutomaticEvidenceAuthorization'));
    expect(
      source,
      contains('App Assistant stays off until background location is allowed.'),
    );
    expect(
      source,
      contains('It never starts a workday or confirms mileage on its own.'),
    );
    expect(
      source,
      contains(
        'Confirmed odometer mileage is never changed without your review.',
      ),
    );
  });
}
