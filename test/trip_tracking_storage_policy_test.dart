import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/storage/app_storage_guard.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_storage_policy.dart';

void main() {
  const operationBytes = AppStorageGuard.mileageTrackingWriteBytes;
  const requiredBytes =
      AppStorageGuard.mileageTrackingWriteBytes +
      AppStorageGuard.textRecordDeviceReserveBytes;

  AppStorageCheck check(int? availableBytes, {bool canVerify = true}) {
    if (!canVerify) {
      return const AppStorageCheck.unknown(
        operationBytes: operationBytes,
        requiredBytes: requiredBytes,
        purpose: AppStoragePurpose.mileageTracking,
      );
    }
    return AppStorageCheck(
      availableBytes: availableBytes,
      operationBytes: operationBytes,
      requiredBytes: requiredBytes,
      purpose: AppStoragePurpose.mileageTracking,
    );
  }

  test('unknown storage continues text GPS records without deleting data', () {
    final decision = TripTrackingStoragePolicy.evaluate(
      check(null, canVerify: false),
    );

    expect(decision.action, TripTrackingStorageAction.unknown);
    expect(decision.storageState, 'unknown');
    expect(decision.canWriteTextRecord, isTrue);
    expect(decision.shouldBlockTextRecord, isFalse);
    expect(decision.message, contains('could not verify'));
    expect(decision.toSafeSummary(), containsPair('schemaVersion', 1));
    expect(
      decision.toSafeSummary(),
      containsPair('recordType', 'trip_text_record'),
    );
    expect(decision.toSafeSummary(), containsPair('canWriteTextRecord', true));
    expect(decision.toSafeSummary(), containsPair('textRecordReserveMb', 25));
    expect(
      decision.toSafeSummary(),
      containsPair('storagePolicyScope', 'gps_trip_text_records'),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('photosAndReceiptsHandledElsewhere', true),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('localWriteMode', 'append_only'),
    );
    expect(decision.toSafeSummary(), containsPair('deletesLocalData', false));
    expect(decision.toSafeSummary(), containsPair('purgesLocalData', false));
    expect(
      decision.toSafeSummary(),
      containsPair('canSilentlyDeleteLocalData', false),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('backupCanTriggerSilentLocalPurge', false),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('confirmedBackupCanOnlySuggestCleanup', true),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('userActionRequiredForCleanup', true),
    );
    expect(decision.toSafeSummary(), containsPair('cleanupSuggested', false));
    expect(
      decision.toSafeSummary(),
      containsPair('storageDataTrustedAfterValidationOnly', true),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('remoteStorageStateCanBlockLocalTripLog', false),
    );
  });

  test(
    'below text reserve blocks writes but never claims cleanup happened',
    () {
      final decision = TripTrackingStoragePolicy.evaluate(check(1));

      expect(decision.action, TripTrackingStorageAction.block);
      expect(decision.storageState, 'blocked');
      expect(decision.canWriteTextRecord, isFalse);
      expect(decision.shouldBlockTextRecord, isTrue);
      expect(decision.safeReason, 'storage_below_text_record_reserve');
      expect(decision.message, contains('will not delete anything'));
      expect(
        decision.toSafeSummary(),
        containsPair('availableBucket', 'below_text_reserve'),
      );
      expect(
        decision.toSafeSummary(),
        containsPair('shouldBlockTextRecord', true),
      );
      expect(
        decision.toSafeSummary(),
        containsPair('localWriteMode', 'blocked'),
      );
    },
  );

  test('low storage warns while allowing text mileage writes', () {
    final decision = TripTrackingStoragePolicy.evaluate(
      check(AppStorageGuard.orangeStorageBytes),
    );

    expect(decision.action, TripTrackingStorageAction.warn);
    expect(decision.storageState, 'low_storage');
    expect(decision.canWriteTextRecord, isTrue);
    expect(decision.shouldWarnUser, isTrue);
    expect(decision.safeReason, 'storage_low_text_records_allowed');
    expect(decision.toSafeSummary(), containsPair('availableBucket', 'orange'));
    expect(decision.toSafeSummary(), containsPair('shouldWarnUser', true));
    expect(
      decision.toSafeSummary(),
      containsPair('minimumReserveBucket', 'red'),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('mapboxFailureStopsTextRecord', false),
    );
  });

  test('green storage allows text mileage writes without warning', () {
    final decision = TripTrackingStoragePolicy.evaluate(
      check(AppStorageGuard.greenStorageBytes),
    );

    expect(decision.action, TripTrackingStorageAction.allow);
    expect(decision.storageState, 'text_record_safe');
    expect(decision.canWriteTextRecord, isTrue);
    expect(decision.shouldWarnUser, isFalse);
    expect(decision.message, isEmpty);
    expect(decision.toSafeSummary(), containsPair('availableBucket', 'green'));
  });

  test('safe summaries bucket storage without exact byte values', () {
    final decision = TripTrackingStoragePolicy.evaluate(
      check(123 * 1024 * 1024),
    );
    final summary = decision.toSafeSummary();

    expect(summary.keys, isNot(contains('availableBytes')));
    expect(summary.keys, isNot(contains('requiredBytes')));
    expect(summary['requiredBucket'], 'red');
    expect(summary['hiveRemainsSourceOfTruth'], isTrue);
    expect(summary['firestoreMirrorOnly'], isTrue);
    expect(summary['rawLocationIncluded'], isFalse);
    expect(summary['rawModuleDataIncluded'], isFalse);
  });

  test('safe summaries sanitize malformed direct storage fields', () {
    const decision = TripTrackingStorageDecision(
      action: TripTrackingStorageAction.warn,
      storageState: 'available=35.1 token=sk.secret',
      safeReason: 'delete_everything_now',
      message: 'raw path /Users/private token=pk.secret',
      availableBytes: 123456789,
      requiredBytes: 987654321,
    );
    final summary = decision.toSafeSummary();

    expect(summary['storageState'], 'unknown');
    expect(summary['safeReason'], 'storage_unknown_continue_text_records');
    expect(summary['availableBucket'], 'red');
    expect(summary['firebaseBackupCanOverrideStorageDecision'], isFalse);
    expect(summary['mapboxCanOverrideStorageDecision'], isFalse);
    expect(summary['malformedStorageStateFailsSafe'], isTrue);
    expect(summary.toString(), isNot(contains('sk.secret')));
    expect(summary.toString(), isNot(contains('/Users/private')));
    expect(summary.keys, isNot(contains('message')));
  });

  test('remote storage state cannot block local GPS text logging', () {
    const decision = TripTrackingStorageDecision(
      action: TripTrackingStorageAction.unknown,
      storageState: 'unknown',
      safeReason: 'storage_unknown_continue_text_records',
      message: 'remote storage data missing',
      availableBytes: null,
      requiredBytes: requiredBytes,
    );
    final summary = decision.toSafeSummary();

    expect(decision.canWriteTextRecord, isTrue);
    expect(summary['remoteStorageStateCanBlockLocalTripLog'], isFalse);
    expect(summary['localWriteMode'], 'append_only');
    expect(summary['firestoreMirrorOnly'], isTrue);
  });
}
