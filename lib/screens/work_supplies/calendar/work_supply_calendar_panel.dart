import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../shared/calendar/month_year_picker.dart';

class WorkSupplyCalendarMarker {
  const WorkSupplyCalendarMarker({
    required this.label,
    required this.color,
    required this.count,
  });

  final String label;
  final Color color;
  final int count;
}

class WorkSupplyCalendarPanel extends StatefulWidget {
  const WorkSupplyCalendarPanel({
    super.key,
    required this.markersByDay,
    required this.onDaySelected,
  });

  final Map<DateTime, List<WorkSupplyCalendarMarker>> markersByDay;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<WorkSupplyCalendarPanel> createState() =>
      _WorkSupplyCalendarPanelState();
}

class _WorkSupplyCalendarPanelState extends State<WorkSupplyCalendarPanel> {
  var _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
              if (selected != null) return calendarFullDateLabel(selected);
              return calendarMonthYearLabel(date);
            },
            titleTextStyle: _shadowTextStyle(18),
            leftChevronIcon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFFF7FAF4),
              shadows: [_darkShadow],
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFF7FAF4),
              shadows: [_darkShadow],
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Color(0xFFF7FAF4),
              fontWeight: FontWeight.w900,
              shadows: [_darkShadow],
            ),
            weekendStyle: TextStyle(
              color: Color(0xFFF7FAF4),
              fontWeight: FontWeight.w900,
              shadows: [_darkShadow],
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
              _focusedDay = focusedDay;
            });
            widget.onDaySelected(selectedDay);
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

  Future<void> _openMonthYearPicker(BuildContext context) async {
    final selection = await showCalendarMonthYearPicker(
      context: context,
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
    );
    if (!mounted || selection == null) return;
    setState(() {
      _focusedDay = selection.focusedMonth;
      if (selection.selectedDate != null) _selectedDay = selection.selectedDate;
    });
  }

  Widget? _calendarDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return _CalendarDayCell(
      day: day,
      markers: widget.markersByDay[_dayKey(day)] ?? const [],
      isSelected: isSameDay(_selectedDay, day),
      isToday: isSameDay(DateTime.now(), day),
    );
  }

  Widget? _calendarOutsideDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return _CalendarDayCell(
      day: day,
      markers: const [],
      isSelected: isSameDay(_selectedDay, day),
      isToday: isSameDay(DateTime.now(), day),
      isOutsideMonth: true,
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.markers,
    required this.isSelected,
    required this.isToday,
    this.isOutsideMonth = false,
  });

  final DateTime day;
  final List<WorkSupplyCalendarMarker> markers;
  final bool isSelected;
  final bool isToday;
  final bool isOutsideMonth;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(color: _cellOverlayColor()),
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
          if (!isOutsideMonth && markers.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: 3,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final marker in markers.take(2))
                      _CalendarBadge(marker: marker),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _dayNumberColor() {
    if (isSelected) return const Color(0xFF07100A);
    if (isToday) return const Color(0xFF50FF7A);
    if (isOutsideMonth) return const Color(0xB8F4F7F2);
    return const Color(0xFFFFFFFF);
  }

  Color _cellOverlayColor() {
    if (isSelected) return const Color(0xFF29D86D);
    if (isToday) return const Color(0x2E20F060);
    if (isOutsideMonth) return const Color(0x22000000);
    return Colors.transparent;
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

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge({required this.marker});

  final WorkSupplyCalendarMarker marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 17,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: marker.color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF050607), width: 1),
      ),
      child: Text(
        marker.count > 9 ? marker.label : '${marker.count}',
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

DateTime _dayKey(DateTime day) => DateTime.utc(day.year, day.month, day.day);

const _darkShadow = Shadow(
  color: Color(0xEE000000),
  blurRadius: 2,
  offset: Offset(0, 1),
);

TextStyle _shadowTextStyle(double size) {
  return TextStyle(
    color: const Color(0xFFF7FAF4),
    fontSize: size,
    fontWeight: FontWeight.w900,
    shadows: const [
      _darkShadow,
      Shadow(color: Color(0xAA000000), blurRadius: 5, offset: Offset(0, 0)),
    ],
  );
}
