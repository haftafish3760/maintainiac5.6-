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
    'storageState': storageState,
    'safeReason': safeReason,
    'recordType': 'trip_text_record',
    'canWriteTextRecord': canWriteTextRecord,
    'shouldWarnUser': shouldWarnUser,
    'shouldBlockTextRecord': shouldBlockTextRecord,
    'availableBucket': _bucketBytes(availableBytes),
    'requiredBucket': _bucketBytes(requiredBytes),
    'minimumReserveBucket': _bucketBytes(
      AppStorageGuard.textRecordDeviceReserveBytes,
    ),
    'localWriteMode': shouldBlockTextRecord ? 'blocked' : 'append_only',
    'deletesLocalData': false,
    'purgesLocalData': false,
    'canSilentlyDeleteLocalData': false,
    'backupCanTriggerSilentLocalPurge': false,
    'userActionRequiredForCleanup': true,
    'cleanupSuggested': false,
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
