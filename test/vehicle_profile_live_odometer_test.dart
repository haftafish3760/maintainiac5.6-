import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_detail.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  testWidgets('vehicle profile detail redraws the active live odometer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final appState = AppStateController();
    addTearDown(odometer.dispose);
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: GlobalOdometerScope(
          controller: odometer,
          child: const MaterialApp(
            home: VehicleProfileDetailScreen(
              vehicle: VehicleProfilePreview(
                id: 'vehicle_1',
                nickname: 'Work Truck',
                year: '2026',
                make: 'Ford',
                model: 'Transit',
                odometer: 'stale-reading',
                status: 'ACTIVE',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1000'), findsOneWidget);
    expect(find.text('stale-reading'), findsNothing);

    expect(
      odometer.beginLiveTripProjection(
        tripId: 'vehicle-detail-live-trip',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'vehicle-detail-live-trip',
        estimatedOdometer: 1004,
      ),
      isTrue,
    );
    await tester.pump();

    expect(find.text('1004'), findsOneWidget);
    expect(odometer.confirmedReading, 1000);
  });
}
