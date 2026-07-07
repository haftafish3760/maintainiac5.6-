import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

class _GeneratedCoreReceipt {
  const _GeneratedCoreReceipt(this.line, this.item);

  final String line;
  final WorkSupplyItem item;
}

void main() {
  test(
    'plumbing US English core generated batch shard plan covers all cases',
    () {
      final allCases = _coreGeneratedReceipts(
        maxPerPath: 64,
      ).take(4000).toList();
      const shardSize = 250;
      final shardCount = (allCases.length / shardSize).ceil();
      final coveredIndexes = <int>{};

      for (var shard = 0; shard < shardCount; shard += 1) {
        final start = shard * shardSize;
        final end = (start + shardSize).clamp(0, allCases.length);
        expect(start, lessThan(allCases.length));
        expect(end, greaterThan(start));
        coveredIndexes.addAll(
          List.generate(end - start, (index) => start + index),
        );
      }

      expect(allCases.length, 3366);
      expect(shardCount, 14);
      expect(coveredIndexes.length, allCases.length);
      expect(coveredIndexes.first, 0);
      expect(coveredIndexes.last, allCases.length - 1);
    },
  );

  test('plumbing US English core generated batch gate', () {
    const shardStart = int.fromEnvironment(
      'PLUMBING_CORE_GATE_START',
      defaultValue: 0,
    );
    const shardLimit = int.fromEnvironment(
      'PLUMBING_CORE_GATE_LIMIT',
      defaultValue: 250,
    );
    const runFullGate = bool.fromEnvironment('PLUMBING_CORE_GATE_FULL');
    final allCases = _coreGeneratedReceipts(maxPerPath: 64).take(4000).toList();
    final cases = runFullGate
        ? allCases
        : allCases.skip(shardStart).take(shardLimit).toList();
    final failures = <String>[];
    final failureGroups = <String, int>{};

    for (final receipt in cases) {
      final match = matchReceiptLineToCatalog(
        receipt.line,
        tradeScope: 'Plumbing',
        maxCandidates: 120,
      );
      if (match == null) {
        _addFailure(
          failures,
          failureGroups,
          'noMatch',
          receipt,
          'no parser match',
        );
        continue;
      }

      final item = match.item;
      if (item.trade != 'Plumbing') {
        _addFailure(
          failures,
          failureGroups,
          'wrongTrade',
          receipt,
          '${item.trade} / ${item.name}',
        );
      }
      if (item.packTier != WorkSupplyPackTier.core) {
        _addFailure(
          failures,
          failureGroups,
          'wrongTier',
          receipt,
          '${item.packTier.name} / ${item.path} / ${item.name}',
        );
      }
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        _addFailure(
          failures,
          failureGroups,
          'missingResidential',
          receipt,
          '${item.path} / ${item.name}',
        );
      }
      if (match.confidenceLevel != ReceiptConfidenceLevel.good) {
        _addFailure(
          failures,
          failureGroups,
          'lowConfidence',
          receipt,
          '${match.confidenceLevel.name} / ${item.path} / ${item.name}',
        );
      }
      if (!_sameCoreFamily(receipt.item, item)) {
        _addFailure(
          failures,
          failureGroups,
          'wrongFamily',
          receipt,
          '${item.path} / ${item.name}',
        );
      }
    }

    // ignore: avoid_print
    print(
      'PLUMBING_CORE_BATCH cases=${cases.length} total=${allCases.length} '
      'start=${runFullGate ? 0 : shardStart} '
      'limit=${runFullGate ? allCases.length : shardLimit} '
      'full=$runFullGate failures=${failures.length}',
    );
    for (final entry in _topEntries(failureGroups, 12)) {
      // ignore: avoid_print
      print('PLUMBING_CORE_BATCH_GROUP ${entry.key}=${entry.value}');
    }
    for (final failure in failures.take(30)) {
      // ignore: avoid_print
      print('PLUMBING_CORE_BATCH_FAILURE $failure');
    }

    expect(failures, isEmpty, reason: failures.take(30).join('\n'));
  });
}

List<_GeneratedCoreReceipt> _coreGeneratedReceipts({required int maxPerPath}) {
  final byPath = <String, int>{};
  final cases = <_GeneratedCoreReceipt>[];
  final coreItems = workSupplyCatalogItems.where(
    (item) =>
        item.trade == 'Plumbing' &&
        item.packTier == WorkSupplyPackTier.core &&
        item.marketScopes.contains(WorkSupplyMarketScope.residential),
  );

  for (final item in coreItems) {
    final pathCount = byPath.update(
      item.path,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    if (pathCount > maxPerPath) continue;
    for (final line in _receiptLinesFor(item)) {
      cases.add(_GeneratedCoreReceipt(line, item));
    }
  }
  return cases;
}

List<String> _receiptLinesFor(WorkSupplyItem item) {
  final lines = <String>{
    'HD ${_receiptAbbrev(item.name)}',
    'LOWES ${_receiptAbbrev('${item.variant} ${item.system} ${item.itemType}')}',
    if (_specificAlias(item) case final alias?)
      'ACE ${_receiptAbbrev('${item.variant} $alias')}',
    for (final pattern in item.intelligence.receiptPatterns.take(2))
      'SUPPLY ${_receiptAbbrev(pattern)}',
  };
  return lines.where((line) => line.trim().length > 8).take(3).toList();
}

String _receiptAbbrev(String value) {
  return value
      .toUpperCase()
      .replaceAll(' SCHEDULE ', ' SCH ')
      .replaceAll(' FEMALE ', ' F ')
      .replaceAll(' MALE ', ' M ')
      .replaceAll(' ADAPTER', ' ADPT')
      .replaceAll(' COUPLING', ' CPLG')
      .replaceAll(' CONNECTOR', ' CONN')
      .replaceAll(' ELBOW', ' ELB')
      .replaceAll(' ELBOWS', ' ELBS')
      .replaceAll(' WATER HEATER', ' WTR HTR')
      .replaceAll(' DISHWASHER', ' DW')
      .replaceAll(RegExp(r'\bIN\b'), 'IN')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String? _specificAlias(WorkSupplyItem item) {
  final system = item.system.toLowerCase();
  final itemType = item.itemType.toLowerCase();
  for (final alias in item.aliases) {
    final normalized = alias.toLowerCase();
    if (normalized.length < 5) continue;
    if (_genericMaterialAlias(normalized)) continue;
    if (itemType.contains('reducers') && normalized.contains('coupling')) {
      continue;
    }
    if (itemType.contains('reducing couplings') &&
        normalized == 'copper reducer') {
      continue;
    }
    if (system == 'brass' &&
        itemType.contains('adapter') &&
        normalized == 'brass adapter') {
      continue;
    }
    if (system == 'brass' &&
        itemType.contains('compression') &&
        (normalized == 'compression fitting' ||
            normalized == 'brass compression fitting')) {
      continue;
    }
    if (itemType.contains('ball valves') && normalized == 'shutoff valve') {
      continue;
    }
    if (itemType.contains('sanitary tees') &&
        !(normalized.contains('san') || normalized.contains('tee'))) {
      continue;
    }
    if (normalized.contains(system.split(' ').first)) return alias;
    if (normalized.contains('pex') ||
        normalized.contains('pvc') ||
        normalized.contains('cpvc') ||
        normalized.contains('copper') ||
        normalized.contains('brass') ||
        normalized.contains('push') ||
        normalized.contains('dwv') ||
        normalized.contains('water heater') ||
        normalized.contains('dishwasher') ||
        normalized.contains('toilet') ||
        normalized.contains('faucet')) {
      return alias;
    }
  }
  return null;
}

bool _genericMaterialAlias(String alias) {
  return const {
    'pex',
    'pvc',
    'cpvc',
    'copper',
    'brass',
    'dwv',
    'push-fit',
    'push fit',
    'push to connect',
    'push connect',
    'sharkbite style',
  }.contains(alias);
}

bool _sameCoreFamily(WorkSupplyItem expected, WorkSupplyItem actual) {
  if (expected.id == actual.id) return true;
  if (_sameToiletSealProduct(expected, actual)) return true;
  if (expected.trade != actual.trade) return false;
  if (expected.category != actual.category) return false;
  if (expected.system != actual.system) return false;
  if (expected.itemType != actual.itemType) return false;
  final expectedSize = _leadingSize(expected.name);
  final actualSize = _leadingSize(actual.name);
  return expectedSize.isEmpty ||
      actualSize.isEmpty ||
      expectedSize == actualSize;
}

bool _sameToiletSealProduct(WorkSupplyItem expected, WorkSupplyItem actual) {
  if (expected.trade != 'Plumbing' || actual.trade != 'Plumbing') {
    return false;
  }
  final expectedType = expected.itemType.toLowerCase();
  final actualType = actual.itemType.toLowerCase();
  final sealTypes = {
    'closet seal detail',
    'toilet flange and seal detail',
    'wax rings',
  };
  if (!sealTypes.contains(expectedType) || !sealTypes.contains(actualType)) {
    return false;
  }
  final expectedVariant = _normalizedSealVariant(expected.variant);
  final actualVariant = _normalizedSealVariant(actual.variant);
  if (expectedVariant == actualVariant) return true;
  return expectedVariant.contains('wax free') &&
      actualVariant.contains('wax free');
}

String _normalizedSealVariant(String value) {
  return value
      .toLowerCase()
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _leadingSize(String value) {
  final match = RegExp(
    r'^(\d+(?:-\d/\d|/\d)?(?:\.\d+)?)\s*(?:in|x|\b)',
  ).firstMatch(value.toLowerCase());
  return match?.group(1) ?? '';
}

void _addFailure(
  List<String> failures,
  Map<String, int> groups,
  String group,
  _GeneratedCoreReceipt receipt,
  String details,
) {
  groups.update(group, (count) => count + 1, ifAbsent: () => 1);
  failures.add(
    '${receipt.line} -> $group -> ${receipt.item.path} / '
    '${receipt.item.name} -> $details',
  );
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
