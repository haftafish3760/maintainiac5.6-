import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserLegalSafetySuite extends QaSuite {
  const WorkSupplyParserLegalSafetySuite()
    : super('inventory.legal_safety_contract');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _fixturesDirectory = 'test/fixtures/work_supply_parser';
  static const _sourceDirectories = [
    'test/support/work_supply_parser_qa',
    'test/fixtures/work_supply_parser',
  ];

  static const _requiredPlanTokens = [
    'Legal and proprietary-data safety',
    'Do not copy proprietary retailer catalogs',
    'synthetic fixture',
    'generic merchant abbreviation patterns',
    'reviewed public/manual source notes',
    'No full private receipts',
  ];

  static final _blockedFixturePatterns = {
    'private_card': RegExp(
      r'\b(?:card|visa|mastercard|amex)\s*\d{4}\b',
      caseSensitive: false,
    ),
    'auth_code': RegExp(
      r'\bauth(?:orization)?\s*#?\s*\d{4,}\b',
      caseSensitive: false,
    ),
    'copied_receipt_marker': RegExp(
      r'\b(?:transaction id|cashier|terminal|store #|receipt #)\b',
      caseSensitive: false,
    ),
    'bulk_scrape_marker': RegExp(
      r'\b(?:scraped|crawl(?:ed|er)?|downloaded retailer database|copied sku database)\b',
      caseSensitive: false,
    ),
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final present = <String>[];
    var checked = 0;

    final plan = _read(_planPath, failures);
    checked += _requiredPlanTokens.length;
    final missingPlanTokens = [
      for (final token in _requiredPlanTokens)
        if (!plan.contains(token)) token,
    ];
    if (missingPlanTokens.isEmpty) {
      present.add('legal_safety_docs');
    } else {
      failures.add(
        _failure(
          id: 'missing_legal_safety_docs',
          message: 'Legal/proprietary-data parser QA policy is incomplete.',
          expected: _requiredPlanTokens.join(' + '),
          actual: 'missing ${missingPlanTokens.join(' + ')}',
          category: QaFailureTriage.governance,
        ),
      );
    }

    final fixtureFiles = _fixtureFiles(failures);
    for (final file in fixtureFiles) {
      checked++;
      final text = file.readAsStringSync();
      for (final pattern in _blockedFixturePatterns.entries) {
        if (!pattern.value.hasMatch(text)) continue;
        failures.add(
          _failure(
            id: 'blocked_fixture_source_pattern:${pattern.key}:${file.path}',
            message:
                'Fixture text looks like copied private receipt or proprietary data.',
            expected: 'synthetic parser fixture text only',
            actual: context.redactor(file.path),
            category: QaFailureTriage.privacy,
          ),
        );
      }
    }

    final sources = _readSources(failures);
    checked += _sourceDirectories.length;
    for (final blocked in ['puppeteer', 'playwright', 'web scraping']) {
      if (!sources.toLowerCase().contains(blocked)) continue;
      failures.add(
        _failure(
          id: 'blocked_parser_qa_collection_method:$blocked',
          message:
              'Parser QA source references a collection method that needs legal review.',
          expected: 'manual/synthetic/public-source-reviewed data only',
          actual: blocked,
          category: QaFailureTriage.security,
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + _blockedFixturePatterns.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'fixtureFilesScanned': fixtureFiles.length,
        'blockedPatterns': _blockedFixturePatterns.keys.toList()..sort(),
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
          'Use synthetic examples, generic merchant patterns, and reviewed source notes instead of copied private/proprietary data.',
      metadata: {'triageCategory': category},
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      _failure(
        id: 'missing_legal_safety_scan_file:$path',
        message: 'Legal-safety scan file is missing.',
        expected: path,
        actual: 'not found',
        category: QaFailureTriage.schema,
      ),
    );
    return '';
  }

  List<File> _fixtureFiles(List<QaFailure> failures) {
    final directory = Directory(_fixturesDirectory);
    if (!directory.existsSync()) {
      failures.add(
        _failure(
          id: 'missing_legal_safety_fixture_directory',
          message: 'Legal-safety fixture directory is missing.',
          expected: _fixturesDirectory,
          actual: 'not found',
          category: QaFailureTriage.schema,
        ),
      );
      return const [];
    }
    return directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);
  }

  String _readSources(List<QaFailure> failures) {
    final buffer = StringBuffer();
    for (final path in _sourceDirectories) {
      final directory = Directory(path);
      if (!directory.existsSync()) {
        failures.add(
          _failure(
            id: 'missing_legal_safety_source_directory:$path',
            message: 'Legal-safety source directory is missing.',
            expected: path,
            actual: 'not found',
            category: QaFailureTriage.schema,
          ),
        );
        continue;
      }
      for (final file
          in directory.listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('work_supply_parser_legal_safety_qa.dart')) {
          continue;
        }
        if (!file.path.endsWith('.dart') && !file.path.endsWith('.json')) {
          continue;
        }
        buffer.writeln(file.readAsStringSync());
      }
    }
    return buffer.toString();
  }
}
