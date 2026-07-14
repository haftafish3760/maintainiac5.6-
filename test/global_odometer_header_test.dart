import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/odometer/global_odometer_header.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
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

    expect(find.text('0001000'), findsOneWidget);
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

    expect(find.text('0001002'), findsOneWidget);
  });
}
