import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';

void main() {
  test('native request preserves the adaptive sampling recommendation', () {
    const policy = TripTrackingPolicy();
    final request = TripTrackingNativeRequest(
      profile: TripTrackingProfile.roadVehicle,
      sampling: policy.samplingFor(
        speedMetersPerSecond: 16,
        vehicleMovementConfirmed: true,
      ),
    );

    expect(request.toMap()['intervalMillis'], 2000);
    expect(request.toMap()['minimumDisplacementMeters'], 3.0);
  });

  test('native request bounds malformed sampling recommendations', () {
    const tooFast = TripTrackingNativeRequest(
      profile: TripTrackingProfile.roadVehicle,
      sampling: TripSamplingRecommendation(
        mode: TripSamplingMode.precision,
        interval: Duration(milliseconds: -500),
        minimumDisplacementMeters: double.nan,
      ),
    );
    const tooSparse = TripTrackingNativeRequest(
      profile: TripTrackingProfile.roadVehicle,
      sampling: TripSamplingRecommendation(
        mode: TripSamplingMode.economy,
        interval: Duration(minutes: 30),
        minimumDisplacementMeters: 2000,
      ),
    );

    expect(tooFast.toMap()['intervalMillis'], 1000);
    expect(tooFast.toMap()['minimumDisplacementMeters'], 0);
    expect(tooSparse.toMap()['intervalMillis'], 120000);
    expect(tooSparse.toMap()['minimumDisplacementMeters'], 1000);
  });

  test('iOS bridge maps every road-style profile to automotive navigation', () {
    final source = File(
      'ios/Runner/TripTrackingNativeBridge.swift',
    ).readAsStringSync();

    expect(source, contains('private func isRoadStyleProfile'));
    for (final profile in const [
      'roadVehicle',
      'rideshareVehicle',
      'deliveryVehicle',
      'contractorVehicle',
    ]) {
      expect(source, contains('"$profile"'), reason: profile);
    }
    expect(
      source,
      contains('isRoadStyleProfile(profile) ? .automotiveNavigation'),
    );
  });

  test('an explicitly started trip has a responsive adaptive baseline', () {
    const policy = TripTrackingPolicy();

    expect(
      policy
          .samplingFor(
            speedMetersPerSecond: null,
            vehicleMovementConfirmed: false,
            activeTrip: true,
          )
          .interval,
      const Duration(seconds: 5),
    );
  });

  test('native capability payloads resolve to conservative device tiers', () {
    final gpsOnly = TripTrackingPlatformCapabilities.fromMap({
      'locationAvailable': true,
      'backgroundTrackingAvailable': true,
      'activityRecognitionAvailable': false,
      'batteryStateAvailable': false,
    });
    final motion = TripTrackingPlatformCapabilities.fromMap({
      'locationAvailable': true,
      'activityRecognitionAvailable': true,
      'batteryStateAvailable': false,
    });
    final richer = TripTrackingPlatformCapabilities.fromMap({
      'locationAvailable': true,
      'activityRecognitionAvailable': true,
      'batteryStateAvailable': true,
      'lowPowerModeAvailable': true,
    });

    expect(gpsOnly.deviceTier, TripTrackingDeviceCapabilityTier.locationOnly);
    expect(motion.deviceTier, TripTrackingDeviceCapabilityTier.motionAssist);
    expect(
      richer.deviceTier,
      TripTrackingDeviceCapabilityTier.motionAndBatteryAssist,
    );
    expect(richer.lowPowerModeAvailable, isTrue);
  });

  test('malformed native capability values are not trusted', () {
    final capabilities = TripTrackingPlatformCapabilities.fromMap({
      'locationAvailable': 'true',
      'backgroundTrackingAvailable': 1,
      'activityRecognitionAvailable': 'yes',
      'batteryStateAvailable': Object(),
      'lowPowerModeAvailable': null,
    });

    expect(capabilities.locationAvailable, isFalse);
    expect(capabilities.backgroundTrackingAvailable, isFalse);
    expect(capabilities.activityRecognitionAvailable, isFalse);
    expect(capabilities.batteryStateAvailable, isFalse);
    expect(capabilities.lowPowerModeAvailable, isFalse);
    expect(
      capabilities.deviceTier,
      TripTrackingDeviceCapabilityTier.unavailable,
    );
  });

  test('malformed native battery snapshots are not trusted', () {
    final valid = TripTrackingBatterySnapshot.fromMap({
      'batteryPercent': 19.4,
      'isCharging': true,
      'lowPowerModeEnabled': true,
    });
    final invalid = TripTrackingBatterySnapshot.fromMap({
      'batteryPercent': 500,
      'isCharging': 'true',
      'lowPowerModeEnabled': 1,
    });

    expect(valid.batteryPercent, 19);
    expect(valid.isCharging, isTrue);
    expect(valid.lowPowerModeEnabled, isTrue);
    expect(invalid.batteryPercent, isNull);
    expect(invalid.isCharging, isFalse);
    expect(invalid.lowPowerModeEnabled, isFalse);
  });

  test(
    'platform event maps only a declared location payload into a sample',
    () {
      final event = TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        'latitude': 35.2,
        'longitude': -80.8,
        'recordedAt': '2026-07-13T12:00:00.000Z',
        'horizontalAccuracyMeters': 4.5,
        'speedMetersPerSecond': 8.1,
      });

      expect(event.type, TripTrackingPlatformEventType.location);
      expect(event.location?.horizontalAccuracyMeters, 4.5);
      expect(event.location?.speedMetersPerSecond, 8.1);
    },
  );

  test('unknown native event types fail closed as errors', () {
    final event = TripTrackingPlatformEvent.fromMap({'type': 'unexpected'});

    expect(event.type, TripTrackingPlatformEventType.error);
    expect(event.location, isNull);
  });

  test('native status and error strings are bounded before use', () {
    final status = TripTrackingPlatformEvent.fromMap({
      'type': 'status',
      'status': ' stopped ',
      'errorCode': 'ignored/because/status',
    });
    final unsafeError = TripTrackingPlatformEvent.fromMap({
      'type': 'error',
      'errorCode': 'trip_tracking_${'x' * 100}',
      'errorMessage': 'first line\nsecond line',
    });
    final longMessage = TripTrackingPlatformEvent.fromMap({
      'type': 'error',
      'errorCode': 'trip_tracking_gps_disabled',
      'errorMessage': 'm' * 240,
    });
    final sensitiveMessage = TripTrackingPlatformEvent.fromMap({
      'type': 'error',
      'errorCode': 'trip_tracking_gps_disabled',
      'errorMessage': 'token=pk.secret lat=35.123 lon=-80.456',
    });

    expect(status.status, 'stopped');
    expect(status.errorCode, isNull);
    expect(unsafeError.errorCode, isNull);
    expect(unsafeError.errorMessage, 'first line second line');
    expect(longMessage.errorCode, 'trip_tracking_gps_disabled');
    expect(longMessage.errorMessage, hasLength(160));
    expect(sensitiveMessage.errorMessage, isNot(contains('pk.secret')));
    expect(sensitiveMessage.errorMessage, isNot(contains('35.123')));
    expect(sensitiveMessage.errorMessage, contains('token=[redacted]'));
  });

  test('malformed location payloads fail closed without fabricated values', () {
    final event = TripTrackingPlatformEvent.fromMap({
      'type': 'location',
      'latitude': 35.2,
      'horizontalAccuracyMeters': 4.5,
    });

    expect(event.type, TripTrackingPlatformEventType.error);
    expect(event.location, isNull);
    expect(event.errorCode, 'invalidLocationPayload');
  });

  test('non-finite native timestamps fail closed without throwing', () {
    final event = TripTrackingPlatformEvent.fromMap({
      'type': 'location',
      'latitude': 35.2,
      'longitude': -80.8,
      'recordedAt': double.nan,
      'horizontalAccuracyMeters': 4.5,
    });

    expect(event.type, TripTrackingPlatformEventType.error);
    expect(event.errorCode, 'invalidLocationPayload');
  });

  test('untrusted native speed is sanitized without dropping a valid fix', () {
    for (final speed in [double.nan, double.infinity, -1.0]) {
      final event = TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        'latitude': 35.2,
        'longitude': -80.8,
        'recordedAt': '2026-07-13T12:00:00.000Z',
        'horizontalAccuracyMeters': 4.5,
        'speedMetersPerSecond': speed,
      });

      expect(event.type, TripTrackingPlatformEventType.location);
      expect(event.location?.speedMetersPerSecond, isNull);
    }
  });

  test('malformed activity payloads cannot invent walking evidence', () {
    final event = TripTrackingPlatformEvent.fromMap({
      'type': 'activity',
      'activity': 'walking',
      'confidence': 100,
    });

    expect(event.type, TripTrackingPlatformEventType.error);
    expect(event.activity, isNull);
    expect(event.errorCode, 'invalidActivityPayload');
  });

  test('non-finite activity confidence fails closed without throwing', () {
    final event = TripTrackingPlatformEvent.fromMap({
      'type': 'activity',
      'activity': 'walking',
      'confidence': double.nan,
      'recordedAt': '2026-07-13T12:00:00.000Z',
    });

    expect(event.type, TripTrackingPlatformEventType.error);
    expect(event.errorCode, 'invalidActivityPayload');
  });
}
