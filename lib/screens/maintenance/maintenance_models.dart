import 'package:flutter/material.dart';

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

const maintenanceCatalog = <MaintenanceCatalogItem>[
  MaintenanceCatalogItem(
    name: 'Engine Oil',
    icon: '🛢️',
    importance: 100,
    defaultMiles: 5000,
    defaultMonths: 6,
    detailA: 'Oil type',
    detailB: 'Oil weight',
  ),
  MaintenanceCatalogItem(
    name: 'Oil Filter',
    icon: '🧰',
    importance: 92,
    defaultMiles: 5000,
    defaultMonths: 6,
    detailA: 'Filter type',
    detailB: 'Part detail',
  ),
  MaintenanceCatalogItem(
    name: 'Transmission Fluid and Filter',
    icon: '⚙️',
    importance: 96,
    defaultMiles: 60000,
    defaultMonths: 48,
    detailA: 'Fluid family',
    detailB: 'Specification',
  ),
  MaintenanceCatalogItem(
    name: 'Coolant',
    icon: '🌡️',
    importance: 88,
    defaultMiles: 30000,
    defaultMonths: 36,
    detailA: 'Coolant type',
    detailB: 'Mix',
  ),
  MaintenanceCatalogItem(
    name: 'Brake Fluid',
    icon: '🛑',
    importance: 94,
    defaultMiles: 30000,
    defaultMonths: 24,
    detailA: 'Fluid rating',
    detailB: 'Container detail',
  ),
  MaintenanceCatalogItem(
    name: 'Brake Pads',
    icon: '🛑',
    importance: 90,
    defaultMiles: 30000,
    defaultMonths: 24,
    detailA: 'Axle',
    detailB: 'Pad material',
  ),
  MaintenanceCatalogItem(
    name: 'Engine Air Filter',
    icon: '🌬️',
    importance: 72,
    defaultMiles: 12000,
    defaultMonths: 12,
    detailA: 'Filter style',
    detailB: 'Part detail',
  ),
  MaintenanceCatalogItem(
    name: 'Cabin Air Filter',
    icon: '🌬️',
    importance: 55,
    defaultMiles: 12000,
    defaultMonths: 12,
    detailA: 'Filter style',
    detailB: 'Part detail',
  ),
  MaintenanceCatalogItem(
    name: 'Spark Plugs',
    icon: '⚡',
    importance: 84,
    defaultMiles: 60000,
    defaultMonths: 48,
    detailA: 'Plug type',
    detailB: 'Gap',
  ),
  MaintenanceCatalogItem(
    name: 'Serpentine Belt',
    icon: '🔁',
    importance: 86,
    defaultMiles: 60000,
    defaultMonths: 48,
    detailA: 'Belt type',
    detailB: 'Length/detail',
  ),
  MaintenanceCatalogItem(
    name: 'Radiator Hose',
    icon: '〰️',
    importance: 82,
    defaultMiles: 60000,
    defaultMonths: 48,
    detailA: 'Hose position',
    detailB: 'Part detail',
  ),
  MaintenanceCatalogItem(
    name: 'Heater Hose',
    icon: '〰️',
    importance: 80,
    defaultMiles: 60000,
    defaultMonths: 48,
    detailA: 'Hose position',
    detailB: 'Part detail',
  ),
  MaintenanceCatalogItem(
    name: 'Wiper Blades',
    icon: '🌧️',
    importance: 70,
    defaultMiles: 12000,
    defaultMonths: 12,
    detailA: 'Blade position',
    detailB: 'Blade size',
  ),
  MaintenanceCatalogItem(
    name: 'Battery',
    icon: '🔋',
    importance: 86,
    defaultMiles: 0,
    defaultMonths: 48,
    detailA: 'Battery type',
    detailB: 'Group size',
    timeOnly: true,
  ),
  MaintenanceCatalogItem(
    name: 'Power Steering Fluid',
    icon: '💧',
    importance: 78,
    defaultMiles: 50000,
    defaultMonths: 48,
    detailA: 'Fluid type',
    detailB: 'Specification',
  ),
  MaintenanceCatalogItem(
    name: 'Differential Fluid',
    icon: '⚙️',
    importance: 82,
    defaultMiles: 50000,
    defaultMonths: 48,
    detailA: 'Fluid type',
    detailB: 'Viscosity',
  ),
  MaintenanceCatalogItem(
    name: 'Fuel Filter',
    icon: '⛽',
    importance: 76,
    defaultMiles: 30000,
    defaultMonths: 24,
    detailA: 'Filter type',
    detailB: 'Part detail',
  ),
  MaintenanceCatalogItem(
    name: 'Tires',
    icon: '🛞',
    importance: 92,
    defaultMiles: 50000,
    defaultMonths: 60,
    detailA: 'Tire position',
    detailB: 'Tire size',
  ),
  MaintenanceCatalogItem(
    name: 'Washer Fluid',
    icon: '💧',
    importance: 45,
    defaultMiles: 0,
    defaultMonths: 3,
    detailA: 'Fluid type',
    detailB: 'Season rating',
    timeOnly: true,
  ),
  MaintenanceCatalogItem(
    name: 'Key Fob Battery',
    icon: '🔑',
    importance: 40,
    defaultMiles: 0,
    defaultMonths: 24,
    detailA: 'Battery type',
    detailB: 'Quantity',
    timeOnly: true,
  ),
  MaintenanceCatalogItem(
    name: 'Registration',
    icon: '📄',
    importance: 98,
    defaultMiles: 0,
    defaultMonths: 12,
    detailA: 'Renewal type',
    detailB: 'Renewal period',
    timeOnly: true,
  ),
  MaintenanceCatalogItem(
    name: 'Inspection',
    icon: '✅',
    importance: 97,
    defaultMiles: 0,
    defaultMonths: 12,
    detailA: 'Inspection type',
    detailB: 'Renewal period',
    timeOnly: true,
  ),
];

const engineOilWeights = <String>[
  '0W-8',
  '0W-12',
  '0W-16',
  '0W-20',
  '0W-30',
  '0W-40',
  '5W-16',
  '5W-20',
  '5W-30',
  '5W-40',
  '5W-50',
  '10W-30',
  '10W-40',
  '10W-50',
  '10W-60',
  '15W-40',
  '15W-50',
  '20W-50',
  'SAE 20',
  'SAE 30',
  'SAE 40',
  'SAE 50',
  'Other',
];

class ReceiptLineEntry {
  ReceiptLineEntry({
    required this.itemName,
    this.productName = '',
    this.detailA = '',
    this.detailB = '',
    this.measurement = 'Quarts',
    this.unitsPerContainer = 1,
    this.containerCount = 1,
    this.unitCost = 0,
  });

  final String itemName;
  final String productName;
  final String detailA;
  final String detailB;
  final String measurement;
  final double unitsPerContainer;
  final double containerCount;
  final double unitCost;

  double get totalUnits => unitsPerContainer * containerCount;
  double get totalCost => unitCost * containerCount;

  ReceiptLineEntry copyWith({
    String? productName,
    String? detailA,
    String? detailB,
    String? measurement,
    double? unitsPerContainer,
    double? containerCount,
    double? unitCost,
  }) {
    return ReceiptLineEntry(
      itemName: itemName,
      productName: productName ?? this.productName,
      detailA: detailA ?? this.detailA,
      detailB: detailB ?? this.detailB,
      measurement: measurement ?? this.measurement,
      unitsPerContainer: unitsPerContainer ?? this.unitsPerContainer,
      containerCount: containerCount ?? this.containerCount,
      unitCost: unitCost ?? this.unitCost,
    );
  }
}

Color thresholdColor(int milesRemaining) {
  if (milesRemaining <= 299) return const Color(0xFFE3342F);
  if (milesRemaining <= 599) return const Color(0xFFFF7A00);
  if (milesRemaining <= 900) return const Color(0xFFFFC928);
  return const Color(0xFF20B24A);
}
