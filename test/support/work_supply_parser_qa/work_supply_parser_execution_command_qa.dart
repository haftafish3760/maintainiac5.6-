import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserExecutionCommandSuite extends QaSuite {
  const WorkSupplyParserExecutionCommandSuite()
    : super('inventory.execution_command_contract');

  static const _entryPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _presetPath = 'test/support/qa_harness/qa_suite_presets.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _artifactPath = 'test/support/qa_harness/qa_harness.dart';
  static const _backgroundQueuePath =
      'tool/work_supply_parser_qa_background_queue.dart';
  static const _backgroundQueueStatusPath =
      'tool/work_supply_parser_qa_background_queue_status.dart';
  static const _batchWavePath = 'tool/work_supply_parser_qa_batch_wave.dart';
  static const _batchWaveStatusPath =
      'tool/work_supply_parser_qa_batch_wave_status.dart';
  static const _batchWaveReportPath =
      'tool/work_supply_parser_qa_batch_wave_report.dart';
  static const _transcriptAuditPath =
      'tool/work_supply_parser_qa_transcript_audit.dart';
  static const _failureDigestPath =
      'tool/work_supply_parser_qa_failure_digest.dart';
  static const _durationReportPath =
      'tool/work_supply_parser_qa_duration_report.dart';
  static const _batchSizeAdvisorPath =
      'tool/work_supply_parser_qa_batch_size_advisor.dart';
  static const _queueWatchdogPath =
      'tool/work_supply_parser_qa_queue_watchdog.dart';
  static const _runIntelligenceReportPath =
      'tool/work_supply_parser_qa_run_intelligence_report.dart';
  static const _releaseOneReadinessPath =
      'tool/work_supply_parser_qa_release_one_readiness.dart';
  static const _gateLedgerPath = 'tool/work_supply_parser_qa_gate_ledger.dart';
  static const _gateShouldRunPath =
      'tool/work_supply_parser_qa_gate_should_run.dart';
  static const _generatedRunStatusPath =
      'tool/work_supply_parser_qa_generated_run_status.dart';
  static const _pehCoreStatusRollupPath =
      'tool/work_supply_parser_qa_peh_core_status_rollup.dart';
  static const _pehCoreMacWaveCommandsPath =
      'tool/work_supply_parser_qa_peh_core_mac_wave_commands.dart';

  static const _environmentVariables = [
    'PARSER_QA_STRICT',
    'PARSER_QA_MAX_GENERATED_CASES',
    'PARSER_QA_MAX_FAILURES_PER_SUITE',
    'PARSER_QA_CATALOG_SCHEMA_SAMPLE_LIMIT',
    'PARSER_QA_ALIAS_SAMPLE_LIMIT',
    'PARSER_QA_PROFILE',
    'PARSER_QA_PRESET',
    'PARSER_QA_BASELINE',
    'PARSER_QA_SUITES',
    'PARSER_QA_FIXTURE_IDS',
    'PARSER_QA_MUTATION_MODE',
    'PARSER_QA_MUTATION_SCENARIOS',
    'PARSER_QA_MUTATION_DRY_RUN',
    'PARSER_QA_SHARD_ID',
    'PARSER_QA_TIMEOUT_BUDGET_MS',
    'PARSER_QA_RESUME_FROM',
  ];

  static const _runConfigFields = [
    'profile: profile',
    'preset: preset',
    'baselinePath: baselinePath',
    'maxGeneratedCases: maxGeneratedCases',
    'maxFailuresPerSuite: maxFailuresPerSuite',
    'catalogSchemaSampleLimit: catalogSchemaSampleLimit',
    'aliasSampleLimit: aliasSampleLimit',
    'fixtureIds: fixtureIds',
    'mutationMode: mutationMode',
    'mutationScenarios: mutationScenarios',
    'mutationDryRun: mutationDryRun',
    'shardId: shardId',
    'timeoutBudgetMs: timeoutBudgetMs',
    'resumeFrom: resumeFrom',
    'suiteFilter: suiteFilter',
  ];

  static const _operatingPolicyTokens = [
    'Quality gates must run non-interactively by default',
    'wait for process completion',
    'summarize only actionable results',
    'Do not continuously narrate terminal scroll',
    'Switch to live monitoring only if',
    'Do not rerun analyzer, QA runner, or full quality gates unless source files affecting those checks changed',
  ];

  static const _documentedCommands = [
    _CommandContract('smoke_base', [
      'flutter test test/work_supply_parser_qa_harness_test.dart',
      '--dart-define=PARSER_QA_PROFILE=smoke',
    ]),
    _CommandContract('quick_preset', ['--dart-define=PARSER_QA_PRESET=quick']),
    _CommandContract('fixtures_preset', [
      '--dart-define=PARSER_QA_PRESET=fixtures',
    ]),
    _CommandContract('catalog_preset', [
      '--dart-define=PARSER_QA_PRESET=catalog',
    ]),
    _CommandContract('sample_limited_catalog', [
      '--dart-define=PARSER_QA_CATALOG_SCHEMA_SAMPLE_LIMIT=1000',
      '--dart-define=PARSER_QA_ALIAS_SAMPLE_LIMIT=1000',
    ]),
    _CommandContract('targeted_suite', [
      '--dart-define=PARSER_QA_SUITES=inventory.security_privacy',
    ]),
    _CommandContract('targeted_threshold_gate', [
      '--dart-define=PARSER_QA_SUITES=inventory.security_privacy,qa.threshold_gate',
    ]),
    _CommandContract('focused_fixture_ids', [
      '--dart-define=PARSER_QA_SUITES=inventory.golden_fixtures,qa.threshold_gate',
      '--dart-define=PARSER_QA_FIXTURE_IDS=',
    ]),
    _CommandContract('baseline_diff', ['--dart-define=PARSER_QA_BASELINE=']),
    _CommandContract('full_profile', [
      '--dart-define=PARSER_QA_PROFILE=full',
      '--dart-define=PARSER_QA_MAX_GENERATED_CASES=500',
    ]),
    _CommandContract('release_strict', [
      '--dart-define=PARSER_QA_PROFILE=release',
      '--dart-define=PARSER_QA_STRICT=true',
    ]),
    _CommandContract('mutation_dry_run', [
      '--dart-define=PARSER_QA_MUTATION_MODE=dry-run',
      '--dart-define=PARSER_QA_MUTATION_DRY_RUN=true',
    ]),
    _CommandContract('mutation_scenario_filter', [
      '--dart-define=PARSER_QA_MUTATION_SCENARIOS=',
    ]),
    _CommandContract('release_shard_metadata', [
      '--dart-define=PARSER_QA_SHARD_ID=',
      '--dart-define=PARSER_QA_TIMEOUT_BUDGET_MS=',
      '--dart-define=PARSER_QA_RESUME_FROM=',
    ]),
    _CommandContract('shard_runner_dry_run', [
      'dart run tool/work_supply_parser_qa_shard_runner.dart --dry-run',
    ]),
    _CommandContract('release_signoff', [
      'dart run tool/work_supply_parser_qa_release_signoff.dart',
      '--expected-profile release',
      '--max-age-hours 168',
    ]),
    _CommandContract('report_prune_dry_run', [
      'dart run tool/work_supply_parser_qa_prune_reports.dart',
      '--keep 20',
    ]),
    _CommandContract('report_prune_execute', [
      'dart run tool/work_supply_parser_qa_prune_reports.dart',
      '--execute',
    ]),
    _CommandContract('supported_matrix_report', [
      'dart run tool/work_supply_parser_qa_supported_matrix.dart',
      '--output build/parser_qa_pipeline/supported_matrix.json',
    ]),
    _CommandContract('background_queue_dry_run', [
      'dart run tool/work_supply_parser_qa_background_queue.dart',
      '--trades plumbing',
      '--tiers core,standard',
      '--locales en-US,es-US',
    ]),
    _CommandContract('background_queue_execute', [
      'dart run tool/work_supply_parser_qa_background_queue.dart',
      '--execute',
      '--fixture-run-limit',
    ]),
    _CommandContract('background_queue_status', [
      'dart run tool/work_supply_parser_qa_background_queue_status.dart',
      '--root build/parser_qa_background_queue',
      '--queue-id',
    ]),
    _CommandContract('batch_wave_dry_run', [
      'dart run tool/work_supply_parser_qa_batch_wave.dart',
      '--wave-id residential-core-wave-002',
      '--previous-wave-id residential-core-wave-001',
      '--qa-layer merchant-abbreviation-v1',
    ]),
    _CommandContract('batch_wave_execute', [
      'dart run tool/work_supply_parser_qa_batch_wave.dart',
      '--execute',
      '--fixture-run-limit',
    ]),
    _CommandContract('batch_wave_status', [
      'dart run tool/work_supply_parser_qa_batch_wave_status.dart',
      '--root build/parser_qa_batch_waves',
      '--wave-id',
    ]),
    _CommandContract('batch_wave_report', [
      'dart run tool/work_supply_parser_qa_batch_wave_report.dart',
      '--root build/parser_qa_batch_waves',
      '--wave-ids',
      '--output',
    ]),
    _CommandContract('transcript_audit', [
      'dart run tool/work_supply_parser_qa_transcript_audit.dart',
      '--summary',
      '--output',
    ]),
    _CommandContract('failure_digest', [
      'dart run tool/work_supply_parser_qa_failure_digest.dart',
      '--summary',
      '--output',
    ]),
    _CommandContract('duration_report', [
      'dart run tool/work_supply_parser_qa_duration_report.dart',
      '--summary',
      '--output',
    ]),
    _CommandContract('batch_size_advisor', [
      'dart run tool/work_supply_parser_qa_batch_size_advisor.dart',
      '--duration-report',
      '--current-fixture-run-limit',
      '--target-cell-ms',
      '--min-completed-cells',
      '--output',
    ]),
    _CommandContract('queue_watchdog', [
      'dart run tool/work_supply_parser_qa_queue_watchdog.dart',
      '--status',
      '--max-status-age-ms',
      '--max-active-cell-ms',
      '--output',
    ]),
    _CommandContract('run_intelligence_report', [
      'dart run tool/work_supply_parser_qa_run_intelligence_report.dart',
      '--root build/parser_qa_batch_waves',
      '--wave-id',
      '--output',
    ]),
    _CommandContract('release_one_readiness', [
      'dart run tool/work_supply_parser_qa_release_one_readiness.dart',
      '--wave-report',
      '--pipeline-status',
      '--fixture-readiness',
      '--output',
    ]),
    _CommandContract('gate_ledger', [
      'dart run tool/work_supply_parser_qa_gate_ledger.dart',
      '--gate analyzer',
      '--command',
      '--inputs',
      '--output',
    ]),
    _CommandContract('gate_should_run', [
      'dart run tool/work_supply_parser_qa_gate_should_run.dart',
      '--ledger build/parser_qa_pass_evidence/gate_ledger.json',
      '--inputs',
    ]),
    _CommandContract('generated_run_status', [
      'dart run tool/work_supply_parser_qa_generated_run_status.dart',
      '--report-root',
      '--require-complete',
      '--min-checked-per-cell',
      '--min-pass-rate',
      '--output',
    ]),
    _CommandContract('peh_core_status_rollup', [
      'dart run tool/work_supply_parser_qa_peh_core_status_rollup.dart',
      '--plumbing-status',
      '--electrical-status',
      '--hvac-status',
      '--output',
    ]),
    _CommandContract('peh_core_mac_wave_commands', [
      'dart run tool/work_supply_parser_qa_peh_core_mac_wave_commands.dart',
      '--output',
      'build/parser_qa_pipeline/peh_core_mac_wave_commands.json',
    ]),
  ];

  static const _toolSourceContracts = [
    _ToolSourceContract(
      name: 'background_queue_local_safety',
      path: _backgroundQueuePath,
      tokens: [
        'QA_BACKGROUND_QUEUE_SUMMARY',
        'summary.json',
        'latest_status.json',
        'activeCellStartedAtIso',
        'activeCellElapsedMs',
        'liveServicesAllowed',
        'writesProductionCatalog',
        'dryRun',
        'Process.start',
        'tool/work_supply_parser_qa_matrix_pipeline.dart',
        'latest_generated_fixture_run.json',
        'recoveredFromGeneratedFixtureReport',
        '--cell-timeout-ms',
        'QA_BACKGROUND_QUEUE_CELL_TIMEOUT',
        'taskkill',
        '/T',
        '--execute',
      ],
    ),
    _ToolSourceContract(
      name: 'background_queue_status_readout',
      path: _backgroundQueueStatusPath,
      tokens: [
        'QA_BACKGROUND_QUEUE_STATUS',
        'latest_status.json',
        'summary.json',
        'failedCellCount',
        'completedCellCount',
        'liveServicesAllowed',
        'writesProductionCatalog',
      ],
    ),
    _ToolSourceContract(
      name: 'generated_run_status_readout',
      path: _generatedRunStatusPath,
      tokens: [
        'QA_GENERATED_RUN_STATUS',
        'QA_GENERATED_RUN_STATUS_ARTIFACT',
        'latest_generated_fixture_run.json',
        'expectedCells',
        'presentCells',
        'missingCells',
        'failedCells',
        'unsafeCells',
        'underMinCheckedCells',
        'underMinPassRateCells',
        'minCheckedPerCell',
        'minPassRate',
        'checkedTotal',
        'failureCount',
        'passRate',
        'parserCalls',
        'durationMs',
        'firebaseWritesAllowed',
        'ocrCameraExpensesTouched',
      ],
    ),
    _ToolSourceContract(
      name: 'peh_core_status_rollup_readout',
      path: _pehCoreStatusRollupPath,
      tokens: [
        'QA_PEH_CORE_STATUS_ROLLUP',
        'QA_PEH_CORE_STATUS_ROLLUP_ARTIFACT',
        'underTargetTradeCount',
        'sampleSizedTradeCount',
        'readyForMacMeasurementWave',
        'readyToClaimNinetyPlus',
        'plumbing',
        'electrical',
        'hvac',
      ],
    ),
    _ToolSourceContract(
      name: 'peh_core_mac_wave_commands_readout',
      path: _pehCoreMacWaveCommandsPath,
      tokens: [
        'QA_PEH_CORE_MAC_WAVE_COMMANDS',
        'QA_PEH_CORE_MAC_WAVE_COMMANDS_ARTIFACT',
        'measurementCommandCount',
        'rollupCommandCount',
        'plumbingFocusedRuntimeCommand',
        'mac_peh_core_measurement_',
        'work_supply_parser_qa_run_generated_fixtures.dart',
        'work_supply_parser_qa_generated_run_status.dart',
      ],
    ),
    _ToolSourceContract(
      name: 'batch_wave_accumulated_layer_contract',
      path: _batchWavePath,
      tokens: [
        'QA_BATCH_WAVE_SUMMARY',
        'wave_plan.json',
        'wave_summary.json',
        'accumulatedWaveIds',
        'qaLayer',
        'liveServicesAllowed',
        'writesProductionCatalog',
        'firebaseWritesAllowed',
        'ocrCameraExpensesTouched',
        'runWorkSupplyParserQaBackgroundQueue',
      ],
    ),
    _ToolSourceContract(
      name: 'batch_wave_status_readout',
      path: _batchWaveStatusPath,
      tokens: [
        'QA_BATCH_WAVE_STATUS',
        'wave_summary.json',
        'wave_plan.json',
        'latest_status.json',
        'completedCellCount',
        'failedCellCount',
        'activeCellId',
        'firebaseWritesAllowed',
        'ocrCameraExpensesTouched',
      ],
    ),
    _ToolSourceContract(
      name: 'batch_wave_report_rollup',
      path: _batchWaveReportPath,
      tokens: [
        'QA_BATCH_WAVE_REPORT',
        'QA_BATCH_WAVE_REPORT_ARTIFACT',
        'totalCellCount',
        'completedCellCount',
        'failedCellCount',
        'remainingCellCount',
        'completionPercent',
        'allComplete',
        '--require-complete',
        'requireComplete',
        'unsafe',
        'firebaseWritesAllowed',
        'ocrCameraExpensesTouched',
      ],
    ),
    _ToolSourceContract(
      name: 'transcript_audit_evidence_contract',
      path: _transcriptAuditPath,
      tokens: [
        'QA_TRANSCRIPT_AUDIT',
        'QA_TRANSCRIPT_AUDIT_ARTIFACT',
        'checkedTranscriptCount',
        'failedTranscriptCount',
        'hasCommand',
        'hasExitCode',
        'hasLocalOnlySummary',
      ],
    ),
    _ToolSourceContract(
      name: 'failure_digest_contract',
      path: _failureDigestPath,
      tokens: [
        'QA_FAILURE_DIGEST',
        'QA_FAILURE_DIGEST_ARTIFACT',
        'failedCellCount',
        'failurePreview',
        'Expected:',
        'Actual:',
        'Some tests failed',
      ],
    ),
    _ToolSourceContract(
      name: 'duration_report_contract',
      path: _durationReportPath,
      tokens: [
        'QA_DURATION_REPORT',
        'QA_DURATION_REPORT_ARTIFACT',
        'totalDurationMs',
        'averageDurationMs',
        'slowestCells',
      ],
    ),
    _ToolSourceContract(
      name: 'batch_size_advisor_contract',
      path: _batchSizeAdvisorPath,
      tokens: [
        'QA_BATCH_SIZE_ADVICE',
        'QA_BATCH_SIZE_ADVICE_ARTIFACT',
        'recommendedFixtureRunLimit',
        'targetCellMs',
        'minCompletedCells',
        'slowestDurationMs',
      ],
    ),
    _ToolSourceContract(
      name: 'queue_watchdog_contract',
      path: _queueWatchdogPath,
      tokens: [
        'QA_QUEUE_WATCHDOG',
        'QA_QUEUE_WATCHDOG_ARTIFACT',
        'statusAgeMs',
        'activeCellElapsedMs',
        'active_cell_stale',
      ],
    ),
    _ToolSourceContract(
      name: 'run_intelligence_report_contract',
      path: _runIntelligenceReportPath,
      tokens: [
        'QA_RUN_INTELLIGENCE_REPORT',
        'QA_RUN_INTELLIGENCE_REPORT_ARTIFACT',
        'remainingCellCount',
        'nextActions',
        'recommendedFixtureRunLimit',
        'run_intelligence_report.txt',
      ],
    ),
    _ToolSourceContract(
      name: 'release_one_readiness_contract',
      path: _releaseOneReadinessPath,
      tokens: [
        'QA_RELEASE_ONE_READINESS',
        'QA_RELEASE_ONE_READINESS_ARTIFACT',
        'releaseOneParserEvidenceReady',
        'releaseOnePipelineArtifactsReady',
        'releaseOneFixtureEvidenceReady',
        'fixtureReadinessReady',
        'pipelineMissingCells',
        'nextActions',
      ],
    ),
    _ToolSourceContract(
      name: 'gate_ledger_contract',
      path: _gateLedgerPath,
      tokens: [
        'QA_GATE_LEDGER',
        'QA_GATE_LEDGER_ARTIFACT',
        'fingerprint',
        'liveServicesAllowed',
        'firebaseWritesAllowed',
        'ocrCameraExpensesTouched',
      ],
    ),
    _ToolSourceContract(
      name: 'gate_should_run_contract',
      path: _gateShouldRunPath,
      tokens: [
        'QA_GATE_SHOULD_RUN',
        'shouldRun',
        'changedInputs',
        'uncoveredInputs',
        'covered_unchanged',
        'changed_or_uncovered_inputs',
      ],
    ),
  ];

  static const _presetCases = [
    "case 'quick'",
    "case 'fixtures'",
    "case 'catalog'",
    'return const {}',
  ];

  static const _artifactContracts = [
    _ArtifactContract(
      name: 'latest_json',
      sourceTokens: ['latest_\${report.domain}.json', 'latestJsonPath'],
      planTokens: ['latest_work_supply_inventory_parser.json'],
    ),
    _ArtifactContract(
      name: 'latest_summary',
      sourceTokens: ['latest_\${report.domain}.txt', 'latestSummaryPath'],
      planTokens: ['latest_work_supply_inventory_parser.txt'],
    ),
    _ArtifactContract(
      name: 'latest_pack_health',
      sourceTokens: [
        'latest_\${report.domain}_pack_health.json',
        'latestPackHealthJsonPath',
      ],
      planTokens: ['latest_work_supply_inventory_parser_pack_health.json'],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final entry = _read(_entryPath, failures);
    final presets = _read(_presetPath, failures);
    final plan = _read(_planPath, failures);
    final artifacts = _read(_artifactPath, failures);
    final backgroundQueue = _read(_backgroundQueuePath, failures);
    final backgroundQueueStatus = _read(_backgroundQueueStatusPath, failures);
    final batchWave = _read(_batchWavePath, failures);
    final batchWaveStatus = _read(_batchWaveStatusPath, failures);
    final batchWaveReport = _read(_batchWaveReportPath, failures);
    final transcriptAudit = _read(_transcriptAuditPath, failures);
    final failureDigest = _read(_failureDigestPath, failures);
    final durationReport = _read(_durationReportPath, failures);
    final batchSizeAdvisor = _read(_batchSizeAdvisorPath, failures);
    final queueWatchdog = _read(_queueWatchdogPath, failures);
    final runIntelligenceReport = _read(_runIntelligenceReportPath, failures);
    final releaseOneReadiness = _read(_releaseOneReadinessPath, failures);
    final present = <String>[];
    var checked = 0;

    checked += _environmentVariables.length;
    for (final variable in _environmentVariables) {
      if (entry.contains(variable) && plan.contains(variable)) {
        present.add('env:$variable');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_execution_env:$variable',
          message: 'QA command environment variable is not fully wired.',
          expected: '$variable in entrypoint and docs',
          actual: _presence(entry, plan, variable),
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _runConfigFields.length;
    for (final field in _runConfigFields) {
      if (entry.contains(field)) {
        present.add('runConfig:$field');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_run_config_field:$field',
          message: 'QaRunConfig does not preserve a command-line knob.',
          expected: field,
          actual: 'not found',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _operatingPolicyTokens.length;
    for (final token in _operatingPolicyTokens) {
      if (plan.contains(token)) {
        present.add('operating_policy:$token');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_noninteractive_quality_gate_policy:$token',
          message:
              'The non-interactive quality-gate operating policy is not documented.',
          expected: token,
          actual: 'not found',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _documentedCommands.length;
    for (final command in _documentedCommands) {
      if (command.isPresentIn(plan)) {
        present.add('command:${command.name}');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_documented_command:${command.name}',
          message: 'A supported QA run command is not documented.',
          expected: command.tokens.join(' + '),
          actual: 'not found',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _presetCases.length;
    for (final presetCase in _presetCases) {
      if (presets.contains(presetCase)) {
        present.add('preset:$presetCase');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_preset_case:$presetCase',
          message: 'Named QA preset contract drifted.',
          expected: presetCase,
          actual: 'not found',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _artifactContracts.length;
    for (final artifact in _artifactContracts) {
      if (artifact.isPresent(source: artifacts, plan: plan)) {
        present.add('artifact:${artifact.name}');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_report_artifact_token:${artifact.name}',
          message: 'Reproducible command docs do not match report artifacts.',
          expected:
              'source=${artifact.sourceTokens.join(' + ')}; '
              'docs=${artifact.planTokens.join(' + ')}',
          actual:
              'source=${artifact.sourceTokens.every(artifacts.contains)}, '
              'docs=${artifact.planTokens.every(plan.contains)}',
          category: QaFailureTriage.governance,
        ),
      );
    }

    final toolSources = {
      _backgroundQueuePath: backgroundQueue,
      _backgroundQueueStatusPath: backgroundQueueStatus,
      _batchWavePath: batchWave,
      _batchWaveStatusPath: batchWaveStatus,
      _batchWaveReportPath: batchWaveReport,
      _transcriptAuditPath: transcriptAudit,
      _failureDigestPath: failureDigest,
      _durationReportPath: durationReport,
      _batchSizeAdvisorPath: batchSizeAdvisor,
      _queueWatchdogPath: queueWatchdog,
      _runIntelligenceReportPath: runIntelligenceReport,
      _releaseOneReadinessPath: releaseOneReadiness,
      _gateLedgerPath: _read(_gateLedgerPath, failures),
      _gateShouldRunPath: _read(_gateShouldRunPath, failures),
      _generatedRunStatusPath: _read(_generatedRunStatusPath, failures),
      _pehCoreStatusRollupPath: _read(_pehCoreStatusRollupPath, failures),
      _pehCoreMacWaveCommandsPath: _read(_pehCoreMacWaveCommandsPath, failures),
    };
    checked += _toolSourceContracts.length;
    for (final contract in _toolSourceContracts) {
      final source = toolSources[contract.path] ?? '';
      if (contract.isPresentIn(source) && contract.isPresentIn(plan)) {
        present.add('toolSource:${contract.name}');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_tool_source_contract:${contract.name}',
          message: 'QA background tool contract is not fully governed.',
          expected: '${contract.path}; tokens=${contract.tokens.join(' + ')}',
          actual:
              'source=${contract.isPresentIn(source)}, '
              'docs=${contract.isPresentIn(plan)}',
          category: QaFailureTriage.governance,
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + 4,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'entrypoint': _entryPath,
        'presetFile': _presetPath,
        'plan': _planPath,
        'artifactContract': _artifactPath,
      },
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      expected: expected,
      actual: actual,
      suggestedFix:
          'Keep QA harness command usage reproducible before scaling catalog generation.',
      metadata: {'triageCategory': category},
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      _failure(
        id: 'missing_execution_command_scan_file:$path',
        message: 'Execution-command contract scan file is missing.',
        expected: path,
        actual: 'not found',
        category: QaFailureTriage.schema,
      ),
    );
    return '';
  }

  String _presence(String first, String second, String token) {
    return 'source=${_containsContractToken(first, token)}, '
        'docs=${_containsContractToken(second, token)}';
  }
}

class _CommandContract {
  const _CommandContract(this.name, this.tokens);

  final String name;
  final List<String> tokens;

  bool isPresentIn(String source) {
    return tokens.every((token) => _containsContractToken(source, token));
  }
}

class _ArtifactContract {
  const _ArtifactContract({
    required this.name,
    required this.sourceTokens,
    required this.planTokens,
  });

  final String name;
  final List<String> sourceTokens;
  final List<String> planTokens;

  bool isPresent({required String source, required String plan}) {
    return sourceTokens.every(
          (token) => _containsContractToken(source, token),
        ) &&
        planTokens.every((token) => _containsContractToken(plan, token));
  }
}

class _ToolSourceContract {
  const _ToolSourceContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;

  bool isPresentIn(String source) =>
      tokens.every((token) => _containsContractToken(source, token));
}

bool _containsContractToken(String source, String token) {
  return _normalizeContractText(source).contains(_normalizeContractText(token));
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
