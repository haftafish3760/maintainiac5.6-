import '../storage/app_storage_guard.dart';

enum MaintainiacRestoreMode { full, smart, recordsOnly }

enum MaintainiacRestoreSessionState {
  prepared,
  running,
  paused,
  failed,
  cancelled,
  completed;

  bool get isTerminal =>
      this == MaintainiacRestoreSessionState.cancelled ||
      this == MaintainiacRestoreSessionState.completed;
}

class MaintainiacRestoreStoragePlan {
  const MaintainiacRestoreStoragePlan({
    required this.structuredBytes,
    required this.thumbnailBytes,
    required this.proofBytes,
    required this.temporaryBytes,
    required this.availableBytes,
  }) : assert(structuredBytes >= 0),
       assert(thumbnailBytes >= 0),
       assert(proofBytes >= 0),
       assert(temporaryBytes >= 0),
       assert(availableBytes >= 0);

  factory MaintainiacRestoreStoragePlan.fromMap(Map<dynamic, dynamic> map) =>
      MaintainiacRestoreStoragePlan(
        structuredBytes: _requiredNonNegativeInt(map, 'structuredBytes'),
        thumbnailBytes: _requiredNonNegativeInt(map, 'thumbnailBytes'),
        proofBytes: _requiredNonNegativeInt(map, 'proofBytes'),
        temporaryBytes: _requiredNonNegativeInt(map, 'temporaryBytes'),
        availableBytes: _requiredNonNegativeInt(map, 'availableBytes'),
      );

  final int structuredBytes;
  final int thumbnailBytes;
  final int proofBytes;
  final int temporaryBytes;
  final int availableBytes;

  int transferBytesFor(MaintainiacRestoreMode mode) => switch (mode) {
    MaintainiacRestoreMode.full =>
      structuredBytes + thumbnailBytes + proofBytes,
    MaintainiacRestoreMode.smart => structuredBytes + thumbnailBytes,
    MaintainiacRestoreMode.recordsOnly => structuredBytes,
  };

  int operationBytesFor(MaintainiacRestoreMode mode) =>
      transferBytesFor(mode) + temporaryBytes;

  int requiredDeviceBytesFor(MaintainiacRestoreMode mode) =>
      AppStorageGuard.protectedRequiredBytesFor(
        AppStoragePurpose.restoreImport,
        operationBytesFor(mode),
      );

  bool canFit(MaintainiacRestoreMode mode) =>
      availableBytes >= requiredDeviceBytesFor(mode);

  Map<String, Object?> toMap() => {
    'structuredBytes': structuredBytes,
    'thumbnailBytes': thumbnailBytes,
    'proofBytes': proofBytes,
    'temporaryBytes': temporaryBytes,
    'availableBytes': availableBytes,
  };
}

enum MaintainiacRestoreDisposition {
  applyRemote,
  keepNewerLocal,
  alreadyCurrent,
  conflict,
  rejectCorrupt,
}

class MaintainiacRestoreRecordVersion {
  const MaintainiacRestoreRecordVersion({
    required this.revision,
    required this.schemaVersion,
    required this.contentSha256,
    required this.isDeleted,
  });

  final int revision;
  final int schemaVersion;
  final String contentSha256;
  final bool isDeleted;

  bool get isValid =>
      revision >= 1 &&
      schemaVersion >= 1 &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(contentSha256);
}

class MaintainiacRestoreConflictPolicy {
  const MaintainiacRestoreConflictPolicy._();

  static MaintainiacRestoreDisposition decide({
    required MaintainiacRestoreRecordVersion remote,
    MaintainiacRestoreRecordVersion? local,
    required int maximumSupportedSchemaVersion,
  }) {
    if (!remote.isValid ||
        maximumSupportedSchemaVersion < 1 ||
        remote.schemaVersion > maximumSupportedSchemaVersion ||
        (local != null && !local.isValid)) {
      return MaintainiacRestoreDisposition.rejectCorrupt;
    }
    if (local == null || remote.revision > local.revision) {
      return MaintainiacRestoreDisposition.applyRemote;
    }
    if (remote.revision < local.revision) {
      return MaintainiacRestoreDisposition.keepNewerLocal;
    }
    if (remote.schemaVersion == local.schemaVersion &&
        remote.contentSha256 == local.contentSha256 &&
        remote.isDeleted == local.isDeleted) {
      return MaintainiacRestoreDisposition.alreadyCurrent;
    }
    return MaintainiacRestoreDisposition.conflict;
  }
}

int _requiredNonNegativeInt(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! int || value < 0) {
    throw FormatException('Restore storage plan has invalid $key.');
  }
  return value;
}
