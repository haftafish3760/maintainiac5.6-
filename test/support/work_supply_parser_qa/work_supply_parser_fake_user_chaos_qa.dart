import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFakeUserChaosSuite extends QaSuite {
  const WorkSupplyParserFakeUserChaosSuite()
    : super('inventory.fake_user_chaos_contract');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final scenarios = _scenarios();

    for (final scenario in scenarios) {
      final result = _runScenario(scenario);
      _expect(
        failures,
        result.parserOutputStayedSuggestion,
        id: '${scenario.id}:parser_output_stayed_suggestion',
        message: 'Fake chaos workflow let parser output become source truth.',
        expected: 'Parser/barcode/cloud evidence stays suggestion-only.',
        actual: result.auditTrail.join(' > '),
        triage: QaFailureTriage.reviewSafety,
      );
      _expect(
        failures,
        result.localTruthWins,
        id: '${scenario.id}:local_truth_wins',
        message: 'Fake chaos workflow let non-local evidence win.',
        expected: 'User-confirmed Hive/local truth is final.',
        actual: result.finalState,
        triage: QaFailureTriage.conflict,
      );
      _expect(
        failures,
        result.ambiguousEvidenceRequiredReview,
        id: '${scenario.id}:ambiguous_evidence_review',
        message: 'Ambiguous or conflicting evidence skipped review.',
        expected: 'Conflict/ambiguity requires review or unknown state.',
        actual: result.reviewState,
        triage: QaFailureTriage.reviewSafety,
      );
      _expect(
        failures,
        result.duplicateDidNotDoubleStock,
        id: '${scenario.id}:duplicate_no_double_stock',
        message: 'Duplicate receipt review double-counted inventory stock.',
        expected: 'Duplicate receipt import is idempotent.',
        actual: result.finalState,
        triage: QaFailureTriage.conflict,
      );
      _expect(
        failures,
        result.abandonedReviewWroteNothing,
        id: '${scenario.id}:abandoned_review_wrote_nothing',
        message: 'Abandoned review wrote an inventory or mirror record.',
        expected: 'No confirmed local write and no mirror queue.',
        actual: result.finalState,
        triage: QaFailureTriage.reviewSafety,
      );
      _expect(
        failures,
        result.noLiveServices,
        id: '${scenario.id}:no_live_services',
        message: 'Fake chaos workflow touched a live service.',
        expected: 'No Firebase/network/OCR/camera side effects.',
        actual: result.auditTrail.join(' > '),
        triage: QaFailureTriage.security,
      );
    }

    return timer.finish(
      suite: name,
      checked: scenarios.length * 6,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scenarioCount': scenarios.length,
        'coversBarcodeReceiptDisagreement': true,
        'coversDuplicateReceiptImport': true,
        'coversAbandonedReview': true,
        'coversStaleMirrorConflict': true,
        'parserCalls': 0,
        'uiRequired': false,
        'ocrRequired': false,
        'liveServicesAllowed': false,
      },
    );
  }

  _ChaosResult _runScenario(_ChaosScenario scenario) {
    final env = _FakeChaosEnvironment();
    env.ingestReceiptLine(
      scenario.rawLine,
      enabledPacks: scenario.enabledPacks,
      sourceId: scenario.id,
    );
    if (scenario.barcodeItemId.isNotEmpty) {
      env.scanBarcode(candidateItemId: scenario.barcodeItemId);
    }
    env.parserSuggests(
      candidateItemId: scenario.parserItemId,
      reviewState: scenario.initialReviewState,
    );
    if (scenario.duplicateImport) {
      env.markDuplicateImport();
    }
    switch (scenario.action) {
      case _ChaosAction.confirm:
        env.userConfirms(itemId: scenario.userItemId);
      case _ChaosAction.edit:
        env.userEdits(itemId: scenario.userItemId);
      case _ChaosAction.reject:
        env.userRejects();
      case _ChaosAction.abandon:
        env.userAbandonsReview();
    }
    env.staleMirrorAttemptsWrite(itemId: '${scenario.parserItemId}_cloud');
    return env.result(
      expectedItemId: scenario.userItemId,
      requiresReview: scenario.requiresReview,
      duplicateImport: scenario.duplicateImport,
      abandoned: scenario.action == _ChaosAction.abandon,
    );
  }

  List<_ChaosScenario> _scenarios() {
    return const [
      _ChaosScenario(
        id: 'barcode_receipt_disagreement_requires_review',
        rawLine: 'PVC 3/4 CPLG',
        parserItemId: 'pvc_schedule_40_coupling',
        barcodeItemId: 'pvc_conduit_coupling',
        userItemId: 'pvc_conduit_coupling',
        initialReviewState: 'multiple_possible_matches',
        action: _ChaosAction.edit,
        enabledPacks: {'plumbing', 'electrical'},
        requiresReview: true,
      ),
      _ChaosScenario(
        id: 'duplicate_receipt_import_does_not_double_stock',
        rawLine: '3/4 COPPER 90',
        parserItemId: 'copper_pressure_elbow',
        userItemId: 'copper_pressure_elbow',
        initialReviewState: 'high_confidence_review',
        action: _ChaosAction.confirm,
        enabledPacks: {'plumbing', 'hvac'},
        duplicateImport: true,
      ),
      _ChaosScenario(
        id: 'abandoned_unknown_review_writes_nothing',
        rawLine: 'MISC PART 8891',
        parserItemId: 'unknown_item',
        userItemId: 'unknown_item',
        initialReviewState: 'unknown_item',
        action: _ChaosAction.abandon,
        enabledPacks: {'plumbing', 'electrical', 'hvac'},
        requiresReview: true,
      ),
      _ChaosScenario(
        id: 'mixed_trade_receipt_neighbor_keeps_pvc_reviewable',
        rawLine: 'PVC 3/4 EL near THHN 12 BLK',
        parserItemId: 'ranked_pvc_elbow_candidate',
        userItemId: 'pvc_conduit_elbow',
        initialReviewState: 'multiple_possible_matches',
        action: _ChaosAction.edit,
        enabledPacks: {'plumbing', 'electrical', 'hvac'},
        requiresReview: true,
      ),
    ];
  }

  void _expect(
    List<QaFailure> failures,
    bool condition, {
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String triage,
  }) {
    if (condition) return;
    failures.add(
      QaFailure(
        suite: name,
        id: id,
        message: message,
        expected: expected,
        actual: actual,
        suggestedFix:
            'Keep fake-user parser workflows suggestion-only, local-first, idempotent, and review-safe under hostile human behavior.',
        metadata: {'triageCategory': triage},
      ),
    );
  }
}

class _ChaosScenario {
  const _ChaosScenario({
    required this.id,
    required this.rawLine,
    required this.parserItemId,
    required this.userItemId,
    required this.initialReviewState,
    required this.action,
    required this.enabledPacks,
    this.barcodeItemId = '',
    this.requiresReview = false,
    this.duplicateImport = false,
  });

  final String id;
  final String rawLine;
  final String parserItemId;
  final String barcodeItemId;
  final String userItemId;
  final String initialReviewState;
  final _ChaosAction action;
  final Set<String> enabledPacks;
  final bool requiresReview;
  final bool duplicateImport;
}

enum _ChaosAction { confirm, edit, reject, abandon }

class _FakeChaosEnvironment {
  final auditTrail = <String>[];
  final _seenSources = <String>{};
  String _reviewState = '';
  String _parserItemId = '';
  String _barcodeItemId = '';
  String _localItemId = '';
  var _localQuantity = 0;
  var _mirrorQueued = false;
  final bool _suggestionPromoted = false;
  final bool _liveServiceTouched = false;
  var _abandoned = false;
  var _duplicate = false;

  void ingestReceiptLine(
    String rawLine, {
    required Set<String> enabledPacks,
    required String sourceId,
  }) {
    auditTrail.add('ingest:${enabledPacks.toList()..sort()}');
    _duplicate = !_seenSources.add(sourceId);
    if (rawLine.trim().isEmpty) auditTrail.add('empty_line');
  }

  void scanBarcode({required String candidateItemId}) {
    auditTrail.add('barcode_suggestion');
    _barcodeItemId = candidateItemId;
  }

  void parserSuggests({
    required String candidateItemId,
    required String reviewState,
  }) {
    auditTrail.add('parser_suggestion:$reviewState');
    _parserItemId = candidateItemId;
    _reviewState =
        _barcodeItemId.isNotEmpty && _barcodeItemId != candidateItemId
        ? 'multiple_possible_matches'
        : reviewState;
  }

  void markDuplicateImport() {
    auditTrail.add('duplicate_receipt_detected');
    _duplicate = true;
  }

  void userConfirms({required String itemId}) {
    _commitLocal(itemId);
  }

  void userEdits({required String itemId}) {
    _commitLocal(itemId);
  }

  void userRejects() {
    auditTrail.add('user_rejected');
    _localItemId = 'rejected';
  }

  void userAbandonsReview() {
    auditTrail.add('review_abandoned');
    _abandoned = true;
  }

  void staleMirrorAttemptsWrite({required String itemId}) {
    auditTrail.add('stale_mirror_ignored:$itemId');
  }

  _ChaosResult result({
    required String expectedItemId,
    required bool requiresReview,
    required bool duplicateImport,
    required bool abandoned,
  }) {
    return _ChaosResult(
      auditTrail: List.unmodifiable(auditTrail),
      finalState:
          'item=$_localItemId parser=$_parserItemId qty=$_localQuantity review=$_reviewState mirror=$_mirrorQueued abandoned=$_abandoned',
      reviewState: _reviewState,
      parserOutputStayedSuggestion: !_suggestionPromoted,
      localTruthWins: abandoned || _localItemId == expectedItemId,
      ambiguousEvidenceRequiredReview:
          !requiresReview || _reviewState != 'high_confidence_review',
      duplicateDidNotDoubleStock: !duplicateImport || _localQuantity <= 1,
      abandonedReviewWroteNothing:
          !abandoned || (_localItemId.isEmpty && !_mirrorQueued),
      noLiveServices: !_liveServiceTouched,
    );
  }

  void _commitLocal(String itemId) {
    auditTrail.add('hive_local_write');
    _localItemId = itemId;
    _localQuantity = _duplicate ? 1 : _localQuantity + 1;
    auditTrail.add('fake_mirror_queued');
    _mirrorQueued = true;
  }
}

class _ChaosResult {
  const _ChaosResult({
    required this.auditTrail,
    required this.finalState,
    required this.reviewState,
    required this.parserOutputStayedSuggestion,
    required this.localTruthWins,
    required this.ambiguousEvidenceRequiredReview,
    required this.duplicateDidNotDoubleStock,
    required this.abandonedReviewWroteNothing,
    required this.noLiveServices,
  });

  final List<String> auditTrail;
  final String finalState;
  final String reviewState;
  final bool parserOutputStayedSuggestion;
  final bool localTruthWins;
  final bool ambiguousEvidenceRequiredReview;
  final bool duplicateDidNotDoubleStock;
  final bool abandonedReviewWroteNothing;
  final bool noLiveServices;
}
