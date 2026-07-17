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
  });

  test('malformed free sync counter fails closed', () {
    final decision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: TripTrackingBackupNetworkPolicy.wifiAndMobileData,
      wifiAvailable: true,
      mobileDataAvailable: true,
      syncsUsedInWindow: -1,
    );

    expect(decision.mayAttemptSync, isFalse);
    expect(decision.reasonCode, 'free_sync_limit_invalid');
    expect(decision.userFacingReason, contains('could not be verified'));
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
}
