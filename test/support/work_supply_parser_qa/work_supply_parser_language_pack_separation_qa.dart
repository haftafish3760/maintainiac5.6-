import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserLanguagePackSeparationSuite extends QaSuite {
  const WorkSupplyParserLanguagePackSeparationSuite()
    : super('inventory.language_pack_separation_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_locale_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_spanish_release_one_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_release_one_residential_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_scope_gate_qa.dart',
    'test/work_supply_parser_language_pack_separation_behavior_test.dart',
    'test/work_supply_locale_pack_test.dart',
  };

  static const _languageAxes = {
    'English',
    'Spanish',
    'French',
    'en-US',
    'es-US',
    'en-CA',
    'fr-CA',
    'metric',
    'imperial',
    'locale pack',
  };

  static const _separationRules = {
    'english_and_spanish_are_separate_packs',
    'locale_pack_can_share_canonical_item_identity',
    'locale_aliases_do_not_duplicate_canonical_items',
    'metric_size_aliases_are_locale_specific',
    'imperial_size_aliases_are_locale_specific',
    'spanish_us_receipts_are_release_one_scope',
    'canada_requires_english_and_french_later',
    'language_pack_selection_is_user_or_region_driven',
    'missing_locale_pack_falls_back_conservatively',
    'locale_context_boosts_without_forcing_match',
    'mixed_language_receipts_preserve_locale_pack_id',
    'pvc_overlap_requires_trade_context_and_review',
    'spanish_aliases_cover_plumbing_electrical_hvac_overlap',
  };

  static const _receiptLanguageSignals = {
    'codo',
    'tubo',
    'conector',
    'valvula',
    'filtro',
    'cinta',
    'cable',
    'conducto',
    'acople',
    'tornillo',
    'tuerca',
    'arandela',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _languageAxes.length;
    _requireTokens(
      failures,
      source,
      _languageAxes,
      idPrefix: 'missing_language_axis',
      message: 'Language-pack QA is missing locale/unit coverage.',
      fix:
          'Parser pack QA must model English, Spanish, future French Canadian, US/Canada locales, metric, and imperial forms.',
      triage: QaFailureTriage.locale,
    );

    checked += _separationRules.length;
    _requireRules(failures, source, _separationRules);

    checked += _receiptLanguageSignals.length;
    _requireTokens(
      failures,
      source,
      _receiptLanguageSignals,
      idPrefix: 'missing_spanish_receipt_signal',
      message: 'Language-pack QA is missing Spanish receipt vocabulary.',
      fix:
          'US Spanish parser packs need material, shape, electrical, HVAC, and fastener terms without mixing official English aliases into one oversized pack.',
      triage: QaFailureTriage.locale,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Locale packs may share canonical item identity, but aliases and receipt phrases stay pack-scoped for size and accuracy.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in rules) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_language_pack_rule:${_safeId(rule)}',
          message: 'Language-pack QA is missing a named separation rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add language-pack separation rules before adding Spanish/French aliases at scale.',
          triage: QaFailureTriage.locale,
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
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
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

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
