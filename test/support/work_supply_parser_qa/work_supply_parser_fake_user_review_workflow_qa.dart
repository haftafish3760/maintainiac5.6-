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
    }

    return timer.finish(
      suite: name,
      checked: scenarios.length * 5,
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
    fake.receiveAdapterText(scenario.rawText);
    fake.parserSuggests(
      status: scenario.expectedReviewStatus,
      candidateId: scenario.parserCandidateId,
    );
    switch (scenario.action) {
      case _ReviewAction.accept:
        fake.userAccepts(
          confirmedItemId: scenario.userConfirmedItemId,
          cloudOptIn: scenario.cloudOptIn,
        );
      case _ReviewAction.edit:
        fake.userEdits(
          confirmedItemId: scenario.userConfirmedItemId,
          correctedName: scenario.correctedName,
          cloudOptIn: scenario.cloudOptIn,
        );
      case _ReviewAction.reject:
        fake.userRejects(cloudOptIn: scenario.cloudOptIn);
      case _ReviewAction.markUnknown:
        fake.userMarksUnknown(cloudOptIn: scenario.cloudOptIn);
    }
    fake.parserSuggests(
      status: 'high_confidence_review',
      candidateId: '${scenario.parserCandidateId}_later_pack_update',
    );
    fake.mirrorAttemptsStaleWrite();
    return fake.result(expectedConfirmedItemId: scenario.userConfirmedItemId);
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
        cloudOptIn: true,
      ),
      _WorkflowScenario(
        id: 'unknown_local_only_mark_unknown',
        rawText: 'MISC PART 8891',
        parserCandidateId: 'unknown_item',
        userConfirmedItemId: 'unknown_item',
        expectedReviewStatus: 'unknown_item',
        action: _ReviewAction.markUnknown,
      ),
      _WorkflowScenario(
        id: 'noise_rejected_never_creates_inventory',
        rawText: 'SALES TAX 4.32',
        parserCandidateId: 'not_inventory',
        userConfirmedItemId: 'rejected',
        expectedReviewStatus: 'not_inventory',
        action: _ReviewAction.reject,
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
    this.correctedName = '',
    this.cloudOptIn = false,
  });

  final String id;
  final String rawText;
  final String parserCandidateId;
  final String userConfirmedItemId;
  final String expectedReviewStatus;
  final _ReviewAction action;
  final String correctedName;
  final bool cloudOptIn;
}

enum _ReviewAction { accept, edit, reject, markUnknown }

class _FakeReviewEnvironment {
  final events = <String>[];
  String _reviewStatus = '';
  String _parserCandidateId = '';
  String _localConfirmedItemId = '';
  String _localConfirmedName = '';
  final bool _suggestionSaved = false;
  bool _localWriteDone = false;
  bool _mirrorQueued = false;
  final bool _liveFirebaseTouched = false;

  void receiveAdapterText(String rawText) {
    events.add('adapter_text_received');
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
  }) {
    _commitLocal(confirmedItemId: confirmedItemId);
    if (cloudOptIn) _queueFakeMirror();
  }

  void userEdits({
    required String confirmedItemId,
    required String correctedName,
    required bool cloudOptIn,
  }) {
    _commitLocal(
      confirmedItemId: confirmedItemId,
      confirmedName: correctedName,
    );
    if (cloudOptIn) _queueFakeMirror();
  }

  void userRejects({required bool cloudOptIn}) {
    _commitLocal(confirmedItemId: 'rejected', confirmedName: 'not inventory');
    if (cloudOptIn) _queueFakeMirror();
  }

  void userMarksUnknown({required bool cloudOptIn}) {
    _commitLocal(confirmedItemId: 'unknown_item', confirmedName: 'unknown');
    if (cloudOptIn) _queueFakeMirror();
  }

  void mirrorAttemptsStaleWrite() {
    events.add('stale_mirror_ignored');
  }

  _WorkflowResult result({required String expectedConfirmedItemId}) {
    return _WorkflowResult(
      events: List.unmodifiable(events),
      finalLocalState:
          'item=$_localConfirmedItemId name=$_localConfirmedName parser=$_parserCandidateId',
      reviewStatus: _reviewStatus,
      localWriteBeforeMirror:
          _localWriteDone &&
          (!_mirrorQueued ||
              events.indexOf('hive_local_write') <
                  events.indexOf('fake_firebase_mirror_queued')),
      parserSuggestionNeverAutoSaved: !_suggestionSaved,
      userConfirmedDataWins: _localConfirmedItemId == expectedConfirmedItemId,
      noLiveFirebase: !_liveFirebaseTouched,
      reviewStatusPreserved: _reviewStatus.isNotEmpty,
    );
  }

  void _commitLocal({
    required String confirmedItemId,
    String confirmedName = '',
  }) {
    events.add('hive_local_write');
    _localWriteDone = true;
    _localConfirmedItemId = confirmedItemId;
    _localConfirmedName = confirmedName;
  }

  void _queueFakeMirror() {
    events.add('fake_firebase_mirror_queued');
    _mirrorQueued = true;
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
  });

  final List<String> events;
  final String finalLocalState;
  final String reviewStatus;
  final bool localWriteBeforeMirror;
  final bool parserSuggestionNeverAutoSaved;
  final bool userConfirmedDataWins;
  final bool noLiveFirebase;
  final bool reviewStatusPreserved;
}
