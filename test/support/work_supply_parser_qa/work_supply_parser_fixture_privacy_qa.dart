import 'dart:convert';
import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFixturePrivacySuite extends QaSuite {
  const WorkSupplyParserFixturePrivacySuite()
    : super('inventory.fixture_privacy_contract');

  static final _privatePatterns = <String, RegExp>{
    'card_like_number': RegExp(r'\b(?:\d[ -]?){13,19}\b'),
    'email': RegExp(r'\b[\w.+-]+@[\w.-]+\.[a-z]{2,}\b', caseSensitive: false),
    'phone': RegExp(r'\b(?:\+?1[-. ]?)?\(?\d{3}\)?[-. ]?\d{3}[-. ]?\d{4}\b'),
    'street_address': RegExp(
      r'\b\d{2,6}\s+[a-z0-9 .-]+\s+(street|st|road|rd|avenue|ave|drive|dr|lane|ln|court|ct|boulevard|blvd)\b',
      caseSensitive: false,
    ),
  };

  static const _fixturePaths = [
    'test/fixtures/work_supply_parser/golden_fixtures.json',
    'test/fixtures/work_supply_parser/holdout_fixtures.json',
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    var checked = 0;
    final scannedPaths = <String>[];

    for (final path in _fixturePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      scannedPaths.add(path);
      final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      for (final entry in decoded) {
        final fixture = (entry as Map).cast<String, Object?>();
        final id = fixture['id']?.toString() ?? 'fixture_without_id';
        final rawLine = fixture['rawLine']?.toString() ?? '';
        checked += _privatePatterns.length;
        for (final pattern in _privatePatterns.entries) {
          if (!pattern.value.hasMatch(rawLine)) continue;
          failures.add(
            QaFailure(
              suite: name,
              id: 'fixture_private_data:${pattern.key}:$id',
              message: 'Parser fixture raw line contains private-looking data.',
              severity: QaSeverity.critical,
              expected: 'privacy-safe synthetic or redacted fixture text',
              actual: context.redactor(rawLine),
              suggestedFix:
                  'Replace fixture raw text with synthetic merchant abbreviations and keep private data only in redactor-specific tests.',
              metadata: const {'triageCategory': QaFailureTriage.privacy},
            ),
          );
        }
      }
    }

    return timer.finish(
      suite: name,
      checked: checked + _fixturePaths.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'fixturePaths': _fixturePaths,
        'scannedPaths': scannedPaths,
        'privatePatternNames': _privatePatterns.keys.toList()..sort(),
      },
    );
  }
}
