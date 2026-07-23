import 'app_storage_free_space_stub.dart'
    if (dart.library.ui) 'app_storage_free_space_flutter.dart';

enum AppStoragePurpose {
  appStartup,
  dashboardRecord,
  smallRecordWrite,
  mileageTracking,
  receiptPhotoCapture,
  receiptPhotoSave,
  receiptPdfImport,
  exportFile,
  backupCache,
  restoreImport,
}

typedef AppFreeStorageReader = Future<double?> Function();

/// Shared semantic storage state. UI layers choose their own accessible color
/// tokens from this stable state; storage policy never deletes files.
enum AppStorageLevel { green, yellow, orange, red, unknown }

class AppStorageGuard {
  AppStorageGuard._();

  static const int minimumDeviceReserveBytes = 50 * 1024 * 1024;
  static const int textRecordDeviceReserveBytes = 25 * 1024 * 1024;
  static const int greenStorageBytes = 1024 * 1024 * 1024;
  static const int yellowStorageBytes = 500 * 1024 * 1024;
  static const int orangeStorageBytes = 250 * 1024 * 1024;
  static const int lowStorageWarningBytes = greenStorageBytes;
  static const int smallRecordWriteBytes = 1 * 1024 * 1024;
  static const int dashboardRecordWriteBytes = 1 * 1024 * 1024;
  static const int mileageTrackingWriteBytes = 2 * 1024 * 1024;
  static const int receiptPhotoCaptureBytes = 25 * 1024 * 1024;
  static const int receiptProofSaveBytes = 12 * 1024 * 1024;
  static const int exportFileBytes = 25 * 1024 * 1024;
  static const int backupCacheBytes = 50 * 1024 * 1024;

  static Future<AppStorageCheck> check(
    AppStoragePurpose purpose, {
    AppFreeStorageReader? freeStorageReader,
  }) {
    return checkForBytes(
      operationBytes: defaultOperationBytesFor(purpose),
      purpose: purpose,
      freeStorageReader: freeStorageReader,
    );
  }

  static Future<AppStorageCheck> checkForBytes({
    required int operationBytes,
    required AppStoragePurpose purpose,
    AppFreeStorageReader? freeStorageReader,
  }) async {
    if (operationBytes < 0) {
      throw ArgumentError.value(
        operationBytes,
        'operationBytes',
        'must not be negative',
      );
    }
    final protectedBytes = protectedRequiredBytesFor(purpose, operationBytes);
    try {
      final freeMb = freeStorageReader != null
          ? await freeStorageReader()
          : await readAppFreeDiskSpaceMb();
      if (freeMb == null || !freeMb.isFinite || freeMb < 0) {
        return AppStorageCheck.unknown(
          operationBytes: operationBytes,
          requiredBytes: protectedBytes,
          purpose: purpose,
        );
      }
      return AppStorageCheck(
        availableBytes: (freeMb * 1024 * 1024).floor(),
        operationBytes: operationBytes,
        requiredBytes: protectedBytes,
        purpose: purpose,
      );
    } catch (_) {
      return AppStorageCheck.unknown(
        operationBytes: operationBytes,
        requiredBytes: protectedBytes,
        purpose: purpose,
      );
    }
  }

  static int protectedRequiredBytes(int operationBytes) {
    return operationBytes + minimumDeviceReserveBytes;
  }

  static int protectedRequiredBytesFor(
    AppStoragePurpose purpose,
    int operationBytes,
  ) {
    return operationBytes + deviceReserveBytesFor(purpose);
  }

  static int deviceReserveBytesFor(AppStoragePurpose purpose) {
    return switch (purpose) {
      AppStoragePurpose.appStartup ||
      AppStoragePurpose.dashboardRecord ||
      AppStoragePurpose.smallRecordWrite ||
      AppStoragePurpose.mileageTracking => textRecordDeviceReserveBytes,
      _ => minimumDeviceReserveBytes,
    };
  }

  static int defaultOperationBytesFor(AppStoragePurpose purpose) {
    return switch (purpose) {
      AppStoragePurpose.appStartup => smallRecordWriteBytes,
      AppStoragePurpose.dashboardRecord => dashboardRecordWriteBytes,
      AppStoragePurpose.smallRecordWrite => smallRecordWriteBytes,
      AppStoragePurpose.mileageTracking => mileageTrackingWriteBytes,
      AppStoragePurpose.receiptPhotoCapture => receiptPhotoCaptureBytes,
      AppStoragePurpose.receiptPhotoSave => receiptProofSaveBytes,
      AppStoragePurpose.receiptPdfImport => receiptProofSaveBytes,
      AppStoragePurpose.exportFile => exportFileBytes,
      AppStoragePurpose.backupCache => backupCacheBytes,
      AppStoragePurpose.restoreImport => backupCacheBytes,
    };
  }

  static String purposeLabel(AppStoragePurpose purpose) {
    return switch (purpose) {
      AppStoragePurpose.appStartup => 'start Maintainiac',
      AppStoragePurpose.dashboardRecord => 'save dashboard records',
      AppStoragePurpose.smallRecordWrite => 'save this record',
      AppStoragePurpose.mileageTracking => 'save mileage tracking',
      AppStoragePurpose.receiptPhotoCapture => 'take another receipt photo',
      AppStoragePurpose.receiptPhotoSave => 'save these receipt photos',
      AppStoragePurpose.receiptPdfImport => 'save this PDF receipt proof',
      AppStoragePurpose.exportFile => 'create this export file',
      AppStoragePurpose.backupCache => 'prepare backup data',
      AppStoragePurpose.restoreImport => 'restore saved records',
    };
  }

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).ceil()} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).ceil()} KB';
    return '$bytes bytes';
  }
}

class AppStorageCheck {
  const AppStorageCheck({
    required this.availableBytes,
    required this.operationBytes,
    required this.requiredBytes,
    required this.purpose,
    this.canVerify = true,
  });

  const AppStorageCheck.unknown({
    required this.operationBytes,
    required this.requiredBytes,
    required this.purpose,
  }) : availableBytes = null,
       canVerify = false;

  final int? availableBytes;
  final int operationBytes;
  final int requiredBytes;
  final AppStoragePurpose purpose;
  final bool canVerify;

  bool get hasEnoughSpace {
    final available = availableBytes;
    return available == null || available >= requiredBytes;
  }

  bool get shouldWarnLowStorage {
    final available = availableBytes;
    return available != null &&
        available < AppStorageGuard.lowStorageWarningBytes;
  }

  AppStorageLevel get level {
    final available = availableBytes;
    if (available == null) return AppStorageLevel.unknown;
    if (available >= AppStorageGuard.greenStorageBytes) {
      return AppStorageLevel.green;
    }
    if (available >= AppStorageGuard.yellowStorageBytes) {
      return AppStorageLevel.yellow;
    }
    if (available > AppStorageGuard.orangeStorageBytes) {
      return AppStorageLevel.orange;
    }
    return AppStorageLevel.red;
  }

  String get minimumLabel => AppStorageGuard.formatBytes(requiredBytes);
  String get operationLabel => AppStorageGuard.formatBytes(operationBytes);
  String get reserveLabel => AppStorageGuard.formatBytes(
    AppStorageGuard.deviceReserveBytesFor(purpose),
  );

  String get availableLabel {
    final available = availableBytes;
    if (available == null) return 'unknown';
    return AppStorageGuard.formatBytes(available);
  }

  String blockingMessage() {
    return 'There is not enough free storage to ${AppStorageGuard.purposeLabel(purpose)}. '
        'Available: $availableLabel. Minimum needed: $minimumLabel '
        '($operationLabel for this action plus a $reserveLabel device safety reserve). '
        'Please free up storage space first. Maintainiac will not delete anything from your phone without your approval.';
  }

  String unknownMessage() {
    return 'Maintainiac could not verify free storage before ${AppStorageGuard.purposeLabel(purpose)}. '
        'Minimum recommended free space: $minimumLabel, including a $reserveLabel device safety reserve. '
        'If saving fails, free up storage and try again.';
  }

  String warningMessage() {
    return 'Your device is getting low on storage. Maintainiac can continue, but saving photos, PDFs, exports, or backups may fail until more space is available.';
  }
}
