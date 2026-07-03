import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserSpanishReleaseOneSuite extends QaSuite {
  const WorkSupplyParserSpanishReleaseOneSuite()
    : super('inventory.spanish_release_one');

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};
  static const _spanishSignalTokens = {
    'adaptador',
    'cable',
    'caja',
    'cinta',
    'codo',
    'conector',
    'conducto',
    'filtro',
    'tapon',
    'tubo',
    'valvula',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final warningsByTradeTier = <String, int>{};
    final missingSignalCounts = <String, int>{};
    final localeTermText = _localeTermSourceText();
    var checked = 0;

    for (final item in _releaseOneItems()) {
      checked += 6;
      final missing = _missingSpanishSignals(item, localeTermText);
      for (final signal in missing) {
        _increment(missingSignalCounts, signal);
      }
      if (missing.isEmpty) continue;
      _increment(warningsByTradeTier, '${item.trade}.${item.packTier.name}');
      failures.add(
        QaFailure(
          suite: name,
          id: 'spanish_release_one_gap:${item.id}',
          message:
              'Release-one residential item needs stronger Spanish parser coverage.',
          severity: QaSeverity.warning,
          expected:
              'Spanish aliases/receipt patterns plus US Spanish locale normalization signals',
          actual: '${item.path} / ${item.name}; missing=${missing.join(', ')}',
          suggestedFix:
              'Add es-US aliases, Spanish receipt abbreviations, unit/size variants, and review-safe conflict guards for this item family.',
          metadata: const {'triageCategory': QaFailureTriage.locale},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + _spanishSignalTokens.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scope':
            'Residential Plumbing, Electrical, and HVAC Core/Standard rows for es-US release-one readiness.',
        'localeTermSourcePresent': localeTermText.isNotEmpty,
        'warningsByTradeTier': _topCounts(warningsByTradeTier),
        'topMissingSpanishSignals': _topCounts(missingSignalCounts),
        'spanishSignalTokens': _spanishSignalTokens.toList()..sort(),
      },
    );
  }

  Iterable<WorkSupplyItem> _releaseOneItems() sync* {
    for (final item in workSupplyCatalogItems) {
      if (!_priorityTrades.contains(item.trade)) continue;
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        continue;
      }
      if (item.packTier != WorkSupplyPackTier.core &&
          item.packTier != WorkSupplyPackTier.standard) {
        continue;
      }
      yield item;
    }
  }

  List<String> _missingSpanishSignals(WorkSupplyItem item, String termText) {
    final values = [
      ...item.aliases,
      ...item.intelligence.receiptPatterns,
      ...item.intelligence.attributeTokens,
    ].map(_normalize).toList();
    final haystack = values.join(' ');
    final missing = <String>[];
    if (!_spanishSignalTokens.any(haystack.contains)) {
      missing.add('spanishAliasOrReceiptToken');
    }
    if (!haystack.contains(' pulg') &&
        !haystack.contains('mm') &&
        !haystack.contains('metro') &&
        !RegExp(r'\b\d+/\d+\b').hasMatch(haystack)) {
      missing.add('spanishSizeOrUnitVariant');
    }
    if (!haystack.contains('es-us') &&
        !haystack.contains('spanish') &&
        !haystack.contains('espanol')) {
      missing.add('localePackSignal');
    }
    if (item.intelligence.negativeMatchTokens.isEmpty) {
      missing.add('negativeMatchTokens');
    }
    if (item.intelligence.highImportanceTokens.isEmpty) {
      missing.add('highImportanceTokens');
    }
    if (termText.isEmpty) {
      missing.add('spanishLocaleTermSource');
    } else if (!_spanishSignalTokens.any(termText.contains)) {
      missing.add('spanishLocaleTermCoverage');
    }
    return missing;
  }
}

String _localeTermSourceText() {
  final file = File(
    'lib/screens/work_supplies/data/work_supply_receipt_parser_locale_terms.dart',
  );
  if (!file.existsSync()) return '';
  return _normalize(file.readAsStringSync());
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');
}

void _increment(Map<String, int> counts, String key) {
  counts.update(key, (count) => count + 1, ifAbsent: () => 1);
}

List<Map<String, Object?>> _topCounts(
  Map<String, int> counts, {
  int limit = 12,
}) {
  final entries = counts.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  return [
    for (final entry in entries.take(limit))
      {'name': entry.key, 'count': entry.value},
  ];
}
