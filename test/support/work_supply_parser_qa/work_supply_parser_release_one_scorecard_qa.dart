import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneScorecardSuite extends QaSuite {
  const WorkSupplyParserReleaseOneScorecardSuite()
    : super('inventory.release_one_scorecard_contract');

  static const _scorecardPath =
      'docs/inventory_parser_release1_acceptance_scorecard.md';

  static const _requiredTokens = {
    'Plumbing Core and Standard',
    'Electrical Core and Standard',
    'HVAC Core and Standard',
    'English and Spanish',
    'Merchant-Agnostic Receipt Coverage',
    'unknown merchants',
    'regional chains',
    'supply-house receipts',
    'Synthetic Merchant And Generic Receipt Fixtures',
    'Fake-User Parser Review Workflow',
    'Clear common Core item top candidate',
    'False-confident ambiguous match rate',
    'Ambiguous overlap lines',
    'Hive/local storage is the immediate source of truth',
    'Firebase/Firestore is a mirror',
    'Firebase mirror sync should happen as soon as practical',
    'Portable Parser Core',
    'environment-independent',
    'Ranked candidates must preserve the evidence ladder',
    'enabled trade packs',
    'active estimate/job trade section',
    'receipt-neighbor signals',
    'merchant/department hints',
    'positive evidence',
    'negative evidence',
    'must not silently confirm an item or hide realistic alternate trades',
    'Teachable Correction Memory',
    'Barcode Evidence',
    'Retailer database scraping is forbidden',
    'Real Private Receipt Validation',
    'Serious-Team Additions',
    'Release 1 should not be treated as throwaway or knowingly subpar',
    'Store-independence proof',
    'QA harness completion is not the same thing as catalog completion',
    'inventory catalog expansion still continues in controlled batches',
    'After QA hardening is complete, inventory catalog growth still continues',
    'Next Implementation Order',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final file = File(_scorecardPath);
    final source = file.existsSync() ? file.readAsStringSync() : '';

    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_one_scorecard',
          message: 'Release 1 parser acceptance scorecard is missing.',
          severity: QaSeverity.error,
          expected: _scorecardPath,
          actual: 'not found',
          suggestedFix:
              'Restore the scorecard so release-one parser gates stay measurable.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    for (final token in _requiredTokens) {
      if (source.contains(token)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_one_scorecard_token:${_safeId(token)}',
          message: 'Release 1 parser scorecard is missing required coverage.',
          severity: QaSeverity.error,
          expected: token,
          actual: 'not found',
          suggestedFix:
              'Keep the release-one scorecard aligned with parser accuracy, review-safety, merchant-agnostic, sync, correction, barcode, and portability requirements.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredTokens.length + 1,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scorecardPath': _scorecardPath,
        'requiredTokens': _requiredTokens.length,
        'contract':
            'Release-one parser readiness must be measurable across top trades, locales, merchant-agnostic fixtures, review workflow, local/Firebase sync, portability, correction learning, barcode evidence, and private receipt validation.',
      },
    );
  }
}

String _safeId(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), '');
}
