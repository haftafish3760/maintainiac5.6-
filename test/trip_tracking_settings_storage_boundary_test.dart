import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trip settings do not own Firebase account or SDK wiring', () {
    final source = File(
      'lib/screens/settings/trip_tracking_settings_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('package:firebase_')));
    expect(source, isNot(contains('Firebase.')));
    expect(source, isNot(contains('MaintainiacAuthService')));
    expect(source, isNot(contains('trip_tracking_settings_account_panel')));
    expect(source, contains('Back up reviewed mileage'));
  });
}
