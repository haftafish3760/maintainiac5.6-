import 'maintainiac_durable_record_store.dart';

class MaintainiacDraftRetentionPolicy {
  const MaintainiacDraftRetentionPolicy({
    required this.scopeId,
    this.retentionDays = defaultRetentionDays,
    this.pushReminderEnabled = false,
    this.audioReminderEnabled = false,
    this.localRevision = 0,
  });

  static const int defaultRetentionDays = 90;
  static const int maximumRetentionDays = 3650;

  final String scopeId;
  final int retentionDays;
  final bool pushReminderEnabled;
  final bool audioReminderEnabled;
  final int localRevision;

  bool get inAppReminderEnabled => true;
  bool get dashboardVisible => true;

  Duration get retention => Duration(days: retentionDays);

  DateTime reminderDueAt(DateTime draftUpdatedAt) =>
      draftUpdatedAt.toUtc().add(retention);

  MaintainiacDraftRetentionPolicy copyWith({
    int? retentionDays,
    bool? pushReminderEnabled,
    bool? audioReminderEnabled,
    int? localRevision,
  }) => MaintainiacDraftRetentionPolicy(
    scopeId: scopeId,
    retentionDays: retentionDays ?? this.retentionDays,
    pushReminderEnabled: pushReminderEnabled ?? this.pushReminderEnabled,
    audioReminderEnabled: audioReminderEnabled ?? this.audioReminderEnabled,
    localRevision: localRevision ?? this.localRevision,
  );

  Map<String, Object?> toPayload() {
    _validate();
    return {
      'schema': 'maintainiac_draft_retention_policy_v1',
      'scopeId': scopeId,
      'retentionDays': retentionDays,
      'inAppReminderEnabled': true,
      'pushReminderEnabled': pushReminderEnabled,
      'audioReminderEnabled': audioReminderEnabled,
      'dashboardVisible': true,
    };
  }

  factory MaintainiacDraftRetentionPolicy.fromRecord(
    MaintainiacDurableRecord record,
  ) {
    final payload = record.payload;
    if (record.module != MaintainiacDraftRetentionPolicyStore.recordModule ||
        payload['schema'] != 'maintainiac_draft_retention_policy_v1' ||
        payload['scopeId'] != record.id ||
        payload['retentionDays'] is! int ||
        payload['inAppReminderEnabled'] != true ||
        payload['pushReminderEnabled'] is! bool ||
        payload['audioReminderEnabled'] is! bool ||
        payload['dashboardVisible'] != true) {
      throw const FormatException('Stored draft retention policy is invalid.');
    }
    final policy = MaintainiacDraftRetentionPolicy(
      scopeId: record.id,
      retentionDays: payload['retentionDays'] as int,
      pushReminderEnabled: payload['pushReminderEnabled'] as bool,
      audioReminderEnabled: payload['audioReminderEnabled'] as bool,
      localRevision: record.lifecycle.revision,
    );
    policy._validate();
    return policy;
  }

  void _validate() {
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(scopeId)) {
      throw ArgumentError.value(scopeId, 'scopeId');
    }
    if (retentionDays < 1 || retentionDays > maximumRetentionDays) {
      throw ArgumentError.value(retentionDays, 'retentionDays');
    }
    if (localRevision < 0) {
      throw ArgumentError.value(localRevision, 'localRevision');
    }
  }
}

class MaintainiacDraftRetentionPolicyStore {
  MaintainiacDraftRetentionPolicyStore(this._records);

  static const String recordModule = 'draftRetentionPolicies';

  final MaintainiacDurableRecordStore _records;

  MaintainiacDraftRetentionPolicy policyFor(String scopeId) {
    final stored = _records.recordFor(recordModule, scopeId);
    final policy = stored == null
        ? MaintainiacDraftRetentionPolicy(scopeId: scopeId)
        : MaintainiacDraftRetentionPolicy.fromRecord(stored);
    policy._validate();
    return policy;
  }

  List<MaintainiacDraftRetentionPolicy> get savedPolicies => List.unmodifiable(
    _records
        .recordsFor(recordModule)
        .map(MaintainiacDraftRetentionPolicy.fromRecord),
  );

  Future<MaintainiacDraftRetentionPolicy> save(
    MaintainiacDraftRetentionPolicy policy, {
    DateTime? now,
  }) async {
    final saved = await _records.save(
      module: recordModule,
      id: policy.scopeId,
      payload: policy.toPayload(),
      expectedRevision: policy.localRevision == 0 ? null : policy.localRevision,
      now: now,
    );
    return MaintainiacDraftRetentionPolicy.fromRecord(saved);
  }
}
