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
  testWidgets(
    'active day surfaces odometer anomaly review without correction',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final appState = AppStateController();
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1300,
      );
      final activeWorkday = ActiveWorkdayController.memory();
      final sessionStore = TripTrackingSessionStore.memory();
      final tripController = TripTrackingController(
        sessionStore: sessionStore,
        odometer: odometer,
      );
      final settingsController = TripTrackingSettingsController.memory(
        const TripTrackingSettings(
          gpsAssistedTrackingEnabled: true,
          odometerAnomalyAlertsEnabled: true,
        ),
      );
      addTearDown(appState.dispose);
      addTearDown(odometer.dispose);
      addTearDown(activeWorkday.dispose);
      addTearDown(tripController.dispose);
      addTearDown(settingsController.dispose);

      await activeWorkday.startDay(
        vehicleId: 'vehicle_1',
        vehicleLabel: 'Work Truck',
        workProfileId: 'delivery',
        startOdometer: 1000,
        startedAt: DateTime.utc(2026, 7, 17, 8),
      );
      for (var index = 0; index < 7; index += 1) {
        await sessionStore.saveReview(
          _confirmedReview(
            id: 'usage_$index',
            startedAt: DateTime.utc(2026, 7, 1 + index, 8),
            gpsMiles: 40,
            odometerMiles: 40,
          ),
        );
      }

      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: ActiveWorkdayScope(
            controller: activeWorkday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingSettingsScope(
                controller: settingsController,
                child: TripTrackingScope(
                  controller: tripController,
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
        find.textContaining('unusually high'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('unusually high'), findsOneWidget);
      expect(find.textContaining('GPS stays advisory'), findsOneWidget);
      expect(odometer.confirmedReading, 1300);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('active day surfaces calibration drift as advisory only', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appState = AppStateController();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final activeWorkday = ActiveWorkdayController.memory();
    final sessionStore = TripTrackingSessionStore.memory();
    final tripController = TripTrackingController(
      sessionStore: sessionStore,
      odometer: odometer,
    );
    final settingsController = TripTrackingSettingsController.memory(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        odometerAnomalyAlertsEnabled: true,
      ),
    );
    addTearDown(appState.dispose);
    addTearDown(odometer.dispose);
    addTearDown(activeWorkday.dispose);
    addTearDown(tripController.dispose);
    addTearDown(settingsController.dispose);

    await activeWorkday.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'delivery',
      startOdometer: 1000,
      startedAt: DateTime.utc(2026, 7, 17, 8),
    );
    for (var index = 0; index < 7; index += 1) {
      await sessionStore.saveReview(
        _confirmedReview(
          id: 'calibration_$index',
          startedAt: DateTime.utc(2026, 7, 1 + index, 8),
          gpsMiles: 110,
          odometerMiles: 100,
        ),
      );
    }

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: TripTrackingSettingsScope(
              controller: settingsController,
              child: TripTrackingScope(
                controller: tripController,
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
        find.textContaining('Repeated GPS/odometer drift'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('Repeated GPS/odometer drift'), findsOneWidget);
    expect(find.textContaining('odometer stays official'), findsOneWidget);
    expect(odometer.confirmedReading, 1000);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

TripTrackingReviewRecord _confirmedReview({
  required String id,
  required DateTime startedAt,
  required double gpsMiles,
  required int odometerMiles,
}) {
  const startingOdometer = 1000;
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: 'vehicle_1',
    startingOdometer: startingOdometer,
    estimatedEndingOdometer: startingOdometer + odometerMiles,
    confirmedEndingOdometer: startingOdometer + odometerMiles,
    odometerConfirmedAt: startedAt.add(const Duration(hours: 1)),
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    finishedAt: startedAt.add(const Duration(hours: 1)),
    engineSnapshot: TripTrackingEngineSnapshot(
      totalAcceptedMeters: gpsMiles * 1609.344,
      walkingReviewSuggested: false,
      diagnostics: const TripTrackingDiagnostics(
        receivedSamples: 10,
        acceptedSamples: 10,
        dispositionCounts: {TripSampleDisposition.acceptedDistance: 10},
      ),
    ),
  );
}
