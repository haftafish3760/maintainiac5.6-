part of 'expense_calendar.dart';

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
