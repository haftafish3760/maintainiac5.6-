// Regression tests for exact tenth-unit odometer trip persistence.
//
// Owns active-session and review-record compatibility, round-trip, and
// malformed precision checks. It does not test Dashboard input or Firebase.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 8, 1, 12);

  TripTrackingSessionRecord session({int? tenths}) => TripTrackingSessionRecord(
    id: 'trip-tenths',
    vehicleId: 'vehicle-1',
    startingOdometer: 1000,
    startingOdometerTenths: tenths,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    updatedAt: startedAt,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 0,
      walkingReviewSuggested: false,
    ),
  );

  TripTrackingReviewRecord review() => TripTrackingReviewRecord(
    id: 'trip-tenths',
    vehicleId: 'vehicle-1',
    startingOdometer: 1000,
    startingOdometerTenths: 10007,
    estimatedEndingOdometer: 1001,
    estimatedEndingOdometerTenths: 10012,
    confirmedEndingOdometer: 1001,
    confirmedEndingOdometerTenths: 10014,
    endingOdometerDraft: 1001,
    endingOdometerDraftTenths: 10013,
    odometerConfirmedAt: startedAt.add(const Duration(minutes: 31)),
    profile: TripTrackingProfile.roadVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(minutes: 30)),
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1126,
      walkingReviewSuggested: false,
    ),
  );

  test('active session preserves exact starting odometer tenths', () {
    final restored = TripTrackingSessionRecord.fromMap(
      session(tenths: 10007).toMap(),
    );

    expect(restored.startingOdometer, 1000);
    expect(restored.effectiveStartingOdometerTenths, 10007);
    expect(restored.hasValidTimeline, isTrue);
  });

  test('legacy session safely derives tenths from whole odometer', () {
    final restored = TripTrackingSessionRecord.fromMap(session().toMap());

    expect(restored.startingOdometerTenths, isNull);
    expect(restored.effectiveStartingOdometerTenths, 10000);
    expect(restored.hasValidTimeline, isTrue);
  });

  test(
    'trip review preserves start, estimate, draft, and confirmation tenths',
    () {
      final restored = TripTrackingReviewRecord.fromMap(review().toMap());

      expect(restored.effectiveStartingOdometerTenths, 10007);
      expect(restored.effectiveEstimatedEndingOdometerTenths, 10012);
      expect(restored.effectiveEndingOdometerDraftTenths, 10013);
      expect(restored.effectiveConfirmedEndingOdometerTenths, 10014);
      expect(restored.hasValidTimeline, isTrue);
      expect(restored.isOdometerConfirmed, isTrue);
    },
  );

  test('mismatched whole and tenth fields fail closed', () {
    final malformedSession = TripTrackingSessionRecord.fromMap({
      ...session(tenths: 10007).toMap(),
      'startingOdometerTenths': 9999,
    });
    final malformedReview = TripTrackingReviewRecord.fromMap({
      ...review().toMap(),
      'confirmedEndingOdometerTenths': 9999,
    });

    expect(malformedSession.hasValidTimeline, isFalse);
    expect(malformedReview.hasValidTimeline, isFalse);
  });

  test('lower confirmed tenth cannot hide inside the same whole mile', () {
    final restored = TripTrackingReviewRecord.fromMap({
      ...review().toMap(),
      'confirmedEndingOdometer': 1000,
      'confirmedEndingOdometerTenths': 10006,
    });

    expect(restored.isOdometerConfirmed, isFalse);
    expect(restored.hasValidTimeline, isFalse);
  });

  test('controller carries exact start tenths into TripLog review', () async {
    final odometer = GlobalOdometerController(
      initialReading: 1000,
      initialReadingTenths: 10007,
    );
    final store = TripTrackingSessionStore.memory();
    final controller = TripTrackingController(
      sessionStore: store,
      odometer: odometer,
    );
    addTearDown(controller.dispose);

    expect(
      await controller.start(
        tripId: 'exact-controller-trip',
        vehicleId: odometer.vehicleId,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      ),
      isTrue,
    );
    expect(controller.activeSession?.effectiveStartingOdometerTenths, 10007);
    final completed = await controller.finishForReview(
      finishedAt: startedAt.add(const Duration(minutes: 5)),
    );

    expect(completed, isNotNull);
    expect(completed!.effectiveStartingOdometerTenths, 10007);
    expect(completed.effectiveEstimatedEndingOdometerTenths, 10007);

    expect(
      await controller.confirmOdometerReview(
        reviewId: completed.id,
        confirmedEndingOdometer: 1001,
        confirmedEndingOdometerTenths: 10014,
        confirmedAt: startedAt.add(const Duration(minutes: 6)),
        userAcknowledgedReviewPrompt: true,
      ),
      isTrue,
    );
    expect(odometer.confirmedReadingTenths, 10014);
    expect(
      store.reviewForTrip(completed.id)?.effectiveConfirmedEndingOdometerTenths,
      10014,
    );
  });
}
