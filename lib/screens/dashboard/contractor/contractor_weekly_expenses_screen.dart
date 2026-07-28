import 'package:flutter/material.dart';

import '../../../shared/navigation/app_page_routes.dart';
import '../../../shared/widgets/app_back_button.dart';
import '../../../shared/widgets/app_screen_shell.dart';
import '../../expenses/calendar/expense_calendar.dart';
import '../../expenses/data/expense_ledger_models.dart';
import '../../expenses/data/expense_ledger_store.dart';

class ContractorWeeklyExpensesScreen extends StatefulWidget {
  const ContractorWeeklyExpensesScreen({required this.anchorDate, super.key});

  final DateTime anchorDate;

  @override
  State<ContractorWeeklyExpensesScreen> createState() =>
      _ContractorWeeklyExpensesScreenState();
}

class _ContractorWeeklyExpensesScreenState
    extends State<ContractorWeeklyExpensesScreen> {
  late DateTime _anchorDate = _dateOnly(widget.anchorDate);

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    final range = contractorExpenseWeekRange(_anchorDate);
    final summary = ledger.summaryForRange(range);
    return AppScreenShell(
      section: AppSection.expenses,
      pinnedHeader: const GlobalOdometerHeader(section: AppSection.expenses),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        children: [
          AppScreenHeader(
            title: 'Weekly Expenses',
            actions: [
              IconButton(
                tooltip: 'Previous week',
                onPressed: () => _shiftWeek(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Current week',
                onPressed: _showCurrentWeek,
                icon: const Icon(Icons.today_rounded),
              ),
              IconButton(
                tooltip: 'Next week',
                onPressed: () => _shiftWeek(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ExpenseWeekSummary(range: range, summary: summary),
          const SizedBox(height: 8),
          for (var offset = 0; offset < 7; offset++) ...[
            _ExpenseDayCard(
              day: range.start.add(Duration(days: offset)),
              records: ledger.receiptsForDay(
                range.start.add(Duration(days: offset)),
              ),
              onOpen: () => _openDay(range.start.add(Duration(days: offset))),
            ),
            if (offset < 6) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  void _shiftWeek(int offset) {
    setState(() => _anchorDate = _anchorDate.add(Duration(days: offset * 7)));
  }

  void _showCurrentWeek() {
    setState(() => _anchorDate = _dateOnly(DateTime.now()));
  }

  void _openDay(DateTime day) {
    Navigator.of(
      context,
    ).push(appNativeRoute<void>(context, ExpenseDayScreen(day: day)));
  }
}

ExpenseDateRange contractorExpenseWeekRange(DateTime anchorDate) {
  final day = _dateOnly(anchorDate);
  final start = day.subtract(Duration(days: day.weekday - DateTime.monday));
  return ExpenseDateRange(
    start: start,
    end: start.add(const Duration(days: 6)),
  );
}

class _ExpenseWeekSummary extends StatelessWidget {
  const _ExpenseWeekSummary({required this.range, required this.summary});

  final ExpenseDateRange range;
  final ExpenseLedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _panelDecoration(const Color(0xFF2E78B7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_shortDate(range.start)} - ${_shortDate(range.end)}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ExpenseWeekStat(
                label: 'Business',
                value: _money(summary.businessCents),
                color: const Color(0xFFFF5C5C),
              ),
              _ExpenseWeekStat(
                label: 'Personal',
                value: _money(summary.personalCents),
                color: const Color(0xFF7CC7FF),
              ),
              _ExpenseWeekStat(
                label: 'Records',
                value: '${summary.recordCount}',
                color: const Color(0xFFFFD166),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseWeekStat extends StatelessWidget {
  const _ExpenseWeekStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 105),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseDayCard extends StatelessWidget {
  const _ExpenseDayCard({
    required this.day,
    required this.records,
    required this.onOpen,
  });

  final DateTime day;
  final List<ExpenseReceiptRecord> records;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final totalCents = records.fold<int>(
      0,
      (total, record) => total + record.totalCents,
    );
    final categories = _categoriesFor(records);
    return Material(
      color: const Color(0xFF172023),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
          decoration: _panelDecoration(
            records.isEmpty ? const Color(0xFF59666C) : const Color(0xFFFF8552),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weekday(day),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(_shortDate(day), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      records.isEmpty
                          ? 'No expenses - open to add'
                          : '${records.length} ${records.length == 1 ? 'expense' : 'expenses'}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categories,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _money(totalCents),
                style: const TextStyle(
                  color: Color(0xFFFF8B82),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

String _categoriesFor(List<ExpenseReceiptRecord> records) {
  final categories = <String>{
    for (final record in records)
      for (final line in record.lines)
        if (line.category.trim().isNotEmpty) line.category.trim(),
  }.toList()..sort();
  if (categories.isEmpty) return 'No saved categories';
  if (categories.length <= 3) return categories.join(' - ');
  return '${categories.take(3).join(' - ')} +${categories.length - 3} more';
}

BoxDecoration _panelDecoration(Color borderColor) => BoxDecoration(
  color: const Color(0xFF172023),
  borderRadius: BorderRadius.circular(7),
  border: Border.all(color: borderColor, width: 1.4),
);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

String _shortDate(DateTime day) => '${day.month}/${day.day}/${day.year}';

String _weekday(DateTime day) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][day.weekday - 1];
