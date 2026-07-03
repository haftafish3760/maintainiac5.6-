import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReviewSafetySuite extends QaSuite {
  const WorkSupplyParserReviewSafetySuite()
    : super('inventory.review_safety_contract');

  static const _filesToScan = [
    'lib/screens/work_supplies/data/work_supply_receipt_parser.dart',
    'lib/screens/work_supplies/data/work_supply_inventory_receipt_models.dart',
    'lib/screens/work_supplies/data/work_supply_parsed_receipt_bridge.dart',
    'lib/screens/work_supplies/entry/add_items_receipt_parser_actions.dart',
    'lib/screens/work_supplies/entry/add_items_receipt_actions.dart',
  ];

  static const _forbiddenAutoSaveTokens = [
    'auto_accept',
    'autoAccept',
    'auto_save',
    'autoSave',
    'autosave',
    'autoConfirm',
    'auto_confirm',
  ];

  static const _requiredReviewStatuses = {
    'needs_review',
    'high_confidence_review',
    'unknown_item',
    'multiple_possible_matches',
    'possible_duplicate',
    'possible_return_line',
    'possible_discount_line',
    'possible_receipt_noise',
    'not_inventory',
    'parser_error',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final scanned = <String, String>{};
    for (final path in _filesToScan) {
      final file = File(path);
      scanned[path] = file.existsSync() ? file.readAsStringSync() : '';
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_review_contract_file:$path',
            message: 'Review-safety contract file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update the contract suite path or restore the parser/review model file.',
          ),
        );
      }
    }

    _checkForbiddenAutoSaveTokens(failures, scanned);
    _checkParserResultIsReviewOnly(failures, scanned);
    _checkReviewStatusVocabulary(failures, scanned);

    return timer.finish(
      suite: name,
      checked:
          _filesToScan.length +
          _forbiddenAutoSaveTokens.length +
          _requiredReviewStatuses.length +
          3,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'filesScanned': _filesToScan.length,
        'requiredReviewStatuses': _requiredReviewStatuses.toList()..sort(),
      },
    );
  }

  void _checkForbiddenAutoSaveTokens(
    List<QaFailure> failures,
    Map<String, String> scanned,
  ) {
    for (final entry in scanned.entries) {
      for (final token in _forbiddenAutoSaveTokens) {
        if (!entry.value.contains(token)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'forbidden_auto_save_token:${entry.key}:$token',
            message: 'Parser/review code contains an auto-save style token.',
            severity: QaSeverity.critical,
            expected: 'review-only parser candidates',
            actual: '${entry.key} contains $token',
            suggestedFix:
                'Remove automatic accept/save paths from parser output. Approval must be explicit user action.',
          ),
        );
      }
    }
  }

  void _checkParserResultIsReviewOnly(
    List<QaFailure> failures,
    Map<String, String> scanned,
  ) {
    final parser =
        scanned['lib/screens/work_supplies/data/work_supply_receipt_parser.dart'] ??
        '';
    if (!parser.contains('bool get needsReview')) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'parser_match_missing_review_flag',
          message: 'Parser match result does not expose a review flag.',
          expected: 'ReceiptLineMatch has review-only evidence/status',
          actual: 'needsReview getter missing',
          suggestedFix:
              'Expose review status/evidence on parser candidates before allowing UI or inventory flows to consume them.',
        ),
      );
    }
    if (parser.contains('ReceiptConfidenceLevel.good') &&
        parser.contains('needsReview => confidenceLevel !=')) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'good_confidence_not_review_required',
          message:
              'Current parser confidence model treats Good confidence as not needing review.',
          expected:
              'even high-confidence parser results remain human-review candidates',
          actual: 'needsReview is false when confidenceLevel is good',
          suggestedFix:
              'Separate confidence quality from approval state; high confidence should become high_confidence_review, not confirmed.',
        ),
      );
    }
  }

  void _checkReviewStatusVocabulary(
    List<QaFailure> failures,
    Map<String, String> scanned,
  ) {
    final model =
        scanned['lib/screens/work_supplies/data/work_supply_inventory_receipt_models.dart'] ??
        '';
    if (model.contains('enum WorkSupplyLineReviewStatus') &&
        model.contains('confirmed')) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'review_status_allows_confirmed',
          message:
              'Inventory receipt review status can represent a confirmed line before explicit approval.',
          expected: _requiredReviewStatuses.join(', '),
          actual: 'WorkSupplyLineReviewStatus includes confirmed',
          suggestedFix:
              'Use review-only statuses for parser output and reserve confirmed/approved state for explicit user approval records.',
        ),
      );
    }
    for (final status in _requiredReviewStatuses) {
      if (_containsStatus(model, status)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_review_status:$status',
          message: 'Review model is missing a required parser status.',
          severity: QaSeverity.warning,
          expected: status,
          actual: 'not found in WorkSupplyLineReviewStatus model',
          suggestedFix:
              'Add the parser review-status vocabulary before release-gating ranked parser candidates.',
        ),
      );
    }
  }

  bool _containsStatus(String model, String snakeCaseStatus) {
    final camelCase = snakeCaseStatus.replaceAllMapped(
      RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
    return model.contains(snakeCaseStatus) || model.contains(camelCase);
  }
}
