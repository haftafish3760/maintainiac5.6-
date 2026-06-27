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

extension MaintenanceCatalogSetup on MaintenanceCatalogItem {
  List<int> get mileageIntervalOptions {
    final lower = name.toLowerCase();
    if (timeOnly) return const [0];
    if (lower.contains('engine oil') || lower.contains('oil filter')) {
      return const [3000, 5000, 7500, 10000];
    }
    if (lower.contains('tire')) return const [5000, 6000, 7500, 10000];
    if (lower.contains('air filter') || lower.contains('wiper')) {
      return const [12000, 15000, 20000, 30000];
    }
    if (lower.contains('brake')) return const [15000, 30000, 45000, 60000];
    if (lower.contains('coolant')) {
      return const [25000, 50000, 75000, 100000];
    }
    if (lower.contains('transmission')) {
      return const [25000, 50000, 75000, 100000];
    }
    if (lower.contains('spark') ||
        lower.contains('belt') ||
        lower.contains('hose')) {
      return const [30000, 60000, 90000, 100000];
    }
    return [defaultMiles == 0 ? 12000 : defaultMiles];
  }

  List<int> get monthIntervalOptions {
    final lower = name.toLowerCase();
    if (lower.contains('engine oil') || lower.contains('oil filter')) {
      return const [3, 6, 9, 12];
    }
    if (timeOnly) return const [3, 6, 12, 24, 48];
    if (lower.contains('registration') || lower.contains('inspection')) {
      return const [6, 12, 24];
    }
    return const [6, 12, 24, 36, 48, 60];
  }

  List<String> get detailAOptions {
    final lower = name.toLowerCase();
    if (lower.contains('engine oil')) {
      return const [
        'Conventional',
        'Synthetic blend',
        'Full synthetic',
        'High mileage',
      ];
    }
    if (lower.contains('transmission')) {
      return const [
        'ATF',
        'CVT fluid',
        'Manual transmission fluid',
        'Dual-clutch fluid',
      ];
    }
    if (lower.contains('coolant')) {
      return const [
        'IAT',
        'OAT',
        'HOAT',
        'Asian blue',
        'Asian red/pink',
        'Dex-Cool',
      ];
    }
    if (lower.contains('brake fluid')) {
      return const ['DOT 3', 'DOT 4', 'DOT 5.1'];
    }
    if (lower.contains('brake pad')) {
      return const ['Front', 'Rear', 'Front and rear'];
    }
    if (lower.contains('air filter')) {
      return const ['Standard', 'Premium', 'HEPA', 'Carbon'];
    }
    if (lower.contains('spark')) {
      return const ['Copper', 'Platinum', 'Double platinum', 'Iridium'];
    }
    if (lower.contains('tire')) {
      return const ['Rotation', 'Replacement', 'Balance', 'Alignment'];
    }
    return const [];
  }

  List<String> get detailBOptions {
    final lower = name.toLowerCase();
    if (lower.contains('engine oil')) return engineOilWeights;
    if (lower.contains('transmission')) {
      return const [
        'Dexron/Mercon',
        'ATF+4',
        'Type F',
        'Honda DW-1',
        'Toyota WS',
        'Other',
      ];
    }
    if (lower.contains('coolant')) {
      return const ['50/50 premix', 'Concentrate', 'Universal', 'OEM spec'];
    }
    if (lower.contains('brake pad')) {
      return const ['Ceramic', 'Semi-metallic', 'Organic'];
    }
    if (lower.contains('wiper')) {
      return const ['Driver side', 'Passenger side', 'Rear', 'Full set'];
    }
    return const [];
  }
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

Color thresholdColor(int milesRemaining) {
  if (milesRemaining <= 300) return const Color(0xFFE3342F);
  if (milesRemaining <= 600) return const Color(0xFFFF7A00);
  if (milesRemaining <= 900) return const Color(0xFFFFC928);
  return const Color(0xFF20B24A);
}
