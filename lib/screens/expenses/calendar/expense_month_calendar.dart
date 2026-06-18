part of 'expense_calendar.dart';

class ExpenseMonthCalendar extends StatefulWidget {
  const ExpenseMonthCalendar({super.key});

  @override
  State<ExpenseMonthCalendar> createState() => _ExpenseMonthCalendarState();
}

class _ExpenseMonthCalendarState extends State<ExpenseMonthCalendar> {
  var _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final ledger = ExpenseLedgerScope.of(context);
    return CustomPaint(
      painter: const _ExpenseCalendarPanelPainter(),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF111517), width: 1.4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TableCalendar<void>(
          firstDay: DateTime.utc(2020),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: CalendarFormat.month,
          availableGestures: AvailableGestures.horizontalSwipe,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          sixWeekMonthsEnforced: true,
          rowHeight: 70,
          daysOfWeekHeight: 26,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextFormatter: (date, locale) {
              final selected = _selectedDay;
              return selected == null
                  ? calendarMonthYearLabel(date)
                  : calendarFullDateLabel(selected);
            },
            titleTextStyle: _headerTextStyle,
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFF7FAF4),
              shadows: _headerShadows,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFF7FAF4),
              shadows: _headerShadows,
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: _dayHeaderStyle,
            weekendStyle: _dayHeaderStyle,
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: true,
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
            tablePadding: EdgeInsets.zero,
            tableBorder: TableBorder(
              horizontalInside: BorderSide(
                color: Color(0xFF111517),
                width: 1.2,
              ),
              verticalInside: BorderSide(color: Color(0xFF111517), width: 1.2),
              top: BorderSide(color: Color(0xFF111517), width: 1.2),
              bottom: BorderSide(color: Color(0xFF111517), width: 1.2),
              left: BorderSide(color: Color(0xFF111517), width: 1.2),
              right: BorderSide(color: Color(0xFF111517), width: 1.2),
            ),
            markersMaxCount: 0,
            markerSize: 0,
            defaultTextStyle: TextStyle(
              color: Color(0xFF111517),
              fontWeight: FontWeight.w800,
            ),
            weekendTextStyle: TextStyle(
              color: Color(0xFF111517),
              fontWeight: FontWeight.w800,
            ),
            todayDecoration: BoxDecoration(),
            selectedDecoration: BoxDecoration(),
            defaultDecoration: BoxDecoration(),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            Navigator.of(context).push(
              appNativeRoute<void>(context, ExpenseDayScreen(day: selectedDay)),
            );
          },
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          onHeaderTapped: (_) => _openMonthYearPicker(),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: _dayCell,
            todayBuilder: _dayCell,
            selectedBuilder: _dayCell,
            outsideBuilder: (context, day, focusedDay) {
              return _ExpenseCalendarCell(
                day: day,
                entryCount: ledger.receiptsForDay(day).length,
                muted: true,
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openMonthYearPicker() async {
    final selection = await showCalendarMonthYearPicker(
      context: context,
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
    );
    if (!mounted || selection == null) return;
    setState(() {
      _focusedDay = selection.focusedMonth;
      _selectedDay = selection.selectedDate;
    });
  }

  Widget _dayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    final ledger = ExpenseLedgerScope.of(context);
    return _ExpenseCalendarCell(
      day: day,
      entryCount: ledger.receiptsForDay(day).length,
      selected: isSameDay(_selectedDay, day),
      today: isSameDay(DateTime.now(), day),
    );
  }
}

class _ExpenseCalendarCell extends StatelessWidget {
  const _ExpenseCalendarCell({
    required this.day,
    required this.entryCount,
    this.selected = false,
    this.today = false,
    this.muted = false,
  });

  final DateTime day;
  final int entryCount;
  final bool selected;
  final bool today;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _cellOverlayColor(),
        boxShadow: _cellShadows(),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: _dayNumberColor(),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1,
                shadows: _dayNumberShadows(),
              ),
            ),
          ),
          if (!muted && entryCount > 0)
            Positioned(
              right: 4,
              bottom: 4,
              child: _ExpenseCalendarBadge(
                label: entryCount > 99 ? '99+' : '$entryCount',
                color: const Color(0xFFFFD166),
              ),
            ),
        ],
      ),
    );
  }

  Color _dayNumberColor() {
    if (selected) return const Color(0xFFFFFFFF);
    if (today) return const Color(0xFF50FF7A);
    if (muted) return const Color(0xB8F4F7F2);
    return const Color(0xFFFFFFFF);
  }

  Color _cellOverlayColor() {
    if (selected) return const Color(0xFF2E78B7);
    if (today) return const Color(0x2E20F060);
    if (muted) return const Color(0x22000000);
    return Colors.transparent;
  }

  List<BoxShadow> _cellShadows() {
    if (selected) {
      return const [
        BoxShadow(color: Color(0xAA34A9E8), blurRadius: 9, spreadRadius: -1),
      ];
    }
    if (today) {
      return const [
        BoxShadow(color: Color(0xAA20F060), blurRadius: 8, spreadRadius: -2),
      ];
    }
    return const [];
  }

  List<Shadow> _dayNumberShadows() {
    if (selected) {
      return const [
        Shadow(color: Color(0x88FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
      ];
    }
    return const [
      Shadow(color: Color(0xEE000000), blurRadius: 0, offset: Offset(0, 1)),
      Shadow(color: Color(0xEE000000), blurRadius: 0, offset: Offset(1, 0)),
      Shadow(color: Color(0xCC000000), blurRadius: 0, offset: Offset(-1, 0)),
      Shadow(color: Color(0xCC000000), blurRadius: 0, offset: Offset(0, -1)),
      Shadow(color: Color(0xAA20F060), blurRadius: 7),
    ];
  }
}

class _ExpenseCalendarBadge extends StatelessWidget {
  const _ExpenseCalendarBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 18),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF050607), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF050607),
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
