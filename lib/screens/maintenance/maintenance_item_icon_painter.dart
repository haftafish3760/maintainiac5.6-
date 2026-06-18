part of 'maintenance_item_icon.dart';

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
