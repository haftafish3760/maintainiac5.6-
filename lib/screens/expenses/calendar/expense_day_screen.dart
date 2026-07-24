part of 'expense_calendar.dart';

class ExpenseDayScreen extends StatefulWidget {
  const ExpenseDayScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<ExpenseDayScreen> createState() => _ExpenseDayScreenState();
}

class _ExpenseDayScreenState extends State<ExpenseDayScreen> {
  late var _day = widget.day;
  var _recapPeriod = _CalendarRecapPeriod.day;

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    final entries = ledger
        .receiptsForDay(_day)
        .map(_CalendarExpenseData.fromReceipt)
        .toList();
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.amount);
    final ocrRecap = _CalendarOcrDayRecap.fromEntries(entries);
    final recapRange = _recapPeriod.rangeFor(_day);
    final rangeOcrRecap = _CalendarOcrDayRecap.fromLedgerRange(
      ledger,
      recapRange,
    );
    final metrics = _VehicleExpenseMetrics.fromLedger(ledger, recapRange);
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: AppScreenHeader(
                title: calendarFullDateLabel(_day),
                actions: [
                  IconButton(
                    tooltip: 'Pick month and year',
                    onPressed: _pickDate,
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFE2E8EA),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous day',
                    onPressed: () => _shiftDay(-1),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFFE2E8EA),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next day',
                    onPressed: () => _shiftDay(1),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFE2E8EA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 18),
                children: [
                  _ExpenseCalendarContextHeader(day: _day),
                  const SizedBox(height: 8),
                  _CalendarDaySummary(
                    day: _day,
                    onPreviousDay: () => _shiftDay(-1),
                    onNextDay: () => _shiftDay(1),
                    onPreviousMonth: () => _shiftMonth(-1),
                    onNextMonth: () => _shiftMonth(1),
                  ),
                  const SizedBox(height: 8),
                  _CalendarOcrDayRecapPanel(recap: ocrRecap),
                  const SizedBox(height: 8),
                  if (entries.isEmpty)
                    const _CalendarEmptyState()
                  else
                    for (final entry in entries)
                      _CalendarExpenseEntry(entry: entry),
                  const SizedBox(height: 4),
                  _CalendarRecapPeriodSelector(
                    selected: _recapPeriod,
                    selectedDay: _day,
                    onSelected: (period) =>
                        setState(() => _recapPeriod = period),
                  ),
                  const SizedBox(height: 8),
                  _VehicleExpenseMetricsPanel(
                    metrics: metrics,
                    selectedDay: _day,
                    dayEntryCount: entries.length,
                    dayTotal: total,
                    ocrRecap: rangeOcrRecap,
                    period: _recapPeriod,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            appNativeRoute<Object>(
              context,
              ExpenseReceiptEntryScreen(initialDate: _day),
            ),
          );
        },
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selection = await showCalendarMonthYearPicker(
      context: context,
      focusedDay: _day,
      selectedDay: _day,
    );
    if (!mounted || selection == null) return;
    setState(() => _day = selection.selectedDate ?? selection.focusedMonth);
  }

  void _shiftDay(int offset) {
    setState(() => _day = _day.add(Duration(days: offset)));
  }

  void _shiftMonth(int offset) {
    setState(() => _day = DateTime(_day.year, _day.month + offset, _day.day));
  }
}

enum _CalendarRecapPeriod { day, week, month, ninetyDays, yearToDate }

extension _CalendarRecapPeriodLabels on _CalendarRecapPeriod {
  String get label {
    return switch (this) {
      _CalendarRecapPeriod.day => 'Daily',
      _CalendarRecapPeriod.week => 'Weekly',
      _CalendarRecapPeriod.month => 'Monthly',
      _CalendarRecapPeriod.ninetyDays => '90 Days',
      _CalendarRecapPeriod.yearToDate => 'Year-to-Date',
    };
  }

  String rangeLabel(DateTime anchor) {
    final range = rangeFor(anchor);
    return switch (this) {
      _CalendarRecapPeriod.day => calendarFullDateLabel(anchor),
      _CalendarRecapPeriod.week =>
        '${_shortCalendarDate(range.start)} - ${_shortCalendarDate(range.end)}',
      _CalendarRecapPeriod.month =>
        '${_monthName(anchor.month)} ${anchor.year}',
      _CalendarRecapPeriod.ninetyDays =>
        '${_shortCalendarDate(range.start)} - ${_shortCalendarDate(range.end)}',
      _CalendarRecapPeriod.yearToDate =>
        'Jan 1 - ${_shortCalendarDate(anchor)}',
    };
  }

  ExpenseDateRange rangeFor(DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (this) {
      _CalendarRecapPeriod.day => ExpenseDateRange(start: day, end: day),
      _CalendarRecapPeriod.week => () {
        final start = day.subtract(Duration(days: day.weekday - 1));
        return ExpenseDateRange(
          start: start,
          end: start.add(const Duration(days: 6)),
        );
      }(),
      _CalendarRecapPeriod.month => ExpenseDateRange(
        start: DateTime(day.year, day.month),
        end: DateTime(day.year, day.month + 1, 0),
      ),
      _CalendarRecapPeriod.ninetyDays => ExpenseDateRange(
        start: day.subtract(const Duration(days: 89)),
        end: day,
      ),
      _CalendarRecapPeriod.yearToDate => ExpenseDateRange(
        start: DateTime(day.year),
        end: day,
      ),
    };
  }
}

String _shortCalendarDate(DateTime day) =>
    '${day.month}/${day.day}/${day.year}';
