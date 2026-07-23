import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'maintainiac_restore_callable_source.dart';
import 'maintainiac_restore_session_client.dart';

const _credentialPrefix = 'maintainiac_restore_credential_v1_';

abstract interface class MaintainiacSecureValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterMaintainiacSecureValueStore
    implements MaintainiacSecureValueStore {
  const FlutterMaintainiacSecureValueStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

abstract interface class MaintainiacRestoreCredentialStore {
  Future<void> save(
    String credentialId,
    MaintainiacIssuedRestoreAuthorization credential,
  );

  Future<MaintainiacIssuedRestoreAuthorization?> load(String credentialId);

  Future<void> delete(String credentialId);
}

class MaintainiacRestoreCredentialVault
    implements MaintainiacRestoreCredentialStore {
  const MaintainiacRestoreCredentialVault({
    MaintainiacSecureValueStore values =
        const FlutterMaintainiacSecureValueStore(),
  }) : _values = values;

  final MaintainiacSecureValueStore _values;
  static Future<void> _operationTail = Future<void>.value();

  @override
  Future<void> save(
    String credentialId,
    MaintainiacIssuedRestoreAuthorization credential,
  ) {
    return _serialize(() => _save(credentialId, credential));
  }

  Future<void> _save(
    String credentialId,
    MaintainiacIssuedRestoreAuthorization credential,
  ) async {
    final key = _key(credentialId);
    credential.authorization.validate();
    if (!credential.expiresAtUtc.isUtc ||
        credential.recordCount < 0 ||
        credential.structuredBytes < 0 ||
        credential.manifestRevision < 0) {
      throw const FormatException('Restore credential is invalid.');
    }
    await _values.write(
      key,
      jsonEncode({
        'organizationId': credential.authorization.organizationId,
        'deviceId': credential.authorization.deviceId,
        'sessionId': credential.authorization.sessionId,
        'authorizationToken': credential.authorization.authorizationToken,
        'expiresAtUtc': credential.expiresAtUtc.toIso8601String(),
        'recordCount': credential.recordCount,
        'structuredBytes': credential.structuredBytes,
        'manifestRevision': credential.manifestRevision,
      }),
    );
  }

  @override
  Future<MaintainiacIssuedRestoreAuthorization?> load(String credentialId) {
    return _serialize(() => _load(credentialId));
  }

  Future<MaintainiacIssuedRestoreAuthorization?> _load(
    String credentialId,
  ) async {
    final encoded = await _values.read(_key(credentialId));
    if (encoded == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException {
      throw const FormatException('Stored restore credential is corrupt.');
    }
    if (decoded is! Map) {
      throw const FormatException('Stored restore credential is corrupt.');
    }
    final map = Map<String, Object?>.from(decoded);
    final authorization = MaintainiacRestoreAuthorization(
      organizationId: _requiredToken(map, 'organizationId'),
      deviceId: _requiredToken(map, 'deviceId'),
      sessionId: _requiredToken(map, 'sessionId'),
      authorizationToken: _requiredSha(map, 'authorizationToken'),
    );
    final expiresAt = DateTime.tryParse(map['expiresAtUtc']?.toString() ?? '');
    if (expiresAt == null) {
      throw const FormatException('Stored restore credential is corrupt.');
    }
    return MaintainiacIssuedRestoreAuthorization(
      authorization: authorization,
      expiresAtUtc: expiresAt.toUtc(),
      recordCount: _requiredNonNegativeInt(map, 'recordCount'),
      structuredBytes: _requiredNonNegativeInt(map, 'structuredBytes'),
      manifestRevision: _requiredNonNegativeInt(map, 'manifestRevision'),
    );
  }

  @override
  Future<void> delete(String credentialId) {
    return _serialize(() => _values.delete(_key(credentialId)));
  }

  static Future<T> _serialize<T>(Future<T> Function() operation) async {
    final previous = _operationTail;
    final release = Completer<void>();
    _operationTail = release.future;
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
    }
  }
}

String _key(String credentialId) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(credentialId)) {
    throw const FormatException('Restore credential identifier is invalid.');
  }
  return '$_credentialPrefix$credentialId';
}

String _requiredToken(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || !RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value)) {
    throw const FormatException('Stored restore credential is corrupt.');
  }
  return value;
}

String _requiredSha(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const FormatException('Stored restore credential is corrupt.');
  }
  return value;
}

int _requiredNonNegativeInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int || value < 0) {
    throw const FormatException('Stored restore credential is corrupt.');
  }
  return value;
}
