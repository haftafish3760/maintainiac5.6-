import 'maintainiac_callable_functions.dart';
import 'maintainiac_restore_callable_source.dart';

enum MaintainiacHostedRestoreAction { progress, pause, cancel, complete }

class MaintainiacIssuedRestoreAuthorization {
  const MaintainiacIssuedRestoreAuthorization({
    required this.authorization,
    required this.expiresAtUtc,
    required this.recordCount,
    required this.structuredBytes,
    required this.manifestRevision,
  });

  final MaintainiacRestoreAuthorization authorization;
  final DateTime expiresAtUtc;
  final int recordCount;
  final int structuredBytes;
  final int manifestRevision;
}

class MaintainiacHostedRestoreSession {
  const MaintainiacHostedRestoreSession({
    required this.sessionId,
    required this.status,
    required this.completedItems,
    required this.completedBytes,
    required this.expiresAtUtc,
  });

  final String sessionId;
  final String status;
  final int completedItems;
  final int completedBytes;
  final DateTime expiresAtUtc;
}

class MaintainiacRestoreSessionClient {
  const MaintainiacRestoreSessionClient(this._functions);

  final MaintainiacCallableFunctionClient _functions;

  Future<void> registerDevice({
    required String deviceId,
    required String installationIdHash,
    required String platform,
    required String appVersion,
  }) async {
    await _functions.call(
      name: 'registerRestoreDevice',
      data: {
        'deviceId': deviceId,
        'installationIdHash': installationIdHash,
        'platform': platform,
        'appVersion': appVersion,
      },
    );
  }

  Future<MaintainiacIssuedRestoreAuthorization> issue({
    required String organizationId,
    required String deviceId,
    required String mode,
    required String requestId,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(requestId)) {
      throw ArgumentError.value(requestId, 'requestId');
    }
    final result = await _functions.call(
      name: 'issueRestoreAuthorization',
      data: {
        'organizationId': organizationId,
        'deviceId': deviceId,
        'mode': mode,
        'requestId': requestId,
      },
    );
    return _issued(result, organizationId, deviceId);
  }

  Future<MaintainiacIssuedRestoreAuthorization> refresh(
    MaintainiacRestoreAuthorization authorization,
  ) async {
    authorization.validate();
    final result = await _functions.call(
      name: 'refreshRestoreAuthorization',
      data: {
        'organizationId': authorization.organizationId,
        'deviceId': authorization.deviceId,
        'sessionId': authorization.sessionId,
      },
    );
    return _issued(
      result,
      authorization.organizationId,
      authorization.deviceId,
    );
  }

  MaintainiacIssuedRestoreAuthorization _issued(
    Map<String, Object?> result,
    String organizationId,
    String deviceId,
  ) {
    final sessionId = _requiredToken(result, 'sessionId');
    final token = _requiredSha(result, 'authorizationToken');
    final expiresAt = _requiredDate(result, 'expiresAt');
    return MaintainiacIssuedRestoreAuthorization(
      authorization: MaintainiacRestoreAuthorization(
        organizationId: organizationId,
        deviceId: deviceId,
        sessionId: sessionId,
        authorizationToken: token,
      ),
      expiresAtUtc: expiresAt,
      recordCount: _nonNegativeInt(result, 'recordCount'),
      structuredBytes: _nonNegativeInt(result, 'structuredBytes'),
      manifestRevision: _nonNegativeInt(result, 'manifestRevision'),
    );
  }

  Future<MaintainiacHostedRestoreSession> begin(
    MaintainiacRestoreAuthorization authorization,
  ) => _sessionCall('beginRestoreSession', authorization, const {});

  Future<MaintainiacHostedRestoreSession> update({
    required MaintainiacRestoreAuthorization authorization,
    required MaintainiacHostedRestoreAction action,
    required int completedItems,
    required int completedBytes,
  }) {
    if (completedItems < 0 || completedBytes < 0) {
      throw ArgumentError('Restore progress cannot be negative.');
    }
    return _sessionCall('updateRestoreSession', authorization, {
      'action': action.name,
      'completedItems': completedItems,
      'completedBytes': completedBytes,
    });
  }

  Future<MaintainiacHostedRestoreSession> _sessionCall(
    String name,
    MaintainiacRestoreAuthorization authorization,
    Map<String, Object?> extra,
  ) async {
    authorization.validate();
    final result = await _functions.call(
      name: name,
      data: {
        'organizationId': authorization.organizationId,
        'deviceId': authorization.deviceId,
        'sessionId': authorization.sessionId,
        'authorizationToken': authorization.authorizationToken,
        ...extra,
      },
    );
    return MaintainiacHostedRestoreSession(
      sessionId: _requiredToken(result, 'sessionId'),
      status: _requiredStatus(result),
      completedItems: _nonNegativeInt(result, 'completedItems'),
      completedBytes: _nonNegativeInt(result, 'completedBytes'),
      expiresAtUtc: _requiredDate(result, 'expiresAt'),
    );
  }
}

String _requiredStatus(Map<String, Object?> map) {
  final value = _requiredToken(map, 'status');
  if (!const {
    'authorized',
    'active',
    'paused',
    'cancelled',
    'completed',
  }.contains(value)) {
    throw const FormatException('Restore response is malformed.');
  }
  return value;
}

String _requiredToken(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || !RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value)) {
    throw const FormatException('Restore response is malformed.');
  }
  return value;
}

String _requiredSha(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw const FormatException('Restore response is malformed.');
  }
  return value;
}

int _nonNegativeInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int || value < 0) {
    throw const FormatException('Restore response is malformed.');
  }
  return value;
}

DateTime _requiredDate(Map<String, Object?> map, String key) {
  final parsed = DateTime.tryParse(map[key]?.toString() ?? '');
  if (parsed == null) {
    throw const FormatException('Restore response is malformed.');
  }
  return parsed.toUtc();
}
