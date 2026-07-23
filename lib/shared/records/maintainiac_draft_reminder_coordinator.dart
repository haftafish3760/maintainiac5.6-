import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'maintainiac_draft_retention_policy.dart';
import 'maintainiac_durable_record_store.dart';
import 'maintainiac_record_lifecycle.dart';

class MaintainiacDraftReminderDecision {
  const MaintainiacDraftReminderDecision({
    required this.scopeId,
    required this.draft,
    required this.dueAtUtc,
    required this.showInApp,
    required this.sendPush,
    required this.playAudio,
  });

  final String scopeId;
  final MaintainiacRecordDraft draft;
  final DateTime dueAtUtc;
  final bool showInApp;
  final bool sendPush;
  final bool playAudio;
}

class MaintainiacDraftReminderCoordinator {
  MaintainiacDraftReminderCoordinator({
    required MaintainiacRecordDraftStore drafts,
    required MaintainiacDurableRecordStore records,
  }) : _drafts = drafts,
       _records = records,
       _policies = MaintainiacDraftRetentionPolicyStore(records);

  static const String receiptModule = 'draftReminderReceipts';

  final MaintainiacRecordDraftStore _drafts;
  final MaintainiacDurableRecordStore _records;
  final MaintainiacDraftRetentionPolicyStore _policies;

  List<MaintainiacDraftReminderDecision> dueForScope({
    required String scopeId,
    required Iterable<String> draftModules,
    DateTime? nowUtc,
  }) {
    final policy = _policies.policyFor(scopeId);
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final decisions = <MaintainiacDraftReminderDecision>[];
    final modules = draftModules.toSet().toList()..sort();
    for (final module in modules) {
      for (final draft in _drafts.draftsFor(module)) {
        final dueAt = policy.reminderDueAt(draft.lifecycle.updatedAt);
        if (now.isBefore(dueAt)) continue;
        final receipt = _receiptFor(scopeId, draft);
        final sameRevision =
            receipt?['draftRevision'] == draft.lifecycle.revision &&
            receipt?['draftUpdatedAtUtc'] ==
                draft.lifecycle.updatedAt.toUtc().toIso8601String();
        final inAppDelivered =
            sameRevision && receipt?['inAppDelivered'] == true;
        final pushDelivered = sameRevision && receipt?['pushDelivered'] == true;
        final audioDelivered =
            sameRevision && receipt?['audioDelivered'] == true;
        final decision = MaintainiacDraftReminderDecision(
          scopeId: scopeId,
          draft: draft,
          dueAtUtc: dueAt,
          showInApp: !inAppDelivered,
          sendPush: policy.pushReminderEnabled && !pushDelivered,
          playAudio: policy.audioReminderEnabled && !audioDelivered,
        );
        if (decision.showInApp || decision.sendPush || decision.playAudio) {
          decisions.add(decision);
        }
      }
    }
    return List.unmodifiable(decisions);
  }

  Future<void> recordDelivery(
    MaintainiacDraftReminderDecision decision, {
    required bool inAppDelivered,
    bool pushDelivered = false,
    bool audioDelivered = false,
    DateTime? nowUtc,
  }) async {
    if (!inAppDelivered && !pushDelivered && !audioDelivered) return;
    final id = _receiptId(decision.scopeId, decision.draft);
    final existing = _records.recordFor(receiptModule, id);
    final sameRevision =
        existing?.payload['draftRevision'] ==
            decision.draft.lifecycle.revision &&
        existing?.payload['draftUpdatedAtUtc'] ==
            decision.draft.lifecycle.updatedAt.toUtc().toIso8601String();
    await _records.save(
      module: receiptModule,
      id: id,
      expectedRevision: existing?.lifecycle.revision,
      now: nowUtc,
      payload: {
        'schema': 'maintainiac_draft_reminder_receipt_v1',
        'scopeId': decision.scopeId,
        'draftModule': decision.draft.module,
        'draftId': decision.draft.id,
        'draftRevision': decision.draft.lifecycle.revision,
        'draftUpdatedAtUtc': decision.draft.lifecycle.updatedAt
            .toUtc()
            .toIso8601String(),
        'inAppDelivered':
            inAppDelivered ||
            (sameRevision && existing?.payload['inAppDelivered'] == true),
        'pushDelivered':
            pushDelivered ||
            (sameRevision && existing?.payload['pushDelivered'] == true),
        'audioDelivered':
            audioDelivered ||
            (sameRevision && existing?.payload['audioDelivered'] == true),
      },
    );
  }

  Map<String, dynamic>? _receiptFor(
    String scopeId,
    MaintainiacRecordDraft draft,
  ) => _records.recordFor(receiptModule, _receiptId(scopeId, draft))?.payload;

  String _receiptId(String scopeId, MaintainiacRecordDraft draft) => sha256
      .convert(utf8.encode('$scopeId\u0000${draft.module}\u0000${draft.id}'))
      .toString();
}
