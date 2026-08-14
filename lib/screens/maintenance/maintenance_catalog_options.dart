part of 'maintenance_models.dart';

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
    if (lower.contains('water pump')) {
      return const ['Mechanical', 'Electric'];
    }
    if (lower.contains('thermostat')) {
      return const ['160°F', '180°F', '192°F', '195°F', '203°F', 'Other'];
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
    if (lower.contains('brake pad') ||
        lower.contains('brake rotor') ||
        lower.contains('brake shoe') ||
        lower.contains('brake drum') ||
        lower.contains('brake caliper') ||
        lower.contains('brake hose') ||
        lower.contains('brake line')) {
      return const ['Front', 'Rear', 'Front and rear'];
    }
    if (lower.contains('air filter')) {
      return const ['Standard', 'Premium', 'HEPA', 'Carbon'];
    }
    if (lower.contains('spark')) {
      if (lower.contains('wire')) return const ['Standard', 'Performance'];
      return const ['Copper', 'Platinum', 'Double platinum', 'Iridium'];
    }
    if (lower.contains('ignition coil')) {
      return const ['Individual coil', 'Coil pack', 'Coil-on-plug'];
    }
    if (lower.contains('alternator') || lower == 'starter') {
      return const ['New', 'Remanufactured'];
    }
    if (lower.contains('fuel system')) {
      return const [
        'Fuel injector cleaning',
        'Induction cleaning',
        'Throttle body cleaning',
      ];
    }
    if (lower.contains('air conditioning')) {
      return const [
        'Performance check',
        'Refrigerant recharge',
        'Evacuation and recharge',
      ];
    }
    if (lower.contains('shock') ||
        lower.contains('strut') ||
        lower.contains('ball joint') ||
        lower.contains('tie rod') ||
        lower.contains('sway bar') ||
        lower.contains('wheel bearing') ||
        lower.contains('cv axle')) {
      return const ['Front', 'Rear', 'Front and rear'];
    }
    if (lower.contains('engine mount')) {
      return const ['Rubber', 'Hydraulic', 'Active', 'Other'];
    }
    if (lower.contains('wheel alignment')) {
      return const ['Four-wheel', 'Front-end'];
    }
    if (lower.contains('wheel balancing')) {
      return const ['Road force', 'Computerized', 'Standard'];
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
    if (lower.contains('brake pad') || lower.contains('brake shoe')) {
      return const ['Ceramic', 'Semi-metallic', 'Organic'];
    }
    if (lower.contains('brake rotor') || lower.contains('brake drum')) {
      return const ['Replacement', 'Resurfaced'];
    }
    if (lower.contains('brake caliper')) {
      return const ['Replacement', 'Rebuilt'];
    }
    if (lower.contains('wiper')) {
      return const ['Driver side', 'Passenger side', 'Rear', 'Full set'];
    }
    if (lower.contains('air conditioning')) {
      return const ['R-134a', 'R-1234yf', 'Other'];
    }
    if (lower.contains('shock') || lower.contains('strut')) {
      return const ['Shocks', 'Struts', 'Shocks and struts'];
    }
    if (lower.contains('ball joint')) return const ['Upper', 'Lower'];
    if (lower.contains('tie rod')) return const ['Inner', 'Outer'];
    if (lower.contains('wheel bearing')) {
      return const ['Bearing', 'Hub assembly'];
    }
    if (lower.contains('cv axle')) return const ['New', 'Remanufactured'];
    return const [];
  }
}
