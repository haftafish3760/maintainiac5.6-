import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/durable_storage/maintainiac_durable_storage.dart';

void main() {
  test(
    'client accepts only complete server plan and reservation payloads',
    () async {
      final functions = _Functions({
        'getHostedUsageGrant': {
          'planId': 'free_configurable',
          'displayName': 'Free',
          'storageQuotaBytes': 100 * 1024 * 1024,
          'dailySyncLimit': 4,
          'immediateSyncAllowed': false,
          'policyVersion': 3,
          'downloadAllowanceBytes': 25 * 1024 * 1024,
        },
        'reserveHostedSync': {
          'reservationId': 'reservation-1',
          'used': 1,
          'remaining': 3,
          'limit': 4,
          'windowSeconds': const Duration(hours: 24).inSeconds,
          'reservedAt': DateTime.utc(2026, 7, 22).toIso8601String(),
        },
      });
      final client = MaintainiacHostedPlanClient(
        functions: functions,
        identity: const _Identity('userA'),
      );
      final entitlement = await client.loadEntitlement();
      final reservation = await client.reserveSync(
        attemptId: 'attempt-1',
        batchSha256: 'a' * 64,
        batchBytes: 2048,
      );
      expect(entitlement.dailySyncLimit, 4);
      expect(entitlement.quotaBytes, 100 * 1024 * 1024);
      expect(reservation.remaining, 3);
      expect(functions.calls, ['getHostedUsageGrant', 'reserveHostedSync']);
      expect(functions.payloads.last, {
        'attemptId': 'attempt-1',
        'batchSha256': 'a' * 64,
        'batchBytes': 2048,
      });
    },
  );

  test(
    'client fails closed without authentication or complete server data',
    () async {
      final signedOut = MaintainiacHostedPlanClient(
        functions: _Functions(const {}),
        identity: const _Identity(null),
      );
      await expectLater(signedOut.loadEntitlement(), throwsStateError);

      final malformed = MaintainiacHostedPlanClient(
        functions: _Functions({
          'getHostedUsageGrant': {'planId': 'free'},
          'reserveHostedSync': {
            'reservationId': 'reservation-1',
            'used': 4,
            'remaining': 4,
            'limit': 4,
            'windowSeconds': 1,
            'reservedAt': 'bad-date',
          },
        }),
        identity: const _Identity('userA'),
      );
      await expectLater(malformed.loadEntitlement(), throwsFormatException);
      await expectLater(
        malformed.reserveSync(
          attemptId: 'attempt-1',
          batchSha256: 'a' * 64,
          batchBytes: 2048,
        ),
        throwsFormatException,
      );
      await expectLater(
        malformed.reserveSync(
          attemptId: 'bad/attempt',
          batchSha256: 'a' * 64,
          batchBytes: 2048,
        ),
        throwsArgumentError,
      );
      await expectLater(
        malformed.reserveSync(
          attemptId: 'attempt-1',
          batchSha256: 'bad-hash',
          batchBytes: 2048,
        ),
        throwsArgumentError,
      );
      await expectLater(
        malformed.reserveSync(
          attemptId: 'attempt-1',
          batchSha256: 'a' * 64,
          batchBytes: 0,
        ),
        throwsArgumentError,
      );
    },
  );
}

class _Identity implements MaintainiacCloudIdentityProvider {
  const _Identity(this.currentUid);

  @override
  final String? currentUid;
}

class _Functions implements MaintainiacCallableFunctionClient {
  _Functions(this.responses);

  final Map<String, Map<String, Object?>> responses;
  final List<String> calls = [];
  final List<Map<String, Object?>> payloads = [];

  @override
  Future<Map<String, Object?>> call({
    required String name,
    required Map<String, Object?> data,
  }) async {
    calls.add(name);
    payloads.add(Map.unmodifiable(data));
    final response = responses[name];
    if (response == null) throw StateError('No response for $name.');
    return response;
  }
}
