import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserScalabilitySuite extends QaSuite {
  const WorkSupplyParserScalabilitySuite() : super('inventory.scalability');

  static const _scannedFiles = [
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    'lib/screens/work_supplies/data/work_supply_catalog_search.dart',
    'test/support/qa_harness/qa_threshold_gate.dart',
    'test/support/qa_harness/qa_harness.dart',
    'docs/inventory_parser_qa_harness_plan.md',
  ];

  static const _scaleCheckpoints = [1000, 10000, 50000, 100000];

  static const _contracts = [
    _ScaleContract(
      name: 'receipt_catalog_index',
      tokens: ['_receiptCatalogIndex', '_receiptCatalogTokenIndex'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _ScaleContract(
      name: 'vendor_mapping_index',
      tokens: ['_receiptVendorMappingIndex'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _ScaleContract(
      name: 'throughput_budget',
      tokens: ['minSuiteChecksPerSecond', 'checksPerSecond'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _ScaleContract(
      name: 'slow_suite_reporting',
      tokens: ['slowestSuites', 'QA_SLOW_SUITE'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _ScaleContract(
      name: 'catalog_search_index',
      tokens: ['catalogSearchIndex', 'searchIndex', 'invertedIndex'],
      category: QaFailureTriage.performance,
    ),
    _ScaleContract(
      name: 'index_full_scan_parity',
      tokens: ['indexParity', 'fullScanParity', 'same logical results'],
      category: QaFailureTriage.performance,
    ),
    _ScaleContract(
      name: 'scale_checkpoint_runner',
      tokens: ['1000', '10000', '50000', '100000'],
      category: QaFailureTriage.performance,
    ),
    _ScaleContract(
      name: 'memory_ceiling_report',
      tokens: ['memoryCeiling', 'memoryUse', 'peakMemory'],
      category: QaFailureTriage.performance,
    ),
    _ScaleContract(
      name: 'cold_warm_cache_timing',
      tokens: ['coldStart', 'warmCache', 'indexedLoad'],
      category: QaFailureTriage.performance,
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
            id: 'missing_scalability_scan_file:$path',
            message: 'Scalability scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if parser/index/harness files move.',
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
          id: 'missing_scalability_contract:${contract.name}',
          message: contract.required
              ? 'Required scalability contract is missing.'
              : 'Recommended scalability contract is not represented yet.',
          severity: contract.required ? QaSeverity.error : QaSeverity.warning,
          expected: contract.name,
          actual: 'not found',
          suggestedFix:
              'Add index-based scale coverage before large parser packs are release-gated.',
          metadata: {'triageCategory': contract.category},
        ),
      );
    }

    _checkCatalogSearchFullScanDebt(failures, sourceByPath);

    return timer.finish(
      suite: name,
      checked:
          _contracts.length +
          _scaleCheckpoints.length +
          _scannedFiles.length +
          1,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scaleCheckpoints': _scaleCheckpoints,
        'presentContracts': present,
        'missingRequiredContracts': missingRequired,
        'missingRecommendedContracts': missingRecommended,
        'filesScanned': sourceByPath.keys.toList()..sort(),
      },
    );
  }

  void _checkCatalogSearchFullScanDebt(
    List<QaFailure> failures,
    Map<String, String> sourceByPath,
  ) {
    final search =
        sourceByPath['lib/screens/work_supplies/data/work_supply_catalog_search.dart'] ??
        '';
    if (search.contains('for (final item in workSupplyCatalogItems)')) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'catalog_search_full_scan_debt',
          message:
              'Generic catalog search still scans every catalog item for each query.',
          severity: QaSeverity.warning,
          expected: 'indexed or bounded candidate search for large packs',
          actual: 'for (final item in workSupplyCatalogItems)',
          suggestedFix:
              'Build an indexed catalog search path and add parity tests against the current full-scan behavior before 50k/100k pack runs.',
          metadata: const {'triageCategory': QaFailureTriage.performance},
        ),
      );
    }
  }
}

class _ScaleContract {
  const _ScaleContract({
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
