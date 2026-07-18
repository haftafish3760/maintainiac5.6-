import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/records/maintainiac_durable_record_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_durable_record_bridge.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('reviewed trips save through the shared durable record store', () async {
    final bridge = TripTrackingDurableRecordBridge(
      MaintainiacDurableRecordStore.memory(),
    );
    final saved = await bridge.saveReviewedTrip(_review());

    expect(saved.module, TripTrackingDurableRecordBridge.module);
    expect(saved.payload['durableRecordSchema'], 'trip_tracking_review_v1');
    expect(saved.payload['confirmedEndingOdometer'], 1012);
    expect(saved.payload['hiveRemainsSourceOfTruth'], isTrue);
    expect(saved.payload['firestoreMirrorOnly'], isTrue);
    expect(saved.payload['remoteDataCanOverrideLocalDaytimeData'], isFalse);
    expect(saved.payload['remoteDataCanPurgeLocalDaytimeData'], isFalse);
    expect(saved.payload['remoteDataCanSilentlyResolveConflicts'], isFalse);
    expect(saved.payload['durableRecordRequiresConfirmedOdometer'], isTrue);
    expect(saved.payload['confirmedOdometerRemainsCanonical'], isTrue);
    expect(saved.payload['mapboxCanReplaceOdometer'], isFalse);
    expect(saved.payload['mapboxCanCreateDurableRecord'], isFalse);
    expect(saved.payload['rawGpsIncluded'], isFalse);
    expect(saved.payload['rawMapboxGeometryIncluded'], isFalse);
    expect((saved.payload['engineSnapshot'] as Map)['walkingEvidence'], isNull);
    expect(
      (saved.payload['engineSnapshot']
          as Map)['walkingEvidencePersistedInDurableRecord'],
      isFalse,
    );
    expect(saved.payload.keys, isNot(contains('lastAccepted')));
    expect(bridge.reviewForTrip('trip_1')?.confirmedEndingOdometer, 1012);
  });

  test('unreviewed trips cannot enter shared durable records', () async {
    final bridge = TripTrackingDurableRecordBridge(
      MaintainiacDurableRecordStore.memory(),
    );

    await expectLater(
      () => bridge.saveReviewedTrip(_review(confirmed: false)),
      throwsArgumentError,
    );
    expect(bridge.reviewedTrips(), isEmpty);
  });

  test('unsafe trip ids cannot read or write durable trip records', () async {
    final bridge = TripTrackingDurableRecordBridge(
      MaintainiacDurableRecordStore.memory(),
    );

    await expectLater(
      () => bridge.saveReviewedTrip(_review(id: 'trip:../private')),
      throwsArgumentError,
    );

    expect(bridge.reviewForTrip(' trip:../private '), isNull);
    expect(bridge.reviewedTrips(), isEmpty);
  });

  test(
    'reviewed trip vehicle filters are validated before local reads',
    () async {
      final bridge = TripTrackingDurableRecordBridge(
        MaintainiacDurableRecordStore.memory(),
      );

      await bridge.saveReviewedTrip(_review(id: 'trip_vehicle_1'));
      await bridge.saveReviewedTrip(
        _review(id: 'trip_vehicle_2', vehicleId: 'vehicle_2'),
      );

      expect(bridge.reviewedTrips(vehicleId: ' vehicle_1 '), hasLength(1));
      expect(bridge.reviewedTrips(vehicleId: 'vehicle_1\nvehicle_2'), isEmpty);
      expect(bridge.reviewedTrips(vehicleId: null), hasLength(2));
    },
  );

  test('safe summary advertises durable local-first boundaries', () {
    final bridge = TripTrackingDurableRecordBridge(
      MaintainiacDurableRecordStore.memory(),
    );

    expect(bridge.toSafeSummary(), {
      'schemaVersion': 1,
      'module': 'trip_tracking',
      'usesSharedDurableRecordStore': true,
      'storesReviewedTripsOnly': true,
      'hiveRemainsSourceOfTruth': true,
      'firestoreMirrorOnly': true,
      'remoteDataCanOverrideLocalDaytimeData': false,
      'remoteDataCanPurgeLocalDaytimeData': false,
      'remoteDataCanSilentlyResolveConflicts': false,
      'confirmedBackupCanOnlySuggestCleanup': true,
      'durableRecordRequiresConfirmedOdometer': true,
      'durableRecordRequiresValidTimeline': true,
      'durableRecordRequiresSafeIds': true,
      'backendAuthorizationRequiredForMirror': true,
      'authenticationDoesNotImplyAuthorization': true,
      'remotePayloadTrustedAfterValidationOnly': true,
      'mapboxDataAdvisoryOnly': true,
      'mapboxCanCreateDurableRecord': false,
      'mapboxCanReplaceDurableMileage': false,
      'rawGpsIncluded': false,
      'rawMapboxGeometryIncluded': false,
      'tokensIncluded': false,
    });
  });

  test('safe summary validates local durable bridge boundaries', () {
    final bridge = TripTrackingDurableRecordBridge(
      MaintainiacDurableRecordStore.memory(),
    );
    final validation =
        TripTrackingDurableRecordBridgeSummaryValidation.fromSummary(
          bridge.toSafeSummary(),
        );

    expect(validation.isRenderable, isTrue);
    expect(validation.reasons, isEmpty);
  });

  test(
    'durable bridge summary rejects remote, Mapbox, and token authority',
    () {
      final bridge = TripTrackingDurableRecordBridge(
        MaintainiacDurableRecordStore.memory(),
      );
      final validation =
          TripTrackingDurableRecordBridgeSummaryValidation.fromSummary(
            Map<String, Object?>.from(bridge.toSafeSummary())..addAll({
              'remoteDataCanOverrideLocalDaytimeData': true,
              'remoteDataCanPurgeLocalDaytimeData': true,
              'remoteDataCanSilentlyResolveConflicts': true,
              'confirmedBackupCanOnlySuggestCleanup': false,
              'backendAuthorizationRequiredForMirror': false,
              'authenticationDoesNotImplyAuthorization': false,
              'remotePayloadTrustedAfterValidationOnly': false,
              'mapboxDataAdvisoryOnly': false,
              'mapboxCanCreateDurableRecord': true,
              'mapboxCanReplaceDurableMileage': true,
              'rawGpsIncluded': true,
              'rawMapboxGeometryIncluded': true,
              'tokensIncluded': true,
              'debug': 'sk.secret 35.123456,-80.123456',
            }),
          );

      expect(validation.isRenderable, isFalse);
      expect(validation.reasons, contains('local_day_truth_boundary_missing'));
      expect(validation.reasons, contains('authorization_boundary_missing'));
      expect(validation.reasons, contains('mapbox_can_control_durable_record'));
      expect(
        validation.reasons,
        contains('summary_contains_sensitive_trip_material'),
      );
      expect(validation.reasons, contains('summary_contains_sensitive_text'));
    },
  );
}

TripTrackingReviewRecord _review({
  bool confirmed = true,
  String id = 'trip_1',
  String vehicleId = 'vehicle_1',
}) {
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: 1000,
    estimatedEndingOdometer: 1012,
    confirmedEndingOdometer: confirmed ? 1012 : null,
    odometerConfirmedAt: confirmed ? DateTime.utc(2026, 7, 18, 10) : null,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: DateTime.utc(2026, 7, 18, 8),
    finishedAt: DateTime.utc(2026, 7, 18, 9),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: 19312.128,
      walkingReviewSuggested: true,
      walkingEvidence: [
        TripActivityObservation(
          activity: TripActivity.walking,
          confidence: 95,
          recordedAt: DateTime.utc(2026, 7, 18, 8, 30),
        ),
      ],
    ),
  );
}
