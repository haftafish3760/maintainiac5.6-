import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

void main(List<String> args) {
  final count = _argumentInt(args, 'count', 50000);
  final trade = _argument(args, 'trade', 'Plumbing');
  if (count < 1) throw ArgumentError.value(count, 'count', 'must be positive');
  final probe = _probes[trade.toLowerCase()];
  if (probe == null) {
    throw ArgumentError.value(
      trade,
      'trade',
      'must be Plumbing, Electrical, or HVAC',
    );
  }
  final items = <WorkSupplyItem>[
    for (var index = 0; index < count ~/ 2; index++) _decoy(probe.trade, index),
    probe.target,
    for (var index = count ~/ 2; index < count - 1; index++)
      _decoy(probe.trade, index),
  ];
  final coldTimer = Stopwatch()..start();
  final cold = receiptCatalogIndexParityForQa(
    catalogItems: items,
    requiredNameParts: probe.requiredNameParts,
    tradeScope: probe.trade,
  );
  coldTimer.stop();
  final warmTimer = Stopwatch()..start();
  final warm = receiptCatalogIndexParityForQa(
    catalogItems: items,
    requiredNameParts: probe.requiredNameParts,
    tradeScope: probe.trade,
  );
  warmTimer.stop();
  final parity =
      _same(cold.indexedIds, cold.fullScanIds) &&
      _same(warm.indexedIds, warm.fullScanIds) &&
      _same(cold.indexedIds, warm.indexedIds) &&
      cold.indexedIds.length == 1 &&
      cold.indexedIds.single == probe.target.id;
  final coldParserTimer = Stopwatch()..start();
  final coldMatch = matchReceiptLineToCatalog(
    probe.receiptLine,
    catalogItems: items,
    tradeScope: probe.trade,
    maxCandidates: 80,
  );
  coldParserTimer.stop();
  final warmParserTimer = Stopwatch()..start();
  final warmMatch = matchReceiptLineToCatalog(
    probe.receiptLine,
    catalogItems: items,
    tradeScope: probe.trade,
    maxCandidates: 80,
  );
  warmParserTimer.stop();
  final parserCorrect =
      coldMatch?.item.id == probe.target.id &&
      warmMatch?.item.id == probe.target.id;
  stdout.writeln(
    jsonEncode({
      'schema': 'maintainiac.inventory.peh_index_scale_probe.v1',
      'trade': probe.trade,
      'catalogItems': count,
      'parity': parity,
      'candidateCount': cold.indexedIds.length,
      'coldTotalMs': coldTimer.elapsedMilliseconds,
      'coldIndexedMicros': cold.indexedMicroseconds,
      'coldFullScanMs': cold.fullScanMicroseconds / 1000,
      'warmTotalMs': warmTimer.elapsedMilliseconds,
      'warmIndexedMicros': warm.indexedMicroseconds,
      'warmFullScanMs': warm.fullScanMicroseconds / 1000,
      'actualParserColdMs': coldParserTimer.elapsedMicroseconds / 1000,
      'actualParserWarmMs': warmParserTimer.elapsedMicroseconds / 1000,
      'actualParserCorrect': parserCorrect,
      'residentMemoryMiB': ProcessInfo.currentRss / (1024 * 1024),
    }),
  );
  if (!parity || !parserCorrect) exitCode = 1;
}

String _argument(List<String> args, String name, String fallback) {
  final prefix = '--$name=';
  return args
          .where((argument) => argument.startsWith(prefix))
          .map((argument) => argument.substring(prefix.length))
          .firstOrNull ??
      fallback;
}

int _argumentInt(List<String> args, String name, int fallback) {
  return int.tryParse(_argument(args, name, '$fallback')) ?? fallback;
}

bool _same(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

WorkSupplyItem _decoy(String trade, int index) => WorkSupplyItem(
  id: '${trade.toUpperCase()}-SCALE-$index',
  name: 'Synthetic $trade Inventory Item $index',
  trade: trade,
  category: 'Scale QA',
  system: 'Synthetic',
  itemType: 'Decoy',
  variant: '$index unit',
  unit: 'each',
  aliases: const ['synthetic inventory decoy'],
);

class _Probe {
  const _Probe({
    required this.trade,
    required this.requiredNameParts,
    required this.receiptLine,
    required this.target,
  });

  final String trade;
  final List<String> requiredNameParts;
  final String receiptLine;
  final WorkSupplyItem target;
}

const _probes = <String, _Probe>{
  'plumbing': _Probe(
    trade: 'Plumbing',
    requiredNameParts: ['push-fit', 'supply', 'stop'],
    receiptLine: 'HD 1/2 X 3/8 PUSH ANGLE STOP',
    target: WorkSupplyItem(
      id: 'PLUMBING-SCALE-TARGET',
      name: '1/2 x 3/8 in Push-Fit Supply Stop',
      trade: 'Plumbing',
      category: 'Fittings',
      system: 'Push-Fit',
      itemType: 'Supply Stop',
      variant: '1/2 x 3/8 in',
      unit: 'each',
      aliases: ['push fit angle stop', 'push supply shutoff'],
    ),
  ),
  'electrical': _Probe(
    trade: 'Electrical',
    requiredNameParts: ['gfci', 'receptacle'],
    receiptLine: 'HD 20A GFCI RECEPTACLE WHITE',
    target: WorkSupplyItem(
      id: 'ELECTRICAL-SCALE-TARGET',
      name: '20 Amp GFCI Receptacle White',
      trade: 'Electrical',
      category: 'Devices',
      system: 'Receptacles',
      itemType: 'GFCI Receptacle',
      variant: '20 Amp White',
      unit: 'each',
      aliases: ['20a gfi outlet white', 'ground fault receptacle'],
    ),
  ),
  'hvac': _Probe(
    trade: 'HVAC',
    requiredNameParts: ['dual', 'run', 'capacitor'],
    receiptLine: 'SUPPLY 45/5 MFD DUAL RUN CAPACITOR 440V',
    target: WorkSupplyItem(
      id: 'HVAC-SCALE-TARGET',
      name: '45/5 MFD Dual Run Capacitor 440V',
      trade: 'HVAC',
      category: 'Controls and Electrical',
      system: 'Capacitors and Contactors',
      itemType: 'Dual Run Capacitors',
      variant: '45/5 MFD 440V',
      unit: 'each',
      aliases: ['45 5 dual cap', 'dual run capacitor'],
    ),
  ),
};
