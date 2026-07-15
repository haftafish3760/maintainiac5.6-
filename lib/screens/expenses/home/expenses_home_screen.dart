import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/context/operational_context_store.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../../shared/widgets/receipt_capture/receipt_native_capture_staging.dart';
import '../calendar/expense_calendar.dart';
import '../categories/expense_categories.dart';
import '../data/expense_draft_store.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_scope_filter.dart';
import '../data/expense_ledger_store.dart';
import '../data/expense_screen_telemetry.dart';
import '../data/expense_screen_telemetry_recorder.dart';
import '../entry/expense_receipt_entry_screen.dart';
import '../reminders/expense_reminder_screen.dart';

part 'expenses_home_period.dart';
part 'expenses_home_totals.dart';
part 'expenses_home_frequent_actions.dart';
part 'expenses_home_activity_sections.dart';
part 'expenses_home_shared_widgets.dart';
part 'expenses_home_ledger_rows.dart';
part 'expenses_home_navigation_actions.dart';
part 'expenses_home_category_sheets.dart';
part 'expenses_home_quick_action_settings.dart';
part 'expenses_home_ledger_sheet.dart';
part 'expenses_home_category_entries_screen.dart';
part 'expenses_home_totals_helpers.dart';
part 'expenses_home_models.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  var _anchorDate = _dateOnly(DateTime.now());
  var _showAllProfiles = false;
  late final DateTime _screenOpenedAtUtc;

  @override
  void initState() {
    super.initState();
    _screenOpenedAtUtc = DateTime.now().toUtc();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ExpenseScreenTelemetryRecorder.record(
        context,
        ExpenseTelemetryEventType.screenOpened,
        metadata: {'source': 'expenses_home'},
      );
    });
  }

  @override
  void dispose() {
    final elapsedMs = DateTime.now()
        .toUtc()
        .difference(_screenOpenedAtUtc)
        .inMilliseconds
        .clamp(0, 86400000);
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.screenClosed,
      durationMs: elapsedMs,
      metadata: {'source': 'expenses_home'},
    );
    ExpenseScreenTelemetryRecorder.record(
      context,
      ExpenseTelemetryEventType.timeSpentOnScreen,
      durationMs: elapsedMs,
      metadata: {'source': 'expenses_home'},
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.expenses,
      floatingActionButton: _ExpenseFab(initialDate: _anchorDate),
      pinnedHeader: const GlobalOdometerHeader(section: AppSection.expenses),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ExpenseHomeContent(
            anchorDate: _anchorDate,
            onShiftDay: _shiftDay,
            onToday: () =>
                setState(() => _anchorDate = _dateOnly(DateTime.now())),
            showAllProfiles: _showAllProfiles,
            onToggleProfileScope: () =>
                setState(() => _showAllProfiles = !_showAllProfiles),
          ),
        ],
      ),
    );
  }

  void _shiftDay(int direction) {
    setState(() {
      _anchorDate = _anchorDate.add(Duration(days: direction));
    });
  }
}

class _ExpenseHomeContent extends StatelessWidget {
  const _ExpenseHomeContent({
    required this.anchorDate,
    required this.onShiftDay,
    required this.onToday,
    required this.showAllProfiles,
    required this.onToggleProfileScope,
  });

  final DateTime anchorDate;
  final ValueChanged<int> onShiftDay;
  final VoidCallback onToday;
  final bool showAllProfiles;
  final VoidCallback onToggleProfileScope;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ReceiptDraftsPanel(),
              const SizedBox(height: 8),
              _ExpenseTotalsPanel(
                period: _ExpenseViewPeriod.day,
                anchorDate: anchorDate,
                showAllProfiles: showAllProfiles,
                onToggleProfileScope: onToggleProfileScope,
              ),
              const SizedBox(height: 8),
              const _UpcomingExpensesPanel(),
              const SizedBox(height: 8),
              _FrequentActionsPanel(
                period: _ExpenseViewPeriod.day,
                anchorDate: anchorDate,
              ),
              const SizedBox(height: 8),
              _RecentLedgerPanel(day: anchorDate),
              const SizedBox(height: 10),
              const ExpenseMonthCalendar(),
            ],
          ),
        ),
      ),
    );
  }
}

const _pageBackground = Color(0xFF2A3337);
const _ink = Color(0xFF101719);
const _paper = Color(0xFF1A2226);
const _coolPanel = Color(0xFF122A34);
const _line = Color(0xFF445159);
const _blue = Color(0xFF2E78B7);
const _green = Color(0xFF249D62);
const _gold = Color(0xFFF0B43C);
const _red = Color(0xFFD85B4A);
