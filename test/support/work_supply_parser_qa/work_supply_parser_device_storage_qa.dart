import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserDeviceStorageSuite extends QaSuite {
  const WorkSupplyParserDeviceStorageSuite()
    : super('inventory.device_storage_contract');

  static const _scannedFiles = [
    'lib/screens/work_supplies/data/work_supply_parser_device_profile.dart',
    'lib/screens/work_supplies/data/work_supply_trade_pack_install_guard.dart',
    'test/work_supply_parser_device_profile_test.dart',
    'test/work_supply_trade_pack_install_guard_test.dart',
    'docs/work_supplies_spec.md',
    'docs/materials_catalog_intelligence_contract.md',
  ];

  static const _contracts = [
    _DeviceStorageContract(
      name: 'older_phone_light_limits',
      tokens: ['olderPhone', 'Light receipt assist', 'maxCatalogCandidates'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _DeviceStorageContract(
      name: 'high_capacity_full_limits',
      tokens: ['highCapacity', 'Full inventory receipt assist'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _DeviceStorageContract(
      name: 'storage_unknown_blocks_install',
      tokens: ['storageUnknown', 'could not be verified'],
      category: QaFailureTriage.reviewSafety,
      required: true,
    ),
    _DeviceStorageContract(
      name: 'not_enough_storage_blocks_install',
      tokens: ['notEnoughStorage', 'download, unpack, and recover'],
      category: QaFailureTriage.reviewSafety,
      required: true,
    ),
    _DeviceStorageContract(
      name: 'uncompressed_pack_size_guard',
      tokens: ['estimatedUncompressedBytes', 'uncompressed pack'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _DeviceStorageContract(
      name: 'metered_network_warning',
      tokens: ['wifiRecommended', 'isMeteredNetwork'],
      category: QaFailureTriage.economics,
      required: true,
    ),
    _DeviceStorageContract(
      name: 'older_phone_avoids_large_packs',
      tokens: ['deviceTooLight', 'professional', 'full'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _DeviceStorageContract(
      name: 'cloud_fallback_disclosure',
      tokens: ['Cloud fallback', 'space-saving', 'online-only'],
      category: QaFailureTriage.economics,
    ),
    _DeviceStorageContract(
      name: 'local_pack_offline_path',
      tokens: ['Local pack mode', 'offline capable'],
      category: QaFailureTriage.governance,
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
            id: 'missing_device_storage_scan_file:$path',
            message: 'Device/storage contract scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if device profiles, install guards, or specs move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sourceByPath[path] = file.readAsStringSync();
    }

    final source = sourceByPath.values.join('\n');
    final present = <String>[];
    final missingRequired = <String>[];
    final missingRecommended = <String>[];
    for (final contract in _contracts) {
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      if (contract.required) {
        missingRequired.add(contract.name);
      } else {
        missingRecommended.add(contract.name);
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_device_storage_contract:${contract.name}',
          message: contract.required
              ? 'Required device/storage parser guard is missing.'
              : 'Recommended device/storage parser guard is not represented yet.',
          severity: contract.required ? QaSeverity.error : QaSeverity.warning,
          expected: contract.tokens.join(' + '),
          actual: 'not found',
          suggestedFix:
              'Keep older-device, storage, cloud fallback, and metered-network protections release-gated.',
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
        'missingRequiredContracts': missingRequired,
        'missingRecommendedContracts': missingRecommended,
        'filesScanned': sourceByPath.keys.toList()..sort(),
        'parserCalls': 0,
      },
    );
  }
}

class _DeviceStorageContract {
  const _DeviceStorageContract({
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
    return tokens.every(source.contains);
  }
}
