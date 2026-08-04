// Production-wiring contract for the opt-in App Assistant observer.
//
// Owns static protection of bootstrap and lifecycle wiring. Does not validate
// native provider behavior, location accuracy, or customer-field results.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App Assistant observer is bootstrapped and lifecycle-synchronized', () {
    final main = File('lib/main.dart').readAsStringSync();
    final app = File('lib/app/maintaniac_app.dart').readAsStringSync();

    expect(
      main,
      contains('final tripTrackingPlatform = TripTrackingPlatform()'),
    );
    expect(main, contains('gateway: tripTrackingPlatform'));
    expect(main, contains('syncAutomaticEvidenceObservation();'));
    expect(
      main,
      contains(
        'tripTrackingSettings.addListener(syncAutomaticEvidenceObservation)',
      ),
    );
    expect(main, contains('syncAutomaticEvidenceForTripLifecycle'));
    expect(main, contains('automaticEvidenceRuntime:'));
    expect(main, contains('automaticEvidenceRuntime,'));
    expect(app, contains('widget.automaticEvidenceRuntime.synchronize()'));
    expect(app, contains('widget.automaticEvidenceRuntime.dispose()'));
  });
}
