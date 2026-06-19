import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'calendar_day_flow.dart';
import '../../shared/widgets/calendar_month_year_picker.dart';

class DashboardMonthCalendar extends StatefulWidget {
  const DashboardMonthCalendar({super.key});

  @override
  State<DashboardMonthCalendar> createState() => _DashboardMonthCalendarState();
}

class _DashboardMonthCalendarState extends State<DashboardMonthCalendar> {
  var _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final _scheduledDays = <DateTime>{
    DateTime.utc(2026, 5, 18),
    DateTime.utc(2026, 5, 23),
    DateTime.utc(2026, 5, 30),
  };

  final _completedDays = <DateTime>{
    DateTime.utc(2026, 5, 12),
    DateTime.utc(2026, 5, 15),
    DateTime.utc(2026, 5, 16),
  };

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _CalendarPanelPainter(),
      child: Container(
        width: double.infinity,
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
          headerVisible: true,
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
              if (selected != null) {
                return calendarFullDateLabel(selected);
              }
              return calendarMonthYearLabel(date);
            },
            titleTextStyle: const TextStyle(
              color: Color(0xFFF7FAF4),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
                Shadow(
                  color: Color(0xAA000000),
                  blurRadius: 5,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFF7FAF4),
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFF7FAF4),
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Color(0xFFF7FAF4),
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            weekendStyle: TextStyle(
              color: Color(0xFFF7FAF4),
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0xEE000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
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
            });
            _openCalendarDay(context, selectedDay);
          },
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          onHeaderTapped: (_) => _openMonthYearPicker(context),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: _calendarDayBuilder,
            todayBuilder: _calendarDayBuilder,
            selectedBuilder: _calendarDayBuilder,
            outsideBuilder: _calendarOutsideDayBuilder,
          ),
        ),
      ),
    );
  }

  void _openCalendarDay(BuildContext context, DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CalendarDayFlowScreen(day: day)),
    );
  }

  Future<void> _openMonthYearPicker(BuildContext context) async {
    final selection = await showCalendarMonthYearPicker(
      context: context,
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
    );
    if (!mounted || selection == null) {
      return;
    }
    setState(() {
      _focusedDay = selection.focusedMonth;
      if (selection.selectedDate != null) {
        _selectedDay = selection.selectedDate;
      }
    });
  }

  Widget? _calendarDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    final normalized = DateTime.utc(day.year, day.month, day.day);
    final hasScheduled = _scheduledDays.contains(normalized);
    final hasCompleted = _completedDays.contains(normalized);
    final isSelected = isSameDay(_selectedDay, day);
    final isToday = isSameDay(DateTime.now(), day);

    return _CalendarDayCell(
      day: day,
      hasScheduled: hasScheduled,
      hasCompleted: hasCompleted,
      isSelected: isSelected,
      isToday: isToday,
    );
  }

  Widget? _calendarOutsideDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    final isSelected = isSameDay(_selectedDay, day);
    final isToday = isSameDay(DateTime.now(), day);

    return _CalendarDayCell(
      day: day,
      hasScheduled: false,
      hasCompleted: false,
      isSelected: isSelected,
      isToday: isToday,
      isOutsideMonth: true,
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.hasScheduled,
    required this.hasCompleted,
    required this.isSelected,
    required this.isToday,
    this.isOutsideMonth = false,
  });

  final DateTime day;
  final bool hasScheduled;
  final bool hasCompleted;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;

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
          if (!isOutsideMonth)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasScheduled)
                      const _CalendarBadge(
                        color: Color(0xFF29D86D),
                        label: 'S',
                      ),
                    if (hasScheduled && hasCompleted) const SizedBox(width: 3),
                    if (hasCompleted)
                      const _CalendarBadge(
                        color: Color(0xFFFF4F46),
                        label: 'D',
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _dayNumberColor() {
    if (isSelected) {
      return const Color(0xFF07100A);
    }
    if (isToday) {
      return const Color(0xFF50FF7A);
    }
    if (isOutsideMonth) {
      return const Color(0xB8F4F7F2);
    }
    return const Color(0xFFFFFFFF);
  }

  Color _cellOverlayColor() {
    if (isSelected) {
      return const Color(0xFF29D86D);
    }
    if (isToday) {
      return const Color(0x2E20F060);
    }
    if (isOutsideMonth) {
      return const Color(0x22000000);
    }
    return Colors.transparent;
  }

  List<BoxShadow> _cellShadows() {
    if (isSelected) {
      return const [
        BoxShadow(
          color: Color(0xAA20F060),
          blurRadius: 9,
          spreadRadius: -1,
          offset: Offset(0, 0),
        ),
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];
    }
    if (isToday) {
      return const [
        BoxShadow(
          color: Color(0xAA20F060),
          blurRadius: 8,
          spreadRadius: -2,
          offset: Offset(0, 0),
        ),
      ];
    }
    return const [];
  }

  List<Shadow> _dayNumberShadows() {
    if (isSelected) {
      return const [
        Shadow(color: Color(0x88FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
      ];
    }
    return const [
      Shadow(color: Color(0xEE000000), blurRadius: 0, offset: Offset(0, 1)),
      Shadow(color: Color(0xEE000000), blurRadius: 0, offset: Offset(1, 0)),
      Shadow(color: Color(0xCC000000), blurRadius: 0, offset: Offset(-1, 0)),
      Shadow(color: Color(0xCC000000), blurRadius: 0, offset: Offset(0, -1)),
      Shadow(color: Color(0xAA20F060), blurRadius: 7, offset: Offset(0, 0)),
    ];
  }
}

class _CalendarPanelPainter extends CustomPainter {
  const _CalendarPanelPainter();

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
          stops: [0, 0.22, 0.48, 0.73, 1],
        ).createShader(rect),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.18, size.height * 0.32),
        width: size.width * 0.72,
        height: size.height * 0.42,
      ),
      Paint()
        ..color = const Color(0xFFEDE7D2).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.68),
        width: size.width * 0.68,
        height: size.height * 0.5,
      ),
      Paint()
        ..color = const Color(0xFF667274).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
  }

  @override
  bool shouldRepaint(covariant _CalendarPanelPainter oldDelegate) => false;
}

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge({required this.color, required this.label});

  final Color color;
  final String label;

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
