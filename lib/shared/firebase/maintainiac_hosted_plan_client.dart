import '../backup/cloud_backup_quota.dart';
import 'maintainiac_callable_functions.dart';
import 'maintainiac_cloud_identity.dart';

class MaintainiacHostedPlanClient {
  const MaintainiacHostedPlanClient({
    required MaintainiacCallableFunctionClient functions,
    required MaintainiacCloudIdentityProvider identity,
  }) : _functions = functions,
       _identity = identity;

  final MaintainiacCallableFunctionClient _functions;
  final MaintainiacCloudIdentityProvider _identity;

  Future<CloudBackupEntitlement> loadEntitlement() async {
    _requireUid();
    final payload = await _functions.call(
      name: 'getHostedUsageGrant',
      data: const {},
    );
    final entitlement = CloudBackupEntitlement.tryParseServerPayload(payload);
    if (entitlement == null) {
      throw const FormatException('Hosted backup entitlement is invalid.');
    }
    return entitlement;
  }

  Future<MaintainiacHostedSyncReservation> reserveSync({
    required String attemptId,
    required String batchSha256,
    required int batchBytes,
  }) async {
    _requireUid();
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(attemptId)) {
      throw ArgumentError.value(attemptId, 'attemptId');
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(batchSha256)) {
      throw ArgumentError.value(batchSha256, 'batchSha256');
    }
    if (batchBytes < 1 || batchBytes > 64 * 1024 * 1024) {
      throw ArgumentError.value(batchBytes, 'batchBytes');
    }
    final payload = await _functions.call(
      name: 'reserveHostedSync',
      data: {
        'attemptId': attemptId,
        'batchSha256': batchSha256,
        'batchBytes': batchBytes,
      },
    );
    return MaintainiacHostedSyncReservation.fromServer(payload);
  }

  String _requireUid() {
    final uid = _identity.currentUid?.trim() ?? '';
    if (uid.isEmpty) throw StateError('Sign in before using cloud backup.');
    return uid;
  }
}

class MaintainiacHostedSyncReservation {
  const MaintainiacHostedSyncReservation({
    required this.id,
    required this.used,
    required this.remaining,
    required this.limit,
    required this.window,
    required this.reservedAtUtc,
  });

  factory MaintainiacHostedSyncReservation.fromServer(
    Map<Object?, Object?> payload,
  ) {
    final id = payload['reservationId'];
    final used = payload['used'];
    final remaining = payload['remaining'];
    final limit = payload['limit'];
    final seconds = payload['windowSeconds'];
    final reservedAt = DateTime.tryParse(
      payload['reservedAt']?.toString() ?? '',
    );
    final expectedRemaining = used is int && limit is int
        ? (used >= limit ? 0 : limit - used)
        : null;
    if (id is! String ||
        !RegExp(r'^[A-Za-z0-9-]{1,160}$').hasMatch(id) ||
        used is! int ||
        remaining is! int ||
        limit is! int ||
        used < 1 ||
        used > 100 ||
        remaining < 0 ||
        limit < 1 ||
        limit > 100 ||
        remaining != expectedRemaining ||
        seconds is! int ||
        seconds != const Duration(hours: 24).inSeconds ||
        reservedAt == null) {
      throw const FormatException('Hosted sync reservation is invalid.');
    }
    return MaintainiacHostedSyncReservation(
      id: id,
      used: used,
      remaining: remaining,
      limit: limit,
      window: Duration(seconds: seconds),
      reservedAtUtc: reservedAt.toUtc(),
    );
  }

  final String id;
  final int used;
  final int remaining;
  final int limit;
  final Duration window;
  final DateTime reservedAtUtc;
}
