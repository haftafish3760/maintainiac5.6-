part of 'maintenance_item_icon.dart';

extension _MaintenanceItemIconEnginePainter on _MaintenanceItemIconPainter {
  void _paintOilCan(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .065);
    final fill = _paint(const Color(0xFFE9EEF1));
    final accent = _paint(const Color(0xFF222A2D));
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .17,
        size.height * .40,
        size.width * .43,
        size.height * .31,
      ),
      Radius.circular(size.width * .06),
    );
    final spout = Path()
      ..moveTo(size.width * .58, size.height * .42)
      ..lineTo(size.width * .87, size.height * .31)
      ..lineTo(size.width * .90, size.height * .42)
      ..lineTo(size.width * .61, size.height * .54)
      ..close();
    final handle = Path()
      ..moveTo(size.width * .18, size.height * .47)
      ..cubicTo(
        size.width * .05,
        size.height * .46,
        size.width * .05,
        size.height * .66,
        size.width * .18,
        size.height * .65,
      );
    canvas.drawPath(spout, fill);
    canvas.drawPath(spout, stroke);
    canvas.drawRRect(bodyRect, fill);
    canvas.drawRRect(bodyRect, stroke);
    canvas.drawPath(handle, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .25,
          size.height * .25,
          size.width * .30,
          size.height * .15,
        ),
        Radius.circular(size.width * .04),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .25,
          size.height * .25,
          size.width * .30,
          size.height * .15,
        ),
        Radius.circular(size.width * .04),
      ),
      stroke,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .30,
        size.height * .30,
        size.width * .20,
        size.height * .05,
      ),
      accent,
    );
    canvas.drawOval(
      Rect.fromCircle(
        center: Offset(size.width * .80, size.height * .72),
        radius: size.width * .055,
      ),
      _paint(const Color(0xFF111719)),
    );
  }

  void _paintCoolant(Canvas canvas, Size size) {
    final red = _paint(const Color(0xFFE3342F));
    final stroke = _stroke(const Color(0xFF111719), size.width * .055);
    final center = Offset(size.width * .45, size.height * .35);
    canvas.drawCircle(center, size.width * .12, red);
    canvas.drawLine(
      Offset(size.width * .45, size.height * .47),
      Offset(size.width * .45, size.height * .78),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .58, size.height * .22),
      Offset(size.width * .72, size.height * .13),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .28, size.height * .78),
      Offset(size.width * .72, size.height * .78),
      stroke,
    );
    for (final x in [.32, .44, .56, .68]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(size.width * x, size.height * .84),
          width: size.width * .12,
          height: size.height * .09,
        ),
        math.pi,
        -math.pi,
        false,
        stroke,
      );
    }
  }

  void _paintGearDrop(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF101416), size.width * .06);
    final blue = _paint(const Color(0xFF3DA5FF));
    final center = Offset(size.width * .42, size.height * .45);
    canvas.drawCircle(
      center,
      size.width * .21,
      _paint(const Color(0xFFDCE7EA)),
    );
    canvas.drawCircle(
      center,
      size.width * .09,
      _paint(const Color(0xFF101416)),
    );
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final start = Offset(
        center.dx + math.cos(angle) * size.width * .23,
        center.dy + math.sin(angle) * size.width * .23,
      );
      final end = Offset(
        center.dx + math.cos(angle) * size.width * .31,
        center.dy + math.sin(angle) * size.width * .31,
      );
      canvas.drawLine(start, end, stroke);
    }
    final drop = Path()
      ..moveTo(size.width * .72, size.height * .35)
      ..quadraticBezierTo(
        size.width * .58,
        size.height * .58,
        size.width * .72,
        size.height * .72,
      )
      ..quadraticBezierTo(
        size.width * .86,
        size.height * .58,
        size.width * .72,
        size.height * .35,
      );
    canvas.drawPath(drop, blue);
    canvas.drawPath(drop, stroke);
  }

  void _paintFilter(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .22,
        size.height * .18,
        size.width * .56,
        size.height * .64,
      ),
      Radius.circular(size.width * .09),
    );
    canvas.drawRRect(body, _paint(const Color(0xFFE9EEF1)));
    canvas.drawRRect(body, _stroke(const Color(0xFF111719), size.width * .055));
    for (final x in [.36, .50, .64]) {
      canvas.drawLine(
        Offset(size.width * x, size.height * .25),
        Offset(size.width * x, size.height * .75),
        _stroke(const Color(0xFF7B8A91), size.width * .035),
      );
    }
  }

  void _paintAirFilter(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .055);
    for (final y in [.25, .38, .51, .64]) {
      canvas.drawLine(
        Offset(size.width * .16, size.height * y),
        Offset(size.width * .72, size.height * y),
        stroke,
      );
      canvas.drawArc(
        Rect.fromLTWH(
          size.width * .65,
          size.height * (y - .06),
          size.width * .18,
          size.height * .12,
        ),
        -math.pi / 2,
        math.pi,
        false,
        stroke,
      );
    }
  }

  void _paintSparkPlug(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .42,
          size.height * .14,
          size.width * .20,
          size.height * .48,
        ),
        Radius.circular(size.width * .04),
      ),
      _paint(const Color(0xFFE9EEF1)),
    );
    canvas.drawLine(
      Offset(size.width * .52, size.height * .62),
      Offset(size.width * .34, size.height * .86),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .48, size.height * .62),
      Offset(size.width * .67, size.height * .86),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .38, size.height * .30),
      Offset(size.width * .70, size.height * .30),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .38, size.height * .44),
      Offset(size.width * .70, size.height * .44),
      stroke,
    );
  }

  void _paintBelt(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .15,
        size.height * .20,
        size.width * .70,
        size.height * .58,
      ),
      _stroke(const Color(0xFF111719), size.width * .09),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .28,
        size.height * .32,
        size.width * .44,
        size.height * .34,
      ),
      _stroke(const Color(0xFFDDE7EA), size.width * .05),
    );
  }

  void _paintHose(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .08);
    final path = Path()
      ..moveTo(size.width * .14, size.height * .62)
      ..cubicTo(
        size.width * .30,
        size.height * .18,
        size.width * .58,
        size.height * .82,
        size.width * .86,
        size.height * .36,
      );
    canvas.drawPath(path, stroke);
    canvas.drawCircle(
      Offset(size.width * .14, size.height * .62),
      size.width * .08,
      _paint(const Color(0xFFE9EEF1)),
    );
    canvas.drawCircle(
      Offset(size.width * .86, size.height * .36),
      size.width * .08,
      _paint(const Color(0xFFE9EEF1)),
    );
  }

  void _paintWiper(Canvas canvas, Size size) {
    final stroke = _stroke(const Color(0xFF111719), size.width * .06);
    canvas.drawLine(
      Offset(size.width * .20, size.height * .78),
      Offset(size.width * .78, size.height * .28),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .24, size.height * .74),
      Offset(size.width * .88, size.height * .74),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * .20, size.height * .78),
      size.width * .05,
      _paint(const Color(0xFFE9EEF1)),
    );
  }
}
