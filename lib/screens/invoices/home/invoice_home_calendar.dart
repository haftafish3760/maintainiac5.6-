import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../shared/calendar/month_year_picker.dart';
import 'invoice_home_models.dart';

class InvoiceMonthCalendarPanel extends StatefulWidget {
  const InvoiceMonthCalendarPanel({
    required this.entries,
    required this.onDaySelected,
    super.key,
  });

  final List<InvoiceTimelineEntry> entries;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<InvoiceMonthCalendarPanel> createState() =>
      _InvoiceMonthCalendarPanelState();
}

class _InvoiceMonthCalendarPanelState extends State<InvoiceMonthCalendarPanel> {
  late var _focusedDay = _initialFocusedDay();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _InvoiceCalendarPanelPainter(),
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
            widget.onDaySelected(selectedDay);
          },
          onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          onHeaderTapped: (_) => _openMonthYearPicker(),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: _dayCell,
            todayBuilder: _dayCell,
            selectedBuilder: _dayCell,
            outsideBuilder: (context, day, focusedDay) {
              return _InvoiceCalendarCell(
                day: day,
                entryCount: _countForDay(day),
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
    return _InvoiceCalendarCell(
      day: day,
      entryCount: _countForDay(day),
      selected: isSameDay(_selectedDay, day),
      today: isSameDay(DateTime.now(), day),
    );
  }

  int _countForDay(DateTime day) {
    return widget.entries.where((entry) => isSameDay(entry.day, day)).length;
  }

  DateTime _initialFocusedDay() {
    if (widget.entries.isEmpty) return DateTime.now();
    return widget.entries
        .map((entry) => entry.day)
        .reduce((latest, day) => day.isAfter(latest) ? day : latest);
  }
}

class _InvoiceCalendarCell extends StatelessWidget {
  const _InvoiceCalendarCell({
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
    return Semantics(
      key: Key(_dayKey()),
      label: _semanticLabel(),
      button: true,
      selected: selected,
      child: AnimatedContainer(
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
                child: _InvoiceCalendarBadge(
                  label: entryCount > 99 ? '99+' : '$entryCount',
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _semanticLabel() {
    final countLabel = entryCount == 1 ? '1 record' : '$entryCount records';
    return '${calendarFullDateLabel(day)}, $countLabel';
  }

  String _dayKey() {
    final month = day.month.toString().padLeft(2, '0');
    final dayNumber = day.day.toString().padLeft(2, '0');
    return 'invoice-calendar-day-${day.year}-$month-$dayNumber';
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

class _InvoiceCalendarBadge extends StatelessWidget {
  const _InvoiceCalendarBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 19, minHeight: 18),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF6BE58D),
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

class _InvoiceCalendarPanelPainter extends CustomPainter {
  const _InvoiceCalendarPanelPainter();

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
  bool shouldRepaint(covariant _InvoiceCalendarPanelPainter oldDelegate) {
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
