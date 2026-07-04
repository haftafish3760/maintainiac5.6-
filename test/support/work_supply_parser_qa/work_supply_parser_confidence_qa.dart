import 'dart:convert';
import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_confidence.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserConfidenceCalibrationSuite extends QaSuite {
  const WorkSupplyParserConfidenceCalibrationSuite()
    : super('inventory.confidence_calibration');

  static const _confidenceBandContract = 'Good/Review/Poor confidence bands';
  static const _confidenceEnginePath =
      'lib/screens/work_supplies/data/'
      'work_supply_receipt_parser_confidence_engine.dart';

  static const _requiredEngineTokens = {
    '_specificityEvidenceScore',
    '_receiptAmbiguityRisk',
    '_isCrossTradePvcLine',
    '_isCrossTradeCopperLine',
    '_isGenericFilterLine',
    'confidence += _specificityEvidenceScore',
    'confidence -= _receiptAmbiguityRisk',
    '_nominalReceiptSize',
    '_receiptContainsVariantTokens',
    '_containsExactPhrase',
  };

  static const _forbiddenEngineTokens = {
    'confidenceCap',
    'confidence_cap',
    'capConfidence',
    'suppressAmbiguity',
    'suppress_ambiguity',
    'hideAmbiguity',
    'hide_ambiguity',
    'forceHighConfidence',
    'force_high_confidence',
    'bypassReviewForConfidence',
    'bypass_review_for_confidence',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final fixtures = _loadFixtures();
    final engineSource = _read(_confidenceEnginePath);

    _checkConfidenceBands(failures);
    _checkConfidenceEngineEvidenceContract(failures, engineSource);
    _checkDirectConfidenceOrdersEvidenceBeforeBounding(failures, engineSource);
    for (final fixture in fixtures) {
      switch (fixture.caseType) {
        case 'clear_match':
        case 'quantity_price':
          _requireClearMatchEvidence(failures, fixture);
        case 'receipt_noise':
          _requireConservativeUnknown(
            failures,
            fixture,
            maxAllowed: .2,
            reason: 'receipt noise should stay poor/unknown',
          );
        case 'dangerous_generic':
        case 'ambiguous_review':
        case 'negative_match':
          _requireConservativeUnknown(
            failures,
            fixture,
            maxAllowed: .81,
            reason:
                'risky or ambiguous lines must not cross the Good threshold',
          );
      }
    }

    return timer.finish(
      suite: name,
      checked:
          fixtures.length +
          6 +
          _requiredEngineTokens.length +
          _forbiddenEngineTokens.length +
          2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixtureCount': fixtures.length,
        'confidenceBandContract': _confidenceBandContract,
        'confidenceEnginePath': _confidenceEnginePath,
        'goodThreshold': .82,
        'reviewThreshold': .62,
      },
    );
  }

  void _checkConfidenceBands(List<QaFailure> failures) {
    final probes = {
      .95: ReceiptConfidenceLevel.good,
      .82: ReceiptConfidenceLevel.good,
      .81: ReceiptConfidenceLevel.okay,
      .62: ReceiptConfidenceLevel.okay,
      .61: ReceiptConfidenceLevel.poor,
      .2: ReceiptConfidenceLevel.poor,
    };
    for (final entry in probes.entries) {
      final actual = receiptConfidenceLevelFor(entry.key);
      if (actual == entry.value) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'confidence_band:${entry.key}',
          message: 'Receipt confidence band changed unexpectedly.',
          expected: entry.value.name,
          actual: actual.name,
          suggestedFix:
              'Update fixture thresholds and release gates intentionally if confidence bands change.',
        ),
      );
    }
  }

  void _checkConfidenceEngineEvidenceContract(
    List<QaFailure> failures,
    String source,
  ) {
    if (source.isEmpty) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_confidence_engine_source',
          message: 'Confidence calibration cannot inspect the parser engine.',
          severity: QaSeverity.error,
          expected: _confidenceEnginePath,
          actual: 'not found or empty',
          suggestedFix:
              'Restore the confidence engine source or update this QA contract path.',
        ),
      );
      return;
    }

    for (final token in _requiredEngineTokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_confidence_engine_evidence:${_safeId(token)}',
          message:
              'Confidence engine is missing evidence/ambiguity calibration logic.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Improve confidence by adding evidence, specificity, context, and ambiguity-risk handling instead of hiding uncertainty.',
        ),
      );
    }

    for (final token in _forbiddenEngineTokens) {
      if (!source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'forbidden_confidence_engine_shortcut:${_safeId(token)}',
          message:
              'Confidence engine contains a cap/suppression/bypass shortcut token.',
          severity: QaSeverity.critical,
          expected:
              'evidence-based scoring with ambiguity preserved and review required',
          actual: token,
          suggestedFix:
              'Remove confidence shortcuts; add more context, ranked alternatives, or review-required evidence instead.',
        ),
      );
    }
  }

  void _checkDirectConfidenceOrdersEvidenceBeforeBounding(
    List<QaFailure> failures,
    String source,
  ) {
    final methodStart = source.indexOf('double _directReceiptConfidence(');
    final methodEnd = source.indexOf(
      'double _learnedCorrectionConfidence(',
      methodStart,
    );
    if (methodStart < 0 || methodEnd < 0) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'direct_confidence_method_not_found',
          message: 'Direct receipt confidence method could not be inspected.',
          severity: QaSeverity.error,
          expected:
              'direct confidence computes evidence and ambiguity before final bounding',
          actual: 'method boundary missing',
          suggestedFix:
              'Keep direct confidence as an inspectable evidence-based method.',
        ),
      );
      return;
    }
    final body = source.substring(methodStart, methodEnd);
    final specificity = body.indexOf('confidence += _specificityEvidenceScore');
    final ambiguity = body.indexOf('confidence -= _receiptAmbiguityRisk');
    final bounded = body.indexOf(
      'return _boundedReceiptConfidence(confidence)',
    );
    final ordered =
        specificity >= 0 && ambiguity > specificity && bounded > ambiguity;
    if (ordered) return;
    failures.add(
      QaFailure(
        suite: name,
        id: 'direct_confidence_evidence_order',
        message:
            'Direct receipt confidence must apply specificity and ambiguity before final numeric bounding.',
        severity: QaSeverity.critical,
        expected:
            'specificity evidence, then ambiguity risk, then final bounded return',
        actual:
            'specificityIndex=$specificity ambiguityIndex=$ambiguity boundedIndex=$bounded',
        suggestedFix:
            'Do not cap overconfidence to hide ambiguity; add context/evidence and preserve review uncertainty before final display-safe bounding.',
        metadata: const {'triageCategory': QaFailureTriage.reviewSafety},
      ),
    );
  }

  void _requireClearMatchEvidence(
    List<QaFailure> failures,
    _ConfidenceFixture fixture,
  ) {
    if (fixture.expectUnknown) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'clear_match_marked_unknown:${fixture.id}',
          message: 'Clear-match fixture is marked expectUnknown.',
          expected: 'expectedTrade and expectedNameContains',
          actual: 'expectUnknown=true',
          suggestedFix:
              'Use an ambiguity/noise case type or add clear expected match evidence.',
        ),
      );
    }
    if (fixture.expectedTrade.isEmpty || fixture.expectedNameContains.isEmpty) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'clear_match_missing_expected_evidence:${fixture.id}',
          message: 'Clear-match fixture lacks expected match evidence.',
          expected: 'expectedTrade and expectedNameContains',
          actual:
              'expectedTrade=${fixture.expectedTrade}; expectedNameContains=${fixture.expectedNameContains}',
          suggestedFix:
              'Add expected trade and item-family evidence for clear parser assertions.',
        ),
      );
    }
  }

  void _requireConservativeUnknown(
    List<QaFailure> failures,
    _ConfidenceFixture fixture, {
    required double maxAllowed,
    required String reason,
  }) {
    if (!fixture.expectUnknown) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'risky_fixture_not_unknown:${fixture.id}',
          message: 'Risky fixture is not marked expectUnknown.',
          expected: 'expectUnknown=true',
          actual: 'expectUnknown=false',
          suggestedFix:
              'Mark risky/noise fixtures as review/unknown unless they have enough evidence for a safe clear match.',
        ),
      );
    }
    if (fixture.maxConfidence > maxAllowed) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'risky_fixture_confidence_too_high:${fixture.id}',
          message: 'Risky fixture maxConfidence is too permissive.',
          expected: '<= $maxAllowed',
          actual: '${fixture.maxConfidence}',
          suggestedFix: reason,
        ),
      );
    }
  }
}

class _ConfidenceFixture {
  const _ConfidenceFixture({
    required this.id,
    required this.caseType,
    required this.expectUnknown,
    required this.maxConfidence,
    required this.expectedTrade,
    required this.expectedNameContains,
  });

  final String id;
  final String caseType;
  final bool expectUnknown;
  final double maxConfidence;
  final String expectedTrade;
  final String expectedNameContains;

  static _ConfidenceFixture fromJson(Map<String, Object?> json) {
    return _ConfidenceFixture(
      id: json['id'] as String? ?? 'fixture_without_id',
      caseType: json['caseType'] as String? ?? '',
      expectUnknown: json['expectUnknown'] as bool? ?? false,
      maxConfidence: (json['maxConfidence'] as num?)?.toDouble() ?? 1,
      expectedTrade: json['expectedTrade'] as String? ?? '',
      expectedNameContains: json['expectedNameContains'] as String? ?? '',
    );
  }
}

List<_ConfidenceFixture> _loadFixtures() {
  final file = File('test/fixtures/work_supply_parser/golden_fixtures.json');
  if (!file.existsSync()) return const [];
  final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  return [
    for (final entry in decoded)
      _ConfidenceFixture.fromJson((entry as Map).cast<String, Object?>()),
  ];
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
