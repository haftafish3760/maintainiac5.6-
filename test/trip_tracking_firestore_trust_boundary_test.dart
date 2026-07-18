import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_review_mirror_payload_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_firestore_contract.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('Firestore trust boundary summaries stay fail-closed', () {
    final personal = TripTrackingFirestoreContract.trustBoundarySummary(
      organizationScoped: false,
    );
    final organization = TripTrackingFirestoreContract.trustBoundarySummary(
      organizationScoped: true,
    );

    expect(
      TripTrackingFirestoreContract.isTrustBoundaryClosed(personal),
      isTrue,
    );
    expect(
      TripTrackingFirestoreContract.isTrustBoundaryClosed(organization),
      isTrue,
    );
    expect(personal['authenticationImpliesAuthorization'], isFalse);
    expect(personal['hiveRemainsSourceOfTruth'], isTrue);
    expect(personal['firestoreMirrorOnly'], isTrue);
    expect(personal['remoteCanConfirmOdometer'], isFalse);
    expect(personal['remoteCanCreateOfficialStop'], isFalse);
    expect(personal['remoteCanPurgeLocalTripData'], isFalse);
    expect(personal['rulesMustRejectLiveOdometerProjectionWrites'], isTrue);
    expect(personal['rulesMustRejectClientStopWrites'], isTrue);
    expect(personal['rulesMustRejectMapboxOptimizationWrites'], isTrue);
    expect(personal['publicTokenAllowedInPayload'], isFalse);
    expect(personal['secretTokenAllowedInPayload'], isFalse);
    expect(organization['organizationMembershipRequired'], isTrue);
    expect(organization['organizationSharingConsentRequired'], isTrue);
    expect(organization['fleetReadRequiresConsent'], isTrue);
    expect(organization['employeeTrackingRequiresMutualConsent'], isTrue);
  });

  test(
    'trust boundary detects remote authority and sensitive payload drift',
    () {
      final summary = {
        ...TripTrackingFirestoreContract.trustBoundarySummary(
          organizationScoped: true,
        ),
        'remoteCanOverrideLocalTripLog': true,
        'routeGeometryAllowedInPayload': true,
        'fleetReadRequiresConsent': false,
      };

      final findings = TripTrackingFirestoreContract.trustBoundaryFindings(
        summary,
      );

      expect(findings, contains('remote_authority_too_high'));
      expect(findings, contains('sensitive_payload_boundary_open'));
      expect(findings, contains('organization_consent_boundary_open'));
    },
  );

  test('review mirror payloads require backend revalidation contract', () {
    final decision = TripReviewMirrorPayloadPolicy.build(
      review: _review().copyWith(
        confirmedEndingOdometer: 1010,
        odometerConfirmedAt: DateTime.utc(2026, 7, 17, 9, 5),
      ),
      ownerUid: 'driver_1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );

    expect(decision.mayMirror, isTrue);
    expect(decision.payload['firestoreRulesMustValidateOwner'], isTrue);
    expect(decision.payload['cloudFunctionMustRevalidateOwner'], isTrue);
    expect(decision.payload['cloudFunctionCanConfirmOdometer'], isFalse);

    final unsafe = {
      ...decision.payload,
      'cloudFunctionMustRevalidateOwner': false,
    };
    final inbound = TripReviewMirrorPayloadPolicy.validateInbound(
      payload: unsafe,
      scopeSummary: decision.scopeSummary,
    );

    expect(inbound.status, TripReviewMirrorPayloadStatus.blockedInvalidPayload);
  });

  test('review mirror inbound validation rejects tokens and coordinates', () {
    final decision = TripReviewMirrorPayloadPolicy.build(
      review: _review().copyWith(
        confirmedEndingOdometer: 1010,
        odometerConfirmedAt: DateTime.utc(2026, 7, 17, 9, 5),
      ),
      ownerUid: 'driver_1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );
    final unsafe = {
      ...decision.payload,
      'supportNote': '35.123456,-80.123456',
      'tokenEcho': 'pk.redacted',
    };

    final inbound = TripReviewMirrorPayloadPolicy.validateInbound(
      payload: unsafe,
      scopeSummary: decision.scopeSummary,
    );

    expect(inbound.status, TripReviewMirrorPayloadStatus.blockedInvalidPayload);
    expect(inbound.toSafeDashboardMap().toString(), isNot(contains('35.')));
    expect(inbound.toSafeDashboardMap().toString(), isNot(contains('pk.')));
  });

  test('Firestore mileage rules expose the required backend gates', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('request.resource.data.createdByUid == uid'));
    expect(rules, contains('request.resource.data.updatedByUid == uid'));
    expect(rules, contains('request.resource.data.tripId == recordId'));
    expect(rules, contains('hasOnlyMileageSummaryFields()'));
    expect(rules, contains('hasRequiredMileageSummaryFields()'));
    expect(rules, contains('hasValidMileageSummaryValues()'));
    expect(rules, contains('hasCoherentMileageSummaryDistance()'));
    expect(rules, contains('hasNoClientTripAuthorityFields()'));
    expect(rules, contains('liveOdometerProjection'));
    expect(rules, contains('officialStops'));
    expect(rules, contains('mapboxOptimizedStopOrder'));
    expect(rules, contains('allow delete: if false'));
    expect(rules, contains('request.resource.data.orgId == orgId'));
    expect(
      rules,
      contains('request.resource.data.organizationSharingConsent == true'),
    );
    expect(rules, contains('resource.data.organizationSharingConsent == true'));
  });
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
    cloudBackupScope: TripTrackingCloudBackupScope.personal,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 16093.44,
      walkingReviewSuggested: false,
    ),
  );
}
