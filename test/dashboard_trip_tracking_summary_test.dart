import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_trip_tracking_summary.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('manual default dashboard summary stays local and GPS off', () {
    final summary = DashboardTripTrackingSummary.fromSettings(
      settings: const TripTrackingSettings(),
    );

    expect(summary.dashboardMode, 'default');
    expect(summary.mileageMode, 'manual');
    expect(summary.syncMode, 'wifi_and_mobile');
    expect(summary.gpsAssistState, 'off');
    expect(summary.storageState, 'unknown');
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
    expect(summary.mileageMode, 'gps_assisted');
    expect(summary.syncMode, 'wifi_only');
    expect(summary.gpsAssistState, 'on');
    expect(summary.storageState, 'text_record_safe');
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
      wifiAvailable: false,
      mobileDataAvailable: true,
      syncsUsedInWindow: 5,
    );

    expect(summary.dashboardMode, 'contractor');
    expect(summary.syncMode, 'mobile_only');
    expect(summary.gpsAssistState, 'battery_limited');
    expect(summary.storageState, 'low_storage');
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
      wifiAvailable: true,
      mobileDataAvailable: true,
      syncsUsedInWindow: -1,
    );

    expect(summary.storageState, 'unknown');
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
    final odometer = GlobalOdometerController(initialReading: 1000);
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
    expect(summary.storageState, 'text_record_safe');
    expect(summary.freeSyncsRemaining, 5);
    expect(summary.reviewRequired, isFalse);
  });

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
    expect(blocked.storageState, 'blocked');
    expect(unknown.storageState, 'unknown');
  });
}
