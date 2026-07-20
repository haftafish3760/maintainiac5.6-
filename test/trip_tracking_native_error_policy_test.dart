import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_native_error_policy.dart';

void main() {
  test('recoverable native GPS errors are explicit allow-list only', () {
    for (final code in [
      'trip_tracking_foreground_service_denied',
      'trip_tracking_location_registration_failed',
      'trip_tracking_location_denied',
      'trip_tracking_background_location_denied',
      'trip_tracking_location_accuracy_reduced',
      'trip_tracking_location_error',
      'trip_tracking_gps_unavailable',
      'trip_tracking_gps_disabled',
      'trip_tracking_battery_critical',
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
    expect(
      TripTrackingNativeErrorPolicy.safeMessage('trip_tracking_location_error'),
      'The device could not continue GPS trip tracking.',
    );
    expect(
      TripTrackingNativeErrorPolicy.safeMessage(
        'trip_tracking_location_accuracy_reduced',
      ),
      'Precise GPS access was reduced while tracking.',
    );
    expect(
      TripTrackingNativeErrorPolicy.safeMessage(
        'trip_tracking_activity_unavailable',
      ),
      'Walking-assisted stop evidence is unavailable. GPS tracking continues without it.',
    );
    expect(
      TripTrackingNativeErrorPolicy.safeMessage(
        'trip_tracking_sampling_update_failed',
      ),
      'The device could not apply the requested GPS sampling change.',
    );
    expect(
      TripTrackingNativeErrorPolicy.safeMessage(
        'trip_tracking_permission_busy',
      ),
      'Another GPS permission request is already in progress.',
    );
  });

  test('native error summaries expose only allow-listed codes', () {
    final denied = TripTrackingNativeErrorPolicy.toSafeSummary(
      'trip_tracking_location_denied',
    );
    final malformed = TripTrackingNativeErrorPolicy.toSafeSummary(
      'invalidLocationPayload',
    );
    final unknown = TripTrackingNativeErrorPolicy.toSafeSummary(
      'token=sk.secret lat=35.1',
    );

    expect(denied['nativeErrorCode'], 'trip_tracking_location_denied');
    expect(denied['recoverable'], isTrue);
    expect(denied['requiresUserAction'], isTrue);
    expect(denied['externalNativeErrorTrustedAfterValidationOnly'], isTrue);
    expect(denied['nativeErrorCanDeleteLocalTripData'], isFalse);
    expect(denied['nativeErrorCanOverrideOdometer'], isFalse);
    expect(malformed['ignorableMalformedPayload'], isTrue);
    expect(malformed['gpsCanContinueOffline'], isTrue);
    expect(malformed['firestoreErrorCanOverrideGpsState'], isFalse);
    expect(malformed['mapboxServiceFailureStopsGpsTracking'], isFalse);
    expect(malformed['malformedNativeErrorFailsSafe'], isTrue);
    expect(malformed['malformedPayloadCanStopTrip'], isFalse);
    expect(unknown['nativeErrorCode'], 'unknown_native_gps_error');
    expect(unknown['rawNativePayloadIncluded'], isFalse);
    expect(unknown['mapboxErrorCanCorruptTripLog'], isFalse);
    expect(unknown['odometerRemainsCanonical'], isTrue);
    expect(unknown.toString(), isNot(contains('sk.secret')));
    expect(unknown.toString(), isNot(contains('35.1')));

    final activityUnavailable = TripTrackingNativeErrorPolicy.toSafeSummary(
      'trip_tracking_activity_unavailable',
    );
    expect(
      activityUnavailable['nativeErrorCode'],
      'trip_tracking_activity_unavailable',
    );
    expect(activityUnavailable['recoverable'], isFalse);
  });

  test('native error summaries validate as renderable', () {
    final validation = TripTrackingNativeErrorSummaryValidation.fromSummary(
      TripTrackingNativeErrorPolicy.toSafeSummary('trip_tracking_gps_disabled'),
    );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test(
    'background and precision revocations remain safe recoverable errors',
    () {
      for (final code in [
        'trip_tracking_background_location_denied',
        'trip_tracking_location_accuracy_reduced',
      ]) {
        final summary = TripTrackingNativeErrorPolicy.toSafeSummary(code);
        expect(summary['nativeErrorCode'], code);
        expect(summary['recoverable'], isTrue);
        expect(
          TripTrackingNativeErrorSummaryValidation.fromSummary(
            summary,
          ).isRenderable,
          isTrue,
        );
      }
    },
  );

  test('native error summary rejects forged status and truth claims', () {
    final validation = TripTrackingNativeErrorSummaryValidation.fromSummary({
      ...TripTrackingNativeErrorPolicy.toSafeSummary('invalidLocationPayload'),
      'recoverable': true,
      'requiresUserAction': false,
      'failClosedForGpsStartup': false,
      'nativeErrorCanDeleteLocalTripData': true,
      'nativeErrorCanOverrideOdometer': true,
      'firestoreErrorCanOverrideGpsState': true,
      'mapboxServiceFailureStopsGpsTracking': true,
      'mapboxErrorCanCorruptTripLog': true,
      'odometerRemainsCanonical': false,
      'rawNativePayloadIncluded': true,
      'preciseLocationIncluded': true,
      'tokensIncluded': true,
      'debug': 'token=sk.secret 35.123456,-80.123456',
    });

    expect(validation.isRenderable, isFalse);
    expect(
      validation.reasons,
      contains('native_error_status_conflicts_with_authority'),
    );
    expect(validation.reasons, contains('native_error_can_mutate_trip_truth'));
    expect(
      validation.reasons,
      contains('summary_contains_sensitive_native_error_material'),
    );
  });
}
