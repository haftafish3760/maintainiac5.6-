import 'package:flutter/material.dart';

import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../categories/expense_categories.dart';
import '../data/expense_ledger_models.dart';
import '../data/expense_ledger_store.dart';

part 'expense_allocation_header_totals.dart';
part 'expense_allocation_selectors.dart';
part 'expense_allocation_cards.dart';
part 'expense_allocation_models.dart';

enum ExpenseAllocationLimit { top10, top25, all }

class ExpenseAllocationScreen extends StatefulWidget {
  const ExpenseAllocationScreen({
    super.key,
    required this.range,
    required this.rangeLabel,
  });

  final ExpenseDateRange range;
  final String rangeLabel;

  @override
  State<ExpenseAllocationScreen> createState() =>
      _ExpenseAllocationScreenState();
}

class _ExpenseAllocationScreenState extends State<ExpenseAllocationScreen> {
  var _limit = ExpenseAllocationLimit.top10;
  late var _period = _ReportPeriod.fromRange(widget.range);
  late var _anchorDate = widget.range.start;

  @override
  Widget build(BuildContext context) {
    final range = _period.rangeFor(_anchorDate);
    final rangeLabel = '${_period.label} | ${_period.rangeLabel(_anchorDate)}';
    final report = _AllocationReport.fromLedger(
      ExpenseLedgerScope.of(context),
      range,
    );
    final rows = report.visibleRows(_limit);
    return Scaffold(
      backgroundColor: const Color(0xFF2A3337),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          children: [
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ReportHeader(),
                    const SizedBox(height: 8),
                    _TotalAllocationCard(
                      report: report,
                      rangeLabel: rangeLabel,
                    ),
                    const SizedBox(height: 8),
                    _ReportPeriodSelector(
                      value: _period,
                      label: _period.rangeLabel(_anchorDate),
                      onChanged: (value) => setState(() => _period = value),
                      onPrevious: () => _shiftPeriod(-1),
                      onNext: () => _shiftPeriod(1),
                    ),
                    const SizedBox(height: 8),
                    _LimitSelector(
                      value: _limit,
                      onChanged: (value) => setState(() => _limit = value),
                    ),
                    const SizedBox(height: 8),
                    if (rows.isEmpty)
                      const _EmptyReportCard()
                    else
                      for (final row in rows) _CategoryAllocationCard(row: row),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shiftPeriod(int direction) {
    setState(() {
      _anchorDate = _period.shift(_anchorDate, direction);
    });
  }
}
