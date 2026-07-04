import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCorrectionFeedbackSuite extends QaSuite {
  const WorkSupplyParserCorrectionFeedbackSuite()
    : super('inventory.correction_feedback_contract');

  static const _provenanceBoundaryVocabulary = [
    'local_correction',
    'community_correction',
    'manual_promotion',
    'official_pack_mutation',
  ];

  static const _scannedFiles = [
    'docs/work_supplies_spec.md',
    'docs/materials_catalog_intelligence_contract.md',
    'test/support/work_supply_parser_qa/work_supply_parser_governance_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_pack_lifecycle_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
  ];

  static const _contracts = [
    _CorrectionContract(
      name: 'local_correction_record',
      tokens: ['local correction record', 'item ID', 'parser version'],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _CorrectionContract(
      name: 'proposed_alias_or_rule',
      tokens: ['propose a new alias', 'negative-match rule'],
      category: QaFailureTriage.alias,
      required: true,
    ),
    _CorrectionContract(
      name: 'fixture_proposal_path',
      tokens: ['fixture case', 'regression-tested'],
      category: QaFailureTriage.fixture,
      required: true,
    ),
    _CorrectionContract(
      name: 'manual_promotion_gate',
      tokens: ['manual promotion gate', 'official packs'],
      category: QaFailureTriage.reviewSafety,
      required: true,
    ),
    _CorrectionContract(
      name: 'privacy_safe_feedback',
      tokens: ['privacy-safe evidence', 'raw receipt text'],
      category: QaFailureTriage.privacy,
      required: true,
    ),
    _CorrectionContract(
      name: 'community_opt_in',
      tokens: ['opt-in', 'abuse-protected', 'removable'],
      category: QaFailureTriage.security,
      required: true,
    ),
    _CorrectionContract(
      name: 'rejected_correction_isolation',
      tokens: ['Rejected corrections', 'isolated from official packs'],
      category: QaFailureTriage.reviewSafety,
      required: true,
    ),
    _CorrectionContract(
      name: 'no_silent_official_mutation',
      tokens: ['must not silently mutate official catalog packs'],
      category: QaFailureTriage.reviewSafety,
      required: true,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sourceByPath = <String, String>{};

    for (final path in _scannedFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_correction_feedback_scan_file:$path',
            message: 'Correction feedback scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if correction feedback docs or governance suites move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sourceByPath[path] = file.readAsStringSync();
    }

    final source = sourceByPath.values.join('\n');
    final present = <String>[];
    for (final contract in _contracts) {
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_correction_feedback_contract:${contract.name}',
          message: 'Required correction feedback contract is missing.',
          expected: contract.tokens.join(' + '),
          actual: 'not found',
          suggestedFix:
              'Lock correction learning behind review, privacy, fixture, and promotion gates before release.',
          metadata: {'triageCategory': contract.category},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _scannedFiles.length + _contracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'provenanceBoundaryVocabulary': _provenanceBoundaryVocabulary,
        'filesScanned': sourceByPath.keys.toList()..sort(),
        'parserCalls': 0,
      },
    );
  }
}

class _CorrectionContract {
  const _CorrectionContract({
    required this.name,
    required this.tokens,
    required this.category,
    this.required = false,
  });

  final String name;
  final List<String> tokens;
  final String category;
  final bool required;

  bool isPresentIn(String source) {
    final normalizedSource = _normalizeContractText(source);
    return tokens.every(
      (token) => normalizedSource.contains(_normalizeContractText(token)),
    );
  }
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
