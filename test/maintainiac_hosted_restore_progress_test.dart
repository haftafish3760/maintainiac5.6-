import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  final now = DateTime.utc(2026, 7, 22, 12);

  test(
    'restore credential round trips only through the secure vault',
    () async {
      final values = _SecureValues();
      final vault = MaintainiacRestoreCredentialVault(values: values);
      final issued = _issued(now);

      await vault.save('credential-a', issued);
      final restored = await vault.load('credential-a');

      expect(restored?.authorization.authorizationToken, _token);
      expect(restored?.recordCount, 2);
      expect(values.values.keys.single, contains('credential-a'));
      await vault.delete('credential-a');
      expect(await vault.load('credential-a'), isNull);
    },
  );

  test('credential save and later delete cannot race out of order', () async {
    final values = _BlockingSecureValues();
    final vault = MaintainiacRestoreCredentialVault(values: values);

    final save = vault.save('credential-a', _issued(now));
    await values.writeStarted.future;
    final delete = vault.delete('credential-a');
    values.releaseWrite.complete();
    await Future.wait([save, delete]);

    expect(await vault.load('credential-a'), isNull);
  });

  test(
    'hosted progress is reconciled and terminal credential is removed',
    () async {
      final values = _SecureValues();
      final vault = MaintainiacRestoreCredentialVault(values: values);
      await vault.save('credential-a', _issued(now));
      final functions = _Functions();
      final progress = MaintainiacHostedRestoreProgress(
        client: MaintainiacRestoreSessionClient(functions),
        credentials: vault,
        nowUtc: () => now,
      );

      await progress.reconcile(
        _session(MaintainiacRestoreSessionState.running),
      );
      await progress.reconcile(
        _session(
          MaintainiacRestoreSessionState.completed,
          completedItems: 2,
          completedBytes: 200,
        ),
      );

      expect(functions.names, [
        'beginRestoreSession',
        'updateRestoreSession',
        'updateRestoreSession',
      ]);
      expect(functions.lastAction, 'complete');
      expect(await vault.load('credential-a'), isNull);
    },
  );

  test('expired credential rotates securely before hosted progress', () async {
    final values = _SecureValues();
    final vault = MaintainiacRestoreCredentialVault(values: values);
    await vault.save(
      'credential-a',
      _issued(now, expiresAt: now.subtract(const Duration(seconds: 1))),
    );
    final functions = _Functions();
    final progress = MaintainiacHostedRestoreProgress(
      client: MaintainiacRestoreSessionClient(functions),
      credentials: vault,
      nowUtc: () => now,
    );

    await progress.reconcile(_session(MaintainiacRestoreSessionState.running));
    expect(functions.names.first, 'refreshRestoreAuthorization');
    expect(
      (await vault.load('credential-a'))?.authorization.authorizationToken,
      _rotatedToken,
    );
  });

  test('concurrent recovery callbacks rotate an expired token once', () async {
    final values = _SecureValues();
    final vault = MaintainiacRestoreCredentialVault(values: values);
    await vault.save(
      'credential-a',
      _issued(now, expiresAt: now.subtract(const Duration(seconds: 1))),
    );
    final functions = _Functions();
    final progress = MaintainiacHostedRestoreProgress(
      client: MaintainiacRestoreSessionClient(functions),
      credentials: vault,
      nowUtc: () => now,
    );

    await Future.wait([
      progress.reconcile(_session(MaintainiacRestoreSessionState.running)),
      progress.reconcile(_session(MaintainiacRestoreSessionState.running)),
    ]);

    expect(
      functions.names.where((name) => name == 'refreshRestoreAuthorization'),
      hasLength(1),
    );
  });

  test(
    'unexpected hosted lifecycle response keeps recovery credential',
    () async {
      final values = _SecureValues();
      final vault = MaintainiacRestoreCredentialVault(values: values);
      await vault.save('credential-a', _issued(now));
      final progress = MaintainiacHostedRestoreProgress(
        client: MaintainiacRestoreSessionClient(
          _Functions(forceStatus: 'paused'),
        ),
        credentials: vault,
        nowUtc: () => now,
      );

      await expectLater(
        progress.reconcile(_session(MaintainiacRestoreSessionState.running)),
        throwsStateError,
      );
      expect(await vault.load('credential-a'), isNotNull);
    },
  );
}

const _token =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _rotatedToken =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

MaintainiacIssuedRestoreAuthorization _issued(
  DateTime now, {
  DateTime? expiresAt,
}) => MaintainiacIssuedRestoreAuthorization(
  authorization: const MaintainiacRestoreAuthorization(
    organizationId: 'org-a',
    deviceId: 'device-a',
    sessionId: 'server-session-a',
    authorizationToken: _token,
  ),
  expiresAtUtc: expiresAt ?? now.add(const Duration(hours: 1)),
  recordCount: 2,
  structuredBytes: 200,
  manifestRevision: 1,
);

MaintainiacRestoreSession _session(
  MaintainiacRestoreSessionState state, {
  int completedItems = 0,
  int completedBytes = 0,
}) => MaintainiacRestoreSession(
  id: 'local-session-a',
  accountScopeId: 'org-a.user-a',
  deviceId: 'device-a',
  authorizationId: 'credential-a',
  mode: MaintainiacRestoreMode.recordsOnly,
  state: state,
  storagePlan: const MaintainiacRestoreStoragePlan(
    structuredBytes: 200,
    thumbnailBytes: 0,
    proofBytes: 0,
    temporaryBytes: 0,
    availableBytes: 1000,
  ),
  totalItems: 2,
  completedItems: completedItems,
  completedBytes: completedBytes,
  createdAtUtc: DateTime.utc(2026, 7, 22),
  updatedAtUtc: DateTime.utc(2026, 7, 22),
  revision: 1,
);

class _SecureValues implements MaintainiacSecureValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _BlockingSecureValues extends _SecureValues {
  final writeStarted = Completer<void>();
  final releaseWrite = Completer<void>();

  @override
  Future<void> write(String key, String value) async {
    writeStarted.complete();
    await releaseWrite.future;
    await super.write(key, value);
  }
}

class _Functions implements MaintainiacCallableFunctionClient {
  _Functions({this.forceStatus});

  final String? forceStatus;
  final names = <String>[];
  int completedItems = 0;
  int completedBytes = 0;
  String? lastAction;

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    names.add(name);
    if (name == 'refreshRestoreAuthorization') {
      return {
        'sessionId': 'server-session-a',
        'authorizationToken': _rotatedToken,
        'expiresAt': '2026-07-22T13:00:00.000Z',
        'recordCount': 2,
        'structuredBytes': 200,
        'manifestRevision': 1,
      };
    }
    if (name == 'updateRestoreSession') {
      completedItems = data['completedItems']! as int;
      completedBytes = data['completedBytes']! as int;
      lastAction = data['action']! as String;
    }
    final status =
        forceStatus ??
        switch (lastAction) {
          'pause' => 'paused',
          'cancel' => 'cancelled',
          'complete' => 'completed',
          _ => 'active',
        };
    return {
      'sessionId': 'server-session-a',
      'status': status,
      'completedItems': completedItems,
      'completedBytes': completedBytes,
      'expiresAt': '2026-07-22T13:00:00.000Z',
    };
  }
}
