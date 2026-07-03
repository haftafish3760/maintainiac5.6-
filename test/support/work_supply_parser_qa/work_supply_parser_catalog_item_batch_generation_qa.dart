import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCatalogItemBatchGenerationSuite extends QaSuite {
  const WorkSupplyParserCatalogItemBatchGenerationSuite()
    : super('inventory.catalog_item_batch_generation_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _blueprintGeneratorPath =
      'tool/work_supply_catalog_blueprint_generator.dart';
  static const _blueprintValidatorPath =
      'tool/work_supply_catalog_blueprint_validate.dart';
  static const _pipelinePath = 'tool/work_supply_parser_qa_pipeline.dart';
  static const _pipelineStatusPath =
      'tool/work_supply_parser_qa_pipeline_status.dart';
  static const _itemBatchStatusPath =
      'tool/work_supply_catalog_item_batch_status.dart';
  static const _blueprintModelPath =
      'tool/work_supply_catalog_blueprint_model.dart';
  static const _generatorTestPath =
      'test/work_supply_catalog_blueprint_generator_test.dart';
  static const _validatorTestPath =
      'test/work_supply_catalog_blueprint_validator_test.dart';
  static const _itemBatchStatusTestPath =
      'test/work_supply_catalog_item_batch_status_test.dart';

  static const _requiredBlueprintTokens = {
    'QA_CATALOG_BLUEPRINTS',
    'generationSeed',
    'promotionMode',
    'manual-review-required',
    'synthetic-blueprint',
    'writesProductionCatalog',
    'liveServicesAllowed',
    'receiptPatterns',
    'negativeMatchTokens',
    'aliases',
    'sourceConfidence',
  };

  static const _requiredValidationTokens = {
    'QA_CATALOG_BLUEPRINT_VALIDATION',
    'promotionAllowed',
    'empty_aliases',
    'empty_receiptPatterns',
    'empty_negativeMatchTokens',
    'generated_blueprint_cannot_be_verified',
    'promotion_must_require_manual_review',
    'liveServicesAllowed',
  };

  static const _requiredPipelineTokens = {
    'generate_catalog_blueprints',
    'validate_catalog_blueprints',
    'generate_parser_fixtures',
    'run_generated_parser_fixtures',
    'QA_ECONOMICAL_PIPELINE',
    'QA_PIPELINE_RESUME',
    'latest_pipeline_summary.json',
    'fixtureRunLimit',
    'writesProductionCatalog',
    'liveServicesAllowed',
  };

  static const _requiredStatusTokens = {
    'expectedCells',
    'presentCells',
    'missingCells',
    'unsafeCells',
    'requireComplete',
    'latest_pipeline_status.json',
    'localOnlySafe',
  };

  static const _requiredItemBatchStatusTokens = {
    'QA_CATALOG_ITEM_BATCH_STATUS',
    'work_supply_catalog_item_batch_status',
    'generatedItemCount',
    'manualReviewRequiredCells',
    'resumeCommand',
    'manifestPath',
    'blueprintPath',
    'requireComplete',
    'ocrCameraExpensesTouched',
  };

  static const _requiredProgressTokens = {
    'Pending QA Test Batches',
    'Add catalog item batch memory for promoted production item batches',
    'Validate item batch generation status memory before generating more inventory items',
    'Do Not Rerun Unless Inputs Changed',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final blueprintSource =
        '${_read(_blueprintGeneratorPath)}\n'
        '${_read(_blueprintModelPath)}\n'
        '${_read(_generatorTestPath)}';
    final validationSource =
        '${_read(_blueprintValidatorPath)}\n${_read(_validatorTestPath)}';
    final pipelineSource =
        '${_read(_pipelinePath)}\n${_read(_pipelineStatusPath)}';
    final itemBatchStatusSource =
        '${_read(_itemBatchStatusPath)}\n${_read(_itemBatchStatusTestPath)}';
    final progress = _read(_progressPath);
    var checked = 0;

    checked += _requiredBlueprintTokens.length;
    _checkTokens(
      failures,
      contract: 'blueprint_generation',
      source: blueprintSource,
      tokens: _requiredBlueprintTokens,
      category: QaFailureTriage.governance,
      fix:
          'Catalog item batches must be generated as review-only blueprints with rich parser metadata before production promotion.',
    );

    checked += _requiredValidationTokens.length;
    _checkTokens(
      failures,
      contract: 'blueprint_validation',
      source: validationSource,
      tokens: _requiredValidationTokens,
      category: QaFailureTriage.schema,
      fix:
          'Blueprint validation must block thin/generated/unsafe item rows before they become catalog data.',
    );

    checked += _requiredPipelineTokens.length;
    _checkTokens(
      failures,
      contract: 'catalog_fixture_pipeline',
      source: pipelineSource,
      tokens: _requiredPipelineTokens,
      category: QaFailureTriage.governance,
      fix:
          'Inventory item generation must stay paired with matching fixture generation and optional fixture runs.',
    );

    checked += _requiredStatusTokens.length;
    _checkTokens(
      failures,
      contract: 'pipeline_status',
      source: pipelineSource,
      tokens: _requiredStatusTokens,
      category: QaFailureTriage.governance,
      fix:
          'Pipeline status must identify present, missing, unsafe, and incomplete cells without rerunning parser work.',
    );

    checked += _requiredItemBatchStatusTokens.length;
    _checkTokens(
      failures,
      contract: 'item_batch_status',
      source: itemBatchStatusSource,
      tokens: _requiredItemBatchStatusTokens,
      category: QaFailureTriage.governance,
      fix:
          'Item batch status must report present/missing/unsafe catalog blueprint cells and resume commands before more inventory item generation.',
    );

    checked += _requiredProgressTokens.length;
    _checkTokens(
      failures,
      contract: 'progress_memory',
      source: progress,
      tokens: _requiredProgressTokens,
      category: QaFailureTriage.governance,
      fix:
          'Progress memory must say what item-generation tracking remains before new inventory batches are created.',
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'blueprintGeneratorPath': _blueprintGeneratorPath,
        'blueprintValidatorPath': _blueprintValidatorPath,
        'pipelinePath': _pipelinePath,
        'pipelineStatusPath': _pipelineStatusPath,
        'itemBatchStatusPath': _itemBatchStatusPath,
        'contract':
            'New inventory items must be generated in review-only catalog blueprints, validated for parser metadata depth, paired with generated fixtures, and tracked before production catalog promotion.',
      },
    );
  }

  void _checkTokens(
    List<QaFailure> failures, {
    required String contract,
    required String source,
    required Set<String> tokens,
    required String category,
    required String fix,
  }) {
    for (final token in tokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_${contract}_token:${_safeId(token)}',
          message:
              'Inventory catalog item batch generation contract is incomplete.',
          severity: QaSeverity.warning,
          expected: token,
          actual: 'not found for $contract',
          suggestedFix: fix,
          metadata: {'triageCategory': category},
        ),
      );
    }
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
