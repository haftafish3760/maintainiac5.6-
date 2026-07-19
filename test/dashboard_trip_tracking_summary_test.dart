import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_trip_tracking_summary.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_durable_record_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('manual default dashboard summary stays local and GPS off', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(),
    );

    expect(summary.dashboardMode, 'default');
    expect(summary.workStyle, 'general_road');
    expect(summary.stopDetectionMode, 'walking_assisted');
    expect(summary.stopReviewReasonCode, 'road_vehicle_stop_walk_review');
    expect(summary.stopSignal, 'no_stop');
    expect(summary.stopActionToken, 'keep_tracking');
    expect(summary.stopClassificationReason, 'no_stop_review_needed');
    expect(summary.recommendedActivityRecognition, isTrue);
    expect(summary.requiresStrongerStopDebounce, isFalse);
    expect(summary.recoveryState, 'none');
    expect(summary.recoveryReason, 'trip_recovery_none');
    expect(summary.recoveryUserActionRequired, isFalse);
    expect(summary.mileageMode, 'manual');
    expect(summary.syncMode, 'wifi_and_mobile');
    expect(summary.gpsAssistState, 'off');
    expect(summary.gpsSignalQuality, 'no_samples');
    expect(summary.gpsSignalReason, 'gps_signal_waiting_for_samples');
    expect(summary.gpsSignalReviewRequired, isFalse);
    expect(summary.mapboxAssistState, 'disabled');
    expect(summary.mapboxAssistReason, 'mapbox_assist_disabled');
    expect(summary.mapboxAssistReviewRequired, isFalse);
    expect(summary.mapboxTrustedMileageSource, 'none');
    expect(summary.mapboxRouteDistanceMiles, isNull);
    expect(summary.mapboxRouteDeltaMiles, isNull);
    expect(summary.mapPreviewEnabled, isFalse);
    expect(summary.mapRouteHistorySavingEnabled, isFalse);
    expect(summary.mapRouteHistoryDailyBudgetMb, 0);
    expect(summary.mapRouteHistorySampleIntervalSeconds, 30);
    expect(summary.mapRouteHistoryState, 'disabled');
    expect(summary.mapRouteHistoryEstimatedSamplesPerDay, 960);
    expect(summary.mapRouteHistoryEstimatedDailyMb, 0.088);
    expect(summary.storageState, 'unknown');
    expect(summary.deviceCapabilityState, 'unknown');
    expect(summary.sensorAssistState, 'unknown');
    expect(summary.durableRecordBackupState, 'not_configured');
    expect(summary.odometerCalibrationState, 'disabled');
    expect(summary.odometerCalibrationSamples, isNull);
    expect(summary.odometerCalibrationMultiplier, isNull);
    expect(summary.odometerUsageState, 'disabled');
    expect(summary.odometerUsageReviewedDays, isNull);
    expect(summary.freeSyncsRemaining, isNull);
    expect(summary.syncsUsedInWindow, isNull);
    expect(summary.batteryGpsLimited, isFalse);
    expect(summary.reviewRequired, isFalse);
    expect(summary.hasVerifiedSyncCounters, isFalse);
  });

  test('delivery dashboard summary maps gig profile and verified syncs', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1.5,
        mapRouteHistorySampleIntervalSeconds: 60,
        defaultProfile: TripTrackingProfile.deliveryVehicle,
        backupNetworkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      ),
      nativeTracking: true,
      storageState: 'text_record_safe',
      wifiAvailable: true,
      mobileDataAvailable: false,
      syncsUsedInWindow: 2,
    );

    expect(summary.dashboardMode, 'gig_driver');
    expect(summary.workStyle, 'delivery');
    expect(summary.stopDetectionMode, 'walking_assisted');
    expect(summary.stopReviewReasonCode, 'delivery_stop_walk_review');
    expect(summary.stopSignal, 'no_stop');
    expect(summary.stopActionToken, 'keep_tracking');
    expect(summary.stopClassificationReason, 'no_stop_review_needed');
    expect(summary.recommendedActivityRecognition, isTrue);
    expect(summary.requiresStrongerStopDebounce, isFalse);
    expect(summary.recoveryState, 'none');
    expect(summary.mileageMode, 'gps_assisted');
    expect(summary.syncMode, 'wifi_only');
    expect(summary.gpsAssistState, 'on');
    expect(summary.storageState, 'text_record_safe');
    expect(summary.mapPreviewEnabled, isTrue);
    expect(summary.mapRouteHistorySavingEnabled, isTrue);
    expect(summary.mapRouteHistoryDailyBudgetMb, 1.5);
    expect(summary.mapRouteHistorySampleIntervalSeconds, 60);
    expect(summary.mapRouteHistoryState, 'within_budget');
    expect(summary.mapRouteHistoryEstimatedSamplesPerDay, 480);
    expect(summary.mapRouteHistoryEstimatedDailyMb, 0.044);
    expect(summary.deviceCapabilityState, 'unknown');
    expect(summary.sensorAssistState, 'unknown');
    expect(summary.freeSyncsRemaining, 4);
    expect(summary.syncsUsedInWindow, 2);
    expect(summary.hasVerifiedSyncCounters, isTrue);
  });

  test('contractor summary can mark low battery GPS protection', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.contractorVehicle,
        backupNetworkPolicy: TripTrackingBackupNetworkPolicy.mobileDataOnly,
      ),
      lowBatteryLimited: true,
      reviewRequired: true,
      storageState: 'low_storage',
      deviceCapabilityState: 'full_safety_assist',
      sensorAssistState: 'motion_battery_available',
      odometerCalibrationAssistEnabled: true,
      odometerCalibrationState: 'review_recommended',
      odometerCalibrationSamples: 7,
      odometerCalibrationMultiplier: 1.063829787,
      odometerUsageState: 'review_recommended',
      odometerUsageReviewedDays: 7,
      odometerUsageCurrentMiles: 180.04,
      odometerUsageAverageDailyMiles: 40.04,
      odometerUsageReviewThresholdMiles: 100.04,
      wifiAvailable: false,
      mobileDataAvailable: true,
      syncsUsedInWindow: 5,
    );

    expect(summary.dashboardMode, 'contractor');
    expect(summary.workStyle, 'contractor');
    expect(summary.stopDetectionMode, 'walking_assisted');
    expect(summary.stopReviewReasonCode, 'contractor_stop_walk_review');
    expect(summary.syncMode, 'mobile_only');
    expect(summary.gpsAssistState, 'battery_limited');
    expect(summary.storageState, 'low_storage');
    expect(summary.deviceCapabilityState, 'full_safety_assist');
    expect(summary.sensorAssistState, 'motion_battery_available');
    expect(summary.odometerCalibrationAssistEnabled, isFalse);
    expect(summary.odometerCalibrationState, 'review_recommended');
    expect(summary.odometerCalibrationSamples, 7);
    expect(summary.odometerCalibrationMultiplier, 1.0638);
    expect(summary.odometerUsageState, 'review_recommended');
    expect(summary.odometerUsageReviewedDays, 7);
    expect(summary.odometerUsageCurrentMiles, 180.0);
    expect(summary.odometerUsageAverageDailyMiles, 40.0);
    expect(summary.odometerUsageReviewThresholdMiles, 100.0);
    expect(summary.freeSyncsRemaining, 1);
    expect(summary.batteryGpsLimited, isTrue);
    expect(summary.reviewRequired, isTrue);
  });

  test('recoverable GPS trip uses advisory GPS state', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      recoverableTrip: true,
      nativeTracking: false,
    );

    expect(summary.gpsAssistState, 'gps_assisted');
    expect(summary.mileageMode, 'gps_assisted');
  });

  test('unsafe storage and malformed sync counters do not enter summary', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      storageState: 'raw_coordinates_enabled',
      deviceCapabilityState: 'precise_location_history',
      sensorAssistState: 'raw_motion_payload',
      odometerCalibrationState: 'raw_drift_payload',
      odometerCalibrationSamples: -1,
      odometerCalibrationMultiplier: double.nan,
      odometerUsageState: 'raw_average_payload',
      odometerUsageReviewedDays: -1,
      odometerUsageCurrentMiles: double.infinity,
      odometerUsageAverageDailyMiles: -1,
      odometerUsageReviewThresholdMiles: 20000,
      wifiAvailable: true,
      mobileDataAvailable: true,
      syncsUsedInWindow: -1,
    );

    expect(summary.storageState, 'unknown');
    expect(summary.deviceCapabilityState, 'unknown');
    expect(summary.sensorAssistState, 'unknown');
    expect(summary.odometerCalibrationState, 'unknown');
    expect(summary.odometerCalibrationSamples, isNull);
    expect(summary.odometerCalibrationMultiplier, isNull);
    expect(summary.odometerUsageState, 'unknown');
    expect(summary.odometerUsageReviewedDays, isNull);
    expect(summary.odometerUsageCurrentMiles, isNull);
    expect(summary.odometerUsageAverageDailyMiles, isNull);
    expect(summary.odometerUsageReviewThresholdMiles, isNull);
    expect(summary.freeSyncsRemaining, isNull);
    expect(summary.syncsUsedInWindow, isNull);
    expect(summary.hasVerifiedSyncCounters, isFalse);
  });

  test('free sync ceiling is reflected without claiming extra allowance', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      wifiAvailable: true,
      mobileDataAvailable: true,
      syncsUsedInWindow: HostedUsageLimits.freeUserSyncsPer24HourWindow,
    );

    expect(summary.freeSyncsRemaining, 0);
    expect(summary.syncsUsedInWindow, 6);
    expect(summary.hasVerifiedSyncCounters, isTrue);
  });

  test('runtime summary reports a recoverable local GPS trip', () async {
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );
    addTearDown(controller.dispose);
    addTearDown(odometer.dispose);

    final started = await controller.start(
      tripId: 'runtime_summary_trip',
      vehicleId: odometer.vehicleId,
      profile: TripTrackingProfile.deliveryVehicle,
      startedAt: DateTime.utc(2026, 7, 17, 8),
    );
    expect(started, isTrue);

    final summary = DashboardTripTrackingSummary.fromRuntime(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.deliveryVehicle,
      ),
      tripTracking: controller,
      storageCheck: const AppStorageCheck(
        availableBytes: AppStorageGuard.greenStorageBytes,
        operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
        requiredBytes:
            AppStorageGuard.mileageTrackingWriteBytes +
            AppStorageGuard.textRecordDeviceReserveBytes,
        purpose: AppStoragePurpose.mileageTracking,
      ),
      wifiAvailable: true,
      mobileDataAvailable: false,
      syncsUsedInWindow: 1,
    );

    expect(summary.dashboardMode, 'gig_driver');
    expect(summary.mileageMode, 'gps_assisted');
    expect(summary.gpsAssistState, 'gps_assisted');
    expect(summary.recoveryState, 'ready');
    expect(summary.recoveryReason, 'trip_recovery_ready');
    expect(summary.recoveryUserActionRequired, isFalse);
    expect(summary.storageState, 'text_record_safe');
    expect(summary.freeSyncsRemaining, 5);
    expect(summary.reviewRequired, isFalse);
  });

  test(
    'runtime summary mirrors device capability without raw sensor payloads',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
        platform: _SummaryNativeGateway(),
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);

      expect(
        await controller.start(
          tripId: 'runtime_summary_capability',
          vehicleId: odometer.vehicleId,
          profile: TripTrackingProfile.deliveryVehicle,
          startedAt: DateTime.utc(2026, 7, 17, 9),
        ),
        isTrue,
      );
      expect(
        await controller.startNativeTracking(allowBackground: true),
        isTrue,
      );

      final summary = DashboardTripTrackingSummary.fromRuntime(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          backgroundTrackingEnabled: true,
          activityRecognitionEnabled: true,
          defaultProfile: TripTrackingProfile.deliveryVehicle,
        ),
        tripTracking: controller,
      );

      expect(summary.gpsAssistState, 'on');
      expect(summary.deviceCapabilityState, 'full_safety_assist');
      expect(summary.sensorAssistState, 'motion_battery_available');
      expect(summary.usesSharedDeviceCapabilityProfile, isFalse);
      expect(summary.usesSharedDurableTripRecordStore, isTrue);
      expect(summary.durableTripRecordsReviewedOnly, isTrue);
      expect(summary.durableRecordBackupState, 'not_configured');
      expect(summary.gpsTrackingCanRunWithoutMaps, isTrue);
      expect(summary.mapsRequiredForTracking, isFalse);
      expect(summary.rawGpsIncluded, isFalse);
      expect(summary.rawMapboxGeometryIncluded, isFalse);
    },
  );

  test(
    'runtime summary can prefer shared device profile policy over raw guesses',
    () {
      final summary = DashboardTripTrackingSummary.fromRuntime(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          backgroundTrackingEnabled: true,
          activityRecognitionEnabled: true,
          mapRouteHistorySavingEnabled: true,
          mapRouteHistorySampleIntervalSeconds: 15,
        ),
        deviceCapabilityProfile: _deviceProfile(
          tier: DevicePerformanceTier.entry,
          batteryPercent: 18,
          powerSaving: true,
          sensorTypes: const {'accelerometer', 'gyroscope'},
          wifiUnmetered: false,
        ),
      );

      expect(summary.usesSharedDeviceCapabilityProfile, isTrue);
      expect(summary.deviceCapabilityState, 'foreground_ready');
      expect(summary.sensorAssistState, 'motion_battery_available');
      expect(summary.mapRouteHistorySavingEnabled, isFalse);
      expect(summary.mapRouteHistorySampleIntervalSeconds, 15);
      expect(summary.gpsTrackingCanRunWithoutMaps, isTrue);
      expect(summary.mapsRequiredForTracking, isFalse);
      expect(summary.rawGpsIncluded, isFalse);
      expect(summary.rawMapboxGeometryIncluded, isFalse);
    },
  );

  test('runtime summary reports configured durable trip backup state', () {
    final controller = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      durableRecordBridge: TripTrackingDurableRecordBridge(
        MaintainiacDurableRecordStore.memory(),
      ),
    );
    addTearDown(controller.dispose);

    final summary = DashboardTripTrackingSummary.fromRuntime(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      tripTracking: controller,
    );

    expect(summary.usesSharedDurableTripRecordStore, isTrue);
    expect(summary.durableTripRecordsReviewedOnly, isTrue);
    expect(summary.durableRecordBackupState, 'available');
    expect(summary.rawGpsIncluded, isFalse);
    expect(summary.rawMapboxGeometryIncluded, isFalse);
  });

  test(
    'runtime summary mirrors stop-review tokens without raw GPS history',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
      );
      final startedAt = DateTime.utc(2026, 7, 17, 10);
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);

      expect(
        await controller.start(
          tripId: 'runtime_summary_stop_review',
          vehicleId: odometer.vehicleId,
          profile: TripTrackingProfile.deliveryVehicle,
          startedAt: startedAt,
        ),
        isTrue,
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: startedAt,
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 9,
        ),
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -79.999,
          recordedAt: startedAt.add(const Duration(seconds: 20)),
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 9,
        ),
      );
      for (final seconds in const [40, 60, 80, 100]) {
        await controller.ingest(
          TripLocationSample(
            latitude: 35,
            longitude: -79.999,
            recordedAt: startedAt.add(Duration(seconds: seconds)),
            horizontalAccuracyMeters: 5,
            speedMetersPerSecond: 0,
          ),
          activity: TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 95,
            recordedAt: startedAt.add(Duration(seconds: seconds)),
          ),
        );
      }

      final summary = DashboardTripTrackingSummary.fromRuntime(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          defaultProfile: TripTrackingProfile.deliveryVehicle,
        ),
        tripTracking: controller,
      );

      expect(summary.stopSignal, 'review_only_stop');
      expect(summary.stopActionToken, 'review_delivery_stop');
      expect(summary.stopClassificationReason, 'delivery_stop_walk_review');
      expect(summary.gpsSignalQuality, 'poor');
      expect(summary.gpsSignalReason, 'gps_signal_poor_measurement_quality');
      expect(summary.gpsSignalReviewRequired, isFalse);
      expect(summary.reviewRequired, isTrue);
    },
  );

  test(
    'runtime summary mirrors odometer calibration as review-only state',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      for (var index = 0; index < 7; index += 1) {
        await store.saveReview(
          _confirmedReview(
            id: 'calibration_$index',
            startedAt: DateTime.utc(2026, 7, 1 + index, 8),
            filteredGpsMiles: 110,
            odometerMiles: 100,
          ),
        );
      }

      final summary = DashboardTripTrackingSummary.fromRuntime(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          odometerAnomalyAlertsEnabled: true,
          gpsOdometerCalibrationAssistEnabled: true,
        ),
        tripTracking: controller,
      );

      expect(summary.odometerCalibrationState, 'review_recommended');
      expect(summary.odometerCalibrationAssistEnabled, isTrue);
      expect(summary.odometerCalibrationSamples, 7);
      expect(summary.odometerCalibrationMultiplier, closeTo(.9091, .0001));
      expect(
        controller.odometerCalibrationSignal().canOverwriteConfirmedOdometer,
        isFalse,
      );
    },
  );

  test(
    'runtime summary recommends usage review without changing odometer truth',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1300,
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
      );
      final activeWorkday = ActiveWorkdaySessionRecord(
        id: 'workday_usage',
        vehicleId: 'vehicle_1',
        vehicleLabel: 'Truck',
        workProfileId: 'delivery',
        startedAt: DateTime.utc(2026, 7, 17, 8),
        startOdometer: 1000,
        status: ActiveWorkdayStatus.active,
        events: const [],
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      for (var index = 0; index < 7; index += 1) {
        await store.saveReview(
          _confirmedReview(
            id: 'usage_$index',
            startedAt: DateTime.utc(2026, 7, 1 + index, 8),
            filteredGpsMiles: 40,
            odometerMiles: 40,
          ),
        );
      }

      final summary = DashboardTripTrackingSummary.fromRuntime(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          odometerAnomalyAlertsEnabled: true,
        ),
        tripTracking: controller,
        activeWorkday: activeWorkday,
      );

      expect(summary.odometerUsageState, 'review_recommended');
      expect(summary.odometerUsageReviewedDays, 7);
      expect(summary.odometerUsageCurrentMiles, 300.0);
      expect(summary.odometerUsageAverageDailyMiles, 40.0);
      expect(summary.odometerUsageReviewThresholdMiles, 100.0);
      expect(summary.reviewRequired, isTrue);
      expect(
        controller
            .odometerUsageAnomalySignalForCurrentDay(
              startingOdometer: activeWorkday.startOdometer,
            )
            .canAutoCorrectOdometer,
        isFalse,
      );
    },
  );

  test(
    'runtime summary prefers a confirmed same-weekday mileage baseline',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1150,
      );
      final store = TripTrackingSessionStore.memory();
      final controller = TripTrackingController(
        sessionStore: store,
        odometer: odometer,
        clockNow: () => DateTime.utc(2026, 7, 22, 12),
      );
      final activeWorkday = ActiveWorkdaySessionRecord(
        id: 'workday_weekday_usage',
        vehicleId: 'vehicle_1',
        vehicleLabel: 'Truck',
        workProfileId: 'delivery',
        startedAt: DateTime.utc(2026, 7, 22, 8),
        startOdometer: 1000,
        status: ActiveWorkdayStatus.active,
        events: const [],
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      for (final day in const [1, 8, 15]) {
        await store.saveReview(
          _confirmedReview(
            id: 'wednesday_$day',
            startedAt: DateTime.utc(2026, 7, day, 8),
            filteredGpsMiles: 50,
            odometerMiles: 50,
          ),
        );
      }
      for (final day in const [2, 3, 4, 5, 6, 7, 9]) {
        await store.saveReview(
          _confirmedReview(
            id: 'other_day_$day',
            startedAt: DateTime.utc(2026, 7, day, 8),
            filteredGpsMiles: 300,
            odometerMiles: 300,
          ),
        );
      }

      final summary = DashboardTripTrackingSummary.fromRuntime(
        settings: const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          odometerAnomalyAlertsEnabled: true,
        ),
        tripTracking: controller,
        activeWorkday: activeWorkday,
      );

      expect(summary.odometerUsageState, 'review_recommended');
      expect(summary.odometerUsageReviewedDays, 3);
      expect(summary.odometerUsageAverageDailyMiles, 50.0);
      expect(summary.odometerUsageReviewThresholdMiles, 125.0);
      expect(summary.reviewRequired, isTrue);
    },
  );

  test('runtime summary marks paused workday as requiring review', () {
    final activeWorkday = ActiveWorkdaySessionRecord(
      id: 'workday_1',
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Truck',
      workProfileId: 'contractor',
      startedAt: DateTime.utc(2026, 7, 17, 8),
      startOdometer: 1000,
      status: ActiveWorkdayStatus.paused,
      events: const [],
    );

    final summary = DashboardTripTrackingSummary.fromRuntime(
      settings: const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.contractorVehicle,
      ),
      activeWorkday: activeWorkday,
    );

    expect(summary.dashboardMode, 'contractor');
    expect(summary.reviewRequired, isTrue);
    expect(summary.gpsAssistState, 'gps_assisted');
  });

  test('runtime summary maps battery and storage safety states', () {
    final lowStorage = DashboardTripTrackingSummary.fromRuntime(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      storageCheck: const AppStorageCheck(
        availableBytes: AppStorageGuard.orangeStorageBytes,
        operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
        requiredBytes:
            AppStorageGuard.mileageTrackingWriteBytes +
            AppStorageGuard.textRecordDeviceReserveBytes,
        purpose: AppStoragePurpose.mileageTracking,
      ),
      platformStatus: 'low_battery_requires_user_choice',
    );
    final blocked = DashboardTripTrackingSummary.fromRuntime(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      storageCheck: const AppStorageCheck(
        availableBytes: 1,
        operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
        requiredBytes:
            AppStorageGuard.mileageTrackingWriteBytes +
            AppStorageGuard.textRecordDeviceReserveBytes,
        purpose: AppStoragePurpose.mileageTracking,
      ),
    );
    final criticalBattery = DashboardTripTrackingSummary.fromRuntime(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      platformStatus: 'battery_critical_gps_blocked',
    );
    final unknown = DashboardTripTrackingSummary.fromRuntime(
      settings: const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
      storageCheck: const AppStorageCheck.unknown(
        operationBytes: AppStorageGuard.mileageTrackingWriteBytes,
        requiredBytes:
            AppStorageGuard.mileageTrackingWriteBytes +
            AppStorageGuard.textRecordDeviceReserveBytes,
        purpose: AppStoragePurpose.mileageTracking,
      ),
    );

    expect(lowStorage.gpsAssistState, 'battery_limited');
    expect(lowStorage.batteryGpsLimited, isTrue);
    expect(lowStorage.storageState, 'low_storage');
    expect(criticalBattery.gpsAssistState, 'battery_limited');
    expect(criticalBattery.batteryGpsLimited, isTrue);
    expect(blocked.storageState, 'blocked');
    expect(unknown.storageState, 'unknown');
  });
}

DeviceCapabilityProfile _deviceProfile({
  required DevicePerformanceTier tier,
  required int batteryPercent,
  required bool powerSaving,
  required Set<String> sensorTypes,
  required bool wifiUnmetered,
}) {
  return DeviceCapabilityProfile(
    hardware: const DeviceHardwareSnapshot(
      platform: 'android',
      physicalRamMb: 4096,
      cpuCores: 8,
      applicationHeapMb: 256,
    ),
    runtime: DeviceRuntimeSnapshot(
      observedAt: DateTime.utc(2026, 7, 17),
      freeStorageMb: 2500,
      totalStorageMb: 128000,
      powerSaving: powerSaving,
    ),
    camera: const DeviceCameraCapabilities(),
    extended: DeviceExtendedCapabilities(
      sensors: DeviceSensorCapabilities(types: sensorTypes),
      battery: DeviceBatteryCapabilities(levelPercent: batteryPercent),
      connectivity: DeviceConnectivityCapabilities(
        transports: wifiUnmetered ? const {'wifi'} : const {'mobile'},
        isConnected: true,
        isMetered: !wifiUnmetered,
      ),
    ),
    baselineTier: tier,
    tier: tier,
    confidence: DeviceCapabilityConfidence.high,
    score: 4,
    limitingFactors: const [],
  );
}

TripTrackingReviewRecord _confirmedReview({
  required String id,
  required DateTime startedAt,
  required double filteredGpsMiles,
  required int odometerMiles,
  TripTrackingDiagnostics diagnostics = const TripTrackingDiagnostics(
    receivedSamples: 100,
    acceptedSamples: 90,
    dispositionCounts: {
      TripSampleDisposition.acceptedDistance: 90,
      TripSampleDisposition.rejectedAccuracy: 10,
    },
  ),
}) {
  final startingOdometer = 1000;
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: startingOdometer + odometerMiles,
    confirmedEndingOdometer: startingOdometer + odometerMiles,
    odometerConfirmedAt: startedAt.add(const Duration(hours: 1)),
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 1)),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: filteredGpsMiles * 1609.344,
      walkingReviewSuggested: false,
      diagnostics: diagnostics,
    ),
  );
}

class _SummaryNativeGateway implements TripTrackingNativeGateway {
  @override
  Stream<TripTrackingPlatformEvent> get events =>
      const Stream<TripTrackingPlatformEvent>.empty();

  @override
  Future<TripTrackingPlatformCapabilities> readCapabilities() async =>
      const TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: true,
        activityRecognitionAvailable: true,
        batteryStateAvailable: true,
        lowPowerModeAvailable: true,
      );

  @override
  Future<TripTrackingBatterySnapshot> readBatterySnapshot() async =>
      const TripTrackingBatterySnapshot(
        batteryPercent: 80,
        isCharging: false,
        lowPowerModeEnabled: false,
      );

  @override
  Future<TripTrackingAuthorization> requestAuthorization({
    required bool allowBackground,
    required bool activityRecognitionEnabled,
  }) async => const TripTrackingAuthorization(
    state: TripTrackingAuthorizationState.always,
    preciseLocation: true,
  );

  @override
  Future<bool> start(TripTrackingNativeRequest request) async => true;

  @override
  Future<bool> update(TripTrackingNativeRequest request) async => true;

  @override
  Future<bool> stop() async => true;

  @override
  Future<bool> get isTracking async => false;
}
