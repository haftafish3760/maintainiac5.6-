import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main(List<String> args) {
  final count = _countFrom(args);
  if (count < 1) throw ArgumentError.value(count, 'count', 'must be positive');
  final items = <WorkSupplyItem>[
    for (var index = 0; index < count ~/ 2; index++) _decoy(index),
    _target,
    for (var index = count ~/ 2; index < count - 1; index++) _decoy(index),
  ];
  final coldTimer = Stopwatch()..start();
  final cold = receiptCatalogIndexParityForQa(
    catalogItems: items,
    requiredNameParts: const ['push-fit', 'supply', 'stop'],
    tradeScope: 'Plumbing',
  );
  coldTimer.stop();
  final warmTimer = Stopwatch()..start();
  final warm = receiptCatalogIndexParityForQa(
    catalogItems: items,
    requiredNameParts: const ['push-fit', 'supply', 'stop'],
    tradeScope: 'Plumbing',
  );
  warmTimer.stop();
  final parity =
      _same(cold.indexedIds, cold.fullScanIds) &&
      _same(warm.indexedIds, warm.fullScanIds) &&
      _same(cold.indexedIds, warm.indexedIds) &&
      cold.indexedIds.length == 1 &&
      cold.indexedIds.single == _target.id;
  final parserTimer = Stopwatch()..start();
  final parserMatch = matchReceiptLineToCatalog(
    'HD 1/2 X 3/8 PUSH ANGLE STOP',
    catalogItems: items,
    tradeScope: 'Plumbing',
    maxCandidates: 80,
  );
  parserTimer.stop();
  final parserCorrect = parserMatch?.item.id == _target.id;
  stdout.writeln(
    jsonEncode({
      'schema': 'maintainiac.inventory.plumbing_index_scale_probe.v1',
      'catalogItems': count,
      'parity': parity,
      'candidateCount': cold.indexedIds.length,
      'coldTotalMs': coldTimer.elapsedMilliseconds,
      'coldIndexedMicros': cold.indexedMicroseconds,
      'coldFullScanMs': cold.fullScanMicroseconds / 1000,
      'warmTotalMs': warmTimer.elapsedMilliseconds,
      'warmIndexedMicros': warm.indexedMicroseconds,
      'warmFullScanMs': warm.fullScanMicroseconds / 1000,
      'actualParserMs': parserTimer.elapsedMicroseconds / 1000,
      'actualParserCorrect': parserCorrect,
      'residentMemoryMiB': ProcessInfo.currentRss / (1024 * 1024),
    }),
  );
  if (!parity || !parserCorrect) exitCode = 1;
}

int _countFrom(List<String> args) {
  final value = args
      .where((arg) => arg.startsWith('--count='))
      .map((arg) => arg.substring('--count='.length))
      .firstOrNull;
  return int.tryParse(value ?? '') ?? 50000;
}

bool _same(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

const _target = WorkSupplyItem(
  id: 'PLUMBING-SCALE-TARGET',
  name: '1/2 x 3/8 in Push-Fit Supply Stop',
  trade: 'Plumbing',
  category: 'Fittings',
  system: 'Push-Fit',
  itemType: 'Supply Stop',
  variant: '1/2 x 3/8 in',
  unit: 'each',
  aliases: ['push fit angle stop', 'push supply shutoff'],
);

WorkSupplyItem _decoy(int index) {
  return WorkSupplyItem(
    id: 'PLUMBING-SCALE-$index',
    name: 'Synthetic Plumbing Inventory Item $index',
    trade: 'Plumbing',
    category: 'Scale QA',
    system: 'Synthetic',
    itemType: 'Decoy',
    variant: '$index unit',
    unit: 'each',
    aliases: const ['synthetic inventory decoy'],
  );
}
