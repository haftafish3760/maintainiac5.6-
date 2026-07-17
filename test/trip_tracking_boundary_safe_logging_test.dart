import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';

void main() {
  test('capability diagnostics summarize tiers without device identity', () {
    final capabilities = TripTrackingPlatformCapabilities.fromMap({
      'locationAvailable': true,
      'backgroundTrackingAvailable': true,
      'activityRecognitionAvailable': true,
      'batteryStateAvailable': true,
      'lowPowerModeAvailable': true,
      'deviceModel': 'private-model',
      'hardwareId': 'private-hardware',
    });

    final log = capabilities.toSafeLogMap();

    expect(log['locationAvailable'], isTrue);
    expect(log['backgroundTrackingAvailable'], isTrue);
    expect(log['activityRecognitionAvailable'], isTrue);
    expect(log['batteryStateAvailable'], isTrue);
    expect(log['lowPowerModeAvailable'], isTrue);
    expect(
      log['deviceTier'],
      TripTrackingDeviceCapabilityTier.motionAndBatteryAssist.name,
    );
    expect(log.containsKey('deviceModel'), isFalse);
    expect(log.containsKey('hardwareId'), isFalse);
  });

  test(
    'battery diagnostics bucket percentages instead of logging exact drain',
    () {
      expect(
        const TripTrackingBatterySnapshot(
          batteryPercent: null,
          isCharging: false,
          lowPowerModeEnabled: false,
        ).toSafeLogMap()['batteryPercentBucket'],
        'unknown',
      );
      expect(
        const TripTrackingBatterySnapshot(
          batteryPercent: 19,
          isCharging: false,
          lowPowerModeEnabled: true,
        ).toSafeLogMap(),
        {
          'batteryPercentBucket': 'critical',
          'isCharging': false,
          'lowPowerModeEnabled': true,
        },
      );
      expect(
        const TripTrackingBatterySnapshot(
          batteryPercent: 39,
          isCharging: true,
          lowPowerModeEnabled: false,
        ).toSafeLogMap()['batteryPercentBucket'],
        'low',
      );
      expect(
        const TripTrackingBatterySnapshot(
          batteryPercent: 79,
          isCharging: true,
          lowPowerModeEnabled: false,
        ).toSafeLogMap()['batteryPercentBucket'],
        'normal',
      );
      expect(
        const TripTrackingBatterySnapshot(
          batteryPercent: 80,
          isCharging: true,
          lowPowerModeEnabled: false,
        ).toSafeLogMap()['batteryPercentBucket'],
        'high',
      );
    },
  );

  test(
    'authorization diagnostics show permission state but not raw payloads',
    () {
      final authorization = TripTrackingAuthorization.fromMap(const {
        'state': 'always',
        'preciseLocation': true,
        'token': 'pk.private',
        'userId': 'private-user',
      });

      final log = authorization.toSafeLogMap();

      expect(log['state'], 'always');
      expect(log['preciseLocation'], isTrue);
      expect(log['canTrack'], isTrue);
      expect(log['canTrackInBackground'], isTrue);
      expect(log.containsKey('token'), isFalse);
      expect(log.containsKey('userId'), isFalse);
    },
  );

  test('location event diagnostics never expose precise coordinates', () {
    final event = TripTrackingPlatformEvent.fromMap({
      'type': 'location',
      'latitude': 35.227111,
      'longitude': -80.843124,
      'recordedAt': '2026-07-17T12:00:00.000Z',
      'horizontalAccuracyMeters': 4.5,
      'speedMetersPerSecond': 12.1,
    });

    final log = event.toSafeLogMap();
    final serialized = log.toString();

    expect(log['type'], 'location');
    expect(log['hasLocation'], isTrue);
    expect(log['locationAccuracyBucket'], 'high');
    expect(log['hasSpeed'], isTrue);
    expect(serialized, isNot(contains('35.227111')));
    expect(serialized, isNot(contains('-80.843124')));
    expect(serialized, isNot(contains('latitude')));
    expect(serialized, isNot(contains('longitude')));
  });

  test(
    'coarse and unusable location accuracy are visible without coordinates',
    () {
      final medium = TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        'latitude': 35.0,
        'longitude': -80.0,
        'recordedAt': '2026-07-17T12:00:00.000Z',
        'horizontalAccuracyMeters': 25,
      }).toSafeLogMap();
      final low = TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        'latitude': 35.0,
        'longitude': -80.0,
        'recordedAt': '2026-07-17T12:00:00.000Z',
        'horizontalAccuracyMeters': 120,
      }).toSafeLogMap();
      final unusable = TripTrackingPlatformEvent.fromMap({
        'type': 'location',
        'latitude': 35.0,
        'longitude': -80.0,
        'recordedAt': '2026-07-17T12:00:00.000Z',
        'horizontalAccuracyMeters': 900,
      }).toSafeLogMap();

      expect(medium['locationAccuracyBucket'], 'medium');
      expect(low['locationAccuracyBucket'], 'low');
      expect(unusable['locationAccuracyBucket'], 'unusable');
    },
  );

  test(
    'activity event diagnostics bucket confidence and avoid raw payloads',
    () {
      final event = TripTrackingPlatformEvent.fromMap({
        'type': 'activity',
        'activity': TripActivity.walking.name,
        'confidence': 72,
        'recordedAt': '2026-07-17T12:00:00.000Z',
        'rawProviderBlob': {'private': true},
      });

      final log = event.toSafeLogMap();

      expect(log['type'], 'activity');
      expect(log['hasActivity'], isTrue);
      expect(log['activity'], TripActivity.walking.name);
      expect(log['activityConfidenceBucket'], 'medium');
      expect(log.containsKey('rawProviderBlob'), isFalse);
    },
  );

  test('activity confidence buckets stay bounded', () {
    Map<String, Object?> activityLog(int confidence) =>
        TripTrackingPlatformEvent.fromMap({
          'type': 'activity',
          'activity': TripActivity.automotive.name,
          'confidence': confidence,
          'recordedAt': '2026-07-17T12:00:00.000Z',
        }).toSafeLogMap();

    expect(activityLog(95)['activityConfidenceBucket'], 'high');
    expect(activityLog(60)['activityConfidenceBucket'], 'medium');
    expect(activityLog(30)['activityConfidenceBucket'], 'low');
    expect(activityLog(5)['activityConfidenceBucket'], 'veryLow');
  });

  test(
    'authorization event diagnostics include only sanitized permission facts',
    () {
      final event = TripTrackingPlatformEvent.fromMap({
        'type': 'authorization',
        'state': 'whileInUse',
        'preciseLocation': true,
        'firebaseUid': 'private-user',
      });

      final log = event.toSafeLogMap();

      expect(log['type'], 'authorization');
      expect(log['hasAuthorization'], isTrue);
      expect(log['authorization'], {
        'state': 'whileInUse',
        'preciseLocation': true,
        'canTrack': true,
        'canTrackInBackground': false,
      });
      expect(log.containsKey('firebaseUid'), isFalse);
    },
  );

  test('native error diagnostics redact tokens and coordinates', () {
    final event = TripTrackingPlatformEvent.fromMap({
      'type': 'error',
      'errorCode': 'mapbox.pk.secret.35.227111',
      'errorMessage':
          'token=pk.secret failed at latitude=35.227111 longitude=-80.843124',
    });

    final log = event.toSafeLogMap();
    final serialized = log.toString();

    expect(log['type'], 'error');
    expect(log['errorCode'], 'unknownNativeEvent');
    expect(serialized, contains('token=[redacted]'));
    expect(serialized, contains('latitude=[redacted]'));
    expect(serialized, contains('longitude=[redacted]'));
    expect(serialized, isNot(contains('pk.secret')));
    expect(serialized, isNot(contains('35.227111')));
    expect(serialized, isNot(contains('-80.843124')));
  });

  test('native status diagnostics accept only known lifecycle states', () {
    for (final status in const ['idle', 'tracking', 'stopped']) {
      final event = TripTrackingPlatformEvent.fromMap({
        'type': 'status',
        'status': status,
      });

      expect(event.type, TripTrackingPlatformEventType.status);
      expect(event.toSafeLogMap()['status'], status);
    }

    final invalid = TripTrackingPlatformEvent.fromMap(const {
      'type': 'status',
      'status': 'tracking:35.227111,-80.843124',
    });

    expect(invalid.type, TripTrackingPlatformEventType.error);
    expect(invalid.toSafeLogMap()['errorCode'], 'invalidStatusPayload');
  });
}
