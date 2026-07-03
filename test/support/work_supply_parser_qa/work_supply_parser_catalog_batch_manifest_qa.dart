import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCatalogBatchManifestSuite extends QaSuite {
  const WorkSupplyParserCatalogBatchManifestSuite()
    : super('inventory.catalog_batch_manifest_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _pipelinePath = 'tool/work_supply_parser_qa_pipeline.dart';
  static const _matrixPath = 'tool/work_supply_parser_qa_matrix_pipeline.dart';
  static const _supportedMatrixPath =
      'tool/work_supply_parser_qa_supported_matrix.dart';
  static const _releaseCommandPath =
      'tool/work_supply_parser_qa_release_one_commands.dart';
  static const _fixturePlanPath =
      'tool/work_supply_parser_qa_fixture_batch_plan.dart';
  static const _fixtureStatusPath =
      'tool/work_supply_parser_qa_fixture_batch_status.dart';
  static const _pipelineStatusPath =
      'tool/work_supply_parser_qa_pipeline_status.dart';
  static const _readinessPath =
      'tool/work_supply_parser_qa_release_one_readiness.dart';

  static const _manifestFields = {
    'trade',
    'marketScope',
    'tier',
    'localePackId',
    'fixturePath',
    'blueprintPath',
    'parserRunCommand',
    'generatedCount',
    'validatedCount',
    'failedCount',
    'lastEvidence',
    'coveredInputs',
    'surgicalRerun',
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
  };

  static const _matrixDimensions = {
    'plumbing',
    'electrical',
    'hvac',
    'residential',
    'core',
    'standard',
    'professional',
    'complete',
    'en-US',
    'es-US',
  };

  static const _pipelineTokens = {
    'QA_ECONOMICAL_PIPELINE',
    'QA_ECONOMICAL_MATRIX_PIPELINE',
    'QA_SUPPORTED_MATRIX',
    'QA_RELEASE_ONE_COMMANDS',
    'QA_ECONOMICAL_PIPELINE_STATUS',
    'QA_RELEASE_ONE_READINESS',
    'latest_pipeline_summary.json',
    'latest_pipeline_status.json',
    'release_one_commands.json',
    'fixture_readiness_rollup.json',
  };

  static const _safetyTokens = {
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
    'parserCalls',
    'dryRun',
    'execute',
    'requireComplete',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final pipelineSources = [
      _read(_pipelinePath),
      _read(_matrixPath),
      _read(_supportedMatrixPath),
      _read(_releaseCommandPath),
      _read(_fixturePlanPath),
      _read(_fixtureStatusPath),
      _read(_pipelineStatusPath),
      _read(_readinessPath),
    ].join('\n');
    var checked = 0;

    checked += _manifestFields.length;
    for (final field in _manifestFields) {
      if (progress.contains(field) || pipelineSources.contains(field)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_manifest_field:$field',
          message:
              'Catalog/fixture batch manifest is missing a required tracking field.',
          expected: field,
          actual: 'not found in progress memory or pipeline tools',
          fix:
              'Track batch identity, generated outputs, validation counts, safety flags, evidence, and surgical rerun commands before expanding more items.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _matrixDimensions.length;
    for (final dimension in _matrixDimensions) {
      if (progress.contains(dimension) || pipelineSources.contains(dimension)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_manifest_dimension:${_safeId(dimension)}',
          message:
              'Release-one catalog batch manifest is missing a required matrix dimension.',
          expected: dimension,
          actual: 'not found',
          fix:
              'Keep release-one batches explicit by trade, residential scope, tier, and locale so completed work is not repeated.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _pipelineTokens.length;
    for (final token in _pipelineTokens) {
      if (pipelineSources.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_pipeline_manifest_token:${_safeId(token)}',
          message:
              'Pipeline tooling is missing a required batch-manifest artifact token.',
          expected: token,
          actual: 'not found in pipeline sources',
          fix:
              'Pipeline tools must emit durable machine-readable artifacts for future runs and handoffs.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _safetyTokens.length;
    for (final token in _safetyTokens) {
      if (pipelineSources.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_pipeline_safety_token:${_safeId(token)}',
          message: 'Pipeline tooling is missing a required local-only safety token.',
          expected: token,
          actual: 'not found in pipeline sources',
          fix:
              'Every batch manifest and status artifact must preserve local-only and no-live-write evidence.',
          category: QaFailureTriage.security,
        ),
      );
    }

    _checkCurrentMemory(progress, failures);
    checked += 10;

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'pipelineFiles': [
          _pipelinePath,
          _matrixPath,
          _supportedMatrixPath,
          _releaseCommandPath,
          _fixturePlanPath,
          _fixtureStatusPath,
          _pipelineStatusPath,
          _readinessPath,
        ],
        'contract':
            'Catalog item batches and generated fixture batches must have durable manifests with matrix dimensions, safety flags, evidence paths, counts, and surgical rerun commands before more inventory rows are generated.',
      },
    );
  }

  void _checkCurrentMemory(String progress, List<QaFailure> failures) {
    const requiredMemoryTokens = {
      'Completed Parser Evidence',
      'Generated Fixture Cells',
      'Pending QA Test Batches',
      'Surgical Rerun Map',
      'Do Not Rerun Unless Inputs Changed',
      'focused-validated',
      'focusedRerun',
      'doNotRerunUnless',
      'coveredInputs',
      'lastEvidence',
    };
    for (final token in requiredMemoryTokens) {
      if (progress.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_batch_memory_token:${_safeId(token)}',
          message: 'Progress memory is missing a required batch-memory token.',
          expected: token,
          actual: 'not found in $_progressPath',
          fix:
              'Progress memory must be strong enough to survive context compression and prevent duplicate reruns.',
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
