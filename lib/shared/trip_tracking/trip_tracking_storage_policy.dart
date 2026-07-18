import '../storage/app_storage_guard.dart';

enum TripTrackingStorageAction { allow, warn, block, unknown }

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
