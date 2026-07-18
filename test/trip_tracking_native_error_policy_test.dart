import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_native_error_policy.dart';

void main() {
  test('recoverable native GPS errors are explicit allow-list only', () {
    for (final code in [
      'trip_tracking_foreground_service_denied',
      'trip_tracking_location_registration_failed',
      'trip_tracking_location_denied',
      'trip_tracking_gps_unavailable',
      'trip_tracking_gps_disabled',
    ]) {
      expect(TripTrackingNativeErrorPolicy.requiresRecovery(code), isTrue);
    }

    expect(TripTrackingNativeErrorPolicy.requiresRecovery(null), isFalse);
    expect(TripTrackingNativeErrorPolicy.requiresRecovery(''), isFalse);
    expect(
      TripTrackingNativeErrorPolicy.requiresRecovery(
        'trip_tracking_token_pk_should_not_leak',
      ),
      isFalse,
    );
  });

  test(
    'malformed payload errors are ignored without interrupting tracking',
    () {
      for (final code in [
        'invalidLocationPayload',
        'invalidActivityPayload',
        'invalidNativeEventPayload',
        'invalidStatusPayload',
      ]) {
        expect(
          TripTrackingNativeErrorPolicy.isIgnorableMalformedPayload(code),
          isTrue,
        );
      }

      expect(
        TripTrackingNativeErrorPolicy.isIgnorableMalformedPayload(
          'trip_tracking_gps_disabled',
        ),
        isFalse,
      );
    },
  );

  test('native error messages never echo raw native error payloads', () {
    const sensitiveRawCode =
        'mapbox_pk_or_precise_location_35.1_-80.9_should_not_echo';

    expect(
      TripTrackingNativeErrorPolicy.safeMessage(sensitiveRawCode),
      'GPS reported a device error.',
    );
    expect(
      TripTrackingNativeErrorPolicy.safeMessage(sensitiveRawCode),
      isNot(contains('35.1')),
    );
    expect(
      TripTrackingNativeErrorPolicy.safeMessage(sensitiveRawCode),
      isNot(contains('pk')),
    );
  });
}
