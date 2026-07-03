import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReceiptLineTortureSuite extends QaSuite {
  const WorkSupplyParserReceiptLineTortureSuite()
    : super('inventory.receipt_line_torture_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _fixtureCoveragePath =
      'test/support/work_supply_parser_qa/work_supply_parser_fixture_coverage_qa.dart';
  static const _propertyPath =
      'test/support/work_supply_parser_qa/work_supply_parser_property_qa.dart';
  static const _metamorphicPath =
      'test/support/work_supply_parser_qa/work_supply_parser_metamorphic_qa.dart';
  static const _securityPath =
      'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart';
  static const _mathPath =
      'test/support/work_supply_parser_qa/work_supply_parser_math_qa.dart';
  static const _noisePath =
      'test/support/work_supply_parser_qa/work_supply_parser_noise_qa.dart';
  static const _contextPath =
      'test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart';
  static const _merchantPath =
      'test/support/work_supply_parser_qa/work_supply_parser_merchant_qa.dart';
  static const _localePath =
      'test/support/work_supply_parser_qa/work_supply_parser_locale_qa.dart';
  static const _behaviorPath =
      'test/work_supply_parser_receipt_line_torture_behavior_test.dart';

  static const _tortureDimensions = {
    'merchant_abbreviation',
    'dangerous_word',
    'ambiguous_review',
    'receipt_noise',
    'negative_match',
    'quantity',
    'pack_quantity',
    'linear_feet',
    'unit_cost',
    'line_subtotal',
    'return_line',
    'discount_line',
    'tax_line',
    'mixed_trade_receipt',
    'supply_house',
    'spanish',
    'locale_pack',
    'canadian_format',
    'unicode_control',
    'long_token',
    'path_like',
    'injection_like',
    'ocr_dirty_text',
  };

  static const _merchantDimensions = {
    'Home Depot',
    'Lowes',
    'Ace',
    'Ferguson',
    'Grainger',
    'Menards',
    'True Value',
    'Walmart',
    'Supply House',
    'unknown',
  };

  static const _parserBehaviorDimensions = {
    'ranked candidates',
    'needs review',
    'no auto-save',
    'confidence reasons',
    'trade context',
    'merchant context',
    'locale',
    'quantity/price fixtures',
    'privacy-safe',
    'failure category',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final fixtureCoverage = _read(_fixtureCoveragePath);
    final fixtureSources = [
      fixtureCoverage,
      _read(_propertyPath),
      _read(_metamorphicPath),
      _read(_securityPath),
      _read(_mathPath),
      _read(_noisePath),
      _read(_contextPath),
      _read(_merchantPath),
      _read(_localePath),
      _read(_behaviorPath),
      progress,
    ].join('\n');
    var checked = 0;

    checked += _tortureDimensions.length;
    for (final token in _tortureDimensions) {
      if (fixtureSources.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_torture_dimension:${_safeId(token)}',
          message:
              'Receipt-line torture coverage is missing a required chaos dimension.',
          expected: token,
          actual: 'not found in inventory QA fixture/property/security sources',
          fix:
              'Add generated or golden parser fixtures for this receipt-line risk before release accuracy claims.',
          category: QaFailureTriage.fixture,
        ),
      );
    }

    checked += _merchantDimensions.length;
    for (final merchant in _merchantDimensions) {
      if (fixtureSources.contains(merchant)) continue;
      failures.add(
        _failure(
          id: 'missing_torture_merchant:${_safeId(merchant)}',
          message:
              'Receipt-line torture coverage is missing a major merchant/supply-house style.',
          expected: merchant,
          actual: 'not found in inventory QA sources',
          fix:
              'Add non-proprietary synthetic receipt wording for this merchant style.',
          category: QaFailureTriage.merchantRule,
        ),
      );
    }

    checked += _parserBehaviorDimensions.length;
    for (final token in _parserBehaviorDimensions) {
      if (fixtureSources.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_torture_behavior:${_safeId(token)}',
          message:
              'Receipt-line torture coverage is missing a parser behavior expectation.',
          expected: token,
          actual: 'not found in inventory QA sources',
          fix:
              'Torture fixtures must verify parser behavior, not just fixture existence.',
          category: QaFailureTriage.parserEngine,
        ),
      );
    }

    checked += 5;
    _checkProgressMemory(progress, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'tortureDimensionCount': _tortureDimensions.length,
        'merchantDimensionCount': _merchantDimensions.length,
        'behaviorDimensionCount': _parserBehaviorDimensions.length,
        'contract':
            'Inventory parser QA must cover chaotic real-world receipt lines: abbreviations, returns, discounts, mixed trades, quantities, merchant styles, locale terms, hostile strings, and review-safe ambiguity.',
      },
    );
  }

  void _checkProgressMemory(String progress, List<QaFailure> failures) {
    const requiredTokens = {
      'inventory.receipt_line_torture_contract',
      'focusedRerun',
      'doNotRerunUnless',
      'coveredInputs',
      'focused-validated',
    };
    for (final token in requiredTokens) {
      if (progress.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_torture_memory:${_safeId(token)}',
          message:
              'Progress memory is missing receipt-line torture batch tracking.',
          expected: token,
          actual: 'not found in $_progressPath',
          fix:
              'Track this QA batch so it is not forgotten or rerun unnecessarily after context compression.',
          category: QaFailureTriage.governance,
        ),
      );
    }
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
