import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/jobs/maintainiac_job_store.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../expenses/data/expense_ledger_store.dart';
import '../../expenses/data/expense_ledger_models.dart';
import '../../expenses/data/expense_work_profile_store.dart';
import '../../expenses/entry/expense_receipt_entry_screen.dart';
import '../../expenses/home/expenses_home_screen.dart';
import '../../profiles/employee_permissions_screen.dart';
import '../../invoices/data/invoice_ledger_store.dart';
import '../../invoices/home/invoice_workspace_screen.dart';
import '../../invoices/home/invoice_home_models.dart';
import '../../invoices/home/invoice_info_screens.dart';
import '../../work_supplies/jobs/work_supply_jobs_screen.dart';
import '../../work_supplies/work_supply_screen.dart';
import '../../../shared/calendar/calendar.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/global_odometer.dart';
import '../../../shared/odometer/open_odometer_entry.dart';
import '../../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../../shared/trip_tracking/trip_tracking_session_store.dart';
import '../active_workday_screen.dart';
import '../data/active_workday_store.dart';
import '../start_day_confirmation_sheet.dart';
import '../vehicle_profile_widgets.dart';
import '../workday_note_sheet.dart';
import 'contractor_active_shift_panel.dart';
import 'contractor_dashboard_models.dart';
import 'contractor_dashboard_jobs_panel.dart';
import 'contractor_dashboard_pulse.dart';
import 'contractor_dashboard_sections.dart';
import 'contractor_dashboard_snapshot.dart';
import 'contractor_weekly_expenses_screen.dart';
import 'contractor_weekly_payments_screen.dart';

part 'contractor_dashboard_actions.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});

  @override
  State<ContractorDashboardScreen> createState() =>
      _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState extends State<ContractorDashboardScreen> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    final activeSession = activeWorkday?.activeSession;
    final odometer = GlobalOdometerScope.of(context);
    final appState = AppStateScope.of(context);
    final dayStarted = activeSession != null;
    final milesToday = activeSession?.milesSoFar(odometer.reading) ?? 0;
    final snapshot = ContractorDashboardSnapshot.fromControllers(
      now: _now,
      vehicleCount: appState.vehicles.length,
      milesToday: milesToday,
      dayStarted: dayStarted,
      jobs: MaintainiacJobScope.maybeOf(context),
      expenses: ExpenseLedgerScope.maybeOf(context),
      invoices: InvoiceLedgerScope.maybeOf(context),
    );
    return AppScreenShell(
      section: AppSection.dashboard,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: AppScreenHeader(title: 'Contractor Command Center'),
          ),
          const SizedBox(height: 8),
          const GlobalOdometerHeader(),
          const SizedBox(height: 10),
          ContractorScaleStrip(metrics: snapshot.scaleMetrics),
          const SizedBox(height: 10),
          ContractorOperationsPulse(
            items: snapshot.operationsMetrics,
            onMetricSelected: _openMetric,
          ),
          const SizedBox(height: 10),
          ContractorAttentionPanel(items: snapshot.attentionItems),
          const SizedBox(height: 10),
          if (dayStarted) ...[
            AnimatedBuilder(
              animation: odometer,
              builder: (context, _) => ContractorActiveShiftPanel(
                shiftTime: _shiftTimeLabel(activeSession),
                milesToday: _milesTodayLabel(
                  activeSession,
                  odometerReading: odometer.reading,
                ),
                liveOdometerLabel: odometer.hasLiveTripProjection
                    ? 'Live odometer: ${odometer.displayValue}'
                    : null,
                currentJob: snapshot.jobsToday.isEmpty
                    ? null
                    : snapshot.jobsToday.first.title,
              ),
            ),
            const SizedBox(height: 10),
            ContractorCommandGrid(
              commands: contractorActiveCommands,
              onCommand: _handleCommand,
            ),
            const SizedBox(height: 10),
            ContractorDayControlPanel(
              dayStarted: true,
              onStartDay: _startContractorDay,
              onOpenDay: _openActiveWorkday,
              onStartGps: () => _openActiveWorkday(startGpsWhenOpened: true),
            ),
          ] else ...[
            ContractorCommandGrid(
              commands: contractorPreDayCommands,
              onCommand: _handleCommand,
            ),
            const SizedBox(height: 10),
            ContractorDayControlPanel(
              dayStarted: false,
              onStartDay: _startContractorDay,
            ),
          ],
          const SizedBox(height: 10),
          ContractorJobsPanel(jobs: snapshot.jobsToday, onOpenJobs: _openJobs),
          const SizedBox(height: 10),
          ContractorMetricsStrip(
            metrics: snapshot.businessMetrics,
            onMetricSelected: _openMetric,
          ),
          const SizedBox(height: 76),
          const ContractorCalendar(),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Future<void> _startContractorDay() async {
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    if (activeWorkday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Workday records are unavailable. Close and reopen Maintainiac, then try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (activeWorkday.activeSession != null) {
      _openActiveWorkday(startGpsWhenOpened: true);
      return;
    }
    try {
      final odometer = GlobalOdometerScope.of(context);
      final activeVehicle = AppStateScope.of(context).activeVehicle;
      if (activeVehicle == null) {
        _showActiveDayRequired('Start Day');
        return;
      }
      final activeWorkProfile = ExpenseWorkProfileScope.of(
        context,
      ).activeWorkProfile;
      var confirmedStartOdometer = odometer.confirmedReading;
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
        workProfileId: activeWorkProfile.id,
        startOdometer: confirmedStartOdometer,
      );
      if (!mounted) return;
      _openActiveWorkday();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start contractor day: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openActiveWorkday({bool startGpsWhenOpened = false}) {
    final activeVehicle = AppStateScope.of(context).activeVehicle;
    if (activeVehicle == null) {
      _showActiveDayRequired('Open Workday');
      return;
    }
    final activeWorkProfile = ExpenseWorkProfileScope.of(
      context,
    ).activeWorkProfile;
    final odometer = GlobalOdometerScope.of(context);
    Navigator.of(context).push(
      appSlideRoute<void>(
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
          workProfileName: activeWorkProfile.name,
          promptForTripTrackingSetup:
              TripTrackingSettingsScope.maybeOf(
                context,
              )?.settings.tripTrackingSetupCompleted ==
              false,
          startGpsWhenOpened:
              startGpsWhenOpened &&
              TripTrackingSettingsScope.maybeOf(
                    context,
                  )?.settings.gpsAssistedTrackingEnabled ==
                  true,
        ),
      ),
    );
  }

  Future<bool> _recordContractorDayEvent(
    ActiveWorkdayController activeWorkday,
    ActiveWorkdayEventType type, {
    int? odometerReading,
    String? note,
  }) async {
    try {
      final odometer = GlobalOdometerScope.of(context);
      final tripTracking = TripTrackingScope.maybeOf(context);
      final updated = await activeWorkday.addEvent(
        type: type,
        odometerReading: odometerReading ?? odometer.reading,
        note: note,
      );
      final tripEventType = switch (type) {
        ActiveWorkdayEventType.stop => TripManualEventType.stop,
        ActiveWorkdayEventType.pickup => TripManualEventType.pickup,
        ActiveWorkdayEventType.dropOff => TripManualEventType.dropoff,
        _ => null,
      };
      if (updated != null &&
          updated.events.isNotEmpty &&
          tripEventType != null &&
          tripTracking?.isTracking == true) {
        final workdayEvent = updated.events.last;
        final attached = await tripTracking!.recordUserTripEvent(
          commandId: 'workday.${workdayEvent.id}',
          type: tripEventType,
          initiatingSource: 'dashboard',
          occurredAt: workdayEvent.occurredAt,
          note: note,
        );
        if (!attached && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The stop was saved to your workday but could not be attached to the active GPS trip.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      if (!mounted) return updated != null;
      setState(() {});
      return updated != null;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update contractor day: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  String _shiftTimeLabel(ActiveWorkdaySessionRecord? session) {
    final elapsed = session?.elapsedWorkTimeAt(_now) ?? Duration.zero;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _milesTodayLabel(
    ActiveWorkdaySessionRecord? session, {
    required int odometerReading,
  }) {
    if (session == null) return '0';
    return session.milesSoFar(odometerReading).toString();
  }
}

class ContractorDashboardLauncher extends StatelessWidget {
  const ContractorDashboardLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: const Color(0xFF12324A),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            appNativeRoute<void>(context, const ContractorDashboardScreen()),
          ),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Color(0xFF7CC7FF),
                  size: 24,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contractor Dashboard',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jobs, materials, invoices, expenses, and calendar.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFC7D0D4),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976B9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
