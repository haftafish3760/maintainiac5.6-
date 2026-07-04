import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRealReceiptValidationSuite extends QaSuite {
  const WorkSupplyParserRealReceiptValidationSuite()
    : super('inventory.real_receipt_validation_contract');

  static const _scorecardPath =
      'docs/inventory_parser_release1_acceptance_scorecard.md';
  static const _fixtureGovernancePath =
      'test/support/qa_harness/maintainiac_fixture_governance_gate.dart';
  static const _fixturePrivacyQaPath =
      'test/support/work_supply_parser_qa/'
      'work_supply_parser_fixture_privacy_qa.dart';
  static const _legalSafetyQaPath =
      'test/support/work_supply_parser_qa/work_supply_parser_legal_safety_qa.dart';
  static const _validationToolPath =
      'tool/work_supply_parser_real_receipt_validation_log.dart';
  static const _validationToolTestPath =
      'test/work_supply_parser_real_receipt_validation_log_test.dart';

  static const _workflowTokens = {
    'Real Private Receipt Validation',
    'private receipt content must not be committed to the repo',
    'Merchant category, not full private receipt text',
    'Expected item family',
    'Parser result category',
    'Correct, review-required, unknown, or wrong',
    'Failure reason',
    'synthetic equivalent',
    'rewritten as privacy-safe synthetic data',
  };

  static const _governanceTokens = {
    'redactedReal',
    'privateBlocked',
    'redactionProof',
    'private fixtures must not be allowed in repo',
    'replacementFixture',
  };

  static const _privacyTokens = {
    'card_like_number',
    'email',
    'phone',
    'street_address',
    'privacy-safe synthetic or redacted fixture text',
  };

  static const _toolTokens = {
    'work_supply_parser_real_receipt_validation_log',
    'rawReceiptStored',
    'rawReceiptTextStored',
    'privateReceiptContentCommitted',
    'liveServicesAllowed',
    'firebaseWritesAllowed',
    'ocrCameraExpensesTouched',
    'Forbidden private receipt field',
    'Refusing to write outside build/',
  };

  static const _toolTestTokens = {
    'rejects raw receipt text fields',
    'writes only under build directory',
    'writes a JSON artifact without private receipt content',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    var checked = 0;

    checked += _checkTokens(
      failures,
      contract: 'real_receipt_scorecard',
      source: _read(_scorecardPath),
      tokens: _workflowTokens,
      category: QaFailureTriage.privacy,
      fix:
          'Real receipt validation must record only safe summaries and create synthetic replacement fixtures for regressions.',
    );
    checked += _checkTokens(
      failures,
      contract: 'fixture_governance',
      source: _read(_fixtureGovernancePath),
      tokens: _governanceTokens,
      category: QaFailureTriage.governance,
      fix:
          'Shared fixture governance must distinguish public synthetic fixtures, redacted real evidence, and private data that is blocked from the repo.',
    );
    checked += _checkTokens(
      failures,
      contract: 'fixture_privacy_scan',
      source: _read(_fixturePrivacyQaPath),
      tokens: _privacyTokens,
      category: QaFailureTriage.privacy,
      fix:
          'Fixture privacy scans must detect card-like numbers, contact data, addresses, and unredacted private receipt text.',
    );
    checked += _checkTokens(
      failures,
      contract: 'legal_safety',
      source: _read(_legalSafetyQaPath),
      tokens: {'No full private receipts', 'Fixture text looks like copied'},
      category: QaFailureTriage.security,
      fix:
          'Legal safety QA must reject full private receipts and copied proprietary-looking fixture text.',
    );
    checked += _checkTokens(
      failures,
      contract: 'real_receipt_validation_tool',
      source: _read(_validationToolPath),
      tokens: _toolTokens,
      category: QaFailureTriage.privacy,
      fix:
          'The local private receipt validation tool must write summary-only build artifacts and refuse raw/private receipt fields.',
    );
    checked += _checkTokens(
      failures,
      contract: 'real_receipt_validation_tool_tests',
      source: _read(_validationToolTestPath),
      tokens: _toolTestTokens,
      category: QaFailureTriage.privacy,
      fix:
          'Tool tests must prove raw receipt fields are rejected and only build/ summary artifacts are written.',
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scorecardPath': _scorecardPath,
        'fixtureGovernancePath': _fixtureGovernancePath,
        'contract':
            'Private real receipts may be tested locally by the owner, but repo evidence must stay summarized, redacted, syntheticized, and regression-safe.',
      },
    );
  }

  int _checkTokens(
    List<QaFailure> failures, {
    required String contract,
    required String source,
    required Set<String> tokens,
    required String category,
    required String fix,
  }) {
    for (final token in tokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_${contract}_token:${_safeId(token)}',
          message: 'Real receipt validation contract is incomplete.',
          severity: QaSeverity.warning,
          expected: token,
          actual: 'not found for $contract',
          suggestedFix: fix,
          metadata: {'triageCategory': category},
        ),
      );
    }
    return tokens.length;
  }
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
