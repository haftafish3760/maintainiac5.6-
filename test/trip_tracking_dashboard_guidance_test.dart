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
    expect(guidance.primaryStatus, contains('GPS assist is off'));
    expect(guidance.safetyStatus, contains('GPS is off'));
    expect(guidance.syncStatus, 'Sync: Wi-Fi or mobile data');
    expect(guidance.dashboardBadges, contains('Road vehicle'));
    expect(guidance.dashboardBadges, contains('Sync: Wi-Fi or mobile data'));
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
    expect(guidance.stopDetectionStatus, contains('walking evidence'));
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
    expect(guidance.syncStatus, 'Sync: Wi-Fi only');
    expect(guidance.stopDetectionStatus, contains('driver often stays'));
    expect(guidance.dashboardBadges, contains('Battery guard on'));
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
    expect(guidance.safetyStatus, contains('background tracking'));
    expect(guidance.dashboardBadges, contains('Motion assist on'));
    expect(guidance.dashboardBadges, contains('Background GPS on'));
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
    expect(guidance.syncStatus, 'Sync: mobile data only');
    expect(guidance.recommendsActivityRecognition, isFalse);
    expect(guidance.activityRecognitionActive, isFalse);
    expect(guidance.shouldShowActivityRecognitionRecommendation, isFalse);
    expect(guidance.stopDetectionStatus, contains('ignores walking-stop'));
    expect(guidance.dashboardBadges, isNot(contains('Motion assist on')));
  });

  test('dashboard badges reflect battery guard user choice safely', () {
    final guidance = TripTrackingDashboardGuidance.fromSettings(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        lowBatteryGpsProtectionEnabled: false,
      ),
    );

    expect(guidance.lowBatteryProtectionActive, isFalse);
    expect(guidance.shouldShowBatterySafety, isFalse);
    expect(guidance.safetyStatus, contains('off by user choice'));
    expect(guidance.dashboardBadges, isNot(contains('Battery guard on')));
  });
}
