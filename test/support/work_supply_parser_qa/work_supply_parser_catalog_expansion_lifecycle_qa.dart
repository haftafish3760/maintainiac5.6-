import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCatalogExpansionLifecycleSuite extends QaSuite {
  const WorkSupplyParserCatalogExpansionLifecycleSuite()
    : super('inventory.catalog_expansion_lifecycle_contract');

  static const _scorecardPath =
      'docs/inventory_parser_release1_acceptance_scorecard.md';
  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _backlogPath = 'docs/inventory_catalog_expansion_backlog.md';
  static const _batchGenerationQaPath =
      'test/support/work_supply_parser_qa/'
      'work_supply_parser_catalog_item_batch_generation_qa.dart';
  static const _promotionGateQaPath =
      'test/support/work_supply_parser_qa/'
      'work_supply_parser_item_promotion_gate_qa.dart';
  static const _legalSafetyQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_legal_safety_qa.dart';
  static const _pipelinePath = 'tool/work_supply_parser_qa_pipeline.dart';
  static const _blueprintValidatorPath =
      'tool/work_supply_catalog_blueprint_validate.dart';

  static const _lifecycleTokens = {
    'QA harness completion is not the same thing as catalog completion',
    'inventory catalog expansion still continues in controlled batches',
    'generated item candidates',
    'fixture coverage',
    'regression locks',
    'release-readiness evidence before promotion',
    'Core and Standard must cover everyday service-truck reality',
  };

  static const _backlogTokens = {
    'Plumbing Core Families',
    'Plumbing Standard Families',
    'Electrical Core Families',
    'Electrical Standard Families',
    'HVAC Core Families',
    'HVAC Standard Families',
    'well pumps',
    'pressure switches',
    'GFCI receptacles',
    'PVC conduit',
    'capacitors',
    'condensate drain',
    'Fixture Requirements For Every Batch',
    'Promotion Rules',
  };

  static const _batchSafetyTokens = {
    'manual-review-required',
    'promotionAllowed',
    'writesProductionCatalog',
    'liveServicesAllowed',
    'generatedItemCount',
    'resumeCommand',
    'requireComplete',
  };

  static const _evidenceTokens = {
    'generate_catalog_blueprints',
    'validate_catalog_blueprints',
    'generate_parser_fixtures',
    'run_generated_parser_fixtures',
    'latest_pipeline_summary.json',
    'latest_pipeline_status.json',
  };

  static const _legalTokens = {
    'Retailer database scraping is forbidden',
    'licensed_or_public_source',
    'source confidence',
    'merchant SKU',
    'barcode',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final lifecycleSource = [
      _read(_scorecardPath),
      _read(_progressPath),
      _read(_planPath),
      _read(_backlogPath),
    ].join('\n');
    final batchSource = [
      _read(_batchGenerationQaPath),
      _read(_promotionGateQaPath),
      _read(_pipelinePath),
      _read(_blueprintValidatorPath),
    ].join('\n');
    final legalSource = [
      _read(_scorecardPath),
      _read(_legalSafetyQaPath),
      _read(_planPath),
    ].join('\n');
    var checked = 0;

    checked += _checkTokens(
      failures,
      contract: 'catalog_expansion_lifecycle',
      source: lifecycleSource,
      tokens: _lifecycleTokens,
      category: QaFailureTriage.governance,
      fix:
          'Document that QA harness readiness is a gate, while catalog item expansion continues through controlled, evidence-backed batches.',
    );
    checked += _checkTokens(
      failures,
      contract: 'catalog_expansion_backlog',
      source: _read(_backlogPath),
      tokens: _backlogTokens,
      category: QaFailureTriage.category,
      fix:
          'Maintain a durable Release 1 expansion backlog for Plumbing, Electrical, and HVAC Core/Standard service families.',
    );
    checked += _checkTokens(
      failures,
      contract: 'catalog_batch_safety',
      source: batchSource,
      tokens: _batchSafetyTokens,
      category: QaFailureTriage.reviewSafety,
      fix:
          'Catalog expansion must stay local-only, review-only, resumable, and unable to mutate production catalog rows without promotion evidence.',
    );
    checked += _checkTokens(
      failures,
      contract: 'catalog_expansion_evidence',
      source: batchSource,
      tokens: _evidenceTokens,
      category: QaFailureTriage.fixture,
      fix:
          'Every new item batch needs paired blueprint validation, fixture generation, optional parser runs, and durable status artifacts.',
    );
    checked += _checkTokens(
      failures,
      contract: 'catalog_expansion_legal_provenance',
      source: legalSource,
      tokens: _legalTokens,
      category: QaFailureTriage.security,
      fix:
          'Barcode, SKU, merchant, and brand mappings must use legal provenance and must not come from retailer database scraping.',
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scorecardPath': _scorecardPath,
        'progressPath': _progressPath,
        'backlogPath': _backlogPath,
        'contract':
            'After the reusable QA harness is ready, inventory catalog expansion remains a separate controlled lifecycle: generated candidates, validation, fixtures, parser evidence, legal provenance, manual promotion, and release-readiness reporting.',
      },
    );
  }

  int _checkTokens(
    List<QaFailure> failures, {
    required String contract,
    required String source,
    required Set<String> tokens,
    required String category,
    required String fix,
  }) {
    for (final token in tokens) {
      if (source.toLowerCase().contains(token.toLowerCase())) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_${contract}_token:${_safeId(token)}',
          message: 'Catalog expansion lifecycle contract is incomplete.',
          severity: QaSeverity.warning,
          expected: token,
          actual: 'not found for $contract',
          suggestedFix: fix,
          metadata: {'triageCategory': category},
        ),
      );
    }
    return tokens.length;
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
