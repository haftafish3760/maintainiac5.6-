import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_scope_policy.dart';

void main() {
  test('organization writes require matching path, data, and account', () {
    expect(
      () => MaintainiacFirestoreScopePolicy.validateWrite(
        path: 'orgs/orgA/expenses/expense1',
        data: const {'orgId': 'orgA', 'updatedByUid': 'userA'},
        authenticatedUid: 'userA',
      ),
      returnsNormally,
    );
  });

  test('account switch blocks a stale queued organization write', () {
    expect(
      () => MaintainiacFirestoreScopePolicy.validateWrite(
        path: 'orgs/orgA/expenses/expense1',
        data: const {'orgId': 'orgA', 'updatedByUid': 'userA'},
        authenticatedUid: 'userB',
      ),
      throwsA(isA<MaintainiacFirestoreScopeMismatch>()),
    );
  });

  test('organization path and payload cannot cross tenants', () {
    expect(
      () => MaintainiacFirestoreScopePolicy.validateWrite(
        path: 'orgs/orgB/expenses/expense1',
        data: const {'orgId': 'orgA', 'updatedByUid': 'userA'},
        authenticatedUid: 'userA',
      ),
      throwsA(isA<MaintainiacFirestoreScopeMismatch>()),
    );
  });

  test('non-organization operational health paths remain module neutral', () {
    expect(
      () => MaintainiacFirestoreScopePolicy.validateWrite(
        path: 'parserHealth/receipt_parser_v1',
        data: const {'schema': 'health_v1'},
        authenticatedUid: null,
      ),
      returnsNormally,
    );
  });
}
