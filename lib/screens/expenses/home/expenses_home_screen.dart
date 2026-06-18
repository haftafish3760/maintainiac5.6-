import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/state/app_state.dart';
import '../../../shared/state/expense_settings_store.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../calendar/expense_calendar.dart';
import '../categories/expense_categories.dart';
import '../data/expense_draft_store.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';
import '../entry/expense_receipt_entry_screen.dart';
import '../reminders/expense_reminder_screen.dart';
import '../reports/expense_allocation_screen.dart';
import '../reports/expense_export_screen.dart';

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
  var _period = _ExpenseViewPeriod.day;
  var _anchorDate = _dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return AppScreenShell(
      section: AppSection.expenses,
      floatingActionButton: _ExpenseFab(initialDate: _anchorDate),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const GlobalOdometerHeader(section: AppSection.expenses),
          const SizedBox(height: 8),
          _ExpenseHomeContent(
            period: _period,
            anchorDate: _anchorDate,
            onPeriodChanged: (period) => setState(() => _period = period),
            onShiftPeriod: _shiftPeriod,
            onToday: () =>
                setState(() => _anchorDate = _dateOnly(DateTime.now())),
          ),
        ],
      ),
    );
  }

  void _shiftPeriod(int direction) {
    setState(() {
      _anchorDate = _shiftDateForPeriod(_anchorDate, _period, direction);
    });
  }
}

class _ExpenseHomeContent extends StatelessWidget {
  const _ExpenseHomeContent({
    required this.period,
    required this.anchorDate,
    required this.onPeriodChanged,
    required this.onShiftPeriod,
    required this.onToday,
  });

  final _ExpenseViewPeriod period;
  final DateTime anchorDate;
  final ValueChanged<_ExpenseViewPeriod> onPeriodChanged;
  final ValueChanged<int> onShiftPeriod;
  final VoidCallback onToday;

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
              _ExpensePeriodSelectorPanel(
                period: period,
                anchorDate: anchorDate,
                scopeLabel: _expenseScopeLabel(context),
                onChanged: onPeriodChanged,
                onShift: onShiftPeriod,
                onToday: onToday,
              ),
              const SizedBox(height: 8),
              _ExpenseTotalsPanel(period: period, anchorDate: anchorDate),
              const SizedBox(height: 8),
              _FrequentActionsPanel(period: period, anchorDate: anchorDate),
              const SizedBox(height: 8),
              const _UpcomingExpensesPanel(),
              const SizedBox(height: 8),
              const _ReceiptDraftsPanel(),
              const SizedBox(height: 8),
              const _RecentLedgerPanel(),
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
