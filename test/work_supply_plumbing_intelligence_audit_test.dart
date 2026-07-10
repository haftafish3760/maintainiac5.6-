import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';

void main() {
  test('plumbing intelligence review snapshot groups remaining gaps', () {
    final plumbingItems = workSupplyCatalogItems
        .where((item) => item.trade == 'Plumbing')
        .toList(growable: false);
    final reviewItems = plumbingItems
        .where((item) => item.intelligence.needsReview)
        .toList(growable: false);
    final bySystem = <String, int>{};
    final byReason = <String, int>{};

    for (final item in reviewItems) {
      bySystem.update(item.system, (count) => count + 1, ifAbsent: () => 1);
      final intelligence = item.intelligence;
      if (intelligence.material.isEmpty) {
        byReason.update(
          'missingMaterial',
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      if (intelligence.size.isEmpty) {
        byReason.update('missingSize', (count) => count + 1, ifAbsent: () => 1);
      }
      if (intelligence.shapeOrStyle.isEmpty) {
        byReason.update(
          'missingShape',
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    // ignore: avoid_print
    print(
      [
        'PLUMBING_INTELLIGENCE_REVIEW',
        'items=${plumbingItems.length}',
        'needsReview=${reviewItems.length}',
        'clear=${plumbingItems.length - reviewItems.length}',
        'reviewPercent=${(reviewItems.length / plumbingItems.length * 100).toStringAsFixed(1)}',
      ].join(' '),
    );
    for (final entry in _topEntries(byReason, 8)) {
      // ignore: avoid_print
      print('PLUMBING_REVIEW_REASON ${entry.key}=${entry.value}');
    }
    for (final entry in _topEntries(bySystem, 12)) {
      // ignore: avoid_print
      print('PLUMBING_REVIEW_SYSTEM "${entry.key}"=${entry.value}');
    }
    for (final system in _topEntries(bySystem, 5).map((entry) => entry.key)) {
      final samples = reviewItems
          .where((item) => item.system == system)
          .take(3)
          .map(
            (item) =>
                '${item.itemType} | ${item.variant} | ${_missingReasons(item)}',
          )
          .join(' || ');
      // ignore: avoid_print
      print('PLUMBING_REVIEW_SAMPLE "$system" $samples');
    }

    expect(plumbingItems, isNotEmpty);
    expect(reviewItems, isEmpty);
  });
}

List<MapEntry<String, int>> _topEntries(Map<String, int> values, int take) {
  final entries = values.entries.toList()
    ..sort((a, b) {
      final count = b.value.compareTo(a.value);
      if (count != 0) return count;
      return a.key.compareTo(b.key);
    });
  return entries.take(take).toList(growable: false);
}

String _missingReasons(dynamic item) {
  final intelligence = item.intelligence;
  return [
    if (intelligence.material.isEmpty) 'material',
    if (intelligence.size.isEmpty) 'size',
    if (intelligence.shapeOrStyle.isEmpty) 'shape',
  ].join(',');
}
