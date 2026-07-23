import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_screen.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('confirmed dashboard stop survives into completed trip review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppStateController();
    final workday = ActiveWorkdayController.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final tripStore = TripTrackingSessionStore.memory();
    final trip = TripTrackingController(
      sessionStore: tripStore,
      odometer: odometer,
    );
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(appState.dispose);
    addTearDown(workday.dispose);
    addTearDown(odometer.dispose);
    addTearDown(trip.dispose);
    addTearDown(settings.dispose);

    final startedAt = DateTime.now().toUtc().subtract(
      const Duration(minutes: 10),
    );
    await workday.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'profile_1',
      startOdometer: 1000,
      startedAt: startedAt,
    );
    expect(
      await trip.start(
        tripId: 'dashboard_stop_handoff',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        profileId: 'profile_1',
        startedAt: startedAt,
      ),
      isTrue,
    );

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: workday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settings,
              child: TripTrackingScope(
                controller: trip,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Delivery',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Add Stop'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Add Stop'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Customer delivery');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Stop'));
    await tester.pumpAndSettle();

    final review = await trip.finishForReview(
      finishedAt: DateTime.now().toUtc(),
    );
    expect(review, isNotNull);
    expect(review!.tripEvents, hasLength(1));
    expect(review.tripEvents.single.type, TripManualEventType.stop);
    expect(review.tripEvents.single.userConfirmed, isTrue);
    expect(review.tripEvents.single.note, 'Customer delivery');
    expect(review.tripEvents.single.canChangeMileage, isFalse);
    expect(review.tripEvents.single.canFinalizeTrip, isFalse);
  });
}
