import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCloudCostGuardSuite extends QaSuite {
  const WorkSupplyParserCloudCostGuardSuite()
    : super('inventory.cloud_cost_guard_contract');

  static const _guardedToolPaths = [
    'tool/work_supply_parser_qa_pipeline.dart',
    'tool/work_supply_parser_qa_batch_wave.dart',
    'tool/work_supply_parser_qa_background_queue.dart',
    'tool/work_supply_catalog_blueprint_generator.dart',
    'tool/work_supply_parser_qa_generate_fixtures.dart',
  ];

  static const _requiredSafetyTokens = {
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
  };

  static final _forbiddenLiveTokens = {
    _liveRuntimeToken(_firebaseService('Firestore')),
    _liveRuntimeToken(_firebaseService('Functions')),
    _liveRuntimeToken(_firebaseService('Storage')),
    _firebaseService('Firestore'),
    _firebaseService('Functions'),
    _firebaseService('Storage'),
  };

  static String _liveRuntimeToken(String serviceName) => '$serviceName.instance';

  static String _firebaseService(String product) => 'Firebase$product';

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    var checked = 0;

    for (final path in _guardedToolPaths) {
      final file = File(path);
      final text = file.existsSync() ? file.readAsStringSync() : '';
      for (final token in _requiredSafetyTokens) {
        checked++;
        if (text.contains(token)) continue;
        failures.add(
          _failure(
            id: 'missing_cloud_cost_guard:$path:$token',
            message: 'Parser QA tool is missing a cloud/cost safety flag.',
            expected: token,
            actual: path,
          ),
        );
      }
      for (final token in _forbiddenLiveTokens) {
        checked++;
        if (!text.contains(token)) continue;
        failures.add(
          _failure(
            id: 'forbidden_live_service_token:$path:$token',
            message:
                'Parser QA tool appears to reference a live Firebase operation.',
            expected: 'No live service reads/writes in parser QA generation',
            actual: '$path contains $token',
            severity: QaSeverity.critical,
          ),
        );
      }
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'guardedToolPaths': _guardedToolPaths,
        'requiredSafetyTokens': _requiredSafetyTokens.toList()..sort(),
        'forbiddenLiveTokens': _forbiddenLiveTokens.toList()..sort(),
      },
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    QaSeverity severity = QaSeverity.error,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: severity,
      expected: expected,
      actual: actual,
      suggestedFix:
          'Keep parser QA local-only until Firebase batching, quotas, auth, indexes, and explicit approval are ready.',
      metadata: const {'triageCategory': QaFailureTriage.security},
    );
  }
}
