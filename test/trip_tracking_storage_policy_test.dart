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
    expect(
      decision.toSafeSummary(),
      containsPair('storageStateCanSetGlobalTruth', false),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('storageStateCanConfirmOfficialMileage', false),
    );
    expect(
      decision.toSafeSummary(),
      containsPair('storageStateCanChangeOfficialMileage', false),
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
      expect(decision.message, contains('does not delete files'));
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
    expect(summary['canWriteTextRecord'], isTrue);
    expect(summary['shouldWarnUser'], isFalse);
    expect(summary['shouldBlockTextRecord'], isFalse);
    expect(summary['localWriteMode'], 'append_only');
    expect(summary['availableBucket'], 'red');
    expect(summary['firebaseBackupCanOverrideStorageDecision'], isFalse);
    expect(summary['mapboxCanOverrideStorageDecision'], isFalse);
    expect(summary['malformedStorageStateFailsSafe'], isTrue);
    expect(summary.toString(), isNot(contains('sk.secret')));
    expect(summary.toString(), isNot(contains('/Users/private')));
    expect(summary.keys, isNot(contains('message')));
  });

  test('direct malformed storage blocks cannot stop text GPS logging', () {
    const decision = TripTrackingStorageDecision(
      action: TripTrackingStorageAction.block,
      storageState: 'blocked',
      safeReason: 'remote_claimed_full_disk_token=sk.secret',
      message: 'remote storage says no',
      availableBytes: null,
      requiredBytes: requiredBytes,
    );
    final summary = decision.toSafeSummary();

    expect(summary['safeReason'], 'storage_unknown_continue_text_records');
    expect(summary['canWriteTextRecord'], isTrue);
    expect(summary['shouldBlockTextRecord'], isFalse);
    expect(summary['localWriteMode'], 'append_only');
    expect(summary['remoteStorageStateCanBlockLocalTripLog'], isFalse);
    expect(summary.toString(), isNot(contains('sk.secret')));
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

  test('local trip text records are retained while backup is pending', () {
    final notWritten = TripTrackingLocalRetentionPolicy.evaluate(
      localTextRecordWritten: false,
      remoteBackupConfirmed: true,
      userApprovedCleanupReview: true,
    );
    final pending = TripTrackingLocalRetentionPolicy.evaluate(
      localTextRecordWritten: true,
      remoteBackupConfirmed: false,
      userApprovedCleanupReview: true,
    );

    expect(notWritten.status, TripTrackingLocalRetentionStatus.backupPending);
    expect(notWritten.localTextRecordRetained, isFalse);
    expect(notWritten.canDeleteLocalDataSilently, isFalse);
    expect(pending.status, TripTrackingLocalRetentionStatus.backupPending);
    expect(pending.localTextRecordRetained, isTrue);
    expect(pending.cleanupSuggested, isFalse);
    expect(pending.toSafeSummary()['backupCanDeleteLocalData'], isFalse);
    expect(pending.toSafeSummary()['firebaseCanDeleteLocalData'], isFalse);
  });

  test('confirmed backup keeps local trip records by default', () {
    final decision = TripTrackingLocalRetentionPolicy.evaluate(
      localTextRecordWritten: true,
      remoteBackupConfirmed: true,
      userApprovedCleanupReview: false,
    );
    final summary = decision.toSafeSummary();

    expect(decision.status, TripTrackingLocalRetentionStatus.keepLocal);
    expect(decision.localTextRecordRetained, isTrue);
    expect(decision.cleanupSuggested, isFalse);
    expect(decision.userCanReviewCleanup, isFalse);
    expect(summary['remoteMirrorCanReplaceLocalTruth'], isFalse);
    expect(summary['storageStateCanSetGlobalTruth'], isFalse);
    expect(summary['storageStateCanConfirmOfficialMileage'], isFalse);
    expect(summary['storageStateCanChangeOfficialMileage'], isFalse);
    expect(summary['hiveRemainsOperationalSourceOfTruth'], isTrue);
    expect(summary['firestoreMirrorOnly'], isTrue);
    expect(summary['durableStorageIsSharedAcrossModules'], isTrue);
  });

  test('cleanup review is explicit and still cannot silently purge', () {
    final decision = TripTrackingLocalRetentionPolicy.evaluate(
      localTextRecordWritten: true,
      remoteBackupConfirmed: true,
      userApprovedCleanupReview: true,
    );
    final summary = decision.toSafeSummary();

    expect(
      decision.status,
      TripTrackingLocalRetentionStatus.cleanupReviewAvailable,
    );
    expect(decision.cleanupSuggested, isTrue);
    expect(decision.userCanReviewCleanup, isTrue);
    expect(summary['cleanupRequiresExplicitUserAction'], isTrue);
    expect(summary['cleanupRequiresConfirmedBackup'], isTrue);
    expect(summary['canPurgeLocalTripRecordsSilently'], isFalse);
    expect(summary['mapboxCanDeleteLocalData'], isFalse);
    expect(summary['tokensIncluded'], isFalse);
    expect(summary['preciseFilePathIncluded'], isFalse);
  });

  test('malformed retention summaries fail to keep-local posture', () {
    const decision = TripTrackingLocalRetentionDecision(
      status: TripTrackingLocalRetentionStatus.cleanupReviewAvailable,
      reasonCode: 'delete_all_local_records_token=sk.secret',
      localTextRecordRetained: true,
      remoteBackupConfirmed: true,
      cleanupSuggested: true,
    );
    final summary = decision.toSafeSummary();

    expect(summary['reasonCode'], 'remote_backup_not_confirmed');
    expect(summary['canDeleteLocalDataSilently'], isFalse);
    expect(summary['backupCanDeleteLocalData'], isFalse);
    expect(summary.toString(), isNot(contains('sk.secret')));
  });
}
