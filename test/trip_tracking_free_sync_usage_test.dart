import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/backup/cloud_backup_sync_attempt_store.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_free_sync_usage.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('bridges cloud attempt ledger into trip sync usage safely', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 17, 12);
    final usage = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: 'trip-dashboard-user-device',
    );

    await usage.recordAuthorizedAttempt(now.subtract(const Duration(hours: 2)));
    await usage.recordAuthorizedAttempt(now.subtract(const Duration(hours: 1)));

    expect(usage.usedInWindowAt(now), 2);
    expect(
      usage
          .evaluate(
            networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
            wifiAvailable: true,
            mobileDataAvailable: false,
            nowUtc: now,
          )
          .freeSyncsRemaining,
      HostedUsageLimits.freeUserSyncsPer24HourWindow - 2,
    );
  });

  test(
    'reader and recorder callbacks are safe for upload coordinators',
    () async {
      final store = CloudBackupSyncAttemptStore.memory();
      final now = DateTime.utc(2026, 7, 17, 12);
      final usage = TripTrackingFreeSyncUsage(
        attemptStore: store,
        durableScope: 'trip-dashboard-upload-device',
      );
      final reader = usage.reader(nowUtc: () => now);
      final recorder = usage.recorder();

      expect(reader(), 0);

      await recorder(now);
      await recorder(now.add(const Duration(minutes: 30)));

      expect(reader(), 2);
    },
  );

  test('usage resets after the rolling local 24-hour window', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final first = DateTime.utc(2026, 7, 17, 12);
    final usage = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: 'trip-dashboard-window-device',
    );

    await usage.recordAuthorizedAttempt(first);

    expect(
      usage.usedInWindowAt(first.add(const Duration(hours: 23, minutes: 59))),
      1,
    );
    expect(
      usage.usedInWindowAt(first.add(const Duration(hours: 24, minutes: 1))),
      0,
    );
  });

  test(
    'unsafe durable scopes fail closed through the shared attempt store',
    () async {
      final usage = TripTrackingFreeSyncUsage(
        attemptStore: CloudBackupSyncAttemptStore.memory(),
        durableScope: 'bad:scope',
      );

      expect(
        () => usage.usedInWindowAt(DateTime.utc(2026, 7, 17, 12)),
        throwsArgumentError,
      );
      await expectLater(
        usage.recordAuthorizedAttempt(DateTime.utc(2026, 7, 17, 12)),
        throwsArgumentError,
      );
    },
  );

  test('authorized reservation records exactly one local attempt', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 17, 12);
    final usage = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: 'trip-dashboard-reserve-device',
    );

    final decision = await usage.reserveAuthorizedAttempt(
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      wifiAvailable: true,
      mobileDataAvailable: false,
      nowUtc: now,
    );

    expect(decision.mayAttemptSync, isTrue);
    expect(decision.reasonCode, 'sync_ready');
    expect(usage.usedInWindowAt(now), 1);
  });

  test('blocked reservation never consumes a free sync', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 17, 12);
    final usage = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: 'trip-dashboard-blocked-device',
    );

    final decision = await usage.reserveAuthorizedAttempt(
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      wifiAvailable: false,
      mobileDataAvailable: true,
      nowUtc: now,
    );

    expect(decision.mayAttemptSync, isFalse);
    expect(decision.reasonCode, 'network_policy_blocked');
    expect(usage.usedInWindowAt(now), 0);
  });

  test(
    'reservation refuses the seventh free sync in a rolling window',
    () async {
      final store = CloudBackupSyncAttemptStore.memory();
      final now = DateTime.utc(2026, 7, 17, 12);
      final usage = TripTrackingFreeSyncUsage(
        attemptStore: store,
        durableScope: 'trip-dashboard-limit-device',
      );

      for (
        var index = 0;
        index < HostedUsageLimits.freeUserSyncsPer24HourWindow;
        index += 1
      ) {
        final decision = await usage.reserveAuthorizedAttempt(
          networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
          wifiAvailable: true,
          mobileDataAvailable: true,
          nowUtc: now.add(Duration(minutes: index)),
        );
        expect(decision.mayAttemptSync, isTrue);
      }

      final denied = await usage.reserveAuthorizedAttempt(
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
        wifiAvailable: true,
        mobileDataAvailable: true,
        nowUtc: now.add(const Duration(hours: 1)),
      );

      expect(denied.mayAttemptSync, isFalse);
      expect(denied.reasonCode, 'free_sync_limit_reached');
      expect(
        usage.usedInWindowAt(now.add(const Duration(hours: 1))),
        HostedUsageLimits.freeUserSyncsPer24HourWindow,
      );
    },
  );
}
