import 'package:flutter/material.dart';

import 'active_workday_screen.dart';
import '../../shared/calendar/calendar.dart';
import 'contractor/contractor_dashboard_screen.dart';
import 'dashboard_panels.dart';
import 'dashboard_active_day_panel.dart';
import 'start_day_panel.dart';
import 'start_day_confirmation_sheet.dart';
import 'vehicle_profile_flow.dart';
import 'vehicle_profile_widgets.dart';
import '../../shared/navigation/app_page_routes.dart';
import '../../shared/context/operational_context_store.dart';
import '../../shared/odometer/open_odometer_entry.dart';
import '../../shared/odometer/odometer_vehicle_snapshot.dart';
import '../../shared/state/app_state.dart';
import '../../shared/state/global_odometer.dart';
import '../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../shared/trip_tracking/trip_tracking_dashboard_live_status_policy.dart';
import '../../shared/widgets/app_screen_shell.dart';
import '../expenses/data/expense_work_profile_store.dart';
import 'data/active_workday_store.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreenShell(body: _PreDayDashboardBody());
  }
}

class _PreDayDashboardBody extends StatefulWidget {
  const _PreDayDashboardBody();

  @override
  State<_PreDayDashboardBody> createState() => _PreDayDashboardBodyState();
}

class _PreDayDashboardBodyState extends State<_PreDayDashboardBody> {
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final selectedVehicle = appState.activeVehicle;
    final odometer = GlobalOdometerScope.of(context);
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    final activeSession = activeWorkday?.activeSession;
    final activeWorkProfile = ExpenseWorkProfileScope.of(
      context,
    ).activeWorkProfile;
    final operationalContext = OperationalContextScope.maybeOf(context);
    final tripTracking = TripTrackingScope.maybeOf(context);
    final activeContext = operationalContext?.context;
    final contextLabel = activeContext == null
        ? 'Local dashboard'
        : '${activeContext.dashboardMode.label} / '
              '${activeContext.mileageMode.label} / '
              '${activeContext.syncMode.label}';
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        const SliverToBoxAdapter(child: GlobalOdometerHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: tripTracking == null
                ? odometer
                : Listenable.merge([odometer, tripTracking]),
            builder: (context, _) {
              final gpsStatus =
                  TripTrackingDashboardLiveStatusPolicy.vehicleStatus(
                    activeTrip:
                        activeSession != null || tripTracking?.isTracking == true,
                    nativeTracking:
                        tripTracking?.nativeProviderRegistered == true,
                    hasLiveProjection: odometer.hasLiveTripProjection,
                    gpsAssistanceEnabled:
                        TripTrackingSettingsScope.maybeOf(
                          context,
                        )?.settings.gpsAssistedTrackingEnabled ??
                        true,
                    platformStatus: tripTracking?.platformStatus,
                    awaitingInitialFix:
                        tripTracking?.awaitingInitialFix == true,
                    signalReviewRequired:
                        tripTracking?.signalQualitySummary.requiresUserReview ==
                        true,
                  );
              final activeVehicle = selectedVehicle == null
                  ? VehicleProfilePreview(
                      id: defaultVehicleProfile.id,
                      nickname: defaultVehicleProfile.nickname,
                      year: defaultVehicleProfile.year,
                      make: defaultVehicleProfile.make,
                      model: defaultVehicleProfile.model,
                      odometer: odometer.displayValue,
                      status: gpsStatus,
                      usage: defaultVehicleProfile.usage,
                    )
                  : VehicleProfilePreview(
                      id: selectedVehicle.id,
                      nickname: selectedVehicle.nickname,
                      year: selectedVehicle.year,
                      make: selectedVehicle.make,
                      model: selectedVehicle.model,
                      odometer: odometer.displayValue,
                      status: gpsStatus,
                      usage: selectedVehicle.usage,
                    );
              return DashboardContextSelectors(
                activeVehicle: activeVehicle,
                workProfile: activeWorkProfile.name,
                onVehicleChanged: (vehicle) async {
                  final match = appState.vehicles.where(
                    (candidate) => candidate.id == vehicle.id,
                  );
                  if (match.isEmpty) return;
                  final selected = match.first;
                  final targetOdometerVehicleId = odometerVehicleIdForVehicleId(
                    selected.id,
                    fallbackLabel: selected.nickname,
                  );
                  if (activeSession != null &&
                      activeSession.vehicleId != targetOdometerVehicleId) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'End the current workday before switching vehicles.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (odometer.vehicleId != targetOdometerVehicleId) {
                    final switched = await odometer.switchVehicleById(
                      targetOdometerVehicleId,
                    );
                    if (!context.mounted) return;
                    if (!switched) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Review the active trip before switching vehicles.',
                          ),
                        ),
                      );
                      return;
                    }
                  }
                  await appState.selectVehicle(selected);
                  if (operationalContext != null) {
                    await operationalContext.setActiveVehicle(
                      vehicleId: odometer.vehicleId,
                      vehicleLabel: selected.nickname,
                      usage: selected.usage,
                    );
                  }
                },
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: ContractorDashboardLauncher()),
        if (activeContext != null)
          SliverToBoxAdapter(
            child: OperationalContextStrip(contextLabel: contextLabel),
          ),
        if (activeContext != null)
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: PreDayStartContent(
            onStartDay: _startDay,
            hasActiveDay: activeSession != null,
          ),
        ),
        if (activeSession != null) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: DashboardActiveDayPanel(session: activeSession),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 76)),
        const SliverToBoxAdapter(child: DashboardCalendar()),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
      ],
    );
  }

  Future<void> _startDay() async {
    final odometer = GlobalOdometerScope.of(context);
    final activeVehicle = AppStateScope.of(context).activeVehicle;
    final activeWorkProfile = ExpenseWorkProfileScope.of(
      context,
    ).activeWorkProfile;
    if (activeVehicle == null) return;
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    if (activeWorkday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workday records are not available on this screen.'),
        ),
      );
      return;
    }
    if (activeWorkday.activeSession != null) {
      final tripSettings = TripTrackingSettingsScope.maybeOf(context)?.settings;
      _openActiveWorkday(
        activeVehicle: activeVehicle,
        activeWorkProfileName: activeWorkProfile.name,
        promptForTripTrackingSetup:
            tripSettings?.tripTrackingSetupCompleted == false,
        startGpsWhenOpened:
            tripSettings?.gpsAssistedTrackingEnabled == true,
      );
      return;
    }
    var confirmedStartOdometer = odometer.reading;
    while (mounted) {
      final savedReading = await openOdometerEntryResult(
        context,
        title: 'Starting Odometer',
        saveLabel: 'Review Start Day',
      );
      if (savedReading == null || !mounted) return;
      confirmedStartOdometer = savedReading;
      final action = await openStartDayConfirmationSheet(
        context,
        vehicleLabel: activeVehicle.nickname,
        workProfileName: activeWorkProfile.name,
        startingOdometer: confirmedStartOdometer,
      );
      if (!mounted || action == null) return;
      if (action == StartDayReviewAction.editOdometer) continue;
      break;
    }
    if (!mounted) return;
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: activeVehicle.nickname,
      workProfileId:
          OperationalContextScope.maybeOf(context)?.context.workProfileId ??
          activeWorkProfile.id,
      startOdometer: confirmedStartOdometer,
    );
    if (!mounted) return;
    _openActiveWorkday(
      activeVehicle: activeVehicle,
      activeWorkProfileName: activeWorkProfile.name,
      promptForTripTrackingSetup:
          TripTrackingSettingsScope.maybeOf(
            context,
          )?.settings.tripTrackingSetupCompleted ==
          false,
      startGpsWhenOpened:
          TripTrackingSettingsScope.maybeOf(
            context,
          )?.settings.gpsAssistedTrackingEnabled ==
          true,
    );
  }

  void _openActiveWorkday({
    required VehicleProfile activeVehicle,
    required String activeWorkProfileName,
    bool promptForTripTrackingSetup = false,
    bool startGpsWhenOpened = false,
  }) {
    final odometer = GlobalOdometerScope.of(context);
    Navigator.of(context).push(
      appSlideRoute(
        ActiveWorkdayScreen(
          activeVehicle: VehicleProfilePreview(
            id: activeVehicle.id,
            nickname: activeVehicle.nickname,
            year: activeVehicle.year,
            make: activeVehicle.make,
            model: activeVehicle.model,
            odometer: odometer.displayValue,
            status: 'ACTIVE',
            usage: activeVehicle.usage,
          ),
          workProfileName: activeWorkProfileName,
          promptForTripTrackingSetup: promptForTripTrackingSetup,
          startGpsWhenOpened: startGpsWhenOpened,
        ),
      ),
    );
  }
}
