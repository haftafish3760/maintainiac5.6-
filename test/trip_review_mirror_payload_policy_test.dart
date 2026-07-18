import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_review_mirror_payload_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('confirmed personal review produces redacted mirror payload only', () {
    final decision = TripReviewMirrorPayloadPolicy.build(
      review: review().copyWith(
        confirmedEndingOdometer: 1042,
        odometerConfirmedAt: DateTime.utc(2026, 7, 18, 10, 5),
      ),
      ownerUid: 'driver_1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );
    final payload = decision.payload;
    final safe = decision.toSafeDashboardMap();

    expect(decision.status, TripReviewMirrorPayloadStatus.ready);
    expect(decision.mayMirror, isTrue);
    expect(payload['schema'], 'trip_review_mileage_mirror_v1');
    expect(payload['confirmedMiles'], 42);
    expect(payload['officialMileageSource'], 'odometer');
    expect(payload['odometerIsGlobalTruth'], isTrue);
    expect(payload['mirrorCanSetGlobalTruth'], isFalse);
    expect(payload['mirrorCanConfirmOfficialMileage'], isFalse);
    expect(payload['mirrorCanChangeOfficialMileage'], isFalse);
    expect(payload['gpsDistanceAdvisoryOnly'], isTrue);
    expect(payload['authenticationAloneAuthorizesMirror'], isFalse);
    expect(payload['backendRulesFailClosedForMirrorWrites'], isTrue);
    expect(payload['mirrorRequiresConfirmedLocalReview'], isTrue);
    expect(payload['mirrorRequiresOwnerScopeDayValidation'], isTrue);
    expect(payload['remoteCanOverrideLocalTripLog'], isFalse);
    expect(payload['remoteTotalsCanBecomeCanonical'], isFalse);
    expect(payload['mirrorCanDeleteLocalTripLog'], isFalse);
    expect(payload['rawGpsIncluded'], isFalse);
    expect(payload['routeGeometryIncluded'], isFalse);
    expect(payload['mapboxGeometryIncluded'], isFalse);
    expect(payload['preciseCoordinatesIncluded'], isFalse);
    expect(payload['tokensIncluded'], isFalse);
    expect(payload.values, isNot(contains('driver_1')));
    expect(safe['hiveRemainsSourceOfTruth'], isTrue);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['physicalOdometerRequiredForOfficialMileage'], isTrue);
    expect(safe['confirmedOdometerOverridesExternalMileage'], isTrue);
    expect(safe['externalMileageCannotBecomeGlobalTruth'], isTrue);
    expect(safe['mirrorCanSetGlobalTruth'], isFalse);
    expect(safe['mirrorCanConfirmOfficialMileage'], isFalse);
    expect(safe['mirrorCanChangeOfficialMileage'], isFalse);
    expect(safe['firestoreMirrorOnly'], isTrue);
    expect(safe['authenticationAloneAuthorizesMirror'], isFalse);
    expect(safe['backendRulesFailClosedForMirrorWrites'], isTrue);
  });

  test('unconfirmed odometer blocks mirror even when scope is valid', () {
    final decision = TripReviewMirrorPayloadPolicy.build(
      review: review(),
      ownerUid: 'driver_1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );

    expect(
      decision.status,
      TripReviewMirrorPayloadStatus.blockedUnconfirmedOdometer,
    );
    expect(decision.reasonCode, 'unconfirmed_odometer_blocks_mirror');
    expect(decision.mayMirror, isFalse);
    expect(decision.payload, isEmpty);
  });

  test('organization mirror requires matching safe organization scope', () {
    final confirmed = review().copyWith(
      confirmedEndingOdometer: 1042,
      odometerConfirmedAt: DateTime.utc(2026, 7, 18, 10, 5),
    );
    final missing = TripReviewMirrorPayloadPolicy.build(
      review: confirmed,
      ownerUid: 'driver_1',
      personalBackup: false,
      organizationSharingEnabled: true,
    );
    final ready = TripReviewMirrorPayloadPolicy.build(
      review: confirmed,
      ownerUid: 'driver_1',
      personalBackup: false,
      organizationSharingEnabled: true,
      organizationId: 'org_1',
    );

    expect(missing.status, TripReviewMirrorPayloadStatus.blockedScope);
    expect(missing.reasonCode, 'mirror_organization_missing');
    expect(ready.status, TripReviewMirrorPayloadStatus.ready);
    expect(ready.payload['cloudBackupScope'], 'organization');
    expect(ready.payload['cloudOrganizationBound'], isTrue);
    expect(ready.scopeSummary.values, isNot(contains('org_1')));
  });

  test('unsafe or mismatched owner blocks mirror payload', () {
    final confirmed = review().copyWith(
      cloudAccountUid: 'driver_1',
      confirmedEndingOdometer: 1042,
      odometerConfirmedAt: DateTime.utc(2026, 7, 18, 10, 5),
    );
    final unsafe = TripReviewMirrorPayloadPolicy.build(
      review: confirmed,
      ownerUid: 'sk.secret',
      personalBackup: true,
      organizationSharingEnabled: false,
    );
    final mismatch = TripReviewMirrorPayloadPolicy.build(
      review: confirmed,
      ownerUid: 'driver_2',
      personalBackup: true,
      organizationSharingEnabled: false,
    );

    expect(unsafe.status, TripReviewMirrorPayloadStatus.blockedOwner);
    expect(unsafe.reasonCode, 'unsafe_mirror_owner');
    expect(mismatch.status, TripReviewMirrorPayloadStatus.blockedOwner);
    expect(mismatch.reasonCode, 'mirror_owner_mismatch');
    expect(
      unsafe.toSafeDashboardMap().toString(),
      isNot(contains('sk.secret')),
    );
  });

  test('invalid review timeline blocks mirror payload', () {
    final invalid = TripTrackingReviewRecord.fromMap({
      ...review().toMap(),
      'finishedAt': '2026-07-18T07:00:00.000Z',
      'confirmedEndingOdometer': 1042,
      'odometerConfirmedAt': '2026-07-18T10:05:00.000Z',
    });
    final decision = TripReviewMirrorPayloadPolicy.build(
      review: invalid,
      ownerUid: 'driver_1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );

    expect(decision.status, TripReviewMirrorPayloadStatus.blockedInvalidReview);
    expect(decision.payload, isEmpty);
  });

  test('inbound mirror payload is revalidated before dashboard use', () {
    final outbound = TripReviewMirrorPayloadPolicy.build(
      review: review().copyWith(
        confirmedEndingOdometer: 1042,
        odometerConfirmedAt: DateTime.utc(2026, 7, 18, 10, 5),
      ),
      ownerUid: 'driver_1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );
    final inbound = TripReviewMirrorPayloadPolicy.validateInbound(
      payload: outbound.payload,
      scopeSummary: outbound.scopeSummary,
    );

    expect(inbound.status, TripReviewMirrorPayloadStatus.ready);
    expect(inbound.mayMirror, isTrue);
    expect(inbound.payload['officialMileageSource'], 'odometer');
    expect(inbound.payload['odometerIsGlobalTruth'], isTrue);
    expect(inbound.payload['mirrorCanSetGlobalTruth'], isFalse);
    expect(inbound.payload['mirrorCanConfirmOfficialMileage'], isFalse);
    expect(inbound.payload['mirrorCanChangeOfficialMileage'], isFalse);
    expect(inbound.payload['authenticationAloneAuthorizesMirror'], isFalse);
    expect(inbound.payload['backendRulesFailClosedForMirrorWrites'], isTrue);
    expect(inbound.payload['routeGeometryIncluded'], isFalse);
    expect(
      inbound.toSafeDashboardMap()['remoteTotalsCanBecomeCanonical'],
      isFalse,
    );
  });

  test('inbound mirror payload rejects authority and sensitive material', () {
    final outbound = TripReviewMirrorPayloadPolicy.build(
      review: review().copyWith(
        confirmedEndingOdometer: 1042,
        odometerConfirmedAt: DateTime.utc(2026, 7, 18, 10, 5),
      ),
      ownerUid: 'driver_1',
      personalBackup: true,
      organizationSharingEnabled: false,
    );
    final hostile = TripReviewMirrorPayloadPolicy.validateInbound(
      payload: {
        ...outbound.payload,
        'tripId': 'sk.secret',
        'authenticationAloneAuthorizesMirror': true,
        'backendRulesFailClosedForMirrorWrites': false,
        'mirrorRequiresConfirmedLocalReview': false,
        'mirrorRequiresOwnerScopeDayValidation': false,
        'remoteTotalsCanBecomeCanonical': true,
        'officialMileageSource': 'gps',
        'odometerIsGlobalTruth': false,
        'mirrorCanSetGlobalTruth': true,
        'mirrorCanConfirmOfficialMileage': true,
        'mirrorCanChangeOfficialMileage': true,
        'routeGeometryIncluded': true,
        'tokensIncluded': true,
      },
      scopeSummary: outbound.scopeSummary,
    );

    expect(hostile.status, TripReviewMirrorPayloadStatus.blockedInvalidPayload);
    expect(hostile.reasonCode, 'invalid_review_mirror_payload');
    expect(hostile.payload, isEmpty);
    expect(
      hostile.toSafeDashboardMap().toString(),
      isNot(contains('sk.secret')),
    );
  });

  test(
    'inbound mirror payload rejects missing backend fail-closed contract',
    () {
      final outbound = TripReviewMirrorPayloadPolicy.build(
        review: review().copyWith(
          confirmedEndingOdometer: 1042,
          odometerConfirmedAt: DateTime.utc(2026, 7, 18, 10, 5),
        ),
        ownerUid: 'driver_1',
        personalBackup: true,
        organizationSharingEnabled: false,
      );
      final forged = TripReviewMirrorPayloadPolicy.validateInbound(
        payload: {
          ...outbound.payload,
          'authenticationAloneAuthorizesMirror': true,
          'backendRulesFailClosedForMirrorWrites': false,
          'mirrorRequiresConfirmedLocalReview': false,
          'mirrorRequiresOwnerScopeDayValidation': false,
        },
        scopeSummary: outbound.scopeSummary,
      );

      expect(
        forged.status,
        TripReviewMirrorPayloadStatus.blockedInvalidPayload,
      );
      expect(forged.mayMirror, isFalse);
      expect(forged.payload, isEmpty);
    },
  );
}

TripTrackingReviewRecord review() {
  return TripTrackingReviewRecord(
    id: 'trip_1',
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1041,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: DateTime.utc(2026, 7, 18, 8),
    finishedAt: DateTime.utc(2026, 7, 18, 10),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 67592.4,
      walkingReviewSuggested: false,
    ),
  );
}
