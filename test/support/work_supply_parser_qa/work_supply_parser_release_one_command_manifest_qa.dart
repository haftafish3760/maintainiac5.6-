import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneCommandManifestSuite extends QaSuite {
  const WorkSupplyParserReleaseOneCommandManifestSuite()
    : super('inventory.release_one_command_manifest');

  static const _requiredTokens = {
    'QA_RELEASE_ONE_COMMANDS',
    'cellCount',
    'executionPolicy',
    'executeFlagRequired',
    'runFixturesFlagOptional',
    'liveServicesAllowed',
    'writesProductionCatalog',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
    'plumbing',
    'electrical',
    'hvac',
    'en-US',
    'es-US',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _sourceText();

    for (final token in _requiredTokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_one_command_token:$token',
          message: 'Release-one command manifest contract token is missing.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Keep a generated command manifest for each residential priority parser QA cell.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredTokens.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'requiredTokens': _requiredTokens.toList()..sort(),
        'contract':
            'Release-one residential parser QA cells must have ready-made dry-run-safe commands.',
      },
    );
  }

  String _sourceText() {
    return [
          File('tool/work_supply_parser_qa_release_one_commands.dart'),
          File('test/work_supply_parser_qa_release_one_commands_test.dart'),
        ]
        .where((file) => file.existsSync())
        .map((file) => file.readAsStringSync())
        .join('\n');
  }
}
