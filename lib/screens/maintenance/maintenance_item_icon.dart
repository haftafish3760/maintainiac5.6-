import 'dart:math' as math;

import 'package:flutter/material.dart';

class MaintenanceItemIcon extends StatelessWidget {
  const MaintenanceItemIcon({
    super.key,
    required this.itemName,
    this.size = 36,
  });

  final String itemName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MaintenanceItemIconPainter(itemName),
    );
  }
}

class _MaintenanceItemIconPainter extends CustomPainter {
  const _MaintenanceItemIconPainter(this.itemName);

  final String itemName;

  @override
  void paint(Canvas canvas, Size size) {
    final lower = itemName.toLowerCase();
    if (lower.contains('engine oil')) return _paintOilCan(canvas, size);
    if (lower.contains('oil filter') || lower.contains('fuel filter')) {
      return _paintFilter(canvas, size);
    }
    if (lower.contains('transmission') || lower.contains('differential')) {
      return _paintGearDrop(canvas, size);
    }
    if (lower.contains('coolant')) return _paintCoolant(canvas, size);
    if (lower.contains('brake')) return _paintBrake(canvas, size);
    if (lower.contains('air filter')) return _paintAirFilter(canvas, size);
    if (lower.contains('spark')) return _paintSparkPlug(canvas, size);
    if (lower.contains('belt')) return _paintBelt(canvas, size);
    if (lower.contains('hose')) return _paintHose(canvas, size);
    if (lower.contains('wiper')) return _paintWiper(canvas, size);
    if (lower.contains('battery')) return _paintBattery(canvas, size);
    if (lower.contains('tire')) return _paintTire(canvas, size);
    if (lower.contains('registration')) return _paintDocument(canvas, size);
    if (lower.contains('inspection')) return _paintInspection(canvas, size);
    return _paintWrench(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _MaintenanceItemIconPainter oldDelegate) {
    return oldDelegate.itemName != itemName;
  }

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

  Paint _paint(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
}
