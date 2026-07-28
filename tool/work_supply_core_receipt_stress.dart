import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

const _trades = ['Plumbing', 'Electrical', 'HVAC'];

/// Runs a bounded Core-only synthetic receipt stress sample.
///
/// This is evidence for parser safety, not a real-receipt accuracy claim.
void main(List<String> args) {
  final perTrade = _intOption(args, 'per-trade', 50);
  final seed = _intOption(args, 'seed', 72726);
  final outputPath = _stringOption(
    args,
    'output',
    'build/qa/core_receipt_stress_seed_$seed.json',
  );
  final random = Random(seed);
  final rows = <Map<String, Object?>>[];

  for (final trade in _trades) {
    final core = workSupplyCatalogItems
        .where((item) =>
            item.trade == trade && item.packTier == WorkSupplyPackTier.core)
        .toList(growable: false);
    final sample = [...core]..shuffle(random);
    for (var index = 0; index < perTrade && index < sample.length; index++) {
      final item = sample[index];
      final fixture = _fixtureFor(item, index);
      final match = matchReceiptLineToCatalog(
        fixture.text,
        catalogItems: core,
        tradeScope: trade,
      );
      rows.add({
        'trade': trade,
        'id': item.id,
        'name': item.name,
        'variation': fixture.variation,
        'expectation': fixture.expectation,
        'receiptText': fixture.text,
        'result': match == null
            ? 'no_match'
            : match.item.id == item.id
                ? 'exact_match'
                : 'wrong_match',
        'matchedId': match?.item.id,
        'matchedName': match?.item.name,
        'confidence': match?.confidence,
      });
    }
  }

  final report = <String, Object?>{
    'report': 'maintainiac_core_receipt_stress',
    'scope': 'Core-only synthetic receipt stress test. Human review remains required.',
    'seed': seed,
    'perTrade': perTrade,
    'summary': _summary(rows),
    'items': rows,
  };
  final output = File(outputPath)..parent.createSync(recursive: true);
  output.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln(jsonEncode(report['summary']));
  stdout.writeln('report=$outputPath');
}

_SyntheticFixture _fixtureFor(WorkSupplyItem item, int index) {
  final canonical = item.name.trim();
  switch (index % 4) {
    case 0:
      return _SyntheticFixture('canonical', 'exact_id', canonical);
    case 1:
      return _SyntheticFixture(
        'upper_punctuation_stripped',
        'exact_id',
        canonical.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), ' ').trim(),
      );
    case 2:
      final alias = item.aliases.isEmpty ? canonical : item.aliases.first;
      return _SyntheticFixture('catalog_alias', 'review_required', alias.trim());
    default:
      final pattern = item.intelligence.receiptPatterns.isEmpty
          ? canonical
          : item.intelligence.receiptPatterns.first;
      return _SyntheticFixture('receipt_pattern', 'exact_id', pattern);
  }
}

Map<String, Object?> _summary(List<Map<String, Object?>> rows) {
  Map<String, Object?> summarize(Iterable<Map<String, Object?>> input) {
    final values = input.toList(growable: false);
    final strict = values
        .where((row) => row['expectation'] == 'exact_id')
        .toList(growable: false);
    final aliases = values
        .where((row) => row['expectation'] == 'review_required')
        .toList(growable: false);
    final strictExact = strict.where((row) => row['result'] == 'exact_match').length;
    return {
      'checked': values.length,
      'exactMatches': values.where((row) => row['result'] == 'exact_match').length,
      'wrongMatches': values.where((row) => row['result'] == 'wrong_match').length,
      'noMatches': values.where((row) => row['result'] == 'no_match').length,
      'strictExpectedIdChecked': strict.length,
      'strictExpectedIdExact': strictExact,
      'strictExpectedIdRate': strict.isEmpty ? 0 : strictExact / strict.length,
      'ambiguousAliasChecked': aliases.length,
      'ambiguousAliasWrongMatches': aliases
          .where((row) => row['result'] == 'wrong_match')
          .length,
    };
  }

  return {
    ...summarize(rows),
    'byTrade': {
      for (final trade in _trades)
        trade: summarize(rows.where((row) => row['trade'] == trade)),
    },
  };
}

int _intOption(List<String> args, String name, int fallback) {
  return int.tryParse(_stringOption(args, name, '')) ?? fallback;
}

String _stringOption(List<String> args, String name, String fallback) {
  final prefix = '--$name=';
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return fallback;
}

class _SyntheticFixture {
  const _SyntheticFixture(this.variation, this.expectation, this.text);

  final String variation;
  final String expectation;
  final String text;
}
