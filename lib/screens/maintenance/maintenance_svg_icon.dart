import 'package:flutter/material.dart';

import 'maintenance_item_icon.dart';

class MaintenanceSvgIcon extends StatelessWidget {
  const MaintenanceSvgIcon({super.key, required this.itemName, this.size = 42});

  final String itemName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return MaintenanceItemIcon(itemName: itemName, size: size);
  }
}
