import 'package:flutter/material.dart';

part 'maintenance_catalog.dart';
part 'maintenance_catalog_oil_options.dart';
part 'maintenance_catalog_utility_items.dart';
part 'maintenance_catalog_options.dart';

enum WorkSource { me, shop, both }

extension WorkSourceText on WorkSource {
  String get label => switch (this) {
    WorkSource.me => 'Me',
    WorkSource.shop => 'A Shop',
    WorkSource.both => 'Both',
  };
}

class MaintenanceCatalogItem {
  const MaintenanceCatalogItem({
    required this.name,
    required this.icon,
    required this.importance,
    required this.defaultMiles,
    required this.defaultMonths,
    required this.detailA,
    required this.detailB,
    this.timeOnly = false,
  });

  final String name;
  final String icon;
  final int importance;
  final int defaultMiles;
  final int defaultMonths;
  final String detailA;
  final String detailB;
  final bool timeOnly;
}

Color thresholdColor(int milesRemaining) {
  if (milesRemaining <= 300) return const Color(0xFFE3342F);
  if (milesRemaining <= 600) return const Color(0xFFFF7A00);
  if (milesRemaining <= 900) return const Color(0xFFFFC928);
  return const Color(0xFF20B24A);
}
