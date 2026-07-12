import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  final core = workSupplyCatalogItems
      .where(
        (item) =>
            item.trade == 'HVAC' && item.packTier == WorkSupplyPackTier.core,
      )
      .toList(growable: false);

  test('HVAC Core excludes professional and specialty truck categories', () {
    final drift = core.where((item) {
      final category = item.category.toLowerCase();
      return (category.startsWith('pro hvac') &&
              !item.name.toLowerCase().contains('service valve cap')) ||
          category.contains('rooftop and package unit') ||
          category.contains('hydronic and boiler');
    });
    expect(drift, isEmpty);
    expect(core.length, 1279);
  });

  test('HVAC Core metadata stays aligned with semantic tiering', () {
    final drift = core.where(
      (item) =>
          !item.intelligence.attributeTokens.contains('hvac-core') ||
          !item.intelligence.attributeTokens.contains('residential-service'),
    );
    expect(drift, isEmpty);
  });

  test('HVAC Core retains required residential service families', () {
    const requiredSignals = {
      'filters': ['pleated filter', 'furnace filter'],
      'controls': ['capacitor', 'contactor', 'thermostat'],
      'condensate': ['condensate', 'float switch'],
      'duct repair': ['duct', 'mastic', 'foil tape'],
      'ignition': ['ignitor', 'flame sensor'],
      'motors': ['blower motor', 'fan motor'],
    };
    for (final entry in requiredSignals.entries) {
      expect(
        core.any(
          (item) => _containsAny(
            '${item.name} ${item.system} ${item.itemType}'.toLowerCase(),
            entry.value,
          ),
        ),
        isTrue,
        reason: entry.key,
      );
    }
  });

  test('HVAC Core keeps common case filters and universal motors', () {
    expect(
      core.any(
        (item) =>
            item.itemType == 'Service Truck Filter Case Stock' &&
            item.variant.contains('16 x 25 x 1') &&
            item.variant.contains('MERV 8'),
      ),
      isTrue,
    );
    expect(
      core.any(
        (item) =>
            item.name.contains('1/2 HP 1075 RPM Direct Drive Blower Motor'),
      ),
      isTrue,
    );
  });
}

bool _containsAny(String text, Iterable<String> signals) {
  return signals.any(text.contains);
}
