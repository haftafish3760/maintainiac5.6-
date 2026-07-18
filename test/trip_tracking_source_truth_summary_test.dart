import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_source_truth_summary.dart';

void main() {
  final day = DateTime.utc(2026, 7, 14);

  TripTrackingReviewRecord review({
    String id = 'trip_1',
    String vehicleId = 'vehicle_1',
    int startingOdometer = 1000,
    int estimatedEndingOdometer = 1010,
    int? confirmedEndingOdometer,
    DateTime? odometerConfirmedAt,
    DateTime? startedAt,
  }) => TripTrackingReviewRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: estimatedEndingOdometer,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt ?? day.add(const Duration(hours: 8)),
    finishedAt: (startedAt ?? day.add(const Duration(hours: 8))).add(
      const Duration(minutes: 30),
    ),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1609.344,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
    confirmedEndingOdometer: confirmedEndingOdometer,
    odometerConfirmedAt: odometerConfirmedAt,
  );

  test(
    'daily source truth derives official miles from confirmed odometers',
    () {
      final summary = TripTrackingSourceTruthSummary.forLocalReviewDay(
        day: day,
        reviews: [
          review(
            id: 'trip_confirmed',
            startingOdometer: 1000,
            estimatedEndingOdometer: 1012,
            confirmedEndingOdometer: 1011,
            odometerConfirmedAt: day.add(const Duration(hours: 9)),
          ),
          review(
            id: 'trip_unconfirmed',
            startingOdometer: 2000,
            estimatedEndingOdometer: 2008,
          ),
        ],
      );
      final safe = summary.toSafeDashboardMap();

      expect(summary.confirmedTripCount, 1);
      expect(summary.unconfirmedTripCount, 1);
      expect(summary.confirmedMiles, 11);
      expect(summary.advisoryEstimatedMiles, 8);
      expect(summary.hasUnconfirmedMileage, isTrue);
      expect(safe['derivedFromValidatedLocalReviewRecords'], isTrue);
      expect(safe['officialMileageSource'], 'confirmed_odometer');
      expect(safe['unconfirmedMileageIsAdvisory'], isTrue);
    },
  );

  test('remote and map totals are never marked canonical in summaries', () {
    final summary = TripTrackingSourceTruthSummary.forLocalReviewDay(
      day: day,
      reviews: [review()],
    ).toSafeDashboardMap();

    expect(summary['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(summary['firestoreTotalsAcceptedAsCanonical'], isFalse);
    expect(summary['mapboxDistanceAcceptedAsCanonical'], isFalse);
    expect(summary['remoteRecapCanOverrideLocalDay'], isFalse);
    expect(summary['remoteTotalsRejectedAtTrustBoundary'], isTrue);
    expect(summary['mapboxRoutesRejectedAsOfficialMileage'], isTrue);
    expect(summary['cloudFunctionsCanOverrideLocalDay'], isFalse);
    expect(summary['firebaseAuthDoesNotGrantRecordOwnership'], isTrue);
    expect(summary['notificationsUseRemoteTotals'], isFalse);
    expect(summary['exportsUseRemoteTotals'], isFalse);
    expect(summary['invoicesUseRemoteTotals'], isFalse);
    expect(summary['rawGpsIncluded'], isFalse);
    expect(summary['preciseLocationIncluded'], isFalse);
    expect(summary['routeGeometryIncluded'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
  });

  test('day and vehicle filters reject unrelated records', () {
    final summary = TripTrackingSourceTruthSummary.forLocalReviewDay(
      day: day,
      vehicleId: 'vehicle_1',
      reviews: [
        review(id: 'same_vehicle'),
        review(id: 'wrong_vehicle', vehicleId: 'vehicle_2'),
        review(
          id: 'wrong_day',
          startedAt: day.add(const Duration(days: 1, hours: 8)),
        ),
      ],
    );

    expect(summary.unconfirmedTripCount, 1);
    expect(summary.rejectedRecordCount, 2);
    expect(summary.rejectionReasons, contains('wrong_vehicle'));
    expect(summary.rejectionReasons, contains('outside_requested_day'));
  });

  test('duplicate review ids cannot inflate confirmed mileage totals', () {
    final first = review(
      id: 'trip_duplicate',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1012,
      confirmedEndingOdometer: 1011,
      odometerConfirmedAt: day.add(const Duration(hours: 9)),
    );
    final replayedMirror = review(
      id: 'trip_duplicate',
      startingOdometer: 2000,
      estimatedEndingOdometer: 2050,
      confirmedEndingOdometer: 2050,
      odometerConfirmedAt: day.add(const Duration(hours: 10)),
    );
    final summary = TripTrackingSourceTruthSummary.forLocalReviewDay(
      day: day,
      reviews: [first, replayedMirror],
    );
    final safe = summary.toSafeDashboardMap();

    expect(summary.confirmedTripCount, 1);
    expect(summary.confirmedMiles, 11);
    expect(summary.rejectedRecordCount, 1);
    expect(summary.rejectionReasons, contains('duplicate_review_id'));
    expect(safe['duplicateReviewIdsRejected'], isTrue);
    expect(safe['firestoreTotalsAcceptedAsCanonical'], isFalse);
  });

  test('malformed review ids are rejected before dashboard totals', () {
    final summary = TripTrackingSourceTruthSummary.forLocalReviewDay(
      day: day,
      reviews: [
        review(id: ''),
        review(id: ' trip_with_spaces '),
      ],
    );

    expect(summary.confirmedTripCount, 0);
    expect(summary.unconfirmedTripCount, 0);
    expect(summary.rejectedRecordCount, 2);
    expect(summary.rejectionReasons, contains('invalid_review_id'));
  });

  test('invalid confirmation cannot become official mileage', () {
    final invalid = TripTrackingReviewRecord.fromMap({
      ...review(
        id: 'invalid_confirmation',
        confirmedEndingOdometer: 999,
        odometerConfirmedAt: day.add(const Duration(hours: 9)),
      ).toMap(),
      'confirmedEndingOdometer': 999,
    });
    final summary = TripTrackingSourceTruthSummary.forLocalReviewDay(
      day: day,
      reviews: [invalid],
    );

    expect(summary.confirmedTripCount, 0);
    expect(summary.confirmedMiles, 0);
    expect(summary.rejectedRecordCount, 1);
    expect(summary.rejectionReasons, contains('invalid_timeline'));
  });

  test('empty local source records produce an explicit empty safe summary', () {
    final summary = TripTrackingSourceTruthSummary.forLocalReviewDay(
      day: day,
      reviews: const [],
    );

    expect(summary.isEmpty, isTrue);
    expect(summary.toSafeDashboardMap()['confirmedMiles'], 0);
    expect(summary.toSafeDashboardMap()['advisoryEstimatedMiles'], 0);
  });
}
