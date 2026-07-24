import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_dashboard_guidance.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('dashboard guidance keeps GPS assist opt-in by default', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(),
    );

    expect(guidance.enabled, isFalse);
    expect(guidance.profileLabel, 'Road vehicle');
    expect(guidance.modeToken, 'default');
    expect(guidance.primaryStatus, contains('Phone location is off'));
    expect(guidance.safetyStatus, contains('Battery protection'));
    expect(
      guidance.syncStatus,
      'Sync: Wi-Fi or mobile data; free sync usage pending',
    );
    expect(guidance.syncReason, contains('network status'));
    expect(guidance.mapStatus, 'Maps are separate from GPS assist.');
    expect(guidance.dashboardBadges, contains('Road vehicle'));
    expect(
      guidance.dashboardBadges,
      isNot(contains('Sync: Wi-Fi or mobile data; free sync usage pending')),
    );
    expect(guidance.shouldShowActivityRecognitionRecommendation, isFalse);
    expect(guidance.shouldShowOdometerReview, isFalse);
  });

  test('delivery guidance recommends motion assist without enabling it', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.deliveryVehicle,
      ),
    );

    expect(guidance.enabled, isTrue);
    expect(guidance.profileLabel, 'Delivery');
    expect(guidance.modeToken, 'gig_driver');
    expect(guidance.primaryStatus, contains('delivery'));
    expect(guidance.mapStatus, 'GPS assist is running without maps.');
    expect(guidance.stopDetectionStatus, contains('begin walking'));
    expect(guidance.recommendsActivityRecognition, isTrue);
    expect(guidance.activityRecognitionActive, isFalse);
    expect(guidance.shouldShowActivityRecognitionRecommendation, isTrue);
    expect(guidance.odometerStatus, contains('Odometer remains'));
    expect(guidance.shouldShowOdometerReview, isTrue);
  });

  test('rideshare guidance uses passenger-service stop wording', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.rideshareVehicle,
        backupNetworkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      ),
    );

    expect(guidance.profileLabel, 'Rideshare');
    expect(guidance.modeToken, 'gig_driver');
    expect(guidance.syncStatus, contains('Sync: Wi-Fi only'));
    expect(guidance.stopDetectionStatus, contains('stay in the vehicle'));
    expect(guidance.dashboardBadges, contains('Battery protection on'));
  });

  test('contractor guidance reflects active motion and background choices', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.contractorVehicle,
        activityRecognitionEnabled: true,
        backgroundTrackingEnabled: true,
        odometerAnomalyAlertsEnabled: true,
      ),
    );

    expect(guidance.profileLabel, 'Contractor');
    expect(guidance.modeToken, 'contractor');
    expect(guidance.activityRecognitionActive, isTrue);
    expect(guidance.backgroundTrackingActive, isTrue);
    expect(guidance.odometerAnomalyAlertsActive, isTrue);
    expect(guidance.shouldShowActivityRecognitionRecommendation, isFalse);
    expect(guidance.shouldShowOdometerReview, isFalse);
    expect(guidance.safetyStatus, contains('screen-locked tracking'));
    expect(guidance.dashboardBadges, contains('Stop suggestions on'));
    expect(guidance.dashboardBadges, contains('Works with screen locked'));
    expect(guidance.dashboardBadges, contains('Odometer alerts on'));
  });

  test('equipment guidance does not recommend activity recognition', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        defaultProfile: TripTrackingProfile.lowSpeedEquipment,
        activityRecognitionEnabled: true,
        backupNetworkPolicy: TripTrackingBackupNetworkPolicy.mobileDataOnly,
      ),
    );

    expect(guidance.profileLabel, 'Equipment');
    expect(guidance.modeToken, 'default');
    expect(guidance.syncStatus, contains('Sync: mobile data only'));
    expect(guidance.recommendsActivityRecognition, isFalse);
    expect(guidance.activityRecognitionActive, isFalse);
    expect(guidance.shouldShowActivityRecognitionRecommendation, isFalse);
    expect(guidance.stopDetectionStatus, contains('does not create'));
    expect(guidance.dashboardBadges, isNot(contains('Stop suggestions on')));
  });

  test('dashboard badges reflect battery protection user choice safely', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        lowBatteryGpsProtectionEnabled: false,
      ),
    );

    expect(guidance.lowBatteryProtectionActive, isFalse);
    expect(guidance.shouldShowBatterySafety, isFalse);
    expect(guidance.safetyStatus, contains('off by user choice'));
    expect(guidance.dashboardBadges, isNot(contains('Battery protection on')));
  });

  test('dashboard guidance can include verified free sync context', () {
    final guidance = TripTrackingDashboardGuidance.fromSettingsWithSyncContext(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        backupNetworkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      ),
      wifiAvailable: true,
      mobileDataAvailable: false,
      syncsUsedInWindow: 5,
    );

    expect(guidance.syncStatus, 'Sync: Wi-Fi only; 1 free sync left');
    expect(guidance.syncReason, 'Backup sync is ready.');
    expect(
      guidance.dashboardBadges,
      isNot(contains('Sync: Wi-Fi only; 1 free sync left')),
    );
  });

  test('dashboard guidance keeps map preview and route history separate', () {
    final previewOnly = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
      ),
    );
    final routeHistory = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
    );

    expect(previewOnly.mapStatus, 'Map preview on');
    expect(previewOnly.dashboardBadges, contains('Map preview on'));
    expect(
      previewOnly.dashboardBadges,
      isNot(contains('Map route history on')),
    );
    expect(routeHistory.mapStatus, 'Map route history on');
    expect(routeHistory.dashboardBadges, contains('Map route history on'));
  });

  test('dashboard guidance labels odometer calibration assist as advisory', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        odometerAnomalyAlertsEnabled: true,
        gpsOdometerCalibrationAssistEnabled: true,
      ),
    );

    expect(guidance.gpsOdometerCalibrationAssistActive, isTrue);
    expect(guidance.odometerStatus, contains('tune future GPS estimates'));
    expect(guidance.odometerStatus, contains('cannot replace confirmed'));
    expect(
      guidance.dashboardBadges,
      contains('Odometer calibration assist on'),
    );
  });

  test(
    'dashboard guidance safe map contains no raw location or sensor data',
    () {
      final guidance =
          TripTrackingDashboardGuidance.fromSettingsWithSyncContext(
            const TripTrackingSettings(
              gpsAssistedTrackingEnabled: true,
              defaultProfile: TripTrackingProfile.deliveryVehicle,
            ),
            wifiAvailable: true,
            mobileDataAvailable: true,
            syncsUsedInWindow: 1000,
          );
      final safe = guidance.toSafeDashboardMap();

      expect(safe['syncStatus'], contains('unverified'));
      expect(safe['advisoryOnly'], isTrue);
      expect(safe['startActionShouldRemainPrimary'], isTrue);
      expect(safe['dashboardWidgetsUserCustomizable'], isTrue);
      expect(safe['dashboardCanImportModuleSummaries'], isTrue);
      expect(safe['moduleImportsCanMutateSourceModules'], isFalse);
      expect(safe['activeVehicleGearControlsPageSettings'], isTrue);
      expect(safe['defaultSingleVehicleSupported'], isTrue);
      expect(safe['workProfileOptionalForDefaultSetup'], isTrue);
      expect(safe['vehicleProfileOptionalForDefaultSetup'], isTrue);
      expect(safe['dashboardProfileCanBeChangedLater'], isTrue);
      expect(safe['startButtonVisibleByDefault'], isTrue);
      expect(safe['gpsAssistedTrackingAvailableWithoutMaps'], isTrue);
      expect(safe['odometerRemainsCanonical'], isTrue);
      expect(safe['mapsRequiredForTracking'], isFalse);
      expect(safe['mapPreviewRequiresSeparateOptIn'], isTrue);
      expect(safe['routeHistoryRequiresSeparateOptIn'], isTrue);
      expect(safe['mapboxCanReplaceOdometer'], isFalse);
      expect(safe['mapboxCanWriteConfirmedTripLog'], isFalse);
      expect(safe['remoteTotalsCanBecomeCanonical'], isFalse);
      expect(safe['localTripLogProtected'], isTrue);
      expect(safe['locationSharingRequiresActiveOptIn'], isTrue);
      expect(safe['employeeTrackingRequiresMutualConsent'], isTrue);
      expect(safe['employerGodModeAllowed'], isFalse);
      expect(safe['tokensIncluded'], isFalse);
      expect(safe['preciseLocationIncluded'], isFalse);
      expect(safe['rawLocationIncluded'], isFalse);
      expect(safe['rawSensorPayloadIncluded'], isFalse);
      expect(safe['rawModuleDataIncluded'], isFalse);
    },
  );
}
