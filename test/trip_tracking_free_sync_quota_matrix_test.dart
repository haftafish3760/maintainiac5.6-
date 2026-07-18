import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/backup/cloud_backup_sync_attempt_store.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_free_sync_usage.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'free sync quota matrix reserves only six local attempts per window',
    () async {
      final store = CloudBackupSyncAttemptStore.memory();
      final now = DateTime.utc(2026, 7, 18, 9);
      final usage = TripTrackingFreeSyncUsage(
        attemptStore: store,
        durableScope: TripTrackingFreeSyncUsage.durableScopeForDevice(
          accountUid: 'driver_1',
          deviceId: 'device_1',
        ),
      );

      final decisions = <String>[];
      for (var index = 0; index < 8; index += 1) {
        final decision = await usage.reserveAuthorizedAttempt(
          networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
          wifiAvailable: true,
          mobileDataAvailable: true,
          nowUtc: now.add(Duration(minutes: index)),
        );
        decisions.add(decision.reasonCode);
      }

      expect(
        decisions.where((reason) => reason == 'sync_ready'),
        hasLength(HostedUsageLimits.freeUserSyncsPer24HourWindow),
      );
      expect(
        decisions.where((reason) => reason == 'free_sync_limit_reached'),
        hasLength(2),
      );
      expect(
        usage.usedInWindowAt(now.add(const Duration(minutes: 8))),
        HostedUsageLimits.freeUserSyncsPer24HourWindow,
      );
      expect(
        TripTrackingFreeSyncUsageSummaryValidation.fromSummary(
          usage.toSafeSummary(now),
        ).isRenderable,
        isTrue,
      );
    },
  );

  test('blocked preflight matrix does not consume free sync quota', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 18, 9);
    final usage = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: 'trip-dashboard-preflight-device',
    );
    final cases = [
      (
        policy: TripTrackingBackupNetworkPolicy.wifiOnly,
        wifi: false,
        mobile: true,
      ),
      (
        policy: TripTrackingBackupNetworkPolicy.mobileDataOnly,
        wifi: true,
        mobile: false,
      ),
      (
        policy: TripTrackingBackupNetworkPolicy.wifiOnly,
        wifi: null,
        mobile: true,
      ),
    ];

    for (final entry in cases) {
      final decision = await usage.reserveAuthorizedAttempt(
        networkPolicy: entry.policy,
        wifiAvailable: entry.wifi,
        mobileDataAvailable: entry.mobile,
        nowUtc: now,
      );
      expect(decision.mayAttemptSync, isFalse);
    }

    expect(usage.usedInWindowAt(now), 0);
    expect(
      usage.toSafeSummary(now)['failedPreflightConsumesFreeSync'],
      isFalse,
    );
    expect(usage.toSafeSummary(now)['blockedAttemptConsumesFreeSync'], isFalse);
  });

  test('quota scope isolates account and device ledgers', () async {
    final store = CloudBackupSyncAttemptStore.memory();
    final now = DateTime.utc(2026, 7, 18, 9);
    final driverOneDeviceOne = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: TripTrackingFreeSyncUsage.durableScopeForDevice(
        accountUid: 'driver_1',
        deviceId: 'device_1',
      ),
    );
    final driverOneDeviceTwo = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: TripTrackingFreeSyncUsage.durableScopeForDevice(
        accountUid: 'driver_1',
        deviceId: 'device_2',
      ),
    );
    final driverTwoDeviceOne = TripTrackingFreeSyncUsage(
      attemptStore: store,
      durableScope: TripTrackingFreeSyncUsage.durableScopeForDevice(
        accountUid: 'driver_2',
        deviceId: 'device_1',
      ),
    );

    await driverOneDeviceOne.recordAuthorizedAttempt(now);

    expect(driverOneDeviceOne.usedInWindowAt(now), 1);
    expect(driverOneDeviceTwo.usedInWindowAt(now), 0);
    expect(driverTwoDeviceOne.usedInWindowAt(now), 0);
    expect(
      driverOneDeviceOne.toSafeSummary(now)['quotaScopeIncludesDeviceId'],
      isTrue,
    );
    expect(
      driverOneDeviceOne.toSafeSummary(now)['quotaScopeIncludesAccountUid'],
      isTrue,
    );
    expect(
      driverOneDeviceOne.toSafeSummary(
        now,
      )['remoteCountersCanOverrideLocalUsage'],
      isFalse,
    );
  });
}
