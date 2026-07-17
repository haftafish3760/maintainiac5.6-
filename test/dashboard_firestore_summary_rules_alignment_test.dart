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
