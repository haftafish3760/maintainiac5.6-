import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('sync conflict contract allows different-field safe merge', () {
    const contract = MaintainiacSyncConflictContract([
      MaintainiacSyncConflictCase(
        id: 'conflict_vehicle_notes_merge',
        collection: 'vehicles',
        recordId: 'vehicle_1',
        fields: [
          MaintainiacSyncConflictField(
            name: 'nickname',
            localValue: 'Van 1',
            remoteValue: 'Van 1',
          ),
          MaintainiacSyncConflictField(
            name: 'notes',
            localValue: 'ladder rack',
            remoteValue: 'ladder rack plus bins',
          ),
          MaintainiacSyncConflictField(
            name: 'color',
            localValue: 'white',
            remoteValue: 'white',
          ),
        ],
        resolution: MaintainiacConflictResolution.merged,
        reason: 'Only non-financial notes changed remotely.',
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(
      contract.toJson().toString(),
      contains('conflict_vehicle_notes_merge'),
    );
  });

  test('sync conflict contract protects confirmed financial local data', () {
    const contract = MaintainiacSyncConflictContract([
      MaintainiacSyncConflictCase(
        id: 'conflict_expense_total_local_wins',
        collection: 'expenses',
        recordId: 'expense_1',
        fields: [
          MaintainiacSyncConflictField(
            name: 'totalCents',
            localValue: 1060,
            remoteValue: 1006,
            userConfirmed: true,
            financial: true,
          ),
        ],
        resolution: MaintainiacConflictResolution.localWins,
        reason: 'User-confirmed local financial value outranks mirror.',
      ),
    ]);

    expect(contract.validate(), isEmpty);
    expect(contract.reviewQueue(), isEmpty);
  });

  test(
    'sync conflict contract requires review audit for ambiguous conflicts',
    () {
      const contract = MaintainiacSyncConflictContract([
        MaintainiacSyncConflictCase(
          id: 'conflict_inventory_quantity_review',
          collection: 'inventory',
          recordId: 'item_1',
          fields: [
            MaintainiacSyncConflictField(
              name: 'onHand',
              localValue: 8,
              remoteValue: 6,
              userConfirmed: true,
            ),
          ],
          resolution: MaintainiacConflictResolution.needsReview,
          reason: 'Quantity changed on two devices and needs user review.',
          auditId: 'AUD-INV-0001',
        ),
      ]);

      expect(contract.validate(), isEmpty);
      expect(contract.reviewQueue(), hasLength(1));
    },
  );

  test(
    'sync conflict contract rejects unsafe remote wins and source mutation',
    () {
      const contract = MaintainiacSyncConflictContract([
        MaintainiacSyncConflictCase(
          id: 'conflict_bad_remote_wins',
          collection: 'expenses',
          recordId: 'expense_2',
          fields: [
            MaintainiacSyncConflictField(
              name: 'totalCents',
              localValue: 1200,
              remoteValue: 200,
              userConfirmed: true,
              financial: true,
            ),
          ],
          resolution: MaintainiacConflictResolution.remoteWins,
          reason: 'Bad remote overwrite.',
          writesMirrorOnly: false,
          mutatesLocalWithoutUser: true,
        ),
        MaintainiacSyncConflictCase(
          id: 'conflict_bad_merge',
          collection: 'jobs',
          recordId: 'job_1',
          fields: [
            MaintainiacSyncConflictField(
              name: 'status',
              localValue: 'active',
              remoteValue: 'closed',
            ),
          ],
          resolution: MaintainiacConflictResolution.merged,
          reason: 'Bad same-field merge.',
        ),
        MaintainiacSyncConflictCase(
          id: 'conflict_bad_review',
          collection: 'inventory',
          recordId: 'item_2',
          fields: [
            MaintainiacSyncConflictField(
              name: 'onHand',
              localValue: 2,
              remoteValue: 5,
            ),
          ],
          resolution: MaintainiacConflictResolution.needsReview,
          reason: 'Missing audit id.',
        ),
      ]);

      final failures = contract.validate().join('\n');

      expect(failures, contains('Firestore as mirror only'));
      expect(failures, contains('must not mutate local source'));
      expect(failures, contains('cannot be remote-wins/auto-merged'));
      expect(failures, contains('same-field conflict cannot be marked merged'));
      expect(failures, contains('review conflict needs audit id'));
    },
  );
}
