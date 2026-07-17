import 'dart:io';

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
  });

  test(
    'dashboard upload policy rejects raw location and module data aliases',
    () {
      final doc =
          MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
            uid: 'firebaseUid-1',
            dashboardId: 'today',
            updatedAtUtc: DateTime.utc(2026, 7, 16, 12),
          );

      for (final forbidden in const [
        'latitude',
        'longitude',
        'coordinates',
        'route',
        'routePoints',
        'polyline',
        'address',
        'rawSamples',
        'walkingEvidence',
        'rawModuleRecord',
      ]) {
        final poisoned = MaintainiacFirestoreDocumentDraft(
          path: doc.path,
          data: {...doc.data, forbidden: 'not allowed'},
        );

        expect(
          () => MaintainiacFirestoreUploadPolicy.validateDraft(poisoned),
          throwsArgumentError,
          reason: '$forbidden must not be accepted in dashboard summaries',
        );
      }
    },
  );

  test(
    'Firestore rules contain dashboard summary ownership and privacy gates',
    () {
      final rules = File('firestore.rules').readAsStringSync();

      expect(rules, contains('match /dashboardSummaries/{dashboardId}'));
      expect(rules, contains('function isDashboardCommandCenterSummary'));
      expect(rules, contains('hasOnlyDashboardSummaryFields'));
      expect(rules, contains('hasValidDashboardSyncCounters'));
      expect(rules, contains('function isAllowedDashboardMode'));
      expect(rules, contains('function isAllowedDashboardSyncMode'));
      expect(rules, contains('function isAllowedGpsAssistState'));
      expect(rules, contains('function hasValidDashboardSummaryStrings'));
      expect(
        rules,
        contains('request.resource.data.dashboardId.size() <= 128'),
      );
      expect(
        rules,
        contains('request.resource.data.activeVehicleId.size() <= 128'),
      );
      for (final field in const <String>[
        'dashboardId',
        'createdByUid',
        'updatedByUid',
        'updatedAt',
      ]) {
        expect(rules, contains('request.resource.data.$field.size() > 0'));
      }
      for (final field in const <String>[
        'orgId',
        'activeVehicleId',
        'activeWorkdayId',
        'activeWorkProfileId',
      ]) {
        expect(rules, contains('request.resource.data.$field is string'));
        expect(rules, contains('request.resource.data.$field.size() > 0'));
      }
      expect(rules, contains('request.resource.data.freeSyncsRemaining <= 6'));
      expect(rules, contains('request.resource.data.syncsUsedInWindow <= 999'));
      expect(
        rules,
        contains('request.resource.data.locationDataIncluded == false'),
      );
      expect(
        rules,
        contains('request.resource.data.rawModuleDataIncluded == false'),
      );
      expect(rules, contains('request.resource.data.createdByUid == uid'));
      expect(
        rules,
        contains('request.resource.data.createdByUid == request.auth.uid'),
      );
      expect(rules, contains('allow delete: if false;'));
    },
  );
}
