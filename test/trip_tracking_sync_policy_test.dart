import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/firebase/hosted_usage_limits.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_sync_policy.dart';

void main() {
  test('free sync policy allows six sync attempts per 24 hour window', () {
    for (
      var used = 0;
      used < HostedUsageLimits.freeUserSyncsPer24HourWindow;
      used += 1
    ) {
      final decision = TripTrackingBackupSyncPolicy.evaluate(
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
        wifiAvailable: true,
        mobileDataAvailable: false,
        syncsUsedInWindow: used,
      );

      expect(decision.mayAttemptSync, isTrue, reason: 'used=$used');
      expect(
        decision.freeSyncsRemaining,
        HostedUsageLimits.freeUserSyncsPer24HourWindow - used,
      );
      expect(decision.reasonCode, 'sync_ready');
    }
  });

  test('free sync policy blocks the seventh free sync safely', () {
    final decision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      wifiAvailable: true,
      mobileDataAvailable: true,
      syncsUsedInWindow: HostedUsageLimits.freeUserSyncsPer24HourWindow,
    );

    expect(decision.mayAttemptSync, isFalse);
    expect(decision.freeSyncAllowed, isFalse);
    expect(decision.freeSyncsRemaining, 0);
    expect(decision.reasonCode, 'free_sync_limit_reached');
    expect(decision.userFacingReason, contains('24-hour window'));
    expect(decision.dashboardLabel, contains('0 free syncs left'));
    expect(decision.toSafeSummary(), {
      'schemaVersion': 1,
      'networkPolicy': 'wifiAndMobileData',
      'networkKnown': true,
      'networkAllowed': true,
      'freeSyncAllowed': false,
      'freeSyncsRemaining': 0,
      'mayAttemptSync': false,
      'reasonCode': 'free_sync_limit_reached',
      'label': 'Sync: Wi-Fi or mobile data; 0 free syncs left',
      'tokensIncluded': false,
      'locationDataIncluded': false,
      'rawModuleDataIncluded': false,
    });
  });

  test('malformed free sync counter fails closed', () {
    for (final used in const [-1, 1000]) {
      final decision = TripTrackingBackupSyncPolicy.evaluate(
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
        wifiAvailable: true,
        mobileDataAvailable: true,
        syncsUsedInWindow: used,
      );

      expect(decision.mayAttemptSync, isFalse);
      expect(decision.freeSyncAllowed, isFalse);
      expect(decision.freeSyncsRemaining, isNull);
      expect(decision.reasonCode, 'free_sync_limit_invalid');
      expect(decision.userFacingReason, contains('could not be verified'));
      expect(decision.dashboardLabel, contains('unverified'));
      expect(decision.toSafeSummary()['freeSyncsRemaining'], isNull);
    }
  });

  test('wifi only policy waits on mobile data', () {
    final decision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiOnly,
      wifiAvailable: false,
      mobileDataAvailable: true,
      syncsUsedInWindow: 0,
    );

    expect(decision.mayAttemptSync, isFalse);
    expect(decision.networkAllowed, isFalse);
    expect(decision.reasonCode, 'network_policy_blocked');
    expect(decision.dashboardLabel, contains('Wi-Fi only'));
  });

  test('mobile-data-only policy waits on wifi', () {
    final decision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: TripTrackingBackupNetworkPolicy.mobileDataOnly,
      wifiAvailable: true,
      mobileDataAvailable: false,
      syncsUsedInWindow: 1,
    );

    expect(decision.mayAttemptSync, isFalse);
    expect(decision.networkAllowed, isFalse);
    expect(decision.reasonCode, 'network_policy_blocked');
    expect(decision.dashboardLabel, contains('mobile data only'));
  });

  test('unknown network status does not authorize a sync attempt', () {
    final decision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      syncsUsedInWindow: 2,
    );

    expect(decision.networkKnown, isFalse);
    expect(decision.networkAllowed, isFalse);
    expect(decision.mayAttemptSync, isFalse);
    expect(decision.reasonCode, 'network_unknown');
    expect(decision.userFacingReason, contains('network status'));
  });

  test('known network still waits until free sync usage is verified', () {
    final decision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      wifiAvailable: true,
      mobileDataAvailable: true,
    );

    expect(decision.networkKnown, isTrue);
    expect(decision.networkAllowed, isTrue);
    expect(decision.freeSyncAllowed, isFalse);
    expect(decision.freeSyncsRemaining, isNull);
    expect(decision.mayAttemptSync, isFalse);
    expect(decision.reasonCode, 'free_sync_limit_unknown');
    expect(decision.dashboardLabel, contains('free sync usage pending'));
    expect(decision.userFacingReason, contains('being verified'));
  });

  test('free sync window counter keeps a rolling 24 hour usage window', () {
    final started = DateTime.utc(2026, 7, 17, 8);
    var counter = TripTrackingFreeSyncWindowCounter(
      windowStartedAtUtc: started,
      syncsUsed: 0,
    );

    counter = counter.recordAttempt(started.add(const Duration(hours: 1)));
    counter = counter.recordAttempt(started.add(const Duration(hours: 23)));

    expect(counter.windowStartedAtUtc, started);
    expect(counter.syncsUsed, 2);
    expect(counter.usedInWindowAt(started.add(const Duration(hours: 23))), 2);
    expect(counter.expiresAtUtc(), started.add(const Duration(hours: 24)));
    expect(
      counter.secondsUntilResetAt(started.add(const Duration(hours: 23))),
      3600,
    );
    expect(counter.toSafeSummary(started.add(const Duration(hours: 23))), {
      'schemaVersion': 1,
      'windowState': 'active',
      'syncsUsedInWindow': 2,
      'freeSyncsRemaining': 4,
      'secondsUntilReset': 3600,
      'windowHours': 24,
      'tokensIncluded': false,
      'locationDataIncluded': false,
      'rawModuleDataIncluded': false,
    });
    expect(counter.usedInWindowAt(started.add(const Duration(hours: 24))), 0);
  });

  test('free sync window counter resets after the 24 hour window', () {
    final started = DateTime.utc(2026, 7, 17, 8);
    final counter = TripTrackingFreeSyncWindowCounter(
      windowStartedAtUtc: started,
      syncsUsed: 6,
    ).recordAttempt(started.add(const Duration(hours: 24, minutes: 1)));

    expect(counter.syncsUsed, 1);
    expect(
      counter.windowStartedAtUtc,
      started.add(const Duration(hours: 24, minutes: 1)),
    );
    expect(counter.toSafeSummary(started.add(const Duration(hours: 25))), {
      'schemaVersion': 1,
      'windowState': 'active',
      'syncsUsedInWindow': 1,
      'freeSyncsRemaining': 5,
      'secondsUntilReset': 82860,
      'windowHours': 24,
      'tokensIncluded': false,
      'locationDataIncluded': false,
      'rawModuleDataIncluded': false,
    });
  });

  test('free sync window counter preserves invalid counters as unverified', () {
    final started = DateTime.utc(2026, 7, 17, 8);
    final counter = TripTrackingFreeSyncWindowCounter(
      windowStartedAtUtc: started,
      syncsUsed: -1,
    );

    expect(counter.usedInWindowAt(started.add(const Duration(hours: 1))), -1);
    expect(
      counter.recordAttempt(started.add(const Duration(hours: 2))).syncsUsed,
      -1,
    );
    expect(counter.toSafeSummary(started.add(const Duration(hours: 1))), {
      'schemaVersion': 1,
      'windowState': 'invalid',
      'syncsUsedInWindow': -1,
      'freeSyncsRemaining': null,
      'secondsUntilReset': 82800,
      'windowHours': 24,
      'tokensIncluded': false,
      'locationDataIncluded': false,
      'rawModuleDataIncluded': false,
    });
    expect(
      TripTrackingBackupSyncPolicy.evaluate(
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
        wifiAvailable: true,
        mobileDataAvailable: true,
        syncsUsedInWindow: counter.usedInWindowAt(
          started.add(const Duration(hours: 1)),
        ),
      ).reasonCode,
      'free_sync_limit_invalid',
    );
  });

  test('overrange free sync counters fail closed until the next window', () {
    final started = DateTime.utc(2026, 7, 17, 8);
    final counter = TripTrackingFreeSyncWindowCounter(
      windowStartedAtUtc: started,
      syncsUsed:
          TripTrackingBackupSyncPolicy.maximumVerifiableSyncsUsedInWindow + 1,
    );
    final sameWindow = started.add(const Duration(hours: 1));
    final nextWindow = started.add(const Duration(hours: 24, minutes: 1));

    expect(counter.usedInWindowAt(sameWindow), -1);
    expect(counter.recordAttempt(sameWindow).syncsUsed, -1);
    expect(counter.toSafeSummary(sameWindow)['windowState'], 'invalid');
    expect(counter.recordAttempt(nextWindow).syncsUsed, 1);
  });

  test('free sync window counter fails closed on device clock rollback', () {
    final started = DateTime.utc(2026, 7, 17, 8);
    final counter = TripTrackingFreeSyncWindowCounter(
      windowStartedAtUtc: started,
      syncsUsed: 2,
    );
    final rolledBack = started.subtract(const Duration(minutes: 5));

    expect(counter.usedInWindowAt(rolledBack), -1);
    expect(counter.recordAttempt(rolledBack).syncsUsed, -1);
    expect(counter.toSafeSummary(rolledBack), {
      'schemaVersion': 1,
      'windowState': 'invalid',
      'syncsUsedInWindow': -1,
      'freeSyncsRemaining': null,
      'secondsUntilReset': 86400,
      'windowHours': 24,
      'tokensIncluded': false,
      'locationDataIncluded': false,
      'rawModuleDataIncluded': false,
    });
    expect(
      TripTrackingBackupSyncPolicy.evaluate(
        networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
        wifiAvailable: true,
        mobileDataAvailable: true,
        syncsUsedInWindow: counter.usedInWindowAt(rolledBack),
      ).mayAttemptSync,
      isFalse,
    );
  });
}
