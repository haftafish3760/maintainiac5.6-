import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserItemPromotionGateSuite extends QaSuite {
  const WorkSupplyParserItemPromotionGateSuite()
    : super('inventory.item_promotion_gate_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _catalogContractPath =
      'docs/materials_catalog_intelligence_contract.md';
  static const _blueprintValidatorPath =
      'tool/work_supply_catalog_blueprint_validate.dart';
  static const _blueprintGeneratorPath =
      'tool/work_supply_catalog_blueprint_generator.dart';
  static const _blueprintPromotionQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_blueprint_promotion_qa.dart';
  static const _blueprintContractQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_blueprint_contract_qa.dart';
  static const _itemMetadataQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_item_metadata_depth_qa.dart';
  static const _vendorQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_vendor_readiness_qa.dart';
  static const _workflowQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart';

  static const _promotionSafetyTokens = {
    'manual-review-required',
    'promotionAllowed',
    'promotion_must_require_manual_review',
    'generated_blueprint_cannot_be_verified',
    'writesProductionCatalog',
    'liveServicesAllowed',
    'synthetic-blueprint',
  };

  static const _smartRowTokens = {
    'item ID',
    'aliases',
    'receipt patterns',
    'negative-match',
    'confidence',
    'classification',
    'catalog version',
    'parser version',
    'source confidence',
    'verified manually',
    'needs review',
  };

  static const _workflowTokens = {
    'inventory/job/estimate/invoice routing',
    'inventory',
    'estimate',
    'job',
    'invoice',
    'tax reporting',
    'markup behavior',
    'billable material',
  };

  static const _vendorTokens = {
    'vendor mappings',
    'merchant-style receipt patterns',
    'SKU/part-number pattern slots',
    'Home Depot',
    'Lowes',
    'Ferguson',
    'Grainger',
    'Menards',
    'True Value',
    'Walmart',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final catalogContract = _read(_catalogContractPath);
    final promotionSource = [
      _read(_blueprintValidatorPath),
      _read(_blueprintGeneratorPath),
      _read(_blueprintPromotionQaPath),
      _read(_blueprintContractQaPath),
    ].join('\n');
    final parserDepthSource = [
      catalogContract,
      _read(_itemMetadataQaPath),
      _read(_vendorQaPath),
      _read(_workflowQaPath),
      progress,
    ].join('\n');
    var checked = 0;

    checked += _promotionSafetyTokens.length;
    for (final token in _promotionSafetyTokens) {
      if (promotionSource.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_promotion_safety_token:${_safeId(token)}',
          message: 'Catalog item promotion gate is missing a safety token.',
          expected: token,
          actual: 'not found in blueprint generator/validator/promotion QA',
          fix:
              'Generated inventory rows must stay review-only until manually promoted and must not write production catalog data automatically.',
          category: QaFailureTriage.reviewSafety,
        ),
      );
    }

    checked += _smartRowTokens.length;
    for (final token in _smartRowTokens) {
      if (parserDepthSource.toLowerCase().contains(token.toLowerCase())) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_smart_row_token:${_safeId(token)}',
          message: 'Catalog item promotion gate is missing smart-row metadata coverage.',
          expected: token,
          actual: 'not found in catalog contract or parser QA sources',
          fix:
              'Do not promote generated items unless canonical identity, aliases, receipt patterns, conflict rules, confidence, routing, and versioning are present.',
          category: QaFailureTriage.schema,
        ),
      );
    }

    checked += _workflowTokens.length;
    for (final token in _workflowTokens) {
      if (parserDepthSource.toLowerCase().contains(token.toLowerCase())) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_workflow_promotion_token:${_safeId(token)}',
          message:
              'Catalog item promotion gate is missing workflow-routing coverage.',
          expected: token,
          actual: 'not found in workflow/item metadata sources',
          fix:
              'Promoted item rows must be able to feed inventory, jobs, estimates, and invoices without UI coupling.',
          category: QaFailureTriage.category,
        ),
      );
    }

    checked += _vendorTokens.length;
    for (final token in _vendorTokens) {
      if (parserDepthSource.toLowerCase().contains(token.toLowerCase())) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_vendor_promotion_token:${_safeId(token)}',
          message:
              'Catalog item promotion gate is missing vendor/merchant readiness coverage.',
          expected: token,
          actual: 'not found in vendor/item metadata sources',
          fix:
              'Promoted item rows need non-proprietary vendor/SKU-ready fields and merchant-style receipt patterns where known.',
          category: QaFailureTriage.merchantRule,
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
        'catalogContractPath': _catalogContractPath,
        'contract':
            'Generated catalog item batches must remain review-only until promotion gates prove smart-row metadata, vendor readiness, workflow routing, and local-only safety.',
      },
    );
  }

  void _checkProgressMemory(String progress, List<QaFailure> failures) {
    const requiredTokens = {
      'inventory.item_promotion_gate_contract',
      'focusedRerun',
      'doNotRerunUnless',
      'coveredInputs',
      'focused-validated',
    };
    for (final token in requiredTokens) {
      if (progress.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_item_promotion_memory:${_safeId(token)}',
          message: 'Progress memory is missing item promotion gate tracking.',
          expected: token,
          actual: 'not found in $_progressPath',
          fix:
              'Track item promotion QA so generated catalog rows do not bypass review or get reworked blindly.',
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
