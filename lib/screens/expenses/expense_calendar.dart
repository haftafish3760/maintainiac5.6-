import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../shared/navigation/app_page_routes.dart';
import '../../shared/widgets/app_back_button.dart';
import '../../shared/widgets/calendar_month_year_picker.dart';

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
              return _ExpenseCalendarCell(day: day, muted: true);
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
    return _ExpenseCalendarCell(
      day: day,
      selected: isSameDay(_selectedDay, day),
      today: isSameDay(DateTime.now(), day),
    );
  }
}

class _ExpenseCalendarCell extends StatelessWidget {
  const _ExpenseCalendarCell({
    required this.day,
    this.selected = false,
    this.today = false,
    this.muted = false,
  });

  final DateTime day;
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
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: _dayNumberColor(),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  shadows: _dayNumberShadows(),
                ),
              ),
            ),
          ),
          if (!muted)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: _ExpenseCalendarBadge(
                  label: r'$',
                  color: Color(0xFFFFD166),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _dayNumberColor() {
    if (selected) return const Color(0xFF07100A);
    if (today) return const Color(0xFF50FF7A);
    if (muted) return const Color(0xB8F4F7F2);
    return const Color(0xFFFFFFFF);
  }

  Color _cellOverlayColor() {
    if (selected) return const Color(0xFF29D86D);
    if (today) return const Color(0x2E20F060);
    if (muted) return const Color(0x22000000);
    return Colors.transparent;
  }

  List<BoxShadow> _cellShadows() {
    if (selected) {
      return const [
        BoxShadow(color: Color(0xAA20F060), blurRadius: 9, spreadRadius: -1),
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
      width: 17,
      height: 17,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF050607), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF050607),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class ExpenseDayScreen extends StatefulWidget {
  const ExpenseDayScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<ExpenseDayScreen> createState() => _ExpenseDayScreenState();
}

class _ExpenseDayScreenState extends State<ExpenseDayScreen> {
  late var _day = widget.day;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            AppScreenHeader(
              title: calendarFullDateLabel(_day),
              actions: [
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3A40),
                border: Border.all(color: const Color(0xFF66737A)),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No expenses recorded for this date yet.',
                    style: TextStyle(
                      color: Color(0xFFE2E8EA),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This page will hold the expense entries, edits, and reminders for the selected day.',
                    style: TextStyle(
                      color: Color(0xFFD4DDE1),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }

  void _shiftDay(int offset) {
    setState(() => _day = _day.add(Duration(days: offset)));
  }
}

class _ExpenseCalendarPanelPainter extends CustomPainter {
  const _ExpenseCalendarPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0E4DC),
            Color(0xFFB6B9AB),
            Color(0xFFC9D0D3),
            Color(0xFF8F9A9D),
            Color(0xFFD5D0BE),
          ],
          stops: [0, .22, .48, .73, 1],
        ).createShader(rect),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .18, size.height * .32),
        width: size.width * .72,
        height: size.height * .42,
      ),
      Paint()
        ..color = const Color(0xFFEDE7D2).withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .78, size.height * .68),
        width: size.width * .68,
        height: size.height * .5,
      ),
      Paint()
        ..color = const Color(0xFF667274).withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
  }

  @override
  bool shouldRepaint(covariant _ExpenseCalendarPanelPainter oldDelegate) {
    return false;
  }
}

const _headerTextStyle = TextStyle(
  color: Color(0xFFF7FAF4),
  fontSize: 18,
  fontWeight: FontWeight.w900,
  shadows: _headerShadows,
);

const _dayHeaderStyle = TextStyle(
  color: Color(0xFFF7FAF4),
  fontWeight: FontWeight.w900,
  shadows: _headerShadows,
);

const _headerShadows = [
  Shadow(color: Color(0xEE000000), blurRadius: 2, offset: Offset(0, 1)),
  Shadow(color: Color(0xAA000000), blurRadius: 5),
];
