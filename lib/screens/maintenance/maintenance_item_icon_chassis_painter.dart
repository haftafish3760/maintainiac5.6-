part of 'maintenance_item_icon.dart';

extension _MaintenanceItemIconChassisPainter on _MaintenanceItemIconPainter {
  void _paintBrake(Canvas canvas, Size size) {
    final red = _paint(const Color(0xFFE3342F));
    final stroke = _stroke(const Color(0xFF111719), size.width * .06);
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .28,
      red,
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .13,
      _paint(const Color(0xFFE9EEF1)),
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .28,
      stroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * .11,
        size.height * .18,
        size.width * .34,
        size.height * .64,
      ),
      math.pi * .55,
      math.pi * .9,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * .55,
        size.height * .18,
        size.width * .34,
        size.height * .64,
      ),
      math.pi * 1.55,
      math.pi * .9,
      false,
      stroke,
    );
  }

  void _paintBattery(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .16,
        size.height * .30,
        size.width * .68,
        size.height * .42,
      ),
      Radius.circular(size.width * .05),
    );
    canvas.drawRRect(body, _paint(const Color(0xFF20B24A)));
    canvas.drawRRect(body, _stroke(const Color(0xFF111719), size.width * .055));
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .30,
        size.height * .22,
        size.width * .10,
        size.height * .08,
      ),
      _paint(const Color(0xFF111719)),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .60,
        size.height * .22,
        size.width * .10,
        size.height * .08,
      ),
      _paint(const Color(0xFF111719)),
    );
    canvas.drawLine(
      Offset(size.width * .30, size.height * .51),
      Offset(size.width * .43, size.height * .51),
      _stroke(Colors.white, size.width * .04),
    );
    canvas.drawLine(
      Offset(size.width * .57, size.height * .51),
      Offset(size.width * .72, size.height * .51),
      _stroke(Colors.white, size.width * .04),
    );
    canvas.drawLine(
      Offset(size.width * .645, size.height * .43),
      Offset(size.width * .645, size.height * .59),
      _stroke(Colors.white, size.width * .04),
    );
  }

  void _paintTire(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .31,
      _paint(const Color(0xFF111719)),
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .18,
      _paint(const Color(0xFFDDE7EA)),
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .08,
      _paint(const Color(0xFF111719)),
    );
  }
}
