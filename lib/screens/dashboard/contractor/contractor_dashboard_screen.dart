import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../expenses/home/expenses_home_screen.dart';
import '../../expenses/data/expense_work_profile_store.dart';
import '../../invoices/home/invoice_workspace_screen.dart';
import '../../invoices/home/invoice_home_models.dart';
import '../../invoices/home/invoice_info_screens.dart';
import '../../work_supplies/jobs/work_supply_jobs_screen.dart';
import '../../work_supplies/work_supply_screen.dart';
import '../../../shared/calendar/calendar.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/global_odometer.dart';
import '../data/active_workday_store.dart';
import 'contractor_active_shift_panel.dart';
import 'contractor_dashboard_models.dart';
import 'contractor_dashboard_pulse.dart';
import 'contractor_dashboard_sections.dart';

class ContractorDashboardScreen extends StatefulWidget {
  const ContractorDashboardScreen({super.key});

  @override
  State<ContractorDashboardScreen> createState() =>
      _ContractorDashboardScreenState();
}

class _ContractorDashboardScreenState extends State<ContractorDashboardScreen> {
  var _dayStarted = false;
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
    final dayStarted = activeSession?.isActive == true || _dayStarted;
    final dayPaused = activeSession?.isPaused == true;
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
          const ContractorScaleStrip(),
          const SizedBox(height: 10),
          const ContractorOperationsPulse(),
          const SizedBox(height: 10),
          const ContractorAttentionPanel(),
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
              dayPaused: dayPaused,
              onStartDay: _startContractorDay,
              onPauseDay: _toggleContractorDayPause,
              onEndDay: _endContractorDay,
            ),
          ] else ...[
            ContractorDayControlPanel(
              dayStarted: false,
              onStartDay: _startContractorDay,
            ),
            const SizedBox(height: 10),
            ContractorCommandGrid(
              commands: contractorPreDayCommands,
              onCommand: _handleCommand,
            ),
          ],
          const SizedBox(height: 10),
          const ContractorJobsPanel(),
          const SizedBox(height: 10),
          const ContractorMetricsStrip(),
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
      setState(() => _dayStarted = true);
      return;
    }
    if (activeWorkday.activeSession?.isActive == true) {
      setState(() => _dayStarted = true);
      return;
    }
    try {
      final odometer = GlobalOdometerScope.of(context);
      final activeVehicle = AppStateScope.of(context).activeVehicle;
      final activeWorkProfile = ExpenseWorkProfileScope.of(
        context,
      ).activeWorkProfile;
      await activeWorkday.startDay(
        vehicleId: odometer.vehicleId,
        vehicleLabel: activeVehicle?.nickname ?? 'Active vehicle',
        workProfileId: activeWorkProfile.id,
        startOdometer: odometer.reading,
      );
      if (!mounted) return;
      setState(() => _dayStarted = true);
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

  Future<void> _toggleContractorDayPause() async {
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    final session = activeWorkday?.activeSession;
    if (activeWorkday == null || session == null) return;
    await _recordContractorDayEvent(
      activeWorkday,
      session.isPaused
          ? ActiveWorkdayEventType.resumed
          : ActiveWorkdayEventType.paused,
    );
  }

  Future<void> _endContractorDay() async {
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    if (activeWorkday == null || activeWorkday.activeSession == null) {
      setState(() => _dayStarted = false);
      return;
    }
    final ended = await _recordContractorDayEvent(
      activeWorkday,
      ActiveWorkdayEventType.ended,
    );
    if (ended && mounted) setState(() => _dayStarted = false);
  }

  Future<bool> _recordContractorDayEvent(
    ActiveWorkdayController activeWorkday,
    ActiveWorkdayEventType type,
  ) async {
    try {
      final odometer = GlobalOdometerScope.of(context);
      final updated = await activeWorkday.addEvent(
        type: type,
        odometerReading: odometer.reading,
      );
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

  Future<void> _handleCommand(ContractorCommand command) async {
    switch (command.target) {
      case ContractorCommandTarget.createJob:
      case ContractorCommandTarget.jobs:
        _open(const WorkSupplyJobsScreen());
      case ContractorCommandTarget.addReceipt:
      case ContractorCommandTarget.addExpense:
        _open(const ExpensesScreen());
      case ContractorCommandTarget.materials:
        _open(const WorkSupplyScreen());
      case ContractorCommandTarget.createInvoice:
        _open(
          const InvoiceWorkspaceScreen(mode: InvoiceWorkspaceMode.invoices),
        );
      case ContractorCommandTarget.estimate:
        _open(
          const InvoiceWorkspaceScreen(mode: InvoiceWorkspaceMode.estimates),
        );
      case ContractorCommandTarget.recordPayment:
        _open(const InvoicePaymentScreen());
      case ContractorCommandTarget.addStop:
      case ContractorCommandTarget.note:
        await _recordQuickActiveDayEvent(command);
    }
  }

  Future<void> _recordQuickActiveDayEvent(ContractorCommand command) async {
    final activeWorkday = ActiveWorkdayScope.maybeOf(context);
    final session = activeWorkday?.activeSession;
    if (activeWorkday == null || session == null) {
      _showActiveDayRequired(command.label);
      return;
    }
    final type = command.target == ContractorCommandTarget.addStop
        ? ActiveWorkdayEventType.stop
        : ActiveWorkdayEventType.note;
    final updated = await _recordContractorDayEvent(activeWorkday, type);
    if (!updated || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${command.label} saved to the active contractor day.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(appNativeRoute<void>(context, screen));
  }

  void _showActiveDayRequired(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Start your contractor day before using $label.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
