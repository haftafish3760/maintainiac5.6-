import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test('portable nested payloads are deeply immutable', () {
    final line = <String, dynamic>{'amount': 12.5};
    final payload = MaintainiacDurablePayload.freeze({
      'merchant': 'HDWR',
      'line': line,
      'tags': <String>['work'],
      'capturedAt': DateTime.utc(2026, 7, 22),
    });

    line['amount'] = 99;

    expect((payload['line'] as Map)['amount'], 12.5);
    expect(
      () => (payload['line'] as Map)['amount'] = 20,
      throwsUnsupportedError,
    );
    expect(
      () => (payload['tags'] as List).add('other'),
      throwsUnsupportedError,
    );
  });

  test(
    'cycles and unsupported values fail before replacing local truth',
    () async {
      final records = MaintainiacDurableRecordStore.memory();
      await records.save(
        module: 'settings',
        id: 'account',
        payload: const {'theme': 'dark'},
      );
      final cyclic = <String, dynamic>{};
      cyclic['self'] = cyclic;

      await expectLater(
        records.save(module: 'settings', id: 'account', payload: cyclic),
        throwsArgumentError,
      );
      await expectLater(
        records.save(
          module: 'settings',
          id: 'account',
          payload: {'unsupported': Object()},
        ),
        throwsArgumentError,
      );

      expect(
        records.recordFor('settings', 'account')?.payload['theme'],
        'dark',
      );
      expect(records.recordFor('settings', 'account')?.lifecycle.revision, 1);
    },
  );

  test('drafts reject non-text nested keys and non-finite numbers', () async {
    final drafts = MaintainiacRecordDraftStore.memory();

    await expectLater(
      drafts.save(
        module: 'invoices',
        id: 'invoice-1',
        payload: {
          'line': <Object?, Object?>{1: 'invalid'},
        },
      ),
      throwsArgumentError,
    );
    await expectLater(
      drafts.save(
        module: 'invoices',
        id: 'invoice-1',
        payload: {'amount': double.nan},
      ),
      throwsArgumentError,
    );

    expect(drafts.draftFor('invoices', 'invoice-1'), isNull);
  });

  test('recovery rejects unsafe stored payloads as corruption', () {
    final cyclic = <String, dynamic>{};
    cyclic['self'] = cyclic;
    final lifecycle = {
      'createdAt': '2026-07-22T00:00:00.000Z',
      'updatedAt': '2026-07-22T00:00:00.000Z',
      'revision': 1,
      'state': 'active',
      'deletedAt': null,
      'auditEvents': const <String>[],
    };

    expect(
      () => MaintainiacDurableRecord.fromMap({
        'module': 'settings',
        'id': 'account',
        'payload': cyclic,
        'lifecycle': lifecycle,
      }),
      throwsFormatException,
    );
    expect(
      () => MaintainiacRecordDraft.fromMap({
        'module': 'settings',
        'id': 'account',
        'payload': cyclic,
        'lifecycle': lifecycle,
      }),
      throwsFormatException,
    );
  });

  test('record recovery rejects malformed lifecycle metadata', () {
    Map<String, Object?> recordWith(Map<String, Object?> lifecycle) => {
      'module': 'settings',
      'id': 'account',
      'payload': const <String, Object?>{},
      'lifecycle': lifecycle,
    };
    final valid = <String, Object?>{
      'createdAt': '2026-07-22T00:00:00.000Z',
      'updatedAt': '2026-07-22T00:00:00.000Z',
      'revision': 1,
      'state': 'active',
      'deletedAt': null,
      'auditEvents': const <String>[],
    };

    expect(
      () => MaintainiacDurableRecord.fromMap(
        recordWith({...valid, 'state': 'mystery'}),
      ),
      throwsFormatException,
    );
    expect(
      () => MaintainiacDurableRecord.fromMap(
        recordWith({...valid, 'revision': '1'}),
      ),
      throwsFormatException,
    );
    expect(
      () => MaintainiacDurableRecord.fromMap(
        recordWith({
          ...valid,
          'auditEvents': <Object?>['created', 2],
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => MaintainiacDurableRecord.fromMap(
        recordWith({...valid, 'createdAt': '2026-07-23T00:00:00.000Z'}),
      ),
      throwsFormatException,
    );
  });
}
