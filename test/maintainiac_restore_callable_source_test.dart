import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  const authorization = MaintainiacRestoreAuthorization(
    organizationId: 'org-a',
    deviceId: 'device-a',
    sessionId: 'session-a',
    authorizationToken:
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );

  test(
    'callable source always sends the server-issued restore credential',
    () async {
      final functions = _Functions({
        'documents': [
          {
            'id': List.filled(64, 'b').join(),
            'data': {'schema': 'maintainiac_durable_record_v1'},
          },
        ],
      });
      final source = CallableMaintainiacDurableCloudRecordSource(
        functions: functions,
        authorization: authorization,
      );

      final page = await source.fetchPage(
        organizationId: 'org-a',
        uid: 'user-a',
        limit: 10,
      );

      expect(page, hasLength(1));
      expect(functions.name, 'fetchRestoreRecordPage');
      expect(functions.data?['sessionId'], 'session-a');
      expect(
        functions.data?['authorizationToken'],
        authorization.authorizationToken,
      );
    },
  );

  test(
    'callable source rejects cross-organization and oversized requests',
    () async {
      final functions = _Functions(const {'documents': []});
      final source = CallableMaintainiacDurableCloudRecordSource(
        functions: functions,
        authorization: authorization,
      );

      await expectLater(
        source.fetchPage(organizationId: 'org-b', uid: 'user-a', limit: 1),
        throwsFormatException,
      );
      await expectLater(
        source.fetchPage(organizationId: 'org-a', uid: 'user-a', limit: 11),
        throwsFormatException,
      );
      expect(functions.calls, 0);
    },
  );

  test('callable source fails closed on malformed server data', () async {
    final source = CallableMaintainiacDurableCloudRecordSource(
      functions: _Functions(const {'documents': 'bad'}),
      authorization: authorization,
    );

    await expectLater(
      source.fetchPage(organizationId: 'org-a', uid: 'user-a', limit: 1),
      throwsFormatException,
    );
  });

  test('callable source rejects more documents than it requested', () async {
    final source = CallableMaintainiacDurableCloudRecordSource(
      functions: _Functions({
        'documents': List.generate(
          3,
          (index) => {
            'id': index.toRadixString(16).padLeft(64, '0'),
            'data': {'schema': 'maintainiac_durable_record_v1'},
          },
        ),
      }),
      authorization: authorization,
    );

    await expectLater(
      source.fetchPage(organizationId: 'org-a', uid: 'user-a', limit: 2),
      throwsFormatException,
    );
  });
}

class _Functions implements MaintainiacCallableFunctionClient {
  _Functions(this.response);

  final Map<String, Object?> response;
  int calls = 0;
  String? name;
  Map<String, Object?>? data;

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    calls += 1;
    this.name = name;
    this.data = data;
    return response;
  }
}
