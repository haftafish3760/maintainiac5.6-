import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPortabilitySuite extends QaSuite {
  const WorkSupplyParserPortabilitySuite()
    : super('inventory.portability_contract');

  static const _scannedFiles = [
    '.gitignore',
    'docs/inventory_parser_qa_harness_plan.md',
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    'lib/screens/work_supplies/data/work_supply_receipt_parser_confidence_engine.dart',
    'lib/screens/work_supplies/data/work_supply_inventory_receipt_models.dart',
    'lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart',
    'tool/work_supply_parser_qa_shard_runner.dart',
    'tool/work_supply_parser_qa_release_signoff.dart',
    'tool/work_supply_parser_qa_prune_reports.dart',
    'test/support/qa_harness/qa_report_retention.dart',
  ];

  static const _contracts = [
    _PortabilityContract(
      name: 'platform_documentation',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: ['Windows', 'macOS', 'Linux', 'CI', 'Mac Mini'],
    ),
    _PortabilityContract(
      name: 'handoff_documentation',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: ['GitHub', 'external SSD', 'resume point'],
    ),
    _PortabilityContract(
      name: 'portable_artifact_root',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: ['build/parser_qa_reports', 'ignored by Git'],
    ),
    _PortabilityContract(
      name: 'build_output_ignored',
      path: '.gitignore',
      tokens: ['/build/'],
    ),
    _PortabilityContract(
      name: 'dart_entrypoint_commands',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: [
        'dart run tool/work_supply_parser_qa_shard_runner.dart',
        'dart run tool/work_supply_parser_qa_release_signoff.dart',
        'dart run tool/work_supply_parser_qa_prune_reports.dart',
      ],
    ),
    _PortabilityContract(
      name: 'shard_runner_uses_process_run',
      path: 'tool/work_supply_parser_qa_shard_runner.dart',
      tokens: ['Process.run', 'Platform.isWindows', 'runInShell'],
    ),
    _PortabilityContract(
      name: 'retention_uses_platform_separator',
      path: 'test/support/qa_harness/qa_report_retention.dart',
      tokens: ['Platform.pathSeparator', 'Directory(outputDirectory)'],
    ),
    _PortabilityContract(
      name: 'release_signoff_uses_json_artifacts',
      path: 'tool/work_supply_parser_qa_release_signoff.dart',
      tokens: ['jsonDecode', 'summary.json', 'transcriptPath'],
    ),
    _PortabilityContract(
      name: 'prune_tool_dry_run_default',
      path: 'tool/work_supply_parser_qa_prune_reports.dart',
      tokens: ['dryRun: !options.execute', 'QA_RETENTION_SUMMARY'],
    ),
    _PortabilityContract(
      name: 'parser_core_accepts_pure_inputs',
      path: 'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
      tokens: [
        'String rawText',
        'ReceiptParserLearningMemory? memory',
        'trustedItemIdentityIds',
        'tradeScope',
        'localePackId',
      ],
    ),
    _PortabilityContract(
      name: 'parser_core_returns_pure_candidates',
      path: 'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
      tokens: [
        'class ReceiptLineMatch',
        'rawText',
        'item',
        'confidence',
        'matchedTerms',
        'needsReview',
      ],
    ),
    _PortabilityContract(
      name: 'receipt_bridge_stages_for_review',
      path:
          'lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart',
      tokens: [
        'WorkSupplyParsedReceiptDraft',
        'ReceiptProcessingStage.stagedForReview',
        'ReceiptSaveDestination.inventoryReview',
        'canCommitInventory',
      ],
    ),
    _PortabilityContract(
      name: 'review_model_keeps_suggestions_review_only',
      path:
          'lib/screens/work_supplies/data/work_supply_inventory_receipt_models.dart',
      tokens: [
        'WorkSupplyLineReviewStatus',
        'needsReview',
        'highConfidenceReview',
        'unknownItem',
        'multiplePossibleMatches',
      ],
    ),
  ];

  static const _forbiddenToolTokens = [
    'cmd /c',
    'powershell.exe',
    'bash -c',
    '/bin/sh',
    r'C:\Users\',
    '/Users/',
  ];

  static const _parserCoreFiles = [
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    'lib/screens/work_supplies/data/work_supply_receipt_parser_confidence_engine.dart',
    'lib/screens/work_supplies/data/work_supply_inventory_receipt_models.dart',
  ];

  static const _forbiddenParserCoreTokens = [
    'FirebaseFirestore',
    'FirebaseStorage',
    'FirebaseAuth',
    'cloud_firestore',
    'firebase_storage',
    'firebase_auth',
    'Hive.box',
    'Hive.openBox',
    'MethodChannel',
    'Platform.isAndroid',
    'Platform.isIOS',
    'dart:io',
    'File(',
    'Directory(',
    'CameraController',
    'GoogleMlKit',
    'TextRecognizer',
    'ImagePicker',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sources = <String, String>{};
    for (final path in _scannedFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_portability_scan_file:$path',
            message: 'Portability contract scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update the portability suite if harness operation files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sources[path] = file.readAsStringSync();
    }

    final present = <String>[];
    for (final contract in _contracts) {
      final source = sources[contract.path] ?? '';
      if (contract.tokens.every(source.contains)) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_portability_contract:${contract.name}',
          message: 'Inventory parser QA portability contract is missing.',
          severity: QaSeverity.error,
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'not found',
          suggestedFix:
              'Keep parser QA runnable from Windows, Mac Mini, CI, GitHub handoff, and external SSD workflows.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    final toolSource = [
      sources['tool/work_supply_parser_qa_shard_runner.dart'] ?? '',
      sources['tool/work_supply_parser_qa_release_signoff.dart'] ?? '',
      sources['tool/work_supply_parser_qa_prune_reports.dart'] ?? '',
    ].join('\n');
    for (final token in _forbiddenToolTokens) {
      if (!toolSource.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'portable_tool_contains_host_specific_token:$token',
          message: 'QA tool contains a host/shell-specific token.',
          severity: QaSeverity.error,
          expected: 'portable Dart/Flutter command and relative paths',
          actual: token,
          suggestedFix:
              'Replace host-specific shell/path assumptions with Dart APIs or documented CLI arguments.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    for (final path in _parserCoreFiles) {
      final source = sources[path] ?? '';
      for (final token in _forbiddenParserCoreTokens) {
        if (!source.contains(token)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'parser_core_environment_coupling:$path:$token',
            message:
                'Inventory parser core contains environment-specific coupling.',
            severity: QaSeverity.critical,
            expected:
                'pure parser input/output with storage, cloud, OCR, camera, and platform adapters outside the core',
            actual: '$path contains $token',
            suggestedFix:
                'Move environment-specific behavior behind an adapter and keep parser candidates deterministic, review-only, and portable.',
            metadata: const {'triageCategory': QaFailureTriage.governance},
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked:
          _scannedFiles.length +
          _contracts.length +
          _forbiddenToolTokens.length +
          (_parserCoreFiles.length * _forbiddenParserCoreTokens.length),
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'filesScanned': sources.keys.toList()..sort(),
        'forbiddenToolTokens': _forbiddenToolTokens,
        'parserCoreFiles': _parserCoreFiles,
        'forbiddenParserCoreTokens': _forbiddenParserCoreTokens,
      },
    );
  }
}

class _PortabilityContract {
  const _PortabilityContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}
