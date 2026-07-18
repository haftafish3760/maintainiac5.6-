import '../storage/app_storage_guard.dart';

import 'trip_tracking_odometer_truth_policy.dart';

enum TripTrackingStorageAction { allow, warn, block, unknown }

enum TripTrackingLocalRetentionStatus {
  keepLocal,
  backupPending,
  cleanupReviewAvailable,
}

class TripTrackingLocalRetentionDecision {
  const TripTrackingLocalRetentionDecision({
    required this.status,
    required this.reasonCode,
    required this.localTextRecordRetained,
    required this.remoteBackupConfirmed,
    required this.cleanupSuggested,
  });

  final TripTrackingLocalRetentionStatus status;
  final String reasonCode;
  final bool localTextRecordRetained;
  final bool remoteBackupConfirmed;
  final bool cleanupSuggested;

  bool get canDeleteLocalDataSilently => false;

  bool get userCanReviewCleanup =>
      status == TripTrackingLocalRetentionStatus.cleanupReviewAvailable;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
    'status': status.name,
    'reasonCode': _safeRetentionReason(reasonCode),
    'localTextRecordRetained': localTextRecordRetained,
    'remoteBackupConfirmed': remoteBackupConfirmed,
    'cleanupSuggested': cleanupSuggested,
    'userCanReviewCleanup': userCanReviewCleanup,
    'canDeleteLocalDataSilently': false,
    'canPurgeLocalTripRecordsSilently': false,
    'backupCanDeleteLocalData': false,
    'firebaseCanDeleteLocalData': false,
    'mapboxCanDeleteLocalData': false,
    'remoteMirrorCanReplaceLocalTruth': false,
    'storageStateCanSetGlobalTruth': false,
    'storageStateCanConfirmOfficialMileage': false,
    'storageStateCanChangeOfficialMileage': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'durableStorageIsSharedAcrossModules': true,
    'tripTextRecordsAreCheap': true,
    'receiptPhotosHandledElsewhere': true,
    'cleanupRequiresExplicitUserAction': true,
    'cleanupRequiresConfirmedBackup': true,
    'rawLocationIncluded': false,
    'preciseFilePathIncluded': false,
    'tokensIncluded': false,
  };
}

class TripTrackingLocalRetentionPolicy {
  const TripTrackingLocalRetentionPolicy._();

  static TripTrackingLocalRetentionDecision evaluate({
    required bool localTextRecordWritten,
    required bool remoteBackupConfirmed,
    required bool userApprovedCleanupReview,
  }) {
    if (!localTextRecordWritten) {
      return const TripTrackingLocalRetentionDecision(
        status: TripTrackingLocalRetentionStatus.backupPending,
        reasonCode: 'local_text_record_not_yet_written',
        localTextRecordRetained: false,
        remoteBackupConfirmed: false,
        cleanupSuggested: false,
      );
    }
    if (!remoteBackupConfirmed) {
      return const TripTrackingLocalRetentionDecision(
        status: TripTrackingLocalRetentionStatus.backupPending,
        reasonCode: 'remote_backup_not_confirmed',
        localTextRecordRetained: true,
        remoteBackupConfirmed: false,
        cleanupSuggested: false,
      );
    }
    if (userApprovedCleanupReview) {
      return const TripTrackingLocalRetentionDecision(
        status: TripTrackingLocalRetentionStatus.cleanupReviewAvailable,
        reasonCode: 'confirmed_backup_user_cleanup_review_available',
        localTextRecordRetained: true,
        remoteBackupConfirmed: true,
        cleanupSuggested: true,
      );
    }
    return const TripTrackingLocalRetentionDecision(
      status: TripTrackingLocalRetentionStatus.keepLocal,
      reasonCode: 'confirmed_backup_keep_local_by_default',
      localTextRecordRetained: true,
      remoteBackupConfirmed: true,
      cleanupSuggested: false,
    );
  }
}

class TripTrackingStorageDecision {
  const TripTrackingStorageDecision({
    required this.action,
    required this.storageState,
    required this.safeReason,
    required this.message,
    required this.availableBytes,
    required this.requiredBytes,
  });

  final TripTrackingStorageAction action;
  final String storageState;
  final String safeReason;
  final String message;
  final int? availableBytes;
  final int requiredBytes;

  bool get canWriteTextRecord =>
      action == TripTrackingStorageAction.allow ||
      action == TripTrackingStorageAction.warn ||
      action == TripTrackingStorageAction.unknown;
  bool get shouldWarnUser => action == TripTrackingStorageAction.warn;
  bool get shouldBlockTextRecord => action == TripTrackingStorageAction.block;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    ...TripTrackingOdometerTruthPolicy.safeSummaryClaims,
    'action': action.name,
    'storageState': _safeStorageState(storageState),
    'safeReason': _safeStorageReason(safeReason),
    'recordType': 'trip_text_record',
    'canWriteTextRecord': _safeCanWriteTextRecord(
      action: action,
      safeReason: safeReason,
    ),
    'shouldWarnUser': _safeShouldWarnUser(
      action: action,
      safeReason: safeReason,
    ),
    'shouldBlockTextRecord': _safeShouldBlockTextRecord(
      action: action,
      safeReason: safeReason,
    ),
    'availableBucket': _bucketBytes(availableBytes),
    'requiredBucket': _bucketBytes(requiredBytes),
    'minimumReserveBucket': _bucketBytes(
      AppStorageGuard.textRecordDeviceReserveBytes,
    ),
    'textRecordReserveMb': 25,
    'storagePolicyScope': 'gps_trip_text_records',
    'photosAndReceiptsHandledElsewhere': true,
    'localWriteMode':
        _safeShouldBlockTextRecord(action: action, safeReason: safeReason)
        ? 'blocked'
        : 'append_only',
    'deletesLocalData': false,
    'purgesLocalData': false,
    'canSilentlyDeleteLocalData': false,
    'backupCanTriggerSilentLocalPurge': false,
    'confirmedBackupCanOnlySuggestCleanup': true,
    'userActionRequiredForCleanup': true,
    'cleanupSuggested': false,
    'storageDataTrustedAfterValidationOnly': true,
    'remoteStorageStateCanBlockLocalTripLog': false,
    'storageStateCanSetGlobalTruth': false,
    'storageStateCanConfirmOfficialMileage': false,
    'storageStateCanChangeOfficialMileage': false,
    'firebaseBackupCanOverrideStorageDecision': false,
    'mapboxCanOverrideStorageDecision': false,
    'malformedStorageStateFailsSafe': true,
    'hiveRemainsSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'mapboxFailureStopsTextRecord': false,
    'rawLocationIncluded': false,
    'rawModuleDataIncluded': false,
  };
}

class TripTrackingStoragePolicy {
  const TripTrackingStoragePolicy._();

  static TripTrackingStorageDecision evaluate(AppStorageCheck check) {
    if (!check.canVerify) {
      return TripTrackingStorageDecision(
        action: TripTrackingStorageAction.unknown,
        storageState: 'unknown',
        safeReason: 'storage_unknown_continue_text_records',
        message: check.unknownMessage(),
        availableBytes: check.availableBytes,
        requiredBytes: check.requiredBytes,
      );
    }
    if (!check.hasEnoughSpace) {
      return TripTrackingStorageDecision(
        action: TripTrackingStorageAction.block,
        storageState: 'blocked',
        safeReason: 'storage_below_text_record_reserve',
        message: check.blockingMessage(),
        availableBytes: check.availableBytes,
        requiredBytes: check.requiredBytes,
      );
    }
    if (check.shouldWarnLowStorage) {
      return TripTrackingStorageDecision(
        action: TripTrackingStorageAction.warn,
        storageState: 'low_storage',
        safeReason: 'storage_low_text_records_allowed',
        message: check.warningMessage(),
        availableBytes: check.availableBytes,
        requiredBytes: check.requiredBytes,
      );
    }
    return TripTrackingStorageDecision(
      action: TripTrackingStorageAction.allow,
      storageState: 'text_record_safe',
      safeReason: 'storage_safe_text_records_allowed',
      message: '',
      availableBytes: check.availableBytes,
      requiredBytes: check.requiredBytes,
    );
  }
}

String _bucketBytes(int? bytes) {
  if (bytes == null) return 'unknown';
  if (bytes < AppStorageGuard.textRecordDeviceReserveBytes) {
    return 'below_text_reserve';
  }
  if (bytes < AppStorageGuard.orangeStorageBytes) return 'red';
  if (bytes < AppStorageGuard.yellowStorageBytes) return 'orange';
  if (bytes < AppStorageGuard.greenStorageBytes) return 'yellow';
  return 'green';
}

String _safeStorageState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'blocked' => 'blocked',
    'low_storage' => 'low_storage',
    'text_record_safe' => 'text_record_safe',
    _ => 'unknown',
  };
}

String _safeStorageReason(String value) {
  return switch (value.trim()) {
    'storage_unknown_continue_text_records' =>
      'storage_unknown_continue_text_records',
    'storage_below_text_record_reserve' => 'storage_below_text_record_reserve',
    'storage_low_text_records_allowed' => 'storage_low_text_records_allowed',
    'storage_safe_text_records_allowed' => 'storage_safe_text_records_allowed',
    _ => 'storage_unknown_continue_text_records',
  };
}

String _safeRetentionReason(String value) {
  return switch (value.trim()) {
    'local_text_record_not_yet_written' => 'local_text_record_not_yet_written',
    'remote_backup_not_confirmed' => 'remote_backup_not_confirmed',
    'confirmed_backup_keep_local_by_default' =>
      'confirmed_backup_keep_local_by_default',
    'confirmed_backup_user_cleanup_review_available' =>
      'confirmed_backup_user_cleanup_review_available',
    _ => 'remote_backup_not_confirmed',
  };
}

bool _safeShouldBlockTextRecord({
  required TripTrackingStorageAction action,
  required String safeReason,
}) =>
    action == TripTrackingStorageAction.block &&
    _safeStorageReason(safeReason) == 'storage_below_text_record_reserve';

bool _safeShouldWarnUser({
  required TripTrackingStorageAction action,
  required String safeReason,
}) =>
    action == TripTrackingStorageAction.warn &&
    _safeStorageReason(safeReason) == 'storage_low_text_records_allowed';

bool _safeCanWriteTextRecord({
  required TripTrackingStorageAction action,
  required String safeReason,
}) => !_safeShouldBlockTextRecord(action: action, safeReason: safeReason);
