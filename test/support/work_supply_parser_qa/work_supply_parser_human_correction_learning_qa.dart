import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserHumanCorrectionLearningSuite extends QaSuite {
  const WorkSupplyParserHumanCorrectionLearningSuite()
    : super('inventory.human_correction_learning_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_correction_feedback_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_review_safety_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_admin_diagnostic_batch_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_telemetry_qa.dart',
    'test/work_supply_parser_human_correction_learning_behavior_test.dart',
  };

  static const _correctionTargets = {
    'proposed alias',
    'negative rule',
    'merchant rule',
    'regression fixture',
    'confidence hint',
    'missing vendor mapping',
    'locale phrase',
    'Spanish phrase',
    'item family',
    'trade context',
  };

  static const _safetyRules = {
    'correction_never_silently_mutates_official_pack',
    'correction_requires_review_before_promotion',
    'correction_keeps_original_candidate_evidence',
    'correction_records_before_after_item',
    'correction_records_failure_category',
    'correction_redacts_private_receipt_text',
    'correction_does_not_log_card_data',
    'correction_can_be_rejected',
    'correction_can_create_regression_fixture',
    'correction_scopes_to_merchant_locale_trade',
    'community_correction_requires_opt_in',
    'community_correction_is_redacted',
  };

  static const _adminSignals = {
    'device class',
    'device model',
    'pack version',
    'parser version',
    'failure category',
    'trade',
    'item id',
    'candidate count',
    'unknown rate',
    'correction frequency',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _correctionTargets.length;
    _requireTokens(
      failures,
      source,
      _correctionTargets,
      idPrefix: 'missing_correction_target',
      message: 'Human correction QA is missing a learning target.',
      fix:
          'Corrections should produce reviewed aliases, negative rules, merchant rules, fixtures, confidence hints, locale phrases, and mapping improvements.',
      triage: QaFailureTriage.governance,
    );

    checked += _safetyRules.length;
    _requireRules(failures, source, _safetyRules);

    checked += _adminSignals.length;
    _requireTokens(
      failures,
      source,
      _adminSignals,
      idPrefix: 'missing_admin_signal',
      message: 'Human correction QA is missing admin diagnostic signals.',
      fix:
          'Admin diagnostics should show parser health by device class/model, pack/parser version, trade, item, candidate count, unknown rate, and correction frequency without private user data.',
      triage: QaFailureTriage.privacy,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'User corrections become reviewable learning proposals, not automatic pack mutations or private telemetry leaks.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = source.toLowerCase();
    for (final rule in rules) {
      if (lower.contains(rule.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_correction_rule:${_safeId(rule)}',
          message: 'Human correction QA is missing a named safety rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Correction learning must be reviewed, scoped, redacted, rejectable, and fixture-backed.',
          triage: QaFailureTriage.reviewSafety,
        ),
      );
    }
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
  }) {
    final lower = source.toLowerCase();
    for (final token in tokens) {
      if (lower.contains(token.toLowerCase())) continue;
      failures.add(
        _failure(
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          fix: fix,
          triage: triage,
        ),
      );
    }
  }

  String _readSources() {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String triage,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': triage},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
