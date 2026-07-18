import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  test('builds a personal dashboard summary without raw module data', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          activeVehicleId: 'truck 1',
          activeWorkdayId: 'workday 1',
          activeWorkProfileId: 'gig profile',
          dashboardMode: 'gig_driver',
          mileageMode: 'gps_assisted',
          syncMode: 'wifi_only',
          gpsAssistState: 'battery_limited',
          gpsSignalQuality: 'poor',
          gpsSignalReason: 'gps_signal_poor_measurement_quality',
          gpsSignalReviewRequired: true,
          mapboxAssistState: 'distance_review',
          mapboxAssistReason: 'mapbox_distance_review_only',
          mapboxAssistReviewRequired: true,
          mapboxTrustedMileageSource: 'odometer',
          mapboxRouteDistanceMiles: 12.34567,
          mapboxRouteDeltaMiles: 2.34567,
          mapPreviewEnabled: true,
          mapRouteHistorySavingEnabled: true,
          mapRouteHistoryDailyBudgetMb: 1.25,
          mapRouteHistorySampleIntervalSeconds: 45,
          mapRouteHistoryState: 'within_budget',
          mapRouteHistoryEstimatedSamplesPerDay: 640,
          mapRouteHistoryEstimatedDailyMb: 0.059,
          storageState: 'text_record_safe',
          deviceCapabilityState: 'full_safety_assist',
          sensorAssistState: 'motion_battery_available',
          odometerCalibrationAssistEnabled: true,
          odometerCalibrationState: 'review_recommended',
          odometerCalibrationSamples: 7,
          odometerCalibrationMultiplier: .9090909,
          odometerUsageState: 'review_recommended',
          odometerUsageReviewedDays: 7,
          odometerUsageCurrentMiles: 180.04,
          odometerUsageAverageDailyMiles: 40.04,
          odometerUsageReviewThresholdMiles: 100.04,
          freeSyncsRemaining: HostedUsageLimits.freeUserSyncsPer24HourWindow,
          syncsUsedInWindow: 0,
          batteryGpsLimited: true,
          reviewRequired: false,
        );

    expect(
      doc.path,
      'users/firebaseUid-1/${MaintainiacFirestoreSchema.orgDashboardSummaries}/today',
    );
    expect(doc.data['schema'], 'dashboard_command_center_summary_v1');
    expect(doc.data['locationDataIncluded'], isFalse);
    expect(doc.data['rawModuleDataIncluded'], isFalse);
    expect(doc.data['activeVehicleId'], 'truck_1');
    expect(
      doc.data['freeSyncsRemaining'],
      HostedUsageLimits.freeUserSyncsPer24HourWindow,
    );
    expect(doc.data['batteryGpsLimited'], isTrue);
    expect(doc.data['gpsSignalQuality'], 'poor');
    expect(doc.data['gpsSignalReason'], 'gps_signal_poor_measurement_quality');
    expect(doc.data['gpsSignalReviewRequired'], isTrue);
    expect(doc.data['mapboxAssistState'], 'distance_review');
    expect(doc.data['mapboxAssistReason'], 'mapbox_distance_review_only');
    expect(doc.data['mapboxAssistReviewRequired'], isTrue);
    expect(doc.data['mapboxTrustedMileageSource'], 'odometer');
    expect(doc.data['mapboxRouteDistanceMiles'], 12.346);
    expect(doc.data['mapboxRouteDeltaMiles'], 2.346);
    expect(doc.data['mapPreviewEnabled'], isTrue);
    expect(doc.data['mapRouteHistorySavingEnabled'], isTrue);
    expect(doc.data['mapRouteHistoryDailyBudgetMb'], 1.25);
    expect(doc.data['mapRouteHistorySampleIntervalSeconds'], 45);
    expect(doc.data['mapRouteHistoryState'], 'within_budget');
    expect(doc.data['mapRouteHistoryEstimatedSamplesPerDay'], 640);
    expect(doc.data['mapRouteHistoryEstimatedDailyMb'], 0.059);
    expect(doc.data['mapboxRouteGeometryIncluded'], isFalse);
    expect(doc.data['authorizationRequired'], isTrue);
    expect(doc.data['authenticationImpliesAuthorization'], isFalse);
    expect(doc.data['employeeTrackingRequiresMutualConsent'], isTrue);
    expect(doc.data['locationSharingRequiresActiveOptIn'], isTrue);
    expect(doc.data['employerGodModeAllowed'], isFalse);
    expect(doc.data['preciseLocationIncluded'], isFalse);
    expect(doc.data['externalRoutesCanonical'], isFalse);
    expect(doc.data['odometerRemainsCanonical'], isTrue);
    expect(doc.data['externalServiceWritesAllowed'], isFalse);
    expect(doc.data['mapboxCanModifyTripLog'], isFalse);
    expect(doc.data['mapboxCanModifyOdometer'], isFalse);
    expect(doc.data['mapsRequiredForTracking'], isFalse);
    expect(doc.data['mapsRequireSeparateOptIn'], isTrue);
    expect(doc.data['mapRouteHistoryRequiresSeparateOptIn'], isTrue);
    expect(doc.data['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(doc.data['freeUserControlsDailyMapStorageBudget'], isTrue);
    expect(doc.data['rawMapRouteIncluded'], isFalse);
    expect(doc.data['deviceCapabilityState'], 'full_safety_assist');
    expect(doc.data['sensorAssistState'], 'motion_battery_available');
    expect(doc.data['odometerCalibrationAssistEnabled'], isTrue);
    expect(doc.data['odometerCalibrationState'], 'review_recommended');
    expect(doc.data['odometerCalibrationSamples'], 7);
    expect(doc.data['odometerCalibrationMultiplier'], .9091);
    expect(doc.data['odometerUsageState'], 'review_recommended');
    expect(doc.data['odometerUsageReviewedDays'], 7);
    expect(doc.data['odometerUsageCurrentMiles'], 180.04);
    expect(doc.data['odometerUsageAverageDailyMiles'], 40.04);
    expect(doc.data['odometerUsageReviewThresholdMiles'], 100.04);
    expect(doc.data.keys, isNot(contains('latitude')));
    expect(doc.data.keys, isNot(contains('route')));
    expect(doc.data.keys, isNot(contains('rawSamples')));
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('free dashboard sync window is capped at six per 24 hours', () {
    expect(HostedUsageLimits.freeUserSyncsPer24HourWindow, 6);
    expect(HostedUsageLimits.canUseFreeSync(syncsUsedInWindow: 5), isTrue);
    expect(HostedUsageLimits.canUseFreeSync(syncsUsedInWindow: 6), isFalse);
    expect(HostedUsageLimits.freeSyncsRemaining(syncsUsedInWindow: 0), 6);
    expect(HostedUsageLimits.freeSyncsRemaining(syncsUsedInWindow: 6), 0);
    expect(HostedUsageLimits.freeSyncsRemaining(syncsUsedInWindow: 99), 0);
  });

  test('default dashboard summaries keep odometer alerts disabled', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        );

    expect(doc.data['odometerCalibrationState'], 'disabled');
    expect(doc.data['gpsSignalQuality'], 'no_samples');
    expect(doc.data['gpsSignalReason'], 'gps_signal_waiting_for_samples');
    expect(doc.data['gpsSignalReviewRequired'], isFalse);
    expect(doc.data['mapboxAssistState'], 'disabled');
    expect(doc.data['mapboxAssistReason'], 'mapbox_assist_disabled');
    expect(doc.data['mapboxAssistReviewRequired'], isFalse);
    expect(doc.data['mapboxTrustedMileageSource'], 'none');
    expect(doc.data.keys, isNot(contains('mapboxRouteDistanceMiles')));
    expect(doc.data.keys, isNot(contains('mapboxRouteDeltaMiles')));
    expect(doc.data['mapPreviewEnabled'], isFalse);
    expect(doc.data['mapRouteHistorySavingEnabled'], isFalse);
    expect(doc.data['mapRouteHistoryDailyBudgetMb'], 0);
    expect(doc.data['mapRouteHistorySampleIntervalSeconds'], 30);
    expect(doc.data['mapRouteHistoryState'], 'disabled');
    expect(doc.data['mapRouteHistoryEstimatedSamplesPerDay'], 0);
    expect(doc.data['mapRouteHistoryEstimatedDailyMb'], 0);
    expect(doc.data['mapboxRouteGeometryIncluded'], isFalse);
    expect(doc.data['authorizationRequired'], isTrue);
    expect(doc.data['authenticationImpliesAuthorization'], isFalse);
    expect(doc.data['employeeTrackingRequiresMutualConsent'], isTrue);
    expect(doc.data['locationSharingRequiresActiveOptIn'], isTrue);
    expect(doc.data['employerGodModeAllowed'], isFalse);
    expect(doc.data['preciseLocationIncluded'], isFalse);
    expect(doc.data['externalRoutesCanonical'], isFalse);
    expect(doc.data['odometerRemainsCanonical'], isTrue);
    expect(doc.data['externalServiceWritesAllowed'], isFalse);
    expect(doc.data['mapboxCanModifyTripLog'], isFalse);
    expect(doc.data['mapboxCanModifyOdometer'], isFalse);
    expect(doc.data['mapsRequiredForTracking'], isFalse);
    expect(doc.data['mapsRequireSeparateOptIn'], isTrue);
    expect(doc.data['mapRouteHistoryRequiresSeparateOptIn'], isTrue);
    expect(doc.data['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(doc.data['freeUserControlsDailyMapStorageBudget'], isTrue);
    expect(doc.data['rawMapRouteIncluded'], isFalse);
    expect(doc.data['odometerUsageState'], 'disabled');
    expect(doc.data.keys, isNot(contains('odometerCalibrationSamples')));
    expect(doc.data.keys, isNot(contains('odometerCalibrationMultiplier')));
    expect(doc.data.keys, isNot(contains('odometerUsageReviewedDays')));
    expect(doc.data.keys, isNot(contains('odometerUsageCurrentMiles')));
    expect(doc.data.keys, isNot(contains('odometerUsageAverageDailyMiles')));
    expect(doc.data.keys, isNot(contains('odometerUsageReviewThresholdMiles')));
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test(
    'dashboard summaries cannot claim more than the free sync allowance',
    () {
      expect(
        () =>
            MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
              uid: 'firebaseUid-1',
              dashboardId: 'today',
              updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
              freeSyncsRemaining: 99,
              syncsUsedInWindow: 0,
            ),
        throwsArgumentError,
      );
    },
  );

  test('dashboard summaries reject malformed sync usage counters', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          freeSyncsRemaining: 0,
          syncsUsedInWindow: 999,
        );
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);

    for (final value in [-1, 1000]) {
      expect(
        () =>
            MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
              uid: 'firebaseUid-1',
              dashboardId: 'today',
              updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
              freeSyncsRemaining: 0,
              syncsUsedInWindow: value,
            ),
        throwsArgumentError,
      );
    }

    final poisoned = MaintainiacFirestoreDocumentDraft(
      path: doc.path,
      data: {...doc.data, 'syncsUsedInWindow': 1000},
    );
    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
      throwsArgumentError,
    );
  });

  test('dashboard summaries reject inconsistent free sync counters', () {
    expect(
      () => MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
        uid: 'firebaseUid-1',
        dashboardId: 'today',
        updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        freeSyncsRemaining: 6,
        syncsUsedInWindow: 2,
      ),
      throwsArgumentError,
    );

    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          freeSyncsRemaining: 4,
          syncsUsedInWindow: 2,
        );
    final poisoned = MaintainiacFirestoreDocumentDraft(
      path: doc.path,
      data: {...doc.data, 'freeSyncsRemaining': 6},
    );

    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
      throwsArgumentError,
    );
  });

  test('builds an organization dashboard summary scoped to the member org', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          orgId: 'org A',
          dashboardId: 'contractor',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          dashboardMode: 'contractor',
          mileageMode: 'manual',
          syncMode: 'wifi_and_mobile',
          gpsAssistState: 'off',
          storageState: 'green',
        );

    expect(
      doc.path,
      'orgs/org_A/${MaintainiacFirestoreSchema.orgDashboardSummaries}/contractor',
    );
    expect(doc.data['orgId'], 'org_A');
    expect(doc.data['createdByUid'], 'firebaseUid-1');
    MaintainiacFirestoreUploadPolicy.validateDraft(doc);
  });

  test('organization dashboard summaries reject divergent owner UIDs', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          orgId: 'org A',
          dashboardId: 'contractor',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(
        MaintainiacFirestoreDocumentDraft(
          path: doc.path,
          data: {...doc.data, 'updatedByUid': 'firebaseUid-2'},
        ),
      ),
      throwsArgumentError,
    );
  });

  test('dashboard summaries reject blank optional reference ids', () {
    for (final entry in const <String, String>{
      'activeVehicleId': ' /// ',
      'activeWorkdayId': ' /// ',
      'activeWorkProfileId': ' /// ',
    }.entries) {
      expect(
        () =>
            MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
              uid: 'firebaseUid-1',
              dashboardId: 'today',
              updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
              activeVehicleId: entry.key == 'activeVehicleId'
                  ? entry.value
                  : null,
              activeWorkdayId: entry.key == 'activeWorkdayId'
                  ? entry.value
                  : null,
              activeWorkProfileId: entry.key == 'activeWorkProfileId'
                  ? entry.value
                  : null,
            ),
        throwsArgumentError,
        reason: '${entry.key} must fail closed when provided but blank',
      );
    }
  });

  test('dashboard upload policy rejects unknown mode and state values', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        );

    for (final entry in const <String, String>{
      'dashboardMode': 'god_mode',
      'workStyle': 'raw_route_worker',
      'stopDetectionMode': 'always_precise',
      'stopReviewReasonCode': 'raw_stop_address',
      'recoveryState': 'raw_recovery',
      'recoveryReason': 'raw_recovery_payload',
      'mileageMode': 'silent_tracking',
      'syncMode': 'always_spy',
      'gpsAssistState': 'raw_coordinates_enabled',
      'storageState': 'remote_authoritative',
      'deviceCapabilityState': 'precise_location_history',
      'sensorAssistState': 'raw_motion_payload',
      'odometerCalibrationState': 'raw_drift_payload',
      'odometerUsageState': 'raw_average_payload',
    }.entries) {
      final poisoned = MaintainiacFirestoreDocumentDraft(
        path: doc.path,
        data: {...doc.data, entry.key: entry.value},
      );

      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
        throwsArgumentError,
        reason: '${entry.key} must be an allowed dashboard summary value',
      );
    }
  });

  test('dashboard upload policy rejects padded mode and state values', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        );

    for (final entry in const <String, String>{
      'dashboardMode': ' default ',
      'workStyle': ' general_road ',
      'stopDetectionMode': ' walking_assisted ',
      'stopReviewReasonCode': ' road_vehicle_stop_walk_review ',
      'recoveryState': ' none ',
      'recoveryReason': ' trip_recovery_none ',
      'mileageMode': ' manual ',
      'syncMode': ' wifi_only ',
      'gpsAssistState': ' off ',
      'storageState': ' unknown ',
      'deviceCapabilityState': ' unknown ',
      'sensorAssistState': ' unknown ',
      'odometerCalibrationState': ' unknown ',
      'odometerUsageState': ' unknown ',
    }.entries) {
      final poisoned = MaintainiacFirestoreDocumentDraft(
        path: doc.path,
        data: {...doc.data, entry.key: entry.value},
      );

      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
        throwsArgumentError,
        reason: '${entry.key} must match the Firestore rules enum exactly',
      );
    }
  });

  test(
    'dashboard summary accepts walking stop evidence rejected as unsafe',
    () {
      final doc =
          MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
            uid: 'firebaseUid-1',
            dashboardId: 'today',
            updatedAtUtc: DateTime.utc(2026, 7, 18, 12),
            stopSignal: 'unsafe_evidence',
            stopActionToken: 'keep_tracking',
            stopClassificationReason: 'walking_stop_without_vehicle_movement',
            reviewRequired: false,
          );

      expect(
        doc.data['stopClassificationReason'],
        'walking_stop_without_vehicle_movement',
      );
      expect(doc.data['stopSignal'], 'unsafe_evidence');
      expect(doc.data['locationDataIncluded'], isFalse);
      expect(doc.data['rawModuleDataIncluded'], isFalse);
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(doc),
        returnsNormally,
      );
    },
  );

  test('dashboard summary builder rejects unknown mode and state values', () {
    for (final entry in const <String, String>{
      'dashboardMode': 'god_mode',
      'workStyle': 'raw_route_worker',
      'stopDetectionMode': 'always_precise',
      'stopReviewReasonCode': 'raw_stop_address',
      'recoveryState': 'raw_recovery',
      'recoveryReason': 'raw_recovery_payload',
      'mileageMode': 'silent_tracking',
      'syncMode': 'always_spy',
      'gpsAssistState': 'raw_coordinates_enabled',
      'storageState': 'remote_authoritative',
      'deviceCapabilityState': 'precise_location_history',
      'sensorAssistState': 'raw_motion_payload',
      'odometerCalibrationState': 'raw_drift_payload',
      'odometerUsageState': 'raw_average_payload',
    }.entries) {
      expect(
        () =>
            MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
              uid: 'firebaseUid-1',
              dashboardId: 'today',
              updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
              dashboardMode: entry.key == 'dashboardMode'
                  ? entry.value
                  : 'default',
              workStyle: entry.key == 'workStyle'
                  ? entry.value
                  : 'general_road',
              stopDetectionMode: entry.key == 'stopDetectionMode'
                  ? entry.value
                  : 'walking_assisted',
              stopReviewReasonCode: entry.key == 'stopReviewReasonCode'
                  ? entry.value
                  : 'road_vehicle_stop_walk_review',
              recoveryState: entry.key == 'recoveryState'
                  ? entry.value
                  : 'none',
              recoveryReason: entry.key == 'recoveryReason'
                  ? entry.value
                  : 'trip_recovery_none',
              mileageMode: entry.key == 'mileageMode' ? entry.value : 'manual',
              syncMode: entry.key == 'syncMode'
                  ? entry.value
                  : 'device_retained',
              gpsAssistState: entry.key == 'gpsAssistState'
                  ? entry.value
                  : 'off',
              storageState: entry.key == 'storageState'
                  ? entry.value
                  : 'unknown',
              deviceCapabilityState: entry.key == 'deviceCapabilityState'
                  ? entry.value
                  : 'unknown',
              sensorAssistState: entry.key == 'sensorAssistState'
                  ? entry.value
                  : 'unknown',
              odometerCalibrationState: entry.key == 'odometerCalibrationState'
                  ? entry.value
                  : 'unknown',
              odometerUsageState: entry.key == 'odometerUsageState'
                  ? entry.value
                  : 'unknown',
            ),
        throwsArgumentError,
        reason: '${entry.key} must fail before a dashboard draft is queued',
      );
    }
  });

  test('dashboard upload policy rejects malformed optional references', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          activeVehicleId: 'truck_1',
        );

    for (final poisoned in [
      {...doc.data, 'dashboardId': ''},
      {...doc.data, 'activeVehicleId': ''},
      {...doc.data, 'activeWorkdayId': '   '},
      {...doc.data, 'activeWorkProfileId': 42},
    ]) {
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(path: doc.path, data: poisoned),
        ),
        throwsArgumentError,
      );
    }
  });

  test('dashboard upload policy rejects unsafe reference characters', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          activeVehicleId: 'truck_1',
          activeWorkdayId: 'workday_1',
          activeWorkProfileId: 'profile_1',
        );

    for (final entry in const <String, String>{
      'dashboardId': 'today/../../other',
      'createdByUid': 'firebaseUid 1',
      'updatedByUid': 'firebaseUid/1',
      'activeVehicleId': 'truck 1',
      'activeWorkdayId': 'workday/1',
      'activeWorkProfileId': 'profile\n1',
    }.entries) {
      final poisoned = MaintainiacFirestoreDocumentDraft(
        path: doc.path,
        data: {...doc.data, entry.key: entry.value},
      );

      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
        throwsArgumentError,
        reason: '${entry.key} must stay a safe reference token',
      );
    }
  });

  test('dashboard upload policy rejects oversized reference strings', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        );

    for (final entry in const <String, String>{
      'dashboardId': 'today',
      'createdByUid': 'firebaseUid-1',
      'updatedByUid': 'firebaseUid-1',
      'activeVehicleId': 'truck_1',
      'activeWorkdayId': 'workday_1',
      'activeWorkProfileId': 'profile_1',
    }.entries) {
      final poisoned = MaintainiacFirestoreDocumentDraft(
        path: doc.path,
        data: {...doc.data, entry.key: 'x' * 129},
      );

      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
        throwsArgumentError,
        reason: '${entry.key} must stay bounded',
      );
    }
  });

  test('dashboard upload policy rejects malformed timestamps', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
        );

    final poisoned = MaintainiacFirestoreDocumentDraft(
      path: doc.path,
      data: {...doc.data, 'updatedAt': 'not-a-timestamp'},
    );

    expect(
      () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
      throwsArgumentError,
    );
  });

  test('dashboard summary builder rejects unsafe required path ids', () {
    expect(
      () => MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
        uid: 'firebaseUid-1',
        dashboardId: ' /// ',
        updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
      ),
      throwsArgumentError,
    );
    expect(
      () => MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
        uid: 'firebaseUid-1',
        orgId: ' /// ',
        dashboardId: 'today',
        updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
      ),
      throwsArgumentError,
    );
    expect(
      () => MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
        uid: 'firebaseUid-1',
        dashboardId: 'dashboard_${'x' * 160}',
        updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
      ),
      throwsArgumentError,
    );
  });
}
