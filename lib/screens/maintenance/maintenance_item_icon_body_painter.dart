part of 'maintenance_item_icon.dart';

extension _MaintenanceItemIconBodyPainter on _MaintenanceItemIconPainter {
  void _paintDocument(Canvas canvas, Size size) {
    final page = Path()
      ..moveTo(size.width * .26, size.height * .14)
      ..lineTo(size.width * .62, size.height * .14)
      ..lineTo(size.width * .78, size.height * .30)
      ..lineTo(size.width * .78, size.height * .86)
      ..lineTo(size.width * .26, size.height * .86)
      ..close();
    canvas.drawPath(page, _paint(const Color(0xFFE9EEF1)));
    canvas.drawPath(page, _stroke(const Color(0xFF111719), size.width * .05));
    for (final y in [.42, .54, .66]) {
      canvas.drawLine(
        Offset(size.width * .36, size.height * y),
        Offset(size.width * .68, size.height * y),
        _stroke(const Color(0xFF7B8A91), size.width * .03),
      );
    }
  }

  void _paintInspection(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .06);
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .32,
      _paint(const Color(0xFF20B24A)),
    );
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .32,
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .33, size.height * .52),
      Offset(size.width * .45, size.height * .65),
      _stroke(Colors.white, size.width * .08),
    );
    canvas.drawLine(
      Offset(size.width * .45, size.height * .65),
      Offset(size.width * .70, size.height * .36),
      _stroke(Colors.white, size.width * .08),
    );
  }

  void _paintKeyFob(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .055);
    final fob = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .30,
        size.height * .16,
        size.width * .40,
        size.height * .68,
      ),
      Radius.circular(size.width * .12),
    );
    canvas.drawRRect(fob, _paint(const Color(0xFF222A2D)));
    canvas.drawRRect(fob, stroke);
    canvas.drawCircle(
      Offset(size.width * .50, size.height * .30),
      size.width * .055,
      _paint(const Color(0xFFE9EEF1)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .38,
          size.height * .45,
          size.width * .24,
          size.height * .11,
        ),
        Radius.circular(size.width * .04),
      ),
      _paint(const Color(0xFFE9EEF1)),
    );
    canvas.drawLine(
      Offset(size.width * .50, size.height * .67),
      Offset(size.width * .50, size.height * .77),
      _stroke(const Color(0xFFE9EEF1), size.width * .04),
    );
    canvas.drawLine(
      Offset(size.width * .45, size.height * .72),
      Offset(size.width * .55, size.height * .72),
      _stroke(const Color(0xFFE9EEF1), size.width * .04),
    );
  }

  void _paintWrench(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .075);
    canvas.drawLine(
      Offset(size.width * .28, size.height * .75),
      Offset(size.width * .70, size.height * .33),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * .74, size.height * .28),
      size.width * .12,
      stroke,
    );
  }
}
