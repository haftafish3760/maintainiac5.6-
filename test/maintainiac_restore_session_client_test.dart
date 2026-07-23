import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  const token =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('issue binds plan totals to the server authorization', () async {
    final functions = _Functions({
      'issueRestoreAuthorization': {
        'sessionId': 'session-a',
        'authorizationToken': token,
        'expiresAt': '2026-07-23T00:00:00.000Z',
        'recordCount': 12,
        'structuredBytes': 4096,
        'manifestRevision': 3,
      },
    });
    final issued = await MaintainiacRestoreSessionClient(
      functions,
    ).issue(organizationId: 'org-a', deviceId: 'device-a', mode: 'recordsOnly');

    expect(issued.recordCount, 12);
    expect(issued.structuredBytes, 4096);
    expect(issued.authorization.sessionId, 'session-a');
    expect(issued.authorization.authorizationToken, token);
  });

  test('begin and progress always carry the server credential', () async {
    final functions = _Functions({
      'beginRestoreSession': _session('active', 0, 0),
      'updateRestoreSession': _session('active', 2, 100),
    });
    final client = MaintainiacRestoreSessionClient(functions);
    const authorization = MaintainiacRestoreAuthorization(
      organizationId: 'org-a',
      deviceId: 'device-a',
      sessionId: 'session-a',
      authorizationToken: token,
    );

    await client.begin(authorization);
    final progress = await client.update(
      authorization: authorization,
      action: MaintainiacHostedRestoreAction.progress,
      completedItems: 2,
      completedBytes: 100,
    );

    expect(progress.completedItems, 2);
    expect(functions.lastData?['authorizationToken'], token);
    expect(functions.lastData?['action'], 'progress');
  });

  test('malformed hosted session response fails closed', () async {
    final client = MaintainiacRestoreSessionClient(
      _Functions({'beginRestoreSession': _session('active', -1, 0)}),
    );

    await expectLater(
      client.begin(
        const MaintainiacRestoreAuthorization(
          organizationId: 'org-a',
          deviceId: 'device-a',
          sessionId: 'session-a',
          authorizationToken: token,
        ),
      ),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _session(String status, int items, int bytes) => {
  'sessionId': 'session-a',
  'status': status,
  'completedItems': items,
  'completedBytes': bytes,
  'expiresAt': '2026-07-23T00:00:00.000Z',
};

class _Functions implements MaintainiacCallableFunctionClient {
  _Functions(this.responses);

  final Map<String, Map<String, Object?>> responses;
  Map<String, Object?>? lastData;

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    lastData = data;
    return responses[name] ?? const {};
  }
}
