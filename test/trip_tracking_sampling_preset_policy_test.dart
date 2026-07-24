import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sampling_preset_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  const gpsOnly = TripTrackingPlatformCapabilities(
    locationAvailable: true,
    backgroundTrackingAvailable: true,
    activityRecognitionAvailable: false,
  );
  const sensorAssisted = TripTrackingPlatformCapabilities(
    locationAvailable: true,
    backgroundTrackingAvailable: true,
    activityRecognitionAvailable: true,
    batteryStateAvailable: true,
    lowPowerModeAvailable: true,
  );

  test('every named preset has a bounded, distinct cadence', () {
    final intervals = <int>{};
    for (final preset in TripTrackingSamplingPreset.values.where(
      (preset) => preset != TripTrackingSamplingPreset.custom,
    )) {
      final plan = TripTrackingSamplingPresetPolicy.planFor(
        preset: preset,
        customIntervalSeconds: 15,
        capabilities: sensorAssisted,
      );
      expect(plan.sampling.interval.inSeconds, inInclusiveRange(1, 120));
      expect(plan.sampling.minimumDisplacementMeters, greaterThan(0));
      intervals.add(plan.sampling.interval.inSeconds);
    }

    expect(intervals, hasLength(5));
    final highAccuracy = TripTrackingSamplingPresetPolicy.planFor(
      preset: TripTrackingSamplingPreset.highAccuracy,
      customIntervalSeconds: 15,
      capabilities: sensorAssisted,
    );
    expect(highAccuracy.sampling.interval, const Duration(seconds: 2));
    expect(highAccuracy.sampling.minimumDisplacementMeters, 1);
  });

  test('capability tier controls evidence availability, not user cadence', () {
    final gpsOnlyPlan = TripTrackingSamplingPresetPolicy.planFor(
      preset: TripTrackingSamplingPreset.highAccuracy,
      customIntervalSeconds: 15,
      capabilities: gpsOnly,
    );
    final sensorAssistedPlan = TripTrackingSamplingPresetPolicy.planFor(
      preset: TripTrackingSamplingPreset.highAccuracy,
      customIntervalSeconds: 15,
      capabilities: sensorAssisted,
    );

    expect(gpsOnlyPlan.sampling, sensorAssistedPlan.sampling);
    expect(gpsOnlyPlan.walkingEvidenceAvailable, isFalse);
    expect(sensorAssistedPlan.walkingEvidenceAvailable, isTrue);
    expect(gpsOnlyPlan.batteryProtectionEvidenceAvailable, isFalse);
    expect(sensorAssistedPlan.batteryProtectionEvidenceAvailable, isTrue);
  });

  test('custom cadence is bounded before reaching a native request', () {
    final fast = TripTrackingSamplingPresetPolicy.planFor(
      preset: TripTrackingSamplingPreset.custom,
      customIntervalSeconds: -10,
      capabilities: gpsOnly,
    );
    final sparse = TripTrackingSamplingPresetPolicy.planFor(
      preset: TripTrackingSamplingPreset.custom,
      customIntervalSeconds: 500,
      capabilities: gpsOnly,
    );

    expect(fast.sampling.interval, const Duration(seconds: 3));
    expect(fast.sampling.minimumDisplacementMeters, 8);
    expect(sparse.sampling.interval, const Duration(seconds: 60));
  });

  test(
    'adaptive sampling cannot exceed the selected battery-saving cadence',
    () {
      final plan = TripTrackingSamplingPresetPolicy.planFor(
        preset: TripTrackingSamplingPreset.batterySaver,
        customIntervalSeconds: 15,
        capabilities: sensorAssisted,
      );
      final constrained = plan.constrainAdaptive(
        const TripSamplingRecommendation(
          mode: TripSamplingMode.precision,
          interval: Duration(seconds: 2),
          minimumDisplacementMeters: 3,
        ),
      );

      expect(constrained.mode, TripSamplingMode.economy);
      expect(constrained.interval, const Duration(seconds: 30));
      expect(constrained.minimumDisplacementMeters, 20);
    },
  );

  test(
    'adaptive sampling cannot raise GPS power mode behind a battery-saver selection',
    () {
      final plan = TripTrackingSamplingPresetPolicy.planFor(
        preset: TripTrackingSamplingPreset.batterySaver,
        customIntervalSeconds: 15,
        capabilities: sensorAssisted,
      );

      final constrained = plan.constrainAdaptive(
        const TripSamplingRecommendation(
          mode: TripSamplingMode.precision,
          interval: Duration(seconds: 60),
          minimumDisplacementMeters: 30,
        ),
      );

      expect(constrained.mode, TripSamplingMode.economy);
      expect(constrained.interval, const Duration(seconds: 60));
      expect(constrained.minimumDisplacementMeters, 30);
    },
  );

  test(
    'adaptive sampling may reduce power mode when its cadence stays within the user plan',
    () {
      final plan = TripTrackingSamplingPresetPolicy.planFor(
        preset: TripTrackingSamplingPreset.balanced,
        customIntervalSeconds: 15,
        capabilities: sensorAssisted,
      );

      final constrained = plan.constrainAdaptive(
        const TripSamplingRecommendation(
          mode: TripSamplingMode.economy,
          interval: Duration(seconds: 30),
          minimumDisplacementMeters: 20,
        ),
      );

      expect(constrained.mode, TripSamplingMode.economy);
      expect(constrained.interval, const Duration(seconds: 30));
      expect(constrained.minimumDisplacementMeters, 20);
    },
  );

  test('safe diagnostics exclude location, identity, and authority', () {
    final safe = TripTrackingSamplingPresetPolicy.planFor(
      preset: TripTrackingSamplingPreset.enhancedAccuracy,
      customIntervalSeconds: 15,
      capabilities: sensorAssisted,
    ).toSafeLogMap();

    expect(safe['rawLocationIncluded'], isFalse);
    expect(safe['deviceIdentityIncluded'], isFalse);
    expect(safe['canAuthorizeTracking'], isFalse);
    expect(safe['canConfirmOdometerMileage'], isFalse);
  });
}
