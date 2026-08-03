import 'dart:io';

import 'package:doc_scan_kit/doc_scan_kit.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'receipt_capture_models.dart';
import 'receipt_image_processor.dart';

enum ReceiptNativeScanStatus { scanned, unavailable, canceled, failed }

class ReceiptNativeScanResult {
  const ReceiptNativeScanResult({
    required this.status,
    this.cameraResult,
    this.message = '',
  });

  const ReceiptNativeScanResult.unavailable([String message = ''])
    : this(status: ReceiptNativeScanStatus.unavailable, message: message);

  const ReceiptNativeScanResult.canceled()
    : this(status: ReceiptNativeScanStatus.canceled);

  const ReceiptNativeScanResult.failed(String message)
    : this(status: ReceiptNativeScanStatus.failed, message: message);

  final ReceiptNativeScanStatus status;
  final ReceiptCameraResult? cameraResult;
  final String message;

  bool get hasScannedPages =>
      status == ReceiptNativeScanStatus.scanned &&
      (cameraResult?.photoPaths.isNotEmpty ?? false);
}

abstract class ReceiptScannerService {
  const ReceiptScannerService();

  Future<ReceiptNativeScanResult> scanReceipt({
    required int pageLimit,
    required bool allowGalleryImport,
  });
}

class NativeReceiptScannerService extends ReceiptScannerService {
  const NativeReceiptScannerService();

  static bool get documentScannerAllowedOnThisPlatform {
    // Keep native camera capture as the normal path, but make the platform
    // document scanner available as an explicit recovery path. The Android
    // plugin already ships the Google Play Services document-scanner bridge;
    // rejecting Android here prevented the only available perspective-corrected
    // capture option from ever being offered on a supported device.
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<ReceiptNativeScanResult> scanReceipt({
    required int pageLimit,
    required bool allowGalleryImport,
  }) async {
    if (!documentScannerAllowedOnThisPlatform) {
      return const ReceiptNativeScanResult.unavailable();
    }
    final scanner = DocScanKit(
      androidOptions: DocumentScanKitOptionsAndroid(
        pageLimit: pageLimit.clamp(1, 24),
        scannerMode: ScannerModeAndroid.full,
        isGalleryImport: allowGalleryImport,
        saveImage: false,
      ),
      iosOptions: DocumentScanKitOptionsiOS(
        compressionQuality: .98,
        saveImage: false,
        color: const Color(0xFFFFD166),
      ),
    );
    try {
      final pages = await scanner.scanner();
      if (pages.isEmpty) return const ReceiptNativeScanResult.canceled();
      final paths = <String>[];
      final qualityChecks = <ReceiptPhotoQualityCheck>[];
      for (var index = 0; index < pages.length; index++) {
        final page = pages[index];
        final pagePath = await _persistScannerPage(page, index);
        if (pagePath == null) continue;
        paths.add(pagePath);
        qualityChecks.add(
          await ReceiptImageProcessor.qualityCheckFile(pagePath),
        );
      }
      if (paths.isEmpty) return const ReceiptNativeScanResult.canceled();
      return ReceiptNativeScanResult(
        status: ReceiptNativeScanStatus.scanned,
        cameraResult: ReceiptCameraResult.single(
          paths,
          qualityChecks: qualityChecks,
        ),
      );
    } on MissingPluginException {
      return const ReceiptNativeScanResult.unavailable(
        'Native receipt scanning is not available in this build.',
      );
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      if (code.contains('cancel')) {
        return const ReceiptNativeScanResult.canceled();
      }
      final message = error.message?.trim();
      return ReceiptNativeScanResult.failed(
        message == null || message.isEmpty
            ? 'Native receipt scanning could not finish.'
            : message,
      );
    } catch (_) {
      return const ReceiptNativeScanResult.failed(
        'Native receipt scanning could not finish.',
      );
    } finally {
      await scanner.close();
    }
  }

  Future<String?> _persistScannerPage(ScanResult page, int index) async {
    final bytes = page.imagesBytes.isNotEmpty
        ? page.imagesBytes
        : await _readScannerPath(page.imagePath);
    if (bytes == null || bytes.isEmpty) return null;
    final tempDir = await getTemporaryDirectory();
    final file = File(
      path.join(
        tempDir.path,
        'maintainiac_receipt_scan_${DateTime.now().microsecondsSinceEpoch}_$index.jpg',
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Uint8List?> _readScannerPath(String? scannerPath) async {
    final value = scannerPath?.trim();
    if (value == null || value.isEmpty) return null;
    try {
      final file = File(value);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
