import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPropertySuite extends QaSuite {
  const WorkSupplyParserPropertySuite() : super('inventory.property_cases');

  static const _sizes = ['1/2', '3/4', '1', '1-1/2', '2'];
  static const _dangerousFamilies = [
    'PVC',
    'TAPE',
    'FILTER',
    'BOX',
    'ADAPTER',
    'COUPLING',
    'ELBOW',
    'TEE',
    'PIPE',
    'WIRE',
    'CONDUIT',
    'VALVE',
  ];
  static const _modifiers = [
    '',
    ' SCH40',
    ' COND',
    ' ELEC',
    ' FOIL',
    ' WATER',
    ' BLACK',
    ' WHITE',
  ];
  static const _merchants = ['HD', 'LOWES', 'ACE', 'LOCAL'];
  static const _locales = ['en-US', 'es-US'];
  static const _requiredScenarioTypes = {
    'trade_context',
    'merchant_context',
    'locale',
    'package_quantity',
    'return_line',
    'discount_line',
    'tax_line',
    'mixed_trade_job',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final cases = _buildCases(context.maxGeneratedCases);
    final unique = <String>{};
    final scenarioTypes = <String>{};
    for (final generated in cases) {
      scenarioTypes.add(generated.scenarioType);
      final normalized = _normalize(generated.line);
      if (!unique.add(normalized)) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'duplicate_property_case:$normalized',
            message: 'Property generator produced duplicate receipt line.',
            severity: QaSeverity.warning,
            actual: generated.line,
            suggestedFix:
                'Adjust grammar pieces so generated cases add unique coverage.',
          ),
        );
      }
    }
    for (final scenarioType in _requiredScenarioTypes) {
      if (scenarioTypes.contains(scenarioType)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_property_scenario:$scenarioType',
          message: 'Property generator is missing a required parser scenario.',
          expected: _requiredScenarioTypes.join(', '),
          actual: scenarioTypes.join(', '),
          suggestedFix:
              'Seed broad property families before nested grammar cases so smoke runs cover each major parser risk.',
        ),
      );
    }

    if (!context.isFullProfile) {
      return timer.finish(
        suite: name,
        checked: cases.length,
        failures: failures,
        maxFailures: context.maxFailuresPerSuite,
        metrics: {
          'mode': 'property-build-smoke',
          'requestedLimit': context.maxGeneratedCases,
          'generationSeed': 'property-grammar-v1',
          'grammarDimensions': _grammarDimensions,
          'scenarioTypes': scenarioTypes.toList(growable: false)..sort(),
          'uniqueCases': unique.length,
          'parserCalls': 0,
          'note': 'Parser invariants run in full/release profiles.',
        },
      );
    }

    for (final generated in cases) {
      final match = matchReceiptLineToCatalog(
        generated.line,
        maxCandidates: 24,
      );
      if (generated.mustRequireReview &&
          match != null &&
          match.confidence >= .82) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'property_false_confident:${_normalize(generated.line)}',
            message: 'Generated risky line produced confident single match.',
            expected: 'unknown, ambiguous, or needs review',
            actual:
                '${match.item.trade} / ${match.item.name} confidence=${match.confidence}',
            suggestedFix:
                'Add ambiguity ranking, negative-match rules, or lower confidence for generic families.',
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: cases.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requestedLimit': context.maxGeneratedCases,
        'generationSeed': 'property-grammar-v1',
        'grammarDimensions': _grammarDimensions,
        'scenarioTypes': scenarioTypes.toList(growable: false)..sort(),
        'uniqueCases': unique.length,
      },
    );
  }

  List<_PropertyCase> _buildCases(int limit) {
    final cases = <_PropertyCase>[..._seedScenarioCases()];
    for (final merchant in _merchants) {
      for (final size in _sizes) {
        for (final family in _dangerousFamilies) {
          for (final modifier in _modifiers) {
            final line = '$merchant $size $family$modifier'.trim();
            cases.add(
              _PropertyCase(
                line,
                scenarioType: 'dangerous_family',
                mustRequireReview: _mustRequireReview(family, modifier),
              ),
            );
            if (cases.length >= limit) return cases;
          }
        }
      }
    }
    return cases;
  }

  List<_PropertyCase> _seedScenarioCases() {
    return const [
      _PropertyCase(
        'PLUMBING JOB LOWES 3/4 PVC EL',
        scenarioType: 'trade_context',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'ELECTRICAL JOB HOME DEPOT 3/4 PVC COND EL',
        scenarioType: 'trade_context',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'FERGUSON ITEM 12345 1/2 PEX CRMP ELL',
        scenarioType: 'merchant_context',
        mustRequireReview: false,
      ),
      _PropertyCase(
        'ACE 3/8 COMP X 1/2 FIP SUPPLY',
        scenarioType: 'merchant_context',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'LOWES ES 1/2 CODO PEX LATON',
        scenarioType: 'locale',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'HOME DEPOT CA 19MM PVC COUPLING',
        scenarioType: 'locale',
        mustRequireReview: true,
      ),
      _PropertyCase(
        '10PK 1/2 PEX CRIMP RING',
        scenarioType: 'package_quantity',
        mustRequireReview: false,
      ),
      _PropertyCase(
        'BOX 100 1/4 TAPCON',
        scenarioType: 'package_quantity',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'RETURN 3/4 PVC EL -2.48',
        scenarioType: 'return_line',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'RET 1/2 PEX ELL CREDIT',
        scenarioType: 'return_line',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'PROMO DISCOUNT PVC CEMENT -1.00',
        scenarioType: 'discount_line',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'MILITARY DISCOUNT 10 PERCENT',
        scenarioType: 'discount_line',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'SALES TAX PVC COUNTY 0.77',
        scenarioType: 'tax_line',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'TAXABLE ITEMS PLUMBING 14',
        scenarioType: 'tax_line',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'BATH REMODEL PVC EL 3/4 12/2 WIRE FILTER 20X25X1',
        scenarioType: 'mixed_trade_job',
        mustRequireReview: true,
      ),
      _PropertyCase(
        'KITCHEN JOB PEX 1/2 ELEC TAPE FOIL TAPE',
        scenarioType: 'mixed_trade_job',
        mustRequireReview: true,
      ),
    ];
  }

  bool _mustRequireReview(String family, String modifier) {
    if (modifier.trim().isEmpty) return true;
    if (family == 'PVC' && modifier.trim() == 'COND') return true;
    if (family == 'TAPE') return true;
    if (family == 'BOX') return true;
    if (family == 'PIPE') return true;
    return false;
  }

  static const _grammarDimensions = {
    'merchants': _merchants,
    'sizes': _sizes,
    'families': _dangerousFamilies,
    'modifiers': _modifiers,
    'locale': _locales,
    'scenarioTypes': _requiredScenarioTypes,
  };
}

class _PropertyCase {
  const _PropertyCase(
    this.line, {
    required this.scenarioType,
    required this.mustRequireReview,
  });

  final String line;
  final String scenarioType;
  final bool mustRequireReview;
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/\-\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
