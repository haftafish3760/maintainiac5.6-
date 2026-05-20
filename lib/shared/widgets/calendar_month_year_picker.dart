import 'package:flutter/material.dart';

class CalendarMonthYearSelection {
  const CalendarMonthYearSelection({
    required this.focusedMonth,
    this.selectedDate,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
}

Future<CalendarMonthYearSelection?> showCalendarMonthYearPicker({
  required BuildContext context,
  required DateTime focusedDay,
  DateTime? selectedDay,
}) {
  return showModalBottomSheet<CalendarMonthYearSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CalendarMonthYearPickerSheet(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
    ),
  );
}

String calendarFullDateLabel(DateTime date) {
  return '${calendarMonthName(date.month)} ${date.day}, ${date.year}';
}

String calendarMonthYearLabel(DateTime date) {
  return '${calendarMonthName(date.month)} ${date.year}';
}

String calendarMonthName(int month) {
  return switch (month) {
    1 => 'January',
    2 => 'February',
    3 => 'March',
    4 => 'April',
    5 => 'May',
    6 => 'June',
    7 => 'July',
    8 => 'August',
    9 => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December',
    _ => '',
  };
}

class _CalendarMonthYearPickerSheet extends StatefulWidget {
  const _CalendarMonthYearPickerSheet({
    required this.focusedDay,
    required this.selectedDay,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;

  @override
  State<_CalendarMonthYearPickerSheet> createState() =>
      _CalendarMonthYearPickerSheetState();
}

class _CalendarMonthYearPickerSheetState
    extends State<_CalendarMonthYearPickerSheet> {
  late var _month = widget.selectedDay?.month ?? widget.focusedDay.month;
  late var _year = widget.selectedDay?.year ?? widget.focusedDay.year;
  late final TextEditingController _dateController;
  late final ScrollController _yearScrollController;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final date = widget.selectedDay ?? widget.focusedDay;
    _dateController = TextEditingController(
      text: '${date.month}/${date.day}/${date.year}',
    );
    _yearScrollController = ScrollController(
      initialScrollOffset: ((_year - _firstYear).clamp(0, _yearCount - 1)) * 44,
    );
  }

  int get _firstYear => DateTime.now().year - 10;
  int get _lastYear => DateTime.now().year + 10;
  int get _yearCount => _lastYear - _firstYear + 1;

  @override
  void dispose() {
    _dateController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF20282C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF5E6A70), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Jump To Date',
                  style: TextStyle(
                    color: Color(0xFFF7FAF4),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateController,
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(
                    color: Color(0xFFF7FAF4),
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enter date',
                    hintText: 'MM/DD/YYYY',
                    errorText: _dateError,
                  ),
                  onSubmitted: (_) => _useTypedDate(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 246,
                  child: Row(
                    children: [
                      Expanded(
                        child: _MonthSelector(
                          month: _month,
                          onChanged: _setMonth,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _YearSelector(
                          controller: _yearScrollController,
                          firstYear: _firstYear,
                          lastYear: _lastYear,
                          year: _year,
                          onChanged: _setYear,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD32222),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _showMonth,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D75B9),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Show Month'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _useTypedDate,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF20B464),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Use Date'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setMonth(int month) {
    setState(() => _month = month);
    _syncTypedDateToMonthYear();
  }

  void _setYear(int year) {
    setState(() => _year = year);
    _syncTypedDateToMonthYear();
  }

  void _syncTypedDateToMonthYear() {
    final current = _parseTypedDate();
    final day = current?.day ?? 1;
    final clampedDay = day.clamp(1, DateUtils.getDaysInMonth(_year, _month));
    _dateController.text = '$_month/$clampedDay/$_year';
  }

  void _showMonth() {
    Navigator.of(
      context,
    ).pop(CalendarMonthYearSelection(focusedMonth: DateTime(_year, _month)));
  }

  void _useTypedDate() {
    final typedDate = _parseTypedDate();
    if (typedDate == null) {
      setState(() => _dateError = 'Use MM/DD/YYYY');
      return;
    }
    Navigator.of(context).pop(
      CalendarMonthYearSelection(
        focusedMonth: DateTime(typedDate.year, typedDate.month),
        selectedDate: typedDate,
      ),
    );
  }

  DateTime? _parseTypedDate() {
    final parts = _dateController.text.trim().split(RegExp(r'[/-]'));
    if (parts.length != 3) {
      return null;
    }
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month == null || day == null || year == null) {
      return null;
    }
    if (year < _firstYear || year > _lastYear || month < 1 || month > 12) {
      return null;
    }
    final maxDay = DateUtils.getDaysInMonth(year, month);
    if (day < 1 || day > maxDay) {
      return null;
    }
    return DateTime(year, month, day);
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month, required this.onChanged});

  final int month;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 12,
      itemBuilder: (context, index) {
        final value = index + 1;
        final selected = value == month;
        return _PickerRowButton(
          label: calendarMonthName(value),
          selected: selected,
          onTap: () => onChanged(value),
        );
      },
    );
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({
    required this.controller,
    required this.firstYear,
    required this.lastYear,
    required this.year,
    required this.onChanged,
  });

  final ScrollController controller;
  final int firstYear;
  final int lastYear;
  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: lastYear - firstYear + 1,
      itemBuilder: (context, index) {
        final value = firstYear + index;
        final selected = value == year;
        return _PickerRowButton(
          label: '$value',
          selected: selected,
          onTap: () => onChanged(value),
        );
      },
    );
  }
}

class _PickerRowButton extends StatelessWidget {
  const _PickerRowButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFF29D86D) : const Color(0xFF344047),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            height: 38,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF07100A)
                      : const Color(0xFFF7FAF4),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
