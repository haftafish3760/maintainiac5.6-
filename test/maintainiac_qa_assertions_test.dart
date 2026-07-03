import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('shared QA assertions accept safe source truth behavior', () {
    final env = MaintainiacQaEnvironment.standard();
    env.hive.put('expenses', 'expense_1', {'id': 'expense_1', 'dirty': true});
    env.firestoreMirror.mirror('accounts/acct_1/expenses/expense_1', {
      'id': 'expense_1',
      'dirty': true,
    });

    MaintainiacQaAssertions.moneyEquals(1050, 1050);
    MaintainiacQaAssertions.odometerIsMonotonic(100, 101);
    MaintainiacQaAssertions.auditTrailComplete([
      {'id': 'audit_1', 'actorId': 'user_1', 'action': 'expense_created'},
    ]);
    MaintainiacQaAssertions.localWriteBeforeMirror(env);
    MaintainiacQaAssertions.dirtyFlagSet({'dirty': true});
    MaintainiacQaAssertions.dirtyFlagCleared({'dirty': false});
    MaintainiacQaAssertions.mirrorEqualsLocal(
      {'id': 'expense_1'},
      {'id': 'expense_1'},
    );
    MaintainiacQaAssertions.sameAccountOnly('acct_1', 'acct_1');
    MaintainiacQaAssertions.confirmedDataNotOverwritten(
      before: {'totalCents': 1000},
      after: {'totalCents': 1000},
      confirmedFields: ['totalCents'],
    );
    MaintainiacQaAssertions.suggestionStayedSuggestion({
      'reviewStatus': 'suggested',
    });
    MaintainiacQaAssertions.exportContainsOnlyOwnedRecords([
      {'accountId': 'acct_1'},
      {'ownerAccountId': 'acct_1'},
    ], 'acct_1');
    MaintainiacQaAssertions.noUnauthorizedSourceMutation(
      operation: 'inventory_confirm',
      mutatedCollections: ['inventory', 'inventory_movements'],
      allowedCollections: {'inventory', 'inventory_movements'},
    );
    MaintainiacQaAssertions.invoiceEstimateDidNotMutateSources(
      outputType: 'estimate',
      sourceCollectionsTouched: const [],
    );
    MaintainiacQaAssertions.payloadContainsNoPrivateFields({
      'id': 'inventory_1',
      'accountId': 'acct_1',
      'canonicalName': '1/2 in PVC elbow',
    });
    MaintainiacQaAssertions.conflictGeneratedWhenExpected(true);
    MaintainiacQaAssertions.regressionMatchedExpected(
      'needsReview',
      'needsReview',
      'QA-REG-0001',
    );
  });

  test('shared QA assertions reject source truth and privacy failures', () {
    final mirrorFirstEnv = MaintainiacQaEnvironment.standard();
    mirrorFirstEnv.firestoreMirror.mirror('accounts/acct_1/expenses/e1', {
      'id': 'e1',
    });
    final derivedMutationEnv = MaintainiacQaEnvironment.standard();
    derivedMutationEnv.hive.put('expenses', 'expense_1', {'id': 'expense_1'});

    expect(
      () => MaintainiacQaAssertions.moneyEquals(1050, 1000),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.odometerIsMonotonic(101, 100),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.auditTrailComplete([
        {'id': 'audit_1', 'actorId': '', 'action': 'expense_created'},
      ]),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.localWriteBeforeMirror(mirrorFirstEnv),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.mirrorEqualsLocal({'id': 'a'}, {'id': 'b'}),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.sameAccountOnly('acct_1', 'acct_2'),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.confirmedDataNotOverwritten(
        before: {'totalCents': 1000},
        after: {'totalCents': 999},
        confirmedFields: ['totalCents'],
      ),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.suggestionStayedSuggestion({
        'reviewStatus': 'confirmed',
      }),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () =>
          MaintainiacQaAssertions.recapDidNotMutateSources(derivedMutationEnv),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.exportContainsOnlyOwnedRecords([
        {'accountId': 'acct_2'},
      ], 'acct_1'),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.noUnauthorizedSourceMutation(
        operation: 'recap',
        mutatedCollections: ['expenses'],
        allowedCollections: {'recaps'},
      ),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.invoiceEstimateDidNotMutateSources(
        outputType: 'invoice',
        sourceCollectionsTouched: ['inventory'],
      ),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.payloadContainsNoPrivateFields({
        'id': 'vehicle_1',
        'vin': '1HGCM82633A004352',
      }),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.conflictGeneratedWhenExpected(false),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
    expect(
      () => MaintainiacQaAssertions.regressionMatchedExpected(
        'confirmed',
        'needsReview',
        'QA-REG-0002',
      ),
      throwsA(isA<MaintainiacQaAssertionFailure>()),
    );
  });
}
