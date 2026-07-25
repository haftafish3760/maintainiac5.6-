import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trip gate includes production dashboard wiring boundaries', () {
    final source = File('tool/trip_tracking_qa_gate.sh').readAsStringSync();

    for (final requiredTest in <String>[
      'active_workday_gps_start_integration_test.dart',
      'active_workday_trip_event_handoff_test.dart',
      'contractor_dashboard_trip_stop_handoff_test.dart',
      'dashboard_round_start_gps_integration_test.dart',
      'dashboard_live_odometer_block_test.dart',
      'dashboard_mode_routing_test.dart',
      'dashboard_trip_settings_navigation_test.dart',
      'dashboard_trip_cancellation_wiring_test.dart',
      'dashboard_walking_stop_review_wiring_test.dart',
      'vehicle_profile_live_odometer_test.dart',
    ]) {
      expect(source, contains(requiredTest), reason: requiredTest);
    }
    expect(source, contains('--concurrency=1'));
  });
}
