import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_backup_scope_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('personal backup binds an unscoped review to the current account', () {
    final decision = TripTrackingBackupScopePolicy.bindForQueue(
      review: _review(),
      createdByUid: 'firebaseUid-1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );

    expect(decision.canQueue, isTrue);
    expect(decision.boundReview?.cloudAccountUid, 'firebaseUid-1');
    expect(
      decision.boundReview?.cloudBackupScope,
      TripTrackingCloudBackupScope.personal,
    );
    expect(decision.boundReview?.cloudOrganizationId, isNull);
  });

  test('organization backup binds only to a safe current organization', () {
    final decision = TripTrackingBackupScopePolicy.bindForQueue(
      review: _review(),
      createdByUid: 'firebaseUid-1',
      personalBackup: false,
      organizationSharingEnabled: true,
      orgId: 'org_1',
    );
    final missing = TripTrackingBackupScopePolicy.bindForQueue(
      review: _review(),
      createdByUid: 'firebaseUid-1',
      personalBackup: false,
      organizationSharingEnabled: true,
      orgId: 'org/../unsafe',
    );

    expect(decision.canQueue, isTrue);
    expect(
      decision.boundReview?.cloudBackupScope,
      TripTrackingCloudBackupScope.organization,
    );
    expect(decision.boundReview?.cloudOrganizationId, 'org_1');
    expect(missing.canQueue, isFalse);
    expect(
      missing.safeErrorMessage,
      TripTrackingBackupScopePolicy.missingOrganizationMessage,
    );
  });

  test('backup scope summaries do not grant employer tracking authority', () {
    final decision = TripTrackingBackupScopePolicy.bindForQueue(
      review: _review(),
      createdByUid: 'firebaseUid-1',
      personalBackup: false,
      organizationSharingEnabled: true,
      orgId: 'org_1',
    );
    final summary = decision.toSafeSummary();

    expect(summary['authorizationRequired'], isTrue);
    expect(summary['authenticationImpliesAuthorization'], isFalse);
    expect(summary['employeeTrackingRequiresMutualConsent'], isTrue);
    expect(summary['locationSharingRequiresActiveOptIn'], isTrue);
    expect(summary['employerGodModeAllowed'], isFalse);
    expect(summary['preciseLocationIncluded'], isFalse);
    expect(summary['accountIdIncluded'], isFalse);
    expect(summary['organizationIdIncluded'], isFalse);
    expect(summary['rawReviewIncluded'], isFalse);
  });

  test('already-bound reviews cannot be adopted by another account or org', () {
    final accountMismatch = TripTrackingBackupScopePolicy.bindForQueue(
      review: _review().copyWith(cloudAccountUid: 'original_uid'),
      createdByUid: 'different_uid',
      personalBackup: true,
      organizationSharingEnabled: false,
    );
    final orgMismatch = TripTrackingBackupScopePolicy.bindForQueue(
      review: _review().copyWith(
        cloudAccountUid: 'firebaseUid-1',
        cloudBackupScope: TripTrackingCloudBackupScope.organization,
        cloudOrganizationId: 'org_1',
      ),
      createdByUid: 'firebaseUid-1',
      personalBackup: false,
      organizationSharingEnabled: true,
      orgId: 'org_2',
    );

    expect(accountMismatch.canQueue, isFalse);
    expect(orgMismatch.canQueue, isFalse);
    expect(
      accountMismatch.safeErrorMessage,
      TripTrackingBackupScopePolicy.scopeMismatchMessage,
    );
    expect(
      orgMismatch.safeErrorMessage,
      TripTrackingBackupScopePolicy.scopeMismatchMessage,
    );
  });

  test('scope binding validation rejects personal records with org ids', () {
    expect(
      TripTrackingBackupScopePolicy.hasValidScopeBinding(
        scope: TripTrackingCloudBackupScope.personal,
        organizationId: 'org_1',
      ),
      isFalse,
    );
    expect(
      TripTrackingBackupScopePolicy.hasValidScopeBinding(
        scope: TripTrackingCloudBackupScope.organization,
        organizationId: 'org_1',
      ),
      isTrue,
    );
  });
}

TripTrackingReviewRecord _review() => TripTrackingReviewRecord(
  id: 'trip_1',
  vehicleId: 'vehicle_1',
  startingOdometer: 1000,
  estimatedEndingOdometer: 1010,
  confirmedEndingOdometer: 1010,
  odometerConfirmedAt: DateTime.utc(2026, 7, 17, 9, 5),
  profile: TripTrackingProfile.roadVehicle,
  startedAt: DateTime.utc(2026, 7, 17, 8),
  finishedAt: DateTime.utc(2026, 7, 17, 9),
  engineSnapshot: const TripTrackingEngineSnapshot(
    totalAcceptedMeters: 16093.44,
    walkingReviewSuggested: false,
  ),
);
