import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'maintenance_item_icon_painter.dart';
part 'maintenance_item_icon_engine_painter.dart';
part 'maintenance_item_icon_chassis_painter.dart';
part 'maintenance_item_icon_body_painter.dart';

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
