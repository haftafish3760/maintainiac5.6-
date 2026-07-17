import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 17, 8);
  final finishedAt = DateTime.utc(2026, 7, 17, 9);

  Map<String, Object?> sessionMap({Object? schemaVersion = 1}) => {
    'id': 'trip_schema_boundary',
    'vehicleId': 'vehicle_1',
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
      'startingOdometer': 1000,
      'estimatedEndingOdometer': 1002,
      'profile': TripTrackingProfile.roadVehicle.name,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'engineSnapshot': const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 3218.688,
        walkingReviewSuggested: false,
      ).toMap(),
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

  test('active trip schema versions must be integer version one', () {
    for (final schema in const [1.0, 1.5, '1', true, null]) {
      final session = TripTrackingSessionRecord.fromMap(
        sessionMap(schemaVersion: schema),
      );

      expect(session.schemaVersion, 1, reason: '$schema');
      expect(session.hasValidTimeline, isFalse, reason: '$schema');
    }

    final supported = TripTrackingSessionRecord.fromMap(sessionMap());

    expect(supported.schemaVersion, 1);
    expect(supported.hasValidTimeline, isTrue);
  });

  test('review schema versions must be integer version one', () {
    for (final schema in const [1.0, 2, 99, '1', false]) {
      final review = TripTrackingReviewRecord.fromMap(
        reviewMap(schemaVersion: schema),
      );

      expect(review.hasValidTimeline, isFalse, reason: '$schema');
    }

    final supported = TripTrackingReviewRecord.fromMap(reviewMap());

    expect(supported.schemaVersion, 1);
    expect(supported.hasValidTimeline, isTrue);
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
}
