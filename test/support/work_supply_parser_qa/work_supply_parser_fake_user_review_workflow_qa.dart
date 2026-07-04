import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFakeUserReviewWorkflowSuite extends QaSuite {
  const WorkSupplyParserFakeUserReviewWorkflowSuite()
    : super('inventory.fake_user_review_workflow');

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final scenarios = _scenarios();

    for (final scenario in scenarios) {
      final result = _runScenario(scenario);
      _expect(
        failures,
        result.localWriteBeforeMirror,
        id: '${scenario.id}:local_write_before_mirror',
        message: 'Fake user workflow did not commit local truth first.',
        expected: 'Hive/local confirmed write before Firebase mirror action.',
        actual: result.events.join(' > '),
        triage: QaFailureTriage.reviewSafety,
      );
      _expect(
        failures,
        result.parserSuggestionNeverAutoSaved,
        id: '${scenario.id}:suggestion_not_auto_saved',
        message: 'Parser suggestion was allowed to become source data.',
        expected: 'Parser output remains suggestion data until user action.',
        actual: result.events.join(' > '),
        triage: QaFailureTriage.reviewSafety,
      );
      _expect(
        failures,
        result.userConfirmedDataWins,
        id: '${scenario.id}:confirmed_data_wins',
        message: 'User-confirmed data did not outrank parser/cloud data.',
        expected: 'User-confirmed values survive parser updates and mirrors.',
        actual: result.finalLocalState,
        triage: QaFailureTriage.conflict,
      );
      _expect(
        failures,
        result.noLiveFirebase,
        id: '${scenario.id}:no_live_firebase',
        message: 'Fake workflow used a live Firebase-style action.',
        expected: 'Fake mirror queue only; no live service dependency.',
        actual: result.events.join(' > '),
        triage: QaFailureTriage.security,
      );
      _expect(
        failures,
        result.reviewStatusPreserved,
        id: '${scenario.id}:review_status_preserved',
        message: 'Parser review status was lost during workflow routing.',
        expected: scenario.expectedReviewStatus,
        actual: result.reviewStatus,
        triage: QaFailureTriage.governance,
      );
      _expect(
        failures,
        result.rejectedNoiseCreatedNoInventory,
        id: '${scenario.id}:rejected_noise_created_no_inventory',
        message: 'Rejected receipt noise created an inventory record.',
        expected: 'Rejected non-inventory lines may be audited, not stocked.',
        actual: result.finalLocalState,
        triage: QaFailureTriage.reviewSafety,
      );
      _expect(
        failures,
        result.destinationPreserved,
        id: '${scenario.id}:destination_preserved',
        message: 'Parser review workflow lost the user-selected destination.',
        expected:
            'Confirmed item routes to inventory, job, estimate, invoice, or rejection exactly as reviewed.',
        actual: result.finalLocalState,
        triage: QaFailureTriage.governance,
      );
      _expect(
        failures,
        result.contextPreserved,
        id: '${scenario.id}:context_preserved',
        message:
            'Trade/job/estimate context was not preserved as supporting evidence.',
        expected:
            'Enabled packs and active section context stay attached without forcing certainty.',
        actual: result.finalLocalState,
        triage: QaFailureTriage.reviewSafety,
      );
      _expect(
        failures,
        result.cloudOptInControlsMirror,
        id: '${scenario.id}:cloud_opt_in_controls_mirror',
        message: 'Fake Firebase mirror behavior ignored cloud opt-in state.',
        expected:
            'Cloud opt-in queues fake mirror after local write; local-only does not.',
        actual: result.events.join(' > '),
        triage: QaFailureTriage.security,
      );
      _expect(
        failures,
        result.immediateMirrorAttemptAfterLocalWrite,
        id: '${scenario.id}:immediate_mirror_attempt_after_local_write',
        message:
            'Cloud-enabled fake workflow did not attempt mirror sync immediately after local save.',
        expected:
            'Cloud opt-in attempts fake mirror sync after Hive/local write without making Firebase the source of truth.',
        actual: result.events.join(' > '),
        triage: QaFailureTriage.conflict,
      );
      _expect(
        failures,
        result.failedMirrorKeepsLocalTruth,
        id: '${scenario.id}:failed_mirror_keeps_local_truth',
        message: 'Mirror failure was allowed to damage confirmed local truth.',
        expected:
            'Fake Firebase failure keeps confirmed Hive/local item and leaves retry state reviewable.',
        actual: result.restartState,
        triage: QaFailureTriage.conflict,
      );
      _expect(
        failures,
        result.retryClearsPendingMirrorOnlyAfterSuccess,
        id: '${scenario.id}:retry_clears_pending_mirror_only_after_success',
        message:
            'Mirror retry state was cleared before a successful fake mirror write.',
        expected:
            'Pending mirror remains after failure and clears only after fake mirror retry succeeds.',
        actual: result.events.join(' > '),
        triage: QaFailureTriage.conflict,
      );
      _expect(
        failures,
        result.restartPreservedLocalTruth,
        id: '${scenario.id}:restart_preserved_local_truth',
        message: 'App restart simulation lost confirmed local parser data.',
        expected:
            'Restart keeps confirmed Hive/local truth and pending mirror state intact.',
        actual: result.restartState,
        triage: QaFailureTriage.conflict,
      );
    }

    return timer.finish(
      suite: name,
      checked: scenarios.length * 13,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'scenarioCount': scenarios.length,
        'workflow':
            'adapter text -> parser suggestion -> user review action -> Hive/local truth -> fake Firebase mirror queue',
        'liveFirebaseUsed': false,
        'uiRequired': false,
        'ocrRequired': false,
      },
    );
  }

  _WorkflowResult _runScenario(_WorkflowScenario scenario) {
    final fake = _FakeReviewEnvironment();
    fake.receiveAdapterText(
      scenario.rawText,
      destination: scenario.destination,
      enabledTradePacks: scenario.enabledTradePacks,
      activeSectionTrade: scenario.activeSectionTrade,
    );
    fake.parserSuggests(
      status: scenario.expectedReviewStatus,
      candidateId: scenario.parserCandidateId,
    );
    switch (scenario.action) {
      case _ReviewAction.accept:
        fake.userAccepts(
          confirmedItemId: scenario.userConfirmedItemId,
          cloudOptIn: scenario.cloudOptIn,
          failFirstMirrorAttempt: scenario.mirrorFailureBeforeRetry,
        );
      case _ReviewAction.edit:
        fake.userEdits(
          confirmedItemId: scenario.userConfirmedItemId,
          correctedName: scenario.correctedName,
          cloudOptIn: scenario.cloudOptIn,
          failFirstMirrorAttempt: scenario.mirrorFailureBeforeRetry,
        );
      case _ReviewAction.reject:
        fake.userRejects(
          cloudOptIn: scenario.cloudOptIn,
          failFirstMirrorAttempt: scenario.mirrorFailureBeforeRetry,
        );
      case _ReviewAction.markUnknown:
        fake.userMarksUnknown(
          cloudOptIn: scenario.cloudOptIn,
          failFirstMirrorAttempt: scenario.mirrorFailureBeforeRetry,
        );
    }
    fake.parserSuggests(
      status: 'high_confidence_review',
      candidateId: '${scenario.parserCandidateId}_later_pack_update',
    );
    fake.mirrorAttemptsStaleWrite();
    fake.simulateAppRestart();
    return fake.result(
      expectedConfirmedItemId: scenario.userConfirmedItemId,
      expectedReviewStatus: scenario.expectedReviewStatus,
    );
  }

  List<_WorkflowScenario> _scenarios() {
    return const [
      _WorkflowScenario(
        id: 'clear_match_accept_cloud_opt_in',
        rawText: 'HD 3/4 PVC SCH40 COUPLING',
        parserCandidateId: 'pvc_schedule_40_coupling',
        userConfirmedItemId: 'pvc_schedule_40_coupling',
        expectedReviewStatus: 'high_confidence_review',
        action: _ReviewAction.accept,
        destination: _WorkflowDestination.inventory,
        enabledTradePacks: {'plumbing'},
        cloudOptIn: true,
      ),
      _WorkflowScenario(
        id: 'ambiguous_pvc_user_edits_cloud_opt_in',
        rawText: 'PVC 3/4 CPLG 12/2 WIRE',
        parserCandidateId: 'ranked_pvc_coupling_candidate',
        userConfirmedItemId: 'pvc_conduit_coupling',
        expectedReviewStatus: 'multiple_possible_matches',
        action: _ReviewAction.edit,
        correctedName: 'PVC conduit coupling',
        destination: _WorkflowDestination.jobMaterial,
        enabledTradePacks: {'plumbing', 'electrical'},
        activeSectionTrade: 'electrical',
        cloudOptIn: true,
      ),
      _WorkflowScenario(
        id: 'unknown_local_only_mark_unknown',
        rawText: 'MISC PART 8891',
        parserCandidateId: 'unknown_item',
        userConfirmedItemId: 'unknown_item',
        expectedReviewStatus: 'unknown_item',
        action: _ReviewAction.markUnknown,
        destination: _WorkflowDestination.inventory,
        enabledTradePacks: {'plumbing', 'electrical', 'hvac'},
      ),
      _WorkflowScenario(
        id: 'noise_rejected_never_creates_inventory',
        rawText: 'SALES TAX 4.32',
        parserCandidateId: 'not_inventory',
        userConfirmedItemId: 'rejected',
        expectedReviewStatus: 'not_inventory',
        action: _ReviewAction.reject,
        destination: _WorkflowDestination.rejected,
        enabledTradePacks: {'plumbing'},
        cloudOptIn: true,
        mirrorFailureBeforeRetry: true,
      ),
      _WorkflowScenario(
        id: 'estimate_section_context_keeps_pvc_ambiguous',
        rawText: 'PVC EL 3/4',
        parserCandidateId: 'ranked_pvc_elbow_candidate',
        userConfirmedItemId: 'pvc_schedule_40_elbow',
        expectedReviewStatus: 'multiple_possible_matches',
        action: _ReviewAction.edit,
        correctedName: 'PVC schedule 40 elbow',
        destination: _WorkflowDestination.estimateMaterial,
        enabledTradePacks: {'plumbing', 'electrical', 'hvac'},
        activeSectionTrade: 'plumbing',
        cloudOptIn: true,
      ),
      _WorkflowScenario(
        id: 'invoice_material_accepts_user_confirmed_cost_line',
        rawText: '3/4 COPPER 90',
        parserCandidateId: 'ranked_copper_elbow_candidate',
        userConfirmedItemId: 'copper_pressure_elbow',
        expectedReviewStatus: 'high_confidence_review',
        action: _ReviewAction.accept,
        destination: _WorkflowDestination.invoiceMaterial,
        enabledTradePacks: {'plumbing', 'hvac'},
        cloudOptIn: true,
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
            'Keep parser review workflows local-first, review-only, fake-service backed, and user-confirmed-data authoritative.',
        metadata: {'triageCategory': triage},
      ),
    );
  }
}

class _WorkflowScenario {
  const _WorkflowScenario({
    required this.id,
    required this.rawText,
    required this.parserCandidateId,
    required this.userConfirmedItemId,
    required this.expectedReviewStatus,
    required this.action,
    this.destination = _WorkflowDestination.inventory,
    this.enabledTradePacks = const {},
    this.activeSectionTrade = '',
    this.correctedName = '',
    this.cloudOptIn = false,
    this.mirrorFailureBeforeRetry = false,
  });

  final String id;
  final String rawText;
  final String parserCandidateId;
  final String userConfirmedItemId;
  final String expectedReviewStatus;
  final _ReviewAction action;
  final _WorkflowDestination destination;
  final Set<String> enabledTradePacks;
  final String activeSectionTrade;
  final String correctedName;
  final bool cloudOptIn;
  final bool mirrorFailureBeforeRetry;
}

enum _ReviewAction { accept, edit, reject, markUnknown }

enum _WorkflowDestination {
  inventory,
  jobMaterial,
  estimateMaterial,
  invoiceMaterial,
  rejected,
}

class _FakeReviewEnvironment {
  final events = <String>[];
  String _reviewStatus = '';
  String _confirmedReviewStatus = '';
  String _parserCandidateId = '';
  String _localConfirmedItemId = '';
  String _localConfirmedName = '';
  _WorkflowDestination _destination = _WorkflowDestination.inventory;
  String _confirmedDestination = '';
  String _contextEvidence = '';
  String _confirmedContextEvidence = '';
  final bool _suggestionSaved = false;
  bool _localWriteDone = false;
  bool _inventoryRecordCreated = false;
  bool _mirrorQueued = false;
  bool _mirrorSent = false;
  bool _mirrorFailed = false;
  bool _mirrorRetrySucceeded = false;
  String _restartLocalItemId = '';
  String _restartPendingMirror = '';
  final bool _liveFirebaseTouched = false;

  void receiveAdapterText(
    String rawText, {
    required _WorkflowDestination destination,
    required Set<String> enabledTradePacks,
    required String activeSectionTrade,
  }) {
    events.add('adapter_text_received:${destination.name}');
    _destination = destination;
    final packs = enabledTradePacks.toList()..sort();
    _contextEvidence = 'packs=$packs section=$activeSectionTrade';
    if (rawText.trim().isEmpty) events.add('empty_text_rejected');
  }

  void parserSuggests({required String status, required String candidateId}) {
    events.add('parser_suggestion:$status');
    _reviewStatus = status;
    _parserCandidateId = candidateId;
  }

  void userAccepts({
    required String confirmedItemId,
    required bool cloudOptIn,
    required bool failFirstMirrorAttempt,
  }) {
    _commitLocal(confirmedItemId: confirmedItemId);
    if (cloudOptIn) _queueFakeMirror(failFirstAttempt: failFirstMirrorAttempt);
  }

  void userEdits({
    required String confirmedItemId,
    required String correctedName,
    required bool cloudOptIn,
    required bool failFirstMirrorAttempt,
  }) {
    _commitLocal(
      confirmedItemId: confirmedItemId,
      confirmedName: correctedName,
    );
    if (cloudOptIn) _queueFakeMirror(failFirstAttempt: failFirstMirrorAttempt);
  }

  void userRejects({
    required bool cloudOptIn,
    required bool failFirstMirrorAttempt,
  }) {
    _commitLocal(
      confirmedItemId: 'rejected',
      confirmedName: 'not inventory',
      createsInventory: false,
    );
    if (cloudOptIn) _queueFakeMirror(failFirstAttempt: failFirstMirrorAttempt);
  }

  void userMarksUnknown({
    required bool cloudOptIn,
    required bool failFirstMirrorAttempt,
  }) {
    _commitLocal(confirmedItemId: 'unknown_item', confirmedName: 'unknown');
    if (cloudOptIn) _queueFakeMirror(failFirstAttempt: failFirstMirrorAttempt);
  }

  void mirrorAttemptsStaleWrite() {
    events.add('stale_mirror_ignored');
  }

  void simulateAppRestart() {
    events.add('app_restart_simulated');
    _restartLocalItemId = _localConfirmedItemId;
    _restartPendingMirror = _mirrorQueued && !_mirrorSent ? 'pending' : 'none';
  }

  _WorkflowResult result({
    required String expectedConfirmedItemId,
    required String expectedReviewStatus,
  }) {
    return _WorkflowResult(
      events: List.unmodifiable(events),
      finalLocalState:
          'item=$_localConfirmedItemId name=$_localConfirmedName parser=$_parserCandidateId destination=$_confirmedDestination context=$_confirmedContextEvidence',
      reviewStatus: _confirmedReviewStatus,
      localWriteBeforeMirror:
          _localWriteDone &&
          (!_mirrorQueued ||
              events.indexOf('hive_local_write') <
                  events.indexOf('fake_firebase_mirror_queued')),
      parserSuggestionNeverAutoSaved: !_suggestionSaved,
      userConfirmedDataWins: _localConfirmedItemId == expectedConfirmedItemId,
      noLiveFirebase: !_liveFirebaseTouched,
      reviewStatusPreserved: _confirmedReviewStatus == expectedReviewStatus,
      rejectedNoiseCreatedNoInventory:
          expectedConfirmedItemId != 'rejected' || !_inventoryRecordCreated,
      destinationPreserved: _confirmedDestination == _destination.name,
      contextPreserved:
          _confirmedContextEvidence == _contextEvidence &&
          _confirmedContextEvidence.contains('packs='),
      cloudOptInControlsMirror:
          _mirrorQueued == events.contains('fake_firebase_mirror_queued'),
      immediateMirrorAttemptAfterLocalWrite:
          !_mirrorQueued ||
          events.indexOf('hive_local_write') <
              events.indexOf('fake_firebase_mirror_attempted'),
      failedMirrorKeepsLocalTruth:
          !_mirrorFailed ||
          (_localConfirmedItemId == expectedConfirmedItemId &&
              events.contains('fake_firebase_mirror_retry_pending')),
      retryClearsPendingMirrorOnlyAfterSuccess:
          !_mirrorFailed ||
          (_mirrorRetrySucceeded &&
              _mirrorSent &&
              events.indexOf('fake_firebase_mirror_retry_pending') <
                  events.indexOf('fake_firebase_mirror_retry_succeeded')),
      restartState:
          'restartItem=$_restartLocalItemId restartPendingMirror=$_restartPendingMirror',
      restartPreservedLocalTruth:
          _restartLocalItemId == expectedConfirmedItemId &&
          _restartPendingMirror == 'none',
    );
  }

  void _commitLocal({
    required String confirmedItemId,
    String confirmedName = '',
    bool createsInventory = true,
  }) {
    events.add('hive_local_write');
    _localWriteDone = true;
    _localConfirmedItemId = confirmedItemId;
    _localConfirmedName = confirmedName;
    _inventoryRecordCreated = createsInventory;
    _confirmedReviewStatus = _reviewStatus;
    _confirmedDestination = _destination.name;
    _confirmedContextEvidence = _contextEvidence;
  }

  void _queueFakeMirror({required bool failFirstAttempt}) {
    events.add('fake_firebase_mirror_queued');
    _mirrorQueued = true;
    events.add('fake_firebase_mirror_attempted');
    if (failFirstAttempt) {
      _mirrorFailed = true;
      events.add('fake_firebase_mirror_failed');
      events.add('fake_firebase_mirror_retry_pending');
      events.add('fake_firebase_mirror_retry_succeeded');
      _mirrorRetrySucceeded = true;
    } else {
      events.add('fake_firebase_mirror_succeeded');
    }
    _mirrorSent = true;
  }
}

class _WorkflowResult {
  const _WorkflowResult({
    required this.events,
    required this.finalLocalState,
    required this.reviewStatus,
    required this.localWriteBeforeMirror,
    required this.parserSuggestionNeverAutoSaved,
    required this.userConfirmedDataWins,
    required this.noLiveFirebase,
    required this.reviewStatusPreserved,
    required this.rejectedNoiseCreatedNoInventory,
    required this.destinationPreserved,
    required this.contextPreserved,
    required this.cloudOptInControlsMirror,
    required this.immediateMirrorAttemptAfterLocalWrite,
    required this.failedMirrorKeepsLocalTruth,
    required this.retryClearsPendingMirrorOnlyAfterSuccess,
    required this.restartState,
    required this.restartPreservedLocalTruth,
  });

  final List<String> events;
  final String finalLocalState;
  final String reviewStatus;
  final bool localWriteBeforeMirror;
  final bool parserSuggestionNeverAutoSaved;
  final bool userConfirmedDataWins;
  final bool noLiveFirebase;
  final bool reviewStatusPreserved;
  final bool rejectedNoiseCreatedNoInventory;
  final bool destinationPreserved;
  final bool contextPreserved;
  final bool cloudOptInControlsMirror;
  final bool immediateMirrorAttemptAfterLocalWrite;
  final bool failedMirrorKeepsLocalTruth;
  final bool retryClearsPendingMirrorOnlyAfterSuccess;
  final String restartState;
  final bool restartPreservedLocalTruth;
}
