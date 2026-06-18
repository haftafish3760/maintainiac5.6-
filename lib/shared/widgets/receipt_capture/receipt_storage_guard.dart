import 'package:maintaniac/shared/storage/app_storage_guard.dart';

enum ReceiptStoragePurpose { capturePhoto, savePhotos, importPdf }

class ReceiptStorageGuard {
  ReceiptStorageGuard._();

  static const int minimumDeviceReserveBytes =
      AppStorageGuard.minimumDeviceReserveBytes;
  static const int minimumCaptureBytes =
      AppStorageGuard.receiptPhotoCaptureBytes;
  static const int minimumSaveBytes = AppStorageGuard.receiptProofSaveBytes;

  static Future<ReceiptStorageCheck> check(
    ReceiptStoragePurpose purpose,
  ) async {
    return checkForBytes(
      requiredBytes: _requiredFor(purpose),
      purpose: purpose,
    );
  }

  static Future<ReceiptStorageCheck> checkForBytes({
    required int requiredBytes,
    ReceiptStoragePurpose purpose = ReceiptStoragePurpose.savePhotos,
  }) async {
    final check = await AppStorageGuard.checkForBytes(
      operationBytes: requiredBytes,
      purpose: _appPurposeFor(purpose),
    );
    return ReceiptStorageCheck.fromAppCheck(check, purpose: purpose);
  }

  static int protectedRequiredBytes(int operationBytes) {
    return AppStorageGuard.protectedRequiredBytes(operationBytes);
  }

  static int _requiredFor(ReceiptStoragePurpose purpose) {
    return switch (purpose) {
      ReceiptStoragePurpose.capturePhoto => minimumCaptureBytes,
      ReceiptStoragePurpose.savePhotos => minimumSaveBytes,
      ReceiptStoragePurpose.importPdf => minimumSaveBytes,
    };
  }

  static String formatBytes(int bytes) {
    return AppStorageGuard.formatBytes(bytes);
  }

  static AppStoragePurpose _appPurposeFor(ReceiptStoragePurpose purpose) {
    return switch (purpose) {
      ReceiptStoragePurpose.capturePhoto =>
        AppStoragePurpose.receiptPhotoCapture,
      ReceiptStoragePurpose.savePhotos => AppStoragePurpose.receiptPhotoSave,
      ReceiptStoragePurpose.importPdf => AppStoragePurpose.receiptPdfImport,
    };
  }
}

class ReceiptStorageCheck {
  const ReceiptStorageCheck({
    required this.availableBytes,
    required this.operationBytes,
    required this.requiredBytes,
    this.purpose = ReceiptStoragePurpose.savePhotos,
    this.shouldWarnLowStorage = false,
    this.canVerify = true,
  });

  const ReceiptStorageCheck.unknown({
    required this.operationBytes,
    required this.requiredBytes,
    this.purpose = ReceiptStoragePurpose.savePhotos,
  }) : availableBytes = null,
       shouldWarnLowStorage = false,
       canVerify = false;

  ReceiptStorageCheck.fromAppCheck(
    AppStorageCheck check, {
    required this.purpose,
  }) : availableBytes = check.availableBytes,
       operationBytes = check.operationBytes,
       requiredBytes = check.requiredBytes,
       shouldWarnLowStorage = check.shouldWarnLowStorage,
       canVerify = check.canVerify;

  final int? availableBytes;
  final int operationBytes;
  final int requiredBytes;
  final ReceiptStoragePurpose purpose;
  final bool shouldWarnLowStorage;
  final bool canVerify;

  bool get hasEnoughSpace {
    final available = availableBytes;
    return available == null || available >= requiredBytes;
  }

  String get minimumLabel => ReceiptStorageGuard.formatBytes(requiredBytes);
  String get operationLabel => ReceiptStorageGuard.formatBytes(operationBytes);
  String get reserveLabel => ReceiptStorageGuard.formatBytes(
    ReceiptStorageGuard.minimumDeviceReserveBytes,
  );

  String get availableLabel {
    final available = availableBytes;
    if (available == null) return 'unknown';
    return ReceiptStorageGuard.formatBytes(available);
  }

  String blockingMessage(ReceiptStoragePurpose purpose) {
    final action = switch (purpose) {
      ReceiptStoragePurpose.capturePhoto => 'take another receipt photo',
      ReceiptStoragePurpose.savePhotos => 'save these receipt photos',
      ReceiptStoragePurpose.importPdf => 'save this PDF receipt proof',
    };
    return 'There is not enough free storage to $action. '
        'Available: $availableLabel. Minimum needed: $minimumLabel '
        '($operationLabel for this action plus a $reserveLabel device safety reserve). '
        'Please free up storage space first. Maintaniac will not delete anything from your phone without your approval.';
  }

  String unknownMessage(ReceiptStoragePurpose purpose) {
    final action = switch (purpose) {
      ReceiptStoragePurpose.capturePhoto => 'taking a receipt photo',
      ReceiptStoragePurpose.savePhotos => 'saving receipt photos',
      ReceiptStoragePurpose.importPdf => 'saving this PDF receipt proof',
    };
    return 'Maintaniac could not verify free storage before $action. '
        'Minimum recommended free space: $minimumLabel, including a $reserveLabel device safety reserve. '
        'If saving fails, free up storage and try again.';
  }

  String warningMessage() {
    return 'Your device is getting low on storage. Maintaniac can continue, but saving receipt photos, PDFs, or exports may fail until more space is available.';
  }
}
