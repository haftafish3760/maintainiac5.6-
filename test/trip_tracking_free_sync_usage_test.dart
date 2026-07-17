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
}
