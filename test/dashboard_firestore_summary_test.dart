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
          storageState: 'text_record_safe',
          deviceCapabilityState: 'full_safety_assist',
          sensorAssistState: 'motion_battery_available',
          odometerCalibrationState: 'review_recommended',
          odometerCalibrationSamples: 7,
          odometerUsageState: 'review_recommended',
          odometerUsageReviewedDays: 7,
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
    expect(doc.data['deviceCapabilityState'], 'full_safety_assist');
    expect(doc.data['sensorAssistState'], 'motion_battery_available');
    expect(doc.data['odometerCalibrationState'], 'review_recommended');
    expect(doc.data['odometerCalibrationSamples'], 7);
    expect(doc.data['odometerUsageState'], 'review_recommended');
    expect(doc.data['odometerUsageReviewedDays'], 7);
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

  test('dashboard summary builder rejects unknown mode and state values', () {
    for (final entry in const <String, String>{
      'dashboardMode': 'god_mode',
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
