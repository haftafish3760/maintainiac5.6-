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
import 'package:maintaniac/shared/trip_tracking/trip_tracking_trip_log_proposal.dart';

void main() {
  testWidgets('dashboard exposes retry for a preserved TripLog handoff', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final at = DateTime.now().toUtc().subtract(const Duration(minutes: 10));
    final sink = _RetryableProposalSink()..fail = true;
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
      tripLogProposalSink: sink,
    );
    final settings = TripTrackingSettingsController.memory(
      const TripTrackingSettings(gpsAssistedTrackingEnabled: true),
    );
    addTearDown(appState.dispose);
    addTearDown(workday.dispose);
    addTearDown(odometer.dispose);
    addTearDown(trip.dispose);
    addTearDown(settings.dispose);

    await workday.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'profile_1',
      startOdometer: 1000,
      startedAt: at,
    );
    await trip.start(
      tripId: 'trip_log_dashboard_retry',
      vehicleId: 'vehicle_1',
      profile: TripTrackingProfile.roadVehicle,
      profileId: 'profile_1',
      startedAt: at,
    );
    await trip.finishForReview(finishedAt: at.add(const Duration(minutes: 5)));

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
                    workProfileName: 'Contractor',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('TripLog proposal is preserved locally and can be retried.'),
      findsOneWidget,
    );
    expect(find.text('RETRY TRIPLOG HANDOFF'), findsOneWidget);

    sink.fail = false;
    await tester.tap(find.text('RETRY TRIPLOG HANDOFF'));
    await tester.pumpAndSettle();

    expect(sink.proposals, hasLength(1));
    expect(trip.tripLogProposalError, isNull);
    expect(trip.latestPendingTripLogProposal, isNull);
    expect(find.text('RETRY TRIPLOG HANDOFF'), findsNothing);
    expect(find.text('Trip is ready for TripLog review.'), findsOneWidget);
  });
}

class _RetryableProposalSink implements TripTrackingTripLogProposalSink {
  bool fail = false;
  final proposals = <TripTrackingTripLogProposal>[];

  @override
  Future<void> propose(TripTrackingTripLogProposal proposal) async {
    if (fail) throw StateError('local inbox unavailable');
    proposals.add(proposal);
  }
}
