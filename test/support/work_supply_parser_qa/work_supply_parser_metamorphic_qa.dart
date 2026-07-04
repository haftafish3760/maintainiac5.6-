import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMetamorphicSuite extends QaSuite {
  const WorkSupplyParserMetamorphicSuite()
    : super('inventory.metamorphic_variants');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures()
        .where((fixture) => !fixture.expectUnknown)
        .toList(growable: false);
    final variants = <_VariantCase>[];
    for (final fixture in fixtures) {
      variants.addAll(_variantsFor(fixture));
    }

    final uniqueLines = <String>{};
    for (final variant in variants) {
      final normalized = _normalize(variant.line);
      if (!uniqueLines.add(normalized)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'duplicate_variant:${variant.fixture.id}:$normalized',
            message: 'Metamorphic variant generator produced duplicate line.',
            severity: QaSeverity.warning,
            actual: variant.line,
            suggestedFix:
                'Adjust variation generation so every case adds coverage.',
          ),
        );
      }
    }

    if (!context.isFullProfile) {
      return timer.finish(
        suite: name,
        checked: variants.length,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'variant-build-smoke',
          'generationSeed': 'fixture-order-v1',
          'variantKinds': _variantKinds,
          'fixtureCount': fixtures.length,
          'uniqueVariants': uniqueLines.length,
          'note': 'Parser assertions run in full/release profiles.',
        },
      );
    }

    for (final variant in variants.take(context.maxGeneratedCases)) {
      final match = matchReceiptLineToCatalog(
        variant.line,
        tradeScope: variant.fixture.tradeScope,
        localePackId: variant.fixture.localePackId,
        maxCandidates: 24,
      );
      if (match == null) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'variant_missing:${variant.fixture.id}:${variant.kind}',
            message: 'Metamorphic variant lost a known-good match.',
            expected: variant.fixture.expectedSummary,
            actual: context.redactor(variant.line),
            suggestedFix:
                'Strengthen normalization for case, spacing, punctuation, quantity, or price noise.',
          ),
        );
        continue;
      }
      if (variant.fixture.expectedTrade.isNotEmpty &&
          match.item.trade != variant.fixture.expectedTrade) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'variant_wrong_trade:${variant.fixture.id}:${variant.kind}',
            message: 'Metamorphic variant changed the matched trade.',
            expected: variant.fixture.expectedTrade,
            actual: '${match.item.trade} / ${match.item.name}',
            suggestedFix:
                'Make trade scoring stable across harmless receipt formatting changes.',
          ),
        );
      }
      if (variant.fixture.expectedNameContains.isNotEmpty &&
          !match.item.name.toLowerCase().contains(
            variant.fixture.expectedNameContains.toLowerCase(),
          )) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'variant_wrong_item:${variant.fixture.id}:${variant.kind}',
            message: 'Metamorphic variant changed the expected item family.',
            expected: variant.fixture.expectedNameContains,
            actual: match.item.name,
            suggestedFix:
                'Add alias/token normalization that survives receipt formatting changes.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: variants.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'generationSeed': 'fixture-order-v1',
        'variantKinds': _variantKinds,
        'fixtureCount': fixtures.length,
        'uniqueVariants': uniqueLines.length,
        'parserCaseLimit': context.maxGeneratedCases,
      },
    );
  }

  List<_VariantCase> _variantsFor(_Fixture fixture) {
    final raw = fixture.rawLine.trim();
    final compact = raw.replaceAll(RegExp(r'\s+'), ' ');
    final noPunctuation = compact.replaceAll(RegExp(r'[.,;:]'), ' ');
    final spacedSize = compact.replaceAllMapped(
      RegExp(r'(\d)/(\d)'),
      (match) => '${match.group(1)} / ${match.group(2)}',
    );
    final unitOrder = _moveFirstSizeToEnd(compact);
    return _uniqueVariants([
      _VariantCase(fixture, 'uppercase', compact.toUpperCase()),
      _VariantCase(fixture, 'lowercase', compact.toLowerCase()),
      _VariantCase(fixture, 'extra_spacing', compact.replaceAll(' ', '   ')),
      _VariantCase(fixture, 'no_punctuation', noPunctuation),
      _VariantCase(fixture, 'pluralized_family', _pluralizeFamily(compact)),
      _VariantCase(fixture, 'quantity_prefix', '2 @ $compact'),
      _VariantCase(fixture, 'pack_count_prefix', '10PK $compact'),
      _VariantCase(fixture, 'price_suffix', '$compact  \$12.34'),
      _VariantCase(fixture, 'locale_decimal_price_suffix', '$compact  12,34'),
      _VariantCase(fixture, 'sku_prefix', 'SKU 123456 $compact'),
      _VariantCase(
        fixture,
        'merchant_prefix_home_depot',
        'HOME DEPOT $compact',
      ),
      _VariantCase(fixture, 'merchant_prefix_lowes', 'LOWES $compact'),
      _VariantCase(fixture, 'spaced_fraction', spacedSize),
      _VariantCase(fixture, 'unit_order_size_last', unitOrder),
      _VariantCase(fixture, 'hyphenated_fraction', _hyphenateFraction(compact)),
      _VariantCase(fixture, 'slashless_fraction', _slashlessFraction(compact)),
      _VariantCase(fixture, 'store_line_number_prefix', 'A12 $compact'),
      _VariantCase(fixture, 'receipt_qty_each_suffix', '$compact EA'),
      _VariantCase(fixture, 'merchant_abbrev_hd', 'HD $compact'),
      _VariantCase(fixture, 'merchant_abbrev_thd', 'THD $compact'),
      _VariantCase(fixture, 'merchant_abbrev_lws', 'LWS $compact'),
      ..._abbreviationVariants(fixture, compact),
      ..._crossTradeOverlapVariants(fixture, compact),
    ]);
  }

  List<_VariantCase> _uniqueVariants(List<_VariantCase> variants) {
    final seen = <String>{};
    final unique = <_VariantCase>[];
    for (final variant in variants) {
      if (seen.add('${variant.fixture.id}:${_normalize(variant.line)}')) {
        unique.add(variant);
      }
    }
    return unique;
  }

  static const _variantKinds = [
    'uppercase',
    'lowercase',
    'extra_spacing',
    'no_punctuation',
    'pluralized_family',
    'quantity_prefix',
    'pack_count_prefix',
    'price_suffix',
    'locale_decimal_price_suffix',
    'sku_prefix',
    'merchant_prefix_home_depot',
    'merchant_prefix_lowes',
    'spaced_fraction',
    'unit_order_size_last',
    'hyphenated_fraction',
    'slashless_fraction',
    'store_line_number_prefix',
    'receipt_qty_each_suffix',
    'merchant_abbrev_hd',
    'merchant_abbrev_thd',
    'merchant_abbrev_lws',
    'abbrev_coupling',
    'abbrev_elbow',
    'abbrev_copper',
    'abbrev_condensate',
    'cross_trade_pvc_conduit_neighbor',
    'cross_trade_hvac_condensate_neighbor',
    'cross_trade_copper_line_set_neighbor',
    'mixed_trade_receipt_neighbor',
  ];
}

List<_VariantCase> _abbreviationVariants(_Fixture fixture, String value) {
  final variants = <_VariantCase>[];
  final replacements = <String, String>{
    r'\bCOUPLING\b': 'CPLG',
    r'\bCOUPLINGS\b': 'CPLGS',
    r'\bELBOW\b': 'ELL',
    r'\bELBOWS\b': 'ELLS',
    r'\bCOPPER\b': 'CU',
    r'\bCONDENSATE\b': 'COND',
  };
  for (final entry in replacements.entries) {
    final updated = value.replaceAll(
      RegExp(entry.key, caseSensitive: false),
      entry.value,
    );
    if (updated != value) {
      variants.add(
        _VariantCase(fixture, 'abbrev_${entry.value.toLowerCase()}', updated),
      );
    }
  }
  return variants;
}

List<_VariantCase> _crossTradeOverlapVariants(_Fixture fixture, String value) {
  final upper = value.toUpperCase();
  final variants = <_VariantCase>[];
  if (upper.contains('PVC')) {
    variants.addAll([
      _VariantCase(
        fixture,
        'cross_trade_pvc_conduit_neighbor',
        '$value 12/2 WIRE COND',
      ),
      _VariantCase(
        fixture,
        'cross_trade_hvac_condensate_neighbor',
        '$value CONDENSATE DRAIN PUMP',
      ),
      _VariantCase(
        fixture,
        'mixed_trade_receipt_neighbor',
        '$value FOIL TAPE 12/2 WIRE PEX TEE',
      ),
    ]);
  }
  if (upper.contains('COPPER') || RegExp(r'\bCU\b').hasMatch(upper)) {
    variants.add(
      _VariantCase(
        fixture,
        'cross_trade_copper_line_set_neighbor',
        '$value LINE SET INSULATION FILTER DRIER',
      ),
    );
  }
  return variants;
}

String _pluralizeFamily(String value) {
  final tokens = value.split(RegExp(r'\s+'));
  for (var index = tokens.length - 1; index >= 0; index--) {
    final token = tokens[index];
    if (!RegExp(r'^[A-Za-z]{3,}$').hasMatch(token)) continue;
    if (token.toLowerCase().endsWith('s')) return value;
    final copy = [...tokens];
    copy[index] = '${token}s';
    return copy.join(' ');
  }
  return value;
}

String _moveFirstSizeToEnd(String value) {
  final match = RegExp(r'\b\d(?:-\d+/\d+|/\d+)?\b').firstMatch(value);
  if (match == null) return value;
  final size = match.group(0)!;
  final withoutSize = value
      .replaceFirst(size, '')
      .replaceAll(RegExp(r'\s+'), ' ');
  return '$withoutSize $size'.trim();
}

String _hyphenateFraction(String value) {
  return value.replaceAllMapped(
    RegExp(r'\b(\d)/(\d)\b'),
    (match) => '${match.group(1)}-${match.group(2)}',
  );
}

String _slashlessFraction(String value) {
  return value.replaceAllMapped(
    RegExp(r'\b(\d)/(\d)\b'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
}

class _VariantCase {
  const _VariantCase(this.fixture, this.kind, this.line);

  final _Fixture fixture;
  final String kind;
  final String line;
}

class _Fixture {
  const _Fixture({
    required this.id,
    required this.rawLine,
    this.expectedTrade = '',
    this.expectedNameContains = '',
    this.tradeScope,
    this.localePackId = '',
    this.expectUnknown = false,
  });

  final String id;
  final String rawLine;
  final String expectedTrade;
  final String expectedNameContains;
  final String? tradeScope;
  final String localePackId;
  final bool expectUnknown;

  String get expectedSummary {
    return [
      if (expectedTrade.isNotEmpty) 'trade=$expectedTrade',
      if (expectedNameContains.isNotEmpty)
        'name contains "$expectedNameContains"',
    ].join(', ');
  }

  static _Fixture fromJson(Map<String, Object?> json) {
    return _Fixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      rawLine: json['rawLine'] as String? ?? '',
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
      tradeScope: json['tradeScope'] as String?,
      localePackId: json['localePackId'] as String? ?? '',
      expectUnknown: json['expectUnknown'] as bool? ?? false,
    );
  }
}

List<_Fixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _Fixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/$.\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
