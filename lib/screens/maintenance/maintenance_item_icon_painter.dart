part of 'maintenance_item_icon.dart';

class _MaintenanceItemIconPainter extends CustomPainter {
  const _MaintenanceItemIconPainter(this.itemName);

  final String itemName;

  @override
  void paint(Canvas canvas, Size size) {
    _paintIconBase(canvas, size);
    final lower = itemName.toLowerCase();
    if (lower.contains('engine oil')) return _paintOilCan(canvas, size);
    if (lower.contains('oil filter') || lower.contains('fuel filter')) {
      return _paintFilter(canvas, size);
    }
    if (lower.contains('transmission') ||
        lower.contains('differential') ||
        lower.contains('transfer case')) {
      return _paintGearDrop(canvas, size);
    }
    if (lower.contains('coolant')) return _paintCoolant(canvas, size);
    if (lower.contains('brake')) return _paintBrake(canvas, size);
    if (lower.contains('air filter')) return _paintAirFilter(canvas, size);
    if (lower.contains('spark')) return _paintSparkPlug(canvas, size);
    if (lower.contains('belt')) return _paintBelt(canvas, size);
    if (lower.contains('power steering')) {
      return _paintSteeringFluid(canvas, size);
    }
    if (lower.contains('hose')) return _paintHose(canvas, size);
    if (lower.contains('wiper')) return _paintWiper(canvas, size);
    if (lower.contains('battery')) return _paintBattery(canvas, size);
    if (lower.contains('key fob')) return _paintKeyFob(canvas, size);
    if (lower.contains('tire')) return _paintTire(canvas, size);
    if (lower.contains('registration')) return _paintDocument(canvas, size);
    if (lower.contains('inspection')) return _paintInspection(canvas, size);
    return _paintWrench(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _MaintenanceItemIconPainter oldDelegate) {
    return oldDelegate.itemName != itemName;
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

  void _paintIconBase(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * .18)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6FBFC), Color(0xFFC7D4DA), Color(0xFF8B9AA2)],
        ).createShader(rect)
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      Offset(size.width * .30, size.height * .24),
      size.width * .17,
      _paint(Colors.white.withValues(alpha: .55)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(size.width * .025),
        Radius.circular(size.width * .16),
      ),
      _stroke(const Color(0xFF101416), size.width * .045),
    );
  }
}
