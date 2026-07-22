import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('feature modules can use one durable-storage import', () async {
    final drafts = MaintainiacRecordDraftStore.memory();
    final records = MaintainiacDurableRecordStore.memory();
    final checkpoint = await drafts.save(
      module: 'invoices',
      id: 'invoice_1',
      payload: const {'totalCents': 2500},
      now: DateTime.utc(2026, 7, 22, 12),
    );

    final record = await records.saveAndAcknowledgeDraft(
      module: 'invoices',
      id: 'invoice_1',
      payload: checkpoint.payload,
      draftStore: drafts,
      expectedDraftUpdatedAt: checkpoint.lifecycle.updatedAt,
      now: DateTime.utc(2026, 7, 22, 12, 1),
    );

    expect(record.lifecycle.revision, 1);
    expect(drafts.draftFor('invoices', 'invoice_1'), isNull);
    expect(
      drafts
          .draftFor('invoices', 'invoice_1', includeDeleted: true)
          ?.lifecycle
          .isDeleted,
      isTrue,
    );
  });

  test('facade exposes cloud revision and tenant safeguards', () {
    final decision = MaintainiacFirestoreRevisionPolicy.decide(
      incoming: const {'localRevision': 2, 'recordState': 'active'},
      existing: const {'localRevision': 3, 'recordState': 'active'},
    );
    expect(decision.action, MaintainiacFirestoreRevisionAction.conflict);
    expect(
      () => MaintainiacFirestoreScopePolicy.validateWrite(
        path: 'orgs/orgA/invoices/invoice_1',
        data: const {'orgId': 'orgA', 'updatedByUid': 'userA'},
        authenticatedUid: 'userB',
      ),
      throwsA(isA<MaintainiacFirestoreScopeMismatch>()),
    );
  });
}
