import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_boundary_summary.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 17, 8);
  final finishedAt = DateTime.utc(2026, 7, 17, 9);

  Map<String, Object?> sessionMap({Object? schemaVersion = 1}) => {
    'id': 'trip_schema_boundary',
    'vehicleId': 'vehicle_1',
    'vehicleConfigurationRevision': 0,
    'startedTimeZoneOffsetMinutes': 0,
    'startedTimeZoneName': 'UTC',
    'startingOdometer': 1000,
    'profile': TripTrackingProfile.roadVehicle.name,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': startedAt.add(const Duration(minutes: 5)).toIso8601String(),
    'engineSnapshot': const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 0,
      walkingReviewSuggested: false,
    ).toMap(),
    'schemaVersion': schemaVersion,
  };

  Map<String, Object?> reviewMap({
    Object? schemaVersion = 1,
    Object? cloudSyncState,
    Object? cloudSyncedAt,
    Object? cloudBackupScope,
    Object? cloudOrganizationId,
    Object? confirmedEndingOdometer,
    Object? odometerConfirmedAt,
  }) {
    final map = <String, Object?>{
      'id': 'review_schema_boundary',
      'vehicleId': 'vehicle_1',
      'profileId': 'profile_1',
      'vehicleConfigurationRevision': 0,
      'startedTimeZoneOffsetMinutes': 0,
      'startedTimeZoneName': 'UTC',
      'finishedTimeZoneOffsetMinutes': 0,
      'finishedTimeZoneName': 'UTC',
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1002,
      'profile': TripTrackingProfile.roadVehicle.name,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 3218.688,
        walkingReviewSuggested: false,
      ).toMap(),
      'advisories': const <Object?>[],
      'schemaVersion': schemaVersion,
    };
    void addOptional(String key, Object? value) {
      if (value != null) map[key] = value;
    }

    addOptional('cloudSyncState', cloudSyncState);
    addOptional('cloudSyncedAt', cloudSyncedAt);
    addOptional('cloudBackupScope', cloudBackupScope);
    addOptional('cloudOrganizationId', cloudOrganizationId);
    addOptional('confirmedEndingOdometer', confirmedEndingOdometer);
    addOptional('odometerConfirmedAt', odometerConfirmedAt);
    return map;
  }

  test(
    'active trip schema versions migrate to current integer version five',
    () {
      for (final schema in const [1.0, 1.5, '1', true, null]) {
        final session = TripTrackingSessionRecord.fromMap(
          sessionMap(schemaVersion: schema),
        );

        expect(session.schemaVersion, 5, reason: '$schema');
        expect(session.hasValidTimeline, isFalse, reason: '$schema');
      }

      final supported = TripTrackingSessionRecord.fromMap(sessionMap());

      expect(supported.schemaVersion, 5);
      expect(supported.hasValidTimeline, isTrue);

      final current = TripTrackingSessionRecord.fromMap(
        sessionMap(schemaVersion: 5)..addAll({
          'profileId': 'profile_1',
          'revision': 1,
          'lastEventSequence': 1,
          'userEvents': const <Object?>[],
        }),
      );
      final future = TripTrackingSessionRecord.fromMap(
        sessionMap(schemaVersion: 99),
      );

      expect(current.schemaVersion, 5);
      expect(current.hasValidTimeline, isTrue);
      expect(future.hasValidTimeline, isFalse);
    },
  );

  test('review schema versions migrate to current integer version five', () {
    for (final schema in const [1.0, 6, 99, '1', false]) {
      final review = TripTrackingReviewRecord.fromMap(
        reviewMap(schemaVersion: schema),
      );

      expect(review.hasValidTimeline, isFalse, reason: '$schema');
    }

    final supported = TripTrackingReviewRecord.fromMap(reviewMap());

    expect(supported.schemaVersion, 5);
    expect(supported.hasValidTimeline, isTrue);

    final current = TripTrackingReviewRecord.fromMap(
      reviewMap(schemaVersion: 5)..['userEvents'] = const <Object?>[],
    );
    expect(current.schemaVersion, 5);
    expect(current.hasValidTimeline, isTrue);
  });

  test('unknown cloud sync state cannot become trusted backup progress', () {
    final review = TripTrackingReviewRecord.fromMap(
      reviewMap(cloudSyncState: 'uploadedSomewhere'),
    );

    expect(review.cloudSyncState, TripTrackingCloudSyncState.localOnly);
    expect(review.hasValidTimeline, isFalse);
  });

  test('synced reviews require a sync timestamp after trip finish', () {
    final missingTimestamp = TripTrackingReviewRecord.fromMap(
      reviewMap(cloudSyncState: TripTrackingCloudSyncState.synced.name),
    );
    final beforeFinish = TripTrackingReviewRecord.fromMap(
      reviewMap(
        cloudSyncState: TripTrackingCloudSyncState.synced.name,
        cloudSyncedAt: finishedAt
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      ),
    );
    final afterFinish = TripTrackingReviewRecord.fromMap(
      reviewMap(
        cloudSyncState: TripTrackingCloudSyncState.synced.name,
        cloudSyncedAt: finishedAt
            .add(const Duration(seconds: 1))
            .toIso8601String(),
      ),
    );

    expect(missingTimestamp.hasValidTimeline, isFalse);
    expect(beforeFinish.hasValidTimeline, isFalse);
    expect(afterFinish.hasValidTimeline, isTrue);
  });

  test('organization backups require a safe organization id binding', () {
    final missingOrganization = TripTrackingReviewRecord.fromMap(
      reviewMap(
        cloudBackupScope: TripTrackingCloudBackupScope.organization.name,
      ),
    );
    final unsafeOrganization = TripTrackingReviewRecord.fromMap(
      reviewMap(
        cloudBackupScope: TripTrackingCloudBackupScope.organization.name,
        cloudOrganizationId: 'org with spaces',
      ),
    );
    final safeOrganization = TripTrackingReviewRecord.fromMap(
      reviewMap(
        cloudBackupScope: TripTrackingCloudBackupScope.organization.name,
        cloudOrganizationId: 'org_123',
      ),
    );

    expect(missingOrganization.hasValidTimeline, isFalse);
    expect(unsafeOrganization.hasValidTimeline, isFalse);
    expect(safeOrganization.hasValidTimeline, isTrue);
    expect(safeOrganization.cloudOrganizationId, 'org_123');
  });

  test('personal backups reject stray organization ids from remote data', () {
    final review = TripTrackingReviewRecord.fromMap(
      reviewMap(
        cloudBackupScope: TripTrackingCloudBackupScope.personal.name,
        cloudOrganizationId: 'org_123',
      ),
    );

    expect(review.cloudBackupScope, TripTrackingCloudBackupScope.personal);
    expect(review.cloudOrganizationId, isNull);
    expect(review.hasValidTimeline, isFalse);
  });

  test('confirmed odometer fields are all-or-nothing and after finish', () {
    final missingTimestamp = TripTrackingReviewRecord.fromMap(
      reviewMap(confirmedEndingOdometer: 1002),
    );
    final lowerEnding = TripTrackingReviewRecord.fromMap(
      reviewMap(
        confirmedEndingOdometer: 999,
        odometerConfirmedAt: finishedAt
            .add(const Duration(seconds: 1))
            .toIso8601String(),
      ),
    );
    final beforeFinish = TripTrackingReviewRecord.fromMap(
      reviewMap(
        confirmedEndingOdometer: 1002,
        odometerConfirmedAt: finishedAt
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      ),
    );
    final valid = TripTrackingReviewRecord.fromMap(
      reviewMap(
        confirmedEndingOdometer: 1002,
        odometerConfirmedAt: finishedAt
            .add(const Duration(seconds: 1))
            .toIso8601String(),
      ),
    );

    expect(missingTimestamp.hasValidTimeline, isFalse);
    expect(lowerEnding.hasValidTimeline, isFalse);
    expect(beforeFinish.hasValidTimeline, isFalse);
    expect(valid.hasValidTimeline, isTrue);
    expect(valid.isOdometerConfirmed, isTrue);
  });

  test(
    'active trip boundary summary exposes no raw route or identity data',
    () {
      final session = TripTrackingSessionRecord.fromMap({
        ...sessionMap(),
        'id': 'trip_safe_summary',
        'vehicleId': 'vehicle_safe_summary',
        'startingOdometer': 120001,
      });

      final summary = session.toBoundarySummary();

      expect(summary['recordType'], 'activeSession');
      expect(summary['hasSafeTripId'], isTrue);
      expect(summary['hasSafeVehicleId'], isTrue);
      expect(summary['odometerBucket'], '100k_1m');
      expect(summary['storedAsDurableCheckpoint'], isTrue);
      expect(summary['hiveRemainsSourceOfTruth'], isTrue);
      expect(summary['remoteDataCanOverrideLocalTripLog'], isFalse);
      expect(summary['remoteTotalsCanBecomeCanonical'], isFalse);
      expect(summary['mapsRequiredForTracking'], isFalse);
      expect(summary['mapboxCanOverrideOdometer'], isFalse);
      expect(summary['odometerIsGlobalTruth'], isTrue);
      expect(summary['odometerRemainsCanonical'], isTrue);
      expect(summary['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(summary['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(summary['preciseLocationIncluded'], isFalse);
      expect(summary['preciseTimestampIncluded'], isFalse);
      expect(summary['rawEngineSnapshotIncluded'], isFalse);
      expect(summary['rawAdvisoriesIncluded'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
      expect(summary['canCreateOfficialMileage'], isFalse);
      expect(summary.toString(), isNot(contains('trip_safe_summary')));
      expect(summary.toString(), isNot(contains('vehicle_safe_summary')));
      expect(summary.toString(), isNot(contains('120001')));
    },
  );

  test(
    'review boundary summary keeps cloud mirror and odometer advisory only',
    () {
      final review = TripTrackingReviewRecord.fromMap(
        reviewMap(
          cloudSyncState: TripTrackingCloudSyncState.synced.name,
          cloudSyncedAt: finishedAt
              .add(const Duration(seconds: 5))
              .toIso8601String(),
          cloudBackupScope: TripTrackingCloudBackupScope.organization.name,
          cloudOrganizationId: 'org_123',
          confirmedEndingOdometer: 1002,
          odometerConfirmedAt: finishedAt
              .add(const Duration(seconds: 10))
              .toIso8601String(),
        ),
      ).copyWith(cloudAccountUid: 'firebaseUid_1');

      final summary = review.toBoundarySummary();

      expect(summary['recordType'], 'review');
      expect(summary['hasValidTimeline'], isTrue);
      expect(summary['startingOdometerBucket'], '1k_10k');
      expect(summary['estimatedEndingOdometerBucket'], '1k_10k');
      expect(summary['confirmedEndingOdometerBucket'], '1k_10k');
      expect(summary['isOdometerConfirmed'], isTrue);
      expect(summary['cloudSyncState'], TripTrackingCloudSyncState.synced.name);
      expect(
        summary['cloudBackupScope'],
        TripTrackingCloudBackupScope.organization.name,
      );
      expect(summary['hasCloudAccountBinding'], isTrue);
      expect(summary['hasOrganizationBinding'], isTrue);
      expect(summary['cloudSyncTimestampPresent'], isTrue);
      expect(summary['hiveRemainsSourceOfTruth'], isTrue);
      expect(summary['firestoreMirrorOnly'], isTrue);
      expect(summary['remoteDataCanOverrideLocalTripLog'], isFalse);
      expect(summary['remoteTotalsCanBecomeCanonical'], isFalse);
      expect(summary['cloudMirrorCanDeleteLocalTripLog'], isFalse);
      expect(summary['mapsRequiredForReview'], isFalse);
      expect(summary['mapboxCanOverrideOdometer'], isFalse);
      expect(summary['odometerIsGlobalTruth'], isTrue);
      expect(summary['odometerRemainsCanonical'], isTrue);
      expect(summary['calibrationRequiresTrustedGpsWindow'], isTrue);
      expect(summary['poorGpsDaysExcludedFromCalibration'], isTrue);
      expect(summary['authorizationRequiredBeforeCloudWrite'], isTrue);
      expect(summary['authenticationImpliesAuthorization'], isFalse);
      expect(summary['preciseLocationIncluded'], isFalse);
      expect(summary['preciseTimestampIncluded'], isFalse);
      expect(summary['accountIdIncluded'], isFalse);
      expect(summary['organizationIdIncluded'], isFalse);
      expect(summary['rawReviewIncluded'], isFalse);
      expect(summary['tokensIncluded'], isFalse);
      expect(summary['canOverrideOdometer'], isFalse);
      expect(summary.toString(), isNot(contains('firebaseUid_1')));
      expect(summary.toString(), isNot(contains('org_123')));
    },
  );

  test(
    'review boundary summary sanitizes malformed persisted cloud metadata',
    () {
      final review =
          TripTrackingReviewRecord.fromMap(
            reviewMap(
              cloudSyncState: TripTrackingCloudSyncState.failed.name,
              cloudBackupScope: TripTrackingCloudBackupScope.organization.name,
              cloudOrganizationId: 'org id/../unsafe',
            ),
          ).copyWith(
            cloudAccountUid: 'token=sk.secret',
            cloudSyncError: 'Mapbox failed at 35.12345,-80.98765 pk.public',
          );

      final summary = review.toBoundarySummary();

      expect(summary['hasValidTimeline'], isFalse);
      expect(summary['hasCloudAccountBinding'], isFalse);
      expect(summary['hasOrganizationBinding'], isFalse);
      expect(summary['hasCloudSyncError'], isTrue);
      expect(summary['accountIdIncluded'], isFalse);
      expect(summary['organizationIdIncluded'], isFalse);
      expect(summary.toString(), isNot(contains('sk.secret')));
      expect(summary.toString(), isNot(contains('pk.public')));
      expect(summary.toString(), isNot(contains('35.12345')));
      expect(summary.toString(), isNot(contains('-80.98765')));
    },
  );
}
