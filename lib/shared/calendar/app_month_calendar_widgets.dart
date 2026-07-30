part of 'app_month_calendar.dart';

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.hasScheduled,
    required this.hasCompleted,
    required this.plannedEntryCount,
    required this.confirmedEntryCount,
    required this.reviewRequiredEntryCount,
    required this.isSelected,
    required this.isToday,
    required this.entryCount,
    this.isOutsideMonth = false,
  });

  final DateTime day;
  final bool hasScheduled;
  final bool hasCompleted;
  final int plannedEntryCount;
  final int confirmedEntryCount;
  final int reviewRequiredEntryCount;
  final bool isSelected;
  final bool isToday;
  final int entryCount;
  final bool isOutsideMonth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: calendarDayAccessibilityLabel(
        day: day,
        entryCount: entryCount,
        hasScheduled: hasScheduled,
        hasCompleted: hasCompleted,
        plannedEntryCount: plannedEntryCount,
        confirmedEntryCount: confirmedEntryCount,
        reviewRequiredEntryCount: reviewRequiredEntryCount,
        isOutsideMonth: isOutsideMonth,
      ),
      selected: isSelected,
      excludeSemantics: true,
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
            if (!isOutsideMonth && entryCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: _CalendarBadge(
                  color: const Color(0xFF65B8FF),
                  label: entryCount > 9 ? '9+' : '$entryCount',
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
                      if (confirmedEntryCount > 0)
                        _CalendarBadge(
                          color: const Color(0xFF29D86D),
                          label: confirmedEntryCount > 9
                              ? '✓9+'
                              : '✓$confirmedEntryCount',
                        ),
                      if (confirmedEntryCount > 0 &&
                          reviewRequiredEntryCount > 0)
                        const SizedBox(width: 3),
                      if (reviewRequiredEntryCount > 0)
                        _CalendarBadge(
                          color: Color(0xFFFF4F46),
                          label: reviewRequiredEntryCount > 9
                              ? '!9+'
                              : '!$reviewRequiredEntryCount',
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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

  List<BoxShadow> _cellShadows() {
    if (isSelected) {
      return const [
        BoxShadow(color: Color(0xAA20F060), blurRadius: 9, spreadRadius: -1),
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ];
    }
    if (isToday) {
      return const [
        BoxShadow(color: Color(0xAA20F060), blurRadius: 8, spreadRadius: -2),
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
      Shadow(color: Color(0xAA20F060), blurRadius: 7),
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
      width: label.length > 1 ? 25 : 17,
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
