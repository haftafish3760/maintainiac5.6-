import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/global_odometer_header.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 16, 12);

  TripLocationSample sample(double longitude, int seconds) =>
      TripLocationSample(
        latitude: 35,
        longitude: longitude,
        recordedAt: startedAt.add(Duration(seconds: seconds)),
        horizontalAccuracyMeters: 5,
      );

  testWidgets('shared odometer header redraws a live trip projection', (
    tester,
  ) async {
    final odometer = GlobalOdometerController(initialReading: 1000);
    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: odometer,
            child: const Scaffold(body: GlobalOdometerHeader()),
          ),
        ),
      ),
    );

    expect(find.text('1000'), findsOneWidget);
    expect(
      odometer.beginLiveTripProjection(
        tripId: 'trip_1',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'trip_1',
        estimatedOdometer: 1002,
      ),
      isTrue,
    );
    await tester.pump();

    expect(find.text('1002'), findsOneWidget);
    expect(find.text('+2 mi live'), findsOneWidget);
  });

  testWidgets('shared odometer header redraws from accepted GPS trip samples', (
    tester,
  ) async {
    final odometer = GlobalOdometerController(initialReading: 1000);
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );
    addTearDown(tripController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: odometer,
            child: const Scaffold(body: GlobalOdometerHeader()),
          ),
        ),
      ),
    );

    expect(find.text('1000'), findsOneWidget);
    expect(
      await tripController.start(
        tripId: 'trip_accepted_gps_ui',
        vehicleId: odometer.vehicleId,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: startedAt,
      ),
      isTrue,
    );
    await tripController.ingest(sample(-80, 0));
    await tripController.ingest(sample(-79.965, 90));
    await tester.pump();

    expect(find.text('1000'), findsNothing);
    expect(find.text(odometer.displayValue), findsOneWidget);
    expect(find.text(odometer.liveDisplaySnapshot.deltaLabel!), findsOneWidget);
    expect(odometer.reading, greaterThan(1000));
    expect(odometer.confirmedReading, 1000);
  });

  testWidgets('shared odometer header fits a complete live reading on phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final odometer = GlobalOdometerController(initialReading: 328434);
    expect(
      odometer.beginLiveTripProjection(
        tripId: 'trip_header_fit',
        startingOdometer: 328434,
      ),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: GlobalOdometerScope(
            controller: odometer,
            child: const Scaffold(body: GlobalOdometerHeader()),
          ),
        ),
      ),
    );

    expect(find.text('328434'), findsOneWidget);
    expect(find.text('GPS live'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared header does not call a stopped GPS estimate live', (
    tester,
  ) async {
    final odometer = GlobalOdometerController(initialReading: 328434);
    final tripController = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );
    addTearDown(tripController.dispose);
    expect(
      odometer.beginLiveTripProjection(
        tripId: 'trip_paused_header',
        startingOdometer: 328434,
      ),
      isTrue,
    );
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'trip_paused_header',
        estimatedOdometer: 328443,
      ),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: AppStateController(),
          child: TripTrackingScope(
            controller: tripController,
            child: GlobalOdometerScope(
              controller: odometer,
              child: const Scaffold(body: GlobalOdometerHeader()),
            ),
          ),
        ),
      ),
    );

    expect(find.text('328443'), findsOneWidget);
    expect(find.text('GPS paused'), findsOneWidget);
    expect(find.text('+9 mi live'), findsNothing);
  });
}
