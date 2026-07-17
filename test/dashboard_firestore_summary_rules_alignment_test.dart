import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_documents.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_upload_queue.dart';

void main() {
  test('dashboard summary policy rejects legacy camelCase enum aliases', () {
    final doc =
        MaintainiacFirestoreDocumentBuilder.dashboardCommandCenterDocument(
          uid: 'firebaseUid-1',
          dashboardId: 'today',
          updatedAtUtc: DateTime.utc(2026, 7, 17, 12),
        );

    for (final entry in const <String, String>{
      'dashboardMode': 'gigDriver',
      'mileageMode': 'employeeShift',
      'syncMode': 'localOnly',
    }.entries) {
      expect(
        () => MaintainiacFirestoreUploadPolicy.validateDraft(
          MaintainiacFirestoreDocumentDraft(
            path: doc.path,
            data: {...doc.data, entry.key: entry.value},
          ),
        ),
        throwsArgumentError,
        reason: '${entry.key} must use the snake-case dashboard contract',
      );
    }
  });

  test('Firestore rules reject legacy dashboard camelCase aliases', () {
    final rules = File('firestore.rules').readAsStringSync();

    for (final legacyAlias in const [
      'gigDriver',
      'soloContractor',
      'fleetOwner',
      'employeeShift',
      'fleetReview',
      'customerHidden',
      'localOnly',
      'firebaseBackup',
      'companySync',
    ]) {
      expect(
        rules,
        isNot(contains("'$legacyAlias'")),
        reason: '$legacyAlias must not be accepted by backend rules',
      );
    }
  });

  test('Firestore rules expose dashboard profile and stop-detection gates', () {
    final rules = File('firestore.rules').readAsStringSync();

    for (final field in const [
      'workStyle',
      'stopDetectionMode',
      'stopReviewReasonCode',
      'recommendedActivityRecognition',
      'requiresStrongerStopDebounce',
      'recoveryState',
      'recoveryReason',
      'recoveryUserActionRequired',
      'odometerUsageCurrentMiles',
      'odometerUsageAverageDailyMiles',
      'odometerUsageReviewThresholdMiles',
      'authorizationRequired',
      'authenticationImpliesAuthorization',
      'employeeTrackingRequiresMutualConsent',
      'preciseLocationIncluded',
      'externalRoutesCanonical',
      'odometerRemainsCanonical',
    ]) {
      expect(
        rules,
        contains("'$field'"),
        reason: '$field must be part of the dashboard summary allowlist',
      );
      expect(
        rules,
        contains('request.resource.data.$field'),
        reason: '$field must be validated at the Firestore boundary',
      );
    }

    for (final invariant in const [
      'request.resource.data.authorizationRequired == true',
      'request.resource.data.authenticationImpliesAuthorization == false',
      'request.resource.data.employeeTrackingRequiresMutualConsent == true',
      'request.resource.data.preciseLocationIncluded == false',
      'request.resource.data.externalRoutesCanonical == false',
      'request.resource.data.odometerRemainsCanonical == true',
    ]) {
      expect(
        rules,
        contains(invariant),
        reason: '$invariant must be enforced by backend rules',
      );
    }

    for (final token in const [
      'general_road',
      'rideshare',
      'delivery',
      'contractor',
      'equipment',
      'walking_assisted',
      'strong_debounce',
      'walking_ignored',
      'road_vehicle_stop_walk_review',
      'rideshare_stop_requires_extra_evidence',
      'delivery_stop_walk_review',
      'contractor_stop_walk_review',
      'equipment_ignores_walking_stop_evidence',
      'trip_recovery_none',
      'trip_recovery_ready',
      'trip_recovery_pending_replay_ready',
      'trip_recovery_completed_review_present',
      'trip_recovery_invalid_session',
      'trip_recovery_invalid_review_present',
      'trip_recovery_vehicle_mismatch',
      'trip_recovery_odometer_mismatch',
      'trip_recovery_odometer_projection_invalid',
    ]) {
      expect(
        rules,
        contains("'$token'"),
        reason: '$token must be accepted explicitly by backend rules',
      );
    }

    for (final forbidden in const [
      'raw_route_worker',
      'always_precise',
      'raw_stop_address',
      'raw_recovery_payload',
      'precise_stop_coordinates',
    ]) {
      expect(
        rules,
        isNot(contains("'$forbidden'")),
        reason: '$forbidden must not be accepted by backend rules',
      );
    }
  });
}
