part of 'receipt_native_capture_staging.dart';

extension _ReceiptNativeCaptureStagingManifestHelpers
    on ReceiptNativeCaptureStaging {
  String _captureId(
    ReceiptNativeCaptureResult capture,
    int index,
    String sessionId,
  ) {
    final nativeId = index < capture.temporaryCaptureIds.length
        ? capture.temporaryCaptureIds[index].trim()
        : '';
    final safeNativeId = nativeId
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safeNativeId.isNotEmpty) return '$sessionId-$safeNativeId';
    return '$sessionId-$index';
  }

  String _captureSessionId(ReceiptNativeCaptureResult capture) {
    final nativeSeed = capture.temporaryCaptureIds.isEmpty
        ? ''
        : capture.temporaryCaptureIds.first.trim();
    final safeNativeSeed = nativeSeed
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final timestamp = capture.capturedAt.microsecondsSinceEpoch;
    if (safeNativeSeed.isNotEmpty) return 'native-$timestamp-$safeNativeSeed';
    return 'native-$timestamp-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _displayName(int index) {
    return index == 0 ? 'Receipt photo' : 'Receipt photo ${index + 1}';
  }

  String _sourceLabel(ReceiptNativeCameraEngine engine) {
    return switch (engine) {
      ReceiptNativeCameraEngine.cameraX => 'Maintainiac CameraX receipt camera',
      ReceiptNativeCameraEngine.avFoundation =>
        'Maintainiac AVFoundation receipt camera',
      ReceiptNativeCameraEngine.unavailable => 'Maintainiac receipt camera',
    };
  }

  String _byteSizeBucket(int byteSize) {
    if (byteSize <= 0) return 'unknown';
    if (byteSize < 100 * 1024) return 'tiny_under_100kb';
    if (byteSize < 350 * 1024) return 'small_under_350kb';
    if (byteSize < 1024 * 1024) return 'medium_under_1mb';
    if (byteSize < 3 * 1024 * 1024) return 'normal_1mb_to_3mb';
    if (byteSize < 8 * 1024 * 1024) return 'large_3mb_to_8mb';
    return 'very_large_over_8mb';
  }
}
