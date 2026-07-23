import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'GPS-derived lifecycle changes use the controlled rejection boundary',
    () {
      final source = File(
        'lib/shared/trip_tracking/trip_tracking_controller_ingestion.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('TripTrackingSessionStateMachine.evaluateTransition'),
      );
      expect(
        source,
        contains('TripTrackingSessionContractStateMachine.evaluateTransition'),
      );
      expect(source, contains('if (!runtimeAllowed || !contractAllowed)'));
      expect(source, contains('_engine = TripTrackingEngine.fromSnapshot'));
      expect(source, contains("source: 'gps_sample_ingestion'"));
      expect(source, isNot(contains('requireTransition(')));
    },
  );

  test('deferred recovery replay shares the serialized ingestion queue', () {
    final source = File(
      'lib/shared/trip_tracking/trip_tracking_controller_pending_recovery.dart',
    ).readAsStringSync();

    expect(source, contains('await _enqueueIngestion('));
    expect(source, contains('pendingToReplay.sample'));
    expect(source, contains('activity: pendingToReplay.activity'));
  });
}
