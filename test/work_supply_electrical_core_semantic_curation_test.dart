import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  final electrical = workSupplyCatalogItems
      .where((item) => item.trade == 'Electrical')
      .toList(growable: false);
  final core = electrical
      .where((item) => item.packTier == WorkSupplyPackTier.core)
      .toList(growable: false);

  test('Electrical Core excludes broad wall-plate matrices', () {
    final drift = core.where((item) {
      if (!item.itemType.toLowerCase().contains('wall plate')) return false;
      final variant = item.variant.toLowerCase();
      return RegExp(r'\b[4-6]\s+gang\b').hasMatch(variant) ||
          _containsAny(variant, const [' gray', ' black', ' brown']) ||
          (item.itemType == 'Bulk Covers and Wall Plates' &&
              !variant.contains('nylon'));
    });
    expect(drift, isEmpty);
    expect(
      core.any(
        (item) =>
            item.itemType == 'Expanded Wall Plates' &&
            item.variant == '1 Gang Toggle White',
      ),
      isTrue,
    );
  });

  test('Electrical Core excludes long or uncommon THHN rolls', () {
    final thhnCore = core.where(
      (item) => item.itemType == 'Expanded THHN Copper Wire Rolls',
    );
    expect(thhnCore, isNotEmpty);
    expect(
      thhnCore.where(
        (item) =>
            _containsAny(item.variant.toLowerCase(), const [
              '250 ft',
              '500 ft',
            ]) ||
            !_containsAny(item.variant.toLowerCase(), const [
              'black',
              'white',
              'red',
              'green',
            ]),
      ),
      isEmpty,
    );
  });

  test('Electrical Core keeps exact everyday raceway sizes', () {
    final flexible = core.where(
      (item) => item.itemType == 'Bulk Flexible Raceway',
    );
    expect(flexible, isNotEmpty);
    expect(
      flexible.where(
        (item) => RegExp(
          r'(?<![0-9/-])(?:1-1/4|1-1/2|2)\s+in\b',
        ).hasMatch(item.variant),
      ),
      isEmpty,
    );

    final bodies = core.where(
      (item) => item.itemType == 'Expanded Conduit Bodies and Covers',
    );
    expect(bodies, isNotEmpty);
    expect(
      bodies.where(
        (item) => !RegExp(
          r'\blb body\b',
          caseSensitive: false,
        ).hasMatch(item.variant),
      ),
      isEmpty,
    );
  });

  test('Electrical Core keeps only common photocell variants', () {
    final photocells = core.where(
      (item) => item.itemType == 'Bulk Specialty Controls',
    );
    expect(photocells, isNotEmpty);
    expect(
      photocells.where((item) {
        final variant = item.variant.toLowerCase();
        return !variant.contains('photocell') ||
            !variant.contains('120v') ||
            !_containsAny(variant, const ['15 amp', '20 amp']);
      }),
      isEmpty,
    );
  });

  test('Electrical Core retains every required residential family', () {
    const requiredSignals = {
      'wire': ['nm-b', 'thhn'],
      'devices': ['receptacle', 'switch'],
      'breakers': ['breaker'],
      'boxes': ['box'],
      'raceway': ['emt', 'pvc electrical'],
      'termination': ['wire connector', 'grounding'],
      'safety': ['gfci', 'smoke alarm'],
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
}

bool _containsAny(String text, Iterable<String> signals) {
  return signals.any(text.contains);
}
