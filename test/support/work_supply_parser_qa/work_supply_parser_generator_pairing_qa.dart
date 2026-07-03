import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserGeneratorPairingSuite extends QaSuite {
  const WorkSupplyParserGeneratorPairingSuite()
    : super('inventory.generator_pairing_contract');

  static const _sharedOptionTokens = {
    '--trade',
    '--scope',
    '--tier',
    '--locale',
    '--limit',
    '--output-dir',
  };

  static const _sharedManifestTokens = {
    'generationSeed',
    'trade',
    'marketScope',
    'tier',
    'localePackId',
    'requestedLimit',
    'generatedCount',
    'liveServicesAllowed',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final blueprint = File('tool/work_supply_catalog_blueprint_generator.dart');
    final fixture = File('tool/work_supply_parser_qa_generate_fixtures.dart');
    final blueprintText = blueprint.existsSync()
        ? blueprint.readAsStringSync()
        : '';
    final fixtureText = fixture.existsSync() ? fixture.readAsStringSync() : '';

    for (final token in _sharedOptionTokens) {
      _requireInBoth(
        failures,
        token: token,
        blueprintText: blueprintText,
        fixtureText: fixtureText,
        category: 'option',
      );
    }
    for (final token in _sharedManifestTokens) {
      _requireInBoth(
        failures,
        token: token,
        blueprintText: blueprintText,
        fixtureText: fixtureText,
        category: 'manifest',
      );
    }

    return timer.finish(
      suite: name,
      checked: (_sharedOptionTokens.length + _sharedManifestTokens.length) * 2,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sharedOptionTokens': _sharedOptionTokens.toList()..sort(),
        'sharedManifestTokens': _sharedManifestTokens.toList()..sort(),
        'contract':
            'Catalog blueprint generation and parser fixture generation must share trade/scope/tier/locale/limit dimensions.',
      },
    );
  }

  void _requireInBoth(
    List<QaFailure> failures, {
    required String token,
    required String blueprintText,
    required String fixtureText,
    required String category,
  }) {
    if (!blueprintText.contains(token)) {
      failures.add(_failure('blueprint', category, token));
    }
    if (!fixtureText.contains(token)) {
      failures.add(_failure('fixture', category, token));
    }
  }

  QaFailure _failure(String side, String category, String token) {
    return QaFailure(
      suite: name,
      id: 'missing_${side}_${category}_token:$token',
      message: 'Generated catalog/fixture pairing contract token is missing.',
      severity: QaSeverity.error,
      expected: token,
      actual: side,
      suggestedFix:
          'Keep catalog item generation and fixture generation aligned on the same matrix dimensions.',
      metadata: const {'triageCategory': QaFailureTriage.governance},
    );
  }
}
