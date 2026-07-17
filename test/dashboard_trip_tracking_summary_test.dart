import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/dashboard_trip_tracking_summary.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
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
}
