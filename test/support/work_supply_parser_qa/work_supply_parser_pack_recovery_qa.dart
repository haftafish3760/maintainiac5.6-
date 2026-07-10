import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPackRecoverySuite extends QaSuite {
  const WorkSupplyParserPackRecoverySuite()
    : super('inventory.pack_recovery_contract');

  static const _scannedFiles = [
    'docs/inventory_parser_qa_harness_plan.md',
    'lib/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart',
    'lib/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart',
    'test/work_supply_trade_pack_import_recovery_test.dart',
    'test/work_supply_trade_pack_install_guard_test.dart',
  ];

  static const _contracts = [
    _RecoveryContract(
      name: 'missing_manifest_and_chunk',
      path:
          'lib/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart',
      tokens: ['missingManifest', 'missingChunk'],
      category: QaFailureTriage.schema,
    ),
    _RecoveryContract(
      name: 'unsafe_chunk_path_guard',
      path:
          'lib/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart',
      tokens: ['invalidChunkPath', 'storagePath.contains(\'..\')'],
      category: QaFailureTriage.security,
    ),
    _RecoveryContract(
      name: 'corrupt_and_checksum_guard',
      path:
          'lib/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart',
      tokens: ['unreadableChunk', 'checksumMismatch'],
      category: QaFailureTriage.security,
    ),
    _RecoveryContract(
      name: 'item_and_parser_metadata_reject',
      path:
          'lib/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart',
      tokens: ['itemCountMismatch', 'missingParserMetadata'],
      category: QaFailureTriage.parserEngine,
    ),
    _RecoveryContract(
      name: 'storage_recovery_room',
      path:
          'lib/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart',
      tokens: ['download, unpack, and recover', 'notEnoughStorage'],
      category: QaFailureTriage.performance,
    ),
    _RecoveryContract(
      name: 'unknown_storage_blocks_install',
      path: 'test/work_supply_trade_pack_install_guard_test.dart',
      tokens: ['storageUnknown', 'could not be verified'],
      category: QaFailureTriage.performance,
    ),
    _RecoveryContract(
      name: 'missing_chunk_executable_test',
      path: 'test/work_supply_trade_pack_import_recovery_test.dart',
      tokens: ['rejects missing chunks', 'missingChunk'],
      category: QaFailureTriage.schema,
    ),
    _RecoveryContract(
      name: 'corrupt_chunk_executable_test',
      path: 'test/work_supply_trade_pack_import_recovery_test.dart',
      tokens: ['rejects corrupt gzip chunks', 'unreadableChunk'],
      category: QaFailureTriage.security,
    ),
    _RecoveryContract(
      name: 'checksum_mismatch_executable_test',
      path: 'test/work_supply_trade_pack_import_recovery_test.dart',
      tokens: ['rejects checksum-mismatched chunks', 'checksumMismatch'],
      category: QaFailureTriage.security,
    ),
    _RecoveryContract(
      name: 'unsafe_path_executable_test',
      path: 'test/work_supply_trade_pack_import_recovery_test.dart',
      tokens: ['rejects unsafe chunk paths', 'invalidChunkPath'],
      category: QaFailureTriage.security,
    ),
    _RecoveryContract(
      name: 'recovery_docs',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: [
        'inventory.pack_recovery_contract',
        'corrupt pack',
        'interrupted download',
        'duplicate install',
        'missing locale pack',
        'rollback',
      ],
      category: QaFailureTriage.governance,
    ),
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
            id: 'missing_pack_recovery_scan_file:$path',
            message: 'Pack recovery contract scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if pack recovery docs or tests move.',
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
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_pack_recovery_contract:${contract.name}',
          message: 'Pack recovery/disaster contract is missing.',
          severity: QaSeverity.error,
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'not found',
          suggestedFix:
              'Keep corrupt, partial, unsafe, duplicate, locale, and rollback pack paths release-gated.',
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
        'filesScanned': sources.keys.toList()..sort(),
      },
    );
  }
}

class _RecoveryContract {
  const _RecoveryContract({
    required this.name,
    required this.path,
    required this.tokens,
    required this.category,
  });

  final String name;
  final String path;
  final List<String> tokens;
  final String category;

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
