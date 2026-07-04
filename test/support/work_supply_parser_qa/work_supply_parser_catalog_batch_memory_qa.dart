import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCatalogBatchMemorySuite extends QaSuite {
  const WorkSupplyParserCatalogBatchMemorySuite()
    : super('inventory.catalog_batch_memory_contract');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _waveStatusPath =
      'build/parser_qa_batch_waves/pass1939-residential-top-three-all-tiers-wave-execute/queue/'
      'pass1939_residential_top_three_all_tiers_wave_execute_generated_fixture_all_tiers_v7_post_core_standard_wave/'
      'latest_status.json';
  static const _blueprintStatusPath =
      'build/parser_qa_pipeline/status_reports/latest_pipeline_status.json';
  static const _blueprintMatrixSummaryPath =
      'build/parser_qa_pipeline/matrix_reports/latest_pipeline_summary.json';
  static const _releaseReadinessPath =
      'build/parser_qa_pipeline/release_one_readiness.json';
  static const _batchSizeAdvicePath =
      'build/parser_qa_pipeline/batch_size_advice_release_one.json';
  static const _fixtureRoot = 'build/parser_qa_generated/work_supply_parser';
  static const _priorityTrades = ['plumbing', 'electrical', 'hvac'];
  static const _tiers = ['core', 'standard', 'professional', 'complete'];
  static const _locales = ['en-US', 'es-US'];

  static const _requiredProgressSections = {
    'Inventory QA Progress Memory',
    'Completed Parser Evidence',
    'Do Not Rerun Unless Inputs Changed',
    'Pending QA Test Batches',
    'Surgical Rerun Map',
    'Inventory-Only Boundaries',
  };

  static const _requiredMemoryFields = {
    'suiteId',
    'status',
    'lastEvidence',
    'coveredInputs',
    'focusedRerun',
    'doNotRerunUnless',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _readText(_progressPath);
    final plan = _readText(_planPath);
    final status = _readJsonMap(_waveStatusPath, failures);
    final blueprintStatus = _readJsonMap(_blueprintStatusPath, failures);
    final blueprintMatrix = _readJsonMap(_blueprintMatrixSummaryPath, failures);
    final releaseReadiness = _readJsonMap(_releaseReadinessPath, failures);
    final batchAdvice = _readJsonMap(_batchSizeAdvicePath, failures);
    final generatedCells = _generatedFixtureCells();
    var checked = 0;

    checked += _requiredProgressSections.length;
    for (final section in _requiredProgressSections) {
      if (progress.contains(section)) continue;
      failures.add(
        _failure(
          id: 'missing_progress_section:${_safeId(section)}',
          message:
              'Inventory QA progress memory is missing a required section.',
          expected: section,
          actual: 'not found in $_progressPath',
          fix:
              'Add durable progress memory so context compression does not cause repeated work.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _requiredMemoryFields.length;
    for (final field in _requiredMemoryFields) {
      if (progress.contains(field)) continue;
      failures.add(
        _failure(
          id: 'missing_progress_field:$field',
          message:
              'Inventory QA progress memory is missing a required tracking field.',
          expected: field,
          actual: 'not found in $_progressPath',
          fix:
              'Track suite status, covered inputs, evidence, and focused rerun command before adding more catalog batches.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += 8;
    _checkCompletedWave(status, failures);

    checked += 15;
    _checkBlueprintBatchStatus(blueprintStatus, blueprintMatrix, failures);

    checked += 13;
    _checkReleaseReadinessAndAdvice(
      waveStatus: status,
      readiness: releaseReadiness,
      advice: batchAdvice,
      failures: failures,
    );

    checked += generatedCells.length * 4;
    for (final cell in generatedCells) {
      _checkGeneratedCellMemory(cell, progress, failures);
    }

    checked += 8;
    _checkNoDriftMemory(progress, plan, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'generatedCells': generatedCells.length,
        'waveStatusPath': _waveStatusPath,
        'blueprintStatusPath': _blueprintStatusPath,
        'blueprintMatrixSummaryPath': _blueprintMatrixSummaryPath,
        'releaseReadinessPath': _releaseReadinessPath,
        'batchSizeAdvicePath': _batchSizeAdvicePath,
        'contract':
            'The inventory parser QA project must remember completed cells, last evidence, covered inputs, and surgical rerun targets so finished tests are not rerun blindly after context compression.',
      },
    );
  }

  void _checkCompletedWave(
    Map<String, Object?> status,
    List<QaFailure> failures,
  ) {
    if (status.isEmpty) {
      failures.add(
        _failure(
          id: 'missing_all_tiers_wave_status',
          message: 'All-tier residential parser wave status is missing.',
          expected: _waveStatusPath,
          actual: 'not found',
          fix:
              'Record completed parser wave evidence before launching another broad wave.',
          category: QaFailureTriage.governance,
        ),
      );
      return;
    }
    final state = status['state'];
    if (state != 'complete' && state != 'running') {
      failures.add(
        _failure(
          id: 'unexpected_wave_status:state',
          message:
              'Inventory wave status must be either safely running or complete.',
          expected: 'state=running or state=complete',
          actual: 'state=$state',
          fix:
              'Do not build the next broad inventory parser wave unless the current wave is safely running or complete.',
          category: QaFailureTriage.governance,
        ),
      );
    }
    _expectStatus(status, failures, 'cellCount', 24);
    if (state == 'complete') {
      _expectStatus(status, failures, 'completedCellCount', 24);
    } else {
      final completed = status['completedCellCount'];
      if (completed is! int || completed < 1 || completed >= 24) {
        failures.add(
          _failure(
            id: 'unexpected_wave_status:completedCellCount',
            message:
                'Running inventory wave status does not show safe in-progress evidence.',
            expected: 'completedCellCount between 1 and 23 while running',
            actual: 'completedCellCount=$completed',
            fix:
                'Inspect the active local-only wave before launching any additional broad parser work.',
            category: QaFailureTriage.governance,
          ),
        );
      }
    }
    _expectStatus(status, failures, 'failedCellCount', 0);
    _expectStatus(status, failures, 'dryRun', false);
    _expectStatus(status, failures, 'liveServicesAllowed', false);
    _expectStatus(status, failures, 'writesProductionCatalog', false);
    _expectStatus(status, failures, 'firebaseWritesAllowed', false);
    _expectStatus(status, failures, 'ocrCameraExpensesTouched', false);
  }

  void _checkBlueprintBatchStatus(
    Map<String, Object?> status,
    Map<String, Object?> matrix,
    List<QaFailure> failures,
  ) {
    if (status.isEmpty) {
      failures.add(
        _failure(
          id: 'missing_blueprint_batch_status',
          message: 'Latest generated blueprint batch status is missing.',
          expected: _blueprintStatusPath,
          actual: 'not found',
          fix:
              'Run the local pipeline status reader after blueprint generation so future passes can resume surgically.',
          category: QaFailureTriage.governance,
        ),
      );
      return;
    }

    _expectStatus(status, failures, 'expectedCells', 24);
    _expectStatus(status, failures, 'presentCells', 24);
    _expectStatus(status, failures, 'missingCells', 0);
    _expectStatus(status, failures, 'unsafeCells', 0);
    _expectStatus(status, failures, 'parserCalls', 0);
    _expectStatus(status, failures, 'liveServicesAllowed', false);
    _expectStatus(status, failures, 'writesProductionCatalog', false);
    _expectStatus(status, failures, 'requireComplete', true);
    _expectMatrixSafety(matrix, failures);
    _expectMatrixCells(matrix, failures);
  }

  void _checkReleaseReadinessAndAdvice({
    required Map<String, Object?> waveStatus,
    required Map<String, Object?> readiness,
    required Map<String, Object?> advice,
    required List<QaFailure> failures,
  }) {
    if (readiness.isEmpty && waveStatus['state'] == 'complete') {
      failures.add(
        _failure(
          id: 'missing_release_one_readiness_artifact',
          message: 'Release-one parser readiness artifact is missing.',
          expected: _releaseReadinessPath,
          actual: 'not found',
          fix:
              'Generate release-one readiness from completed wave, pipeline status, and fixture readiness before starting another heavy wave.',
          category: QaFailureTriage.governance,
        ),
      );
    } else if (readiness.isNotEmpty) {
      _expectStatus(readiness, failures, 'releaseOneParserEvidenceReady', true);
      _expectStatus(
        readiness,
        failures,
        'releaseOnePipelineArtifactsReady',
        true,
      );
      _expectStatus(
        readiness,
        failures,
        'releaseOneFixtureEvidenceReady',
        true,
      );
      _expectStatus(readiness, failures, 'fixtureReadinessReady', true);
      _expectStatus(readiness, failures, 'waveFailedCellCount', 0);
      _expectStatus(readiness, failures, 'pipelineMissingCells', 0);
    }
    if (advice.isEmpty) {
      failures.add(
        _failure(
          id: 'missing_batch_size_advice_artifact',
          message: 'Batch-size advice artifact is missing.',
          expected: _batchSizeAdvicePath,
          actual: 'not found',
          fix:
              'Generate batch-size advice from duration evidence instead of guessing fixture run limits.',
          category: QaFailureTriage.performance,
        ),
      );
      return;
    }
    _expectStatus(advice, failures, 'currentFixtureRunLimit', 118);
    _expectPositiveInt(advice, failures, 'recommendedFixtureRunLimit');
    _expectAllowedString(advice, failures, 'recommendation', {
      'increase',
      'decrease',
      'keep',
    });
    _expectPositiveInt(advice, failures, 'completedCellCount');
    _expectPositiveInt(advice, failures, 'averageDurationMs');
    _expectStatus(advice, failures, 'liveServicesAllowed', false);
    _expectStatus(advice, failures, 'writesProductionCatalog', false);
  }

  void _expectPositiveInt(
    Map<String, Object?> status,
    List<QaFailure> failures,
    String field,
  ) {
    final value = status[field];
    if (value is int && value > 0) return;
    failures.add(
      _failure(
        id: 'unexpected_wave_status:$field',
        message:
            'Inventory wave tuning evidence is missing a positive numeric field.',
        expected: '$field > 0',
        actual: '$field=$value',
        fix:
            'Regenerate duration/advice evidence from real completed cells before changing parser batch sizes.',
        category: QaFailureTriage.performance,
      ),
    );
  }

  void _expectAllowedString(
    Map<String, Object?> status,
    List<QaFailure> failures,
    String field,
    Set<String> allowed,
  ) {
    final value = status[field];
    if (value is String && allowed.contains(value)) return;
    failures.add(
      _failure(
        id: 'unexpected_wave_status:$field',
        message: 'Inventory wave tuning evidence has an invalid value.',
        expected: '$field in ${allowed.join(', ')}',
        actual: '$field=$value',
        fix:
            'Regenerate batch-size advice with a valid increase/decrease/keep recommendation.',
        category: QaFailureTriage.performance,
      ),
    );
  }

  void _expectMatrixSafety(
    Map<String, Object?> matrix,
    List<QaFailure> failures,
  ) {
    if (matrix.isEmpty) {
      failures.add(
        _failure(
          id: 'missing_blueprint_matrix_summary',
          message: 'Latest blueprint matrix summary is missing.',
          expected: _blueprintMatrixSummaryPath,
          actual: 'not found',
          fix:
              'Keep the release-one residential blueprint matrix summary so generated-cell scope is auditable.',
          category: QaFailureTriage.governance,
        ),
      );
      return;
    }
    _expectStatus(matrix, failures, 'dryRun', false);
    _expectStatus(matrix, failures, 'runFixtures', false);
    _expectStatus(matrix, failures, 'statusGate', true);
    _expectStatus(matrix, failures, 'statusGateExitCode', 0);
    _expectStatus(matrix, failures, 'liveServicesAllowed', false);
    _expectStatus(matrix, failures, 'writesProductionCatalog', false);
  }

  void _expectMatrixCells(
    Map<String, Object?> matrix,
    List<QaFailure> failures,
  ) {
    final results = matrix['results'];
    if (results is! List) {
      failures.add(
        _failure(
          id: 'missing_blueprint_matrix_results',
          message: 'Blueprint matrix summary is missing per-cell results.',
          expected: '12 trade/tier result rows covering two locales each',
          actual: 'results=${results.runtimeType}',
          fix:
              'Record matrix result rows so each trade/tier can be checked without rerunning the generator.',
          category: QaFailureTriage.governance,
        ),
      );
      return;
    }
    if (results.length != 12) {
      failures.add(
        _failure(
          id: 'unexpected_blueprint_matrix_result_count',
          message:
              'Blueprint matrix result count does not match release-one scope.',
          expected: '12 trade/tier rows',
          actual: '${results.length} rows',
          fix:
              'The release-one top-three-trade matrix must cover 3 trades x 4 tiers, each with en-US and es-US.',
          category: QaFailureTriage.governance,
        ),
      );
    }
    for (final result in results.whereType<Map>()) {
      if (result['exitCode'] == 0) continue;
      failures.add(
        _failure(
          id: 'blueprint_matrix_cell_failed:${result['trade']}_${result['tier']}',
          message: 'A generated blueprint matrix cell did not exit cleanly.',
          expected: 'exitCode=0',
          actual: 'exitCode=${result['exitCode']}',
          fix:
              'Fix or rerun only this generated blueprint trade/tier cell before promoting catalog work.',
          category: QaFailureTriage.governance,
        ),
      );
    }
  }

  void _expectStatus(
    Map<String, Object?> status,
    List<QaFailure> failures,
    String field,
    Object expected,
  ) {
    if (status[field] == expected) return;
    failures.add(
      _failure(
        id: 'unexpected_wave_status:$field',
        message:
            'Completed inventory wave status does not match expected evidence.',
        expected: '$field=$expected',
        actual: '$field=${status[field]}',
        fix:
            'Do not build the next broad inventory parser wave on uncertain or unsafe evidence.',
        category: QaFailureTriage.governance,
      ),
    );
  }

  void _checkGeneratedCellMemory(
    _GeneratedCell cell,
    String progress,
    List<QaFailure> failures,
  ) {
    if (!File(cell.fixturePath).existsSync()) {
      failures.add(
        _failure(
          id: 'missing_generated_fixture_cell:${cell.id}',
          message: 'Generated fixture cell is missing from disk.',
          expected: cell.fixturePath,
          actual: 'not found',
          fix:
              'Generate the missing fixture cell before marking this catalog/fixture lane complete.',
          category: QaFailureTriage.fixture,
        ),
      );
      return;
    }
    if (!progress.contains(cell.id)) {
      failures.add(
        _failure(
          id: 'generated_cell_not_in_progress_memory:${cell.id}',
          message: 'Generated fixture cell is not recorded in progress memory.',
          expected: cell.id,
          actual: 'not found in $_progressPath',
          fix:
              'Record every generated trade/scope/tier/locale cell so completed work is not regenerated blindly.',
          category: QaFailureTriage.governance,
        ),
      );
    }
    if (!progress.contains(cell.fixturePath)) {
      failures.add(
        _failure(
          id: 'generated_cell_path_not_in_progress_memory:${cell.id}',
          message: 'Generated fixture path is not recorded in progress memory.',
          expected: cell.fixturePath,
          actual: 'not found in $_progressPath',
          fix:
              'Record fixture paths so focused reruns can target the exact generated cell.',
          category: QaFailureTriage.governance,
        ),
      );
    }
    final rerunToken =
        'PARSER_QA_GENERATED_FIXTURE_PATH=${cell.fixturePath.replaceAll('\\', '/')}';
    if (!progress.contains(rerunToken)) {
      failures.add(
        _failure(
          id: 'missing_surgical_rerun_token:${cell.id}',
          message: 'Generated fixture cell has no focused rerun token.',
          expected: rerunToken,
          actual: 'not found in $_progressPath',
          fix:
              'Add focused rerun commands per generated cell instead of rerunning the full catalog.',
          category: QaFailureTriage.performance,
        ),
      );
    }
  }

  void _checkNoDriftMemory(
    String progress,
    String plan,
    List<QaFailure> failures,
  ) {
    const boundaryTokens = {
      'inventory-only',
      'No UI/UX',
      'No OCR',
      'No camera',
      'No PDF',
      'No Expenses',
      'No Firebase live writes',
      'No maintenance',
    };
    for (final token in boundaryTokens) {
      if (progress.contains(token) || plan.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_no_drift_boundary:${_safeId(token)}',
          message: 'Inventory QA memory is missing a no-drift boundary.',
          expected: token,
          actual: 'not found',
          fix:
              'Keep the working memory explicit so future passes do not drift outside inventory parser/catalog QA.',
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

List<_GeneratedCell> _generatedFixtureCells() {
  return [
    for (final trade in WorkSupplyParserCatalogBatchMemorySuite._priorityTrades)
      for (final tier in WorkSupplyParserCatalogBatchMemorySuite._tiers)
        for (final locale in WorkSupplyParserCatalogBatchMemorySuite._locales)
          _GeneratedCell(
            trade: trade,
            scope: 'residential',
            tier: tier,
            locale: locale,
          ),
  ];
}

class _GeneratedCell {
  const _GeneratedCell({
    required this.trade,
    required this.scope,
    required this.tier,
    required this.locale,
  });

  final String trade;
  final String scope;
  final String tier;
  final String locale;

  String get localeSafe => locale.replaceAll('-', '_');

  String get id => '${trade}_${scope}_${tier}_$localeSafe';

  String get fixturePath =>
      '${WorkSupplyParserCatalogBatchMemorySuite._fixtureRoot}/$trade/$scope/$tier/$locale/generated_fixtures.json';
}

String _readText(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

Map<String, Object?> _readJsonMap(String path, List<QaFailure> failures) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is Map) return decoded.cast<String, Object?>();
  } catch (_) {
    return const {};
  }
  return const {};
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
