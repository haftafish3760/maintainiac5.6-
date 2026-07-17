import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('organization cloud reviews require a safe organization id', () {
    final missingOrg = _reviewMap(
      scope: TripTrackingCloudBackupScope.organization,
    );
    final unsafeOrg = _reviewMap(
      scope: TripTrackingCloudBackupScope.organization,
      organizationId: 'org/../other',
    );
    final validOrg = TripTrackingReviewRecord.fromMap(
      _reviewMap(
        scope: TripTrackingCloudBackupScope.organization,
        organizationId: 'org_1',
      ),
    );

    expect(TripTrackingReviewRecord.fromMap(missingOrg).hasValidTimeline, isFalse);
    expect(TripTrackingReviewRecord.fromMap(unsafeOrg).hasValidTimeline, isFalse);
    expect(validOrg.hasValidTimeline, isTrue);
    expect(validOrg.cloudOrganizationId, 'org_1');
  });

  test('personal cloud reviews cannot retain organization ids', () {
    final restored = TripTrackingReviewRecord.fromMap(
      _reviewMap(
        scope: TripTrackingCloudBackupScope.personal,
        organizationId: 'org_1',
      ),
    );
    final personal = _review().copyWith(
      cloudBackupScope: TripTrackingCloudBackupScope.personal,
      cloudOrganizationId: 'org_1',
    );

    expect(restored.hasValidTimeline, isFalse);
    expect(restored.cloudOrganizationId, isNull);
    expect(personal.cloudOrganizationId, isNull);
  });

  test('direct organization review writes require a safe organization id', () async {
    final store = TripTrackingSessionStore.memory();
    final missingOrg = _review().copyWith(
      cloudBackupScope: TripTrackingCloudBackupScope.organization,
    );
    final validOrg = _review().copyWith(
      cloudBackupScope: TripTrackingCloudBackupScope.organization,
      cloudOrganizationId: 'org_1',
    );

    await expectLater(store.saveReview(missingOrg), throwsArgumentError);
    await store.saveReview(validOrg);

    expect(store.reviewForTrip('trip_1')?.cloudOrganizationId, 'org_1');
  });
}

Map<String, Object?> _reviewMap({
  TripTrackingCloudBackupScope? scope,
  String? organizationId,
}) {
  final review = _review();
  final map = <String, Object?>{
    ...review.toMap(),
  };
  if (organizationId != null) map['cloudOrganizationId'] = organizationId;
  if (scope != null) map['cloudBackupScope'] = scope.name;
  return map;
}

TripTrackingReviewRecord _review() {
  return TripTrackingReviewRecord(
    id: 'trip_1',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1010,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: DateTime.utc(2026, 7, 17, 8),
    finishedAt: DateTime.utc(2026, 7, 17, 9),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 16093.44,
      walkingReviewSuggested: false,
    ),
  );
}
