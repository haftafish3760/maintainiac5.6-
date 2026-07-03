import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserBulkGenerationPipelineSuite extends QaSuite {
  const WorkSupplyParserBulkGenerationPipelineSuite()
    : super('inventory.bulk_generation_pipeline_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_catalog_item_batch_generation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_generated_artifact_manifest_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_generated_fixture_cell_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_catalog_batch_manifest_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_item_promotion_gate_qa.dart',
  };

  static const _pipelineStages = {
    'blueprint',
    'generated item',
    'generated fixture',
    'schema validation',
    'alias validation',
    'conflict validation',
    'merchant validation',
    'promotion gate',
    'progress memory',
    'focused rerun',
  };

  static const _batchRules = {
    'generate_items_and_fixtures_together',
    'do_not_promote_without_fixture_pair',
    'do_not_rerun_completed_cells_unless_inputs_changed',
    'batch_manifest_records_scope_trade_tier_locale',
    'batch_status_records_failed_cell_count',
    'batch_status_records_completed_cell_count',
    'local_only_generation',
    'no_live_firebase_generation',
    'no_ocr_camera_expenses_touch',
    'surgical_retry_for_failed_cell',
  };

  static const _scaleTokens = {
    'plumbing',
    'electrical',
    'hvac',
    'fasteners',
    'residential',
    'en-US',
    'es-US',
    'core',
    'standard',
    'professional',
    'complete',
  };

  static const _qualitySignals = {
    'stable id',
    'canonical name',
    'aliases',
    'receipt phrases',
    'merchant abbreviations',
    'negative match',
    'confidence',
    'source metadata',
    'review status',
    'generated flag',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _pipelineStages.length;
    _requireTokens(
      failures,
      source,
      _pipelineStages,
      idPrefix: 'missing_pipeline_stage',
      message: 'Bulk generation QA is missing a required pipeline stage.',
      fix:
          'Bulk catalog expansion must flow through blueprint, generated item, generated fixture, validation, promotion, progress memory, and surgical rerun stages.',
      triage: QaFailureTriage.governance,
    );

    checked += _batchRules.length;
    _requireRules(failures, source, _batchRules);

    checked += _scaleTokens.length;
    _requireTokens(
      failures,
      source,
      _scaleTokens,
      idPrefix: 'missing_scale_axis',
      message: 'Bulk generation QA is missing release-one scale axes.',
      fix:
          'The pipeline must cover residential plumbing, electrical, HVAC, fasteners, English, Spanish, and all pack tiers.',
      triage: QaFailureTriage.locale,
    );

    checked += _qualitySignals.length;
    _requireTokens(
      failures,
      source,
      _qualitySignals,
      idPrefix: 'missing_quality_signal',
      message: 'Bulk generation QA is missing smart-row metadata requirements.',
      fix:
          'Generated catalog rows need identity, aliases, merchant phrases, negative rules, confidence hints, source metadata, and review status.',
      triage: QaFailureTriage.schema,
    );

    checked += 5;
    _requireThroughputBudget(source, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Bulk generation must create smart items and paired QA fixtures together, then promote only through local, focused, repeatable gates.',
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
          id: 'missing_bulk_generation_rule:${_safeId(rule)}',
          message: 'Bulk generation QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add this rule so item generation and QA fixture generation stay batched, local-only, and promotion-gated.',
          triage: QaFailureTriage.governance,
        ),
      );
    }
  }

  void _requireThroughputBudget(String source, List<QaFailure> failures) {
    const tokens = {
      'batch',
      'focused',
      'surgical',
      'doNotRerunUnless',
      'writesProductionCatalog',
    };
    final lower = source.toLowerCase();
    for (final token in tokens) {
      if (lower.contains(token.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_bulk_throughput_guard:${_safeId(token)}',
          message: 'Bulk generation QA is missing a throughput/rerun guard.',
          expected: token,
          actual: 'not found',
          fix:
              'Track completed inputs and use surgical reruns so QA does not repeatedly grind the full catalog.',
          triage: QaFailureTriage.performance,
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
