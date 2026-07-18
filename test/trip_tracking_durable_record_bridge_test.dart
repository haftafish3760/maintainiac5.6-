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
    expect(saved.payload['durableRecordRequiresConfirmedOdometer'], isTrue);
    expect(saved.payload['confirmedOdometerRemainsCanonical'], isTrue);
    expect(saved.payload['mapboxCanReplaceOdometer'], isFalse);
    expect(saved.payload['rawGpsIncluded'], isFalse);
    expect(saved.payload['rawMapboxGeometryIncluded'], isFalse);
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
      'confirmedBackupCanOnlySuggestCleanup': true,
      'durableRecordRequiresConfirmedOdometer': true,
      'durableRecordRequiresValidTimeline': true,
      'durableRecordRequiresSafeIds': true,
      'backendAuthorizationRequiredForMirror': true,
      'authenticationDoesNotImplyAuthorization': true,
      'remotePayloadTrustedAfterValidationOnly': true,
      'mapboxDataAdvisoryOnly': true,
      'rawGpsIncluded': false,
      'rawMapboxGeometryIncluded': false,
      'tokensIncluded': false,
    });
  });
}

TripTrackingReviewRecord _review({
  bool confirmed = true,
  String id = 'trip_1',
}) {
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1012,
    confirmedEndingOdometer: confirmed ? 1012 : null,
    odometerConfirmedAt: confirmed ? DateTime.utc(2026, 7, 18, 10) : null,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: DateTime.utc(2026, 7, 18, 8),
    finishedAt: DateTime.utc(2026, 7, 18, 9),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 19312.128,
      walkingReviewSuggested: true,
    ),
  );
}
