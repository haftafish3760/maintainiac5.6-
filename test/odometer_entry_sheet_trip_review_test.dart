import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/odometer_entry_sheet.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  testWidgets('odometer entry sheet follows live GPS until manually edited', (
    tester,
  ) async {
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalOdometerScope(
          controller: odometer,
          child: const Scaffold(
            body: OdometerEntrySheet(
              title: 'Update Odometer',
              saveLabel: 'Save',
            ),
          ),
        ),
      ),
    );

    expect(find.text('1000'), findsOneWidget);

    expect(
      odometer.beginLiveTripProjection(
        tripId: 'trip_live_sheet',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'trip_live_sheet',
        estimatedOdometer: 1002,
      ),
      isTrue,
    );
    await tester.pump();

    expect(find.text('1002'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1005');
    await tester.pump();
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'trip_live_sheet',
        estimatedOdometer: 1008,
      ),
      isTrue,
    );
    await tester.pump();

    expect(find.text('1005'), findsOneWidget);
    expect(find.text('1008'), findsNothing);
  });

  testWidgets('trip confirmation compares entered odometer with filtered GPS', (
    tester,
  ) async {
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final review = TripTrackingReviewRecord(
      id: 'trip_review',
      vehicleId: 'vehicle_1',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1012,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 19312.128,
        walkingReviewSuggested: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalOdometerScope(
          controller: odometer,
          child: Scaffold(
            body: OdometerEntrySheet(
              title: 'Review GPS Trip Odometer',
              saveLabel: 'Confirm Odometer',
              tripReview: review,
            ),
          ),
        ),
      ),
    );

    expect(find.text('1000'), findsOneWidget);
    expect(find.text('GPS TRIP COMPARISON'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '1020');
    await tester.pump();

    expect(find.text('GPS TRIP COMPARISON'), findsOneWidget);
    expect(find.textContaining('Confirmed: 20 mi'), findsOneWidget);
    expect(find.textContaining('GPS: 12.0 mi'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm Odometer'));
    await tester.pump();
    await tester.tap(find.text('Business'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save Miles'));
    await tester.pumpAndSettle();

    expect(odometer.history, hasLength(2));
    expect(odometer.history.last.sourceType, 'gps_trip_review');
    expect(odometer.history.last.sourceId, review.id);
  });

  testWidgets('trip confirmation refuses a different active vehicle', (
    tester,
  ) async {
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_b',
      initialReading: 1000,
    );
    final review = TripTrackingReviewRecord(
      id: 'trip_other_vehicle',
      vehicleId: 'vehicle_a',
      startingOdometer: 1000,
      estimatedEndingOdometer: 1001,
      profile: TripTrackingProfile.roadVehicle,
      startedAt: DateTime.utc(2026, 7, 14, 12),
      finishedAt: DateTime.utc(2026, 7, 14, 13),
      engineSnapshot: const TripTrackingEngineSnapshot(
        totalAcceptedMeters: 100,
        walkingReviewSuggested: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GlobalOdometerScope(
          controller: odometer,
          child: Scaffold(
            body: OdometerEntrySheet(
              title: 'Review GPS Trip Odometer',
              saveLabel: 'Confirm Odometer',
              tripReview: review,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm Odometer'));
    await tester.pump();

    expect(find.textContaining('Switch to the vehicle used'), findsOneWidget);
    expect(odometer.confirmedReading, 1000);
  });
}
