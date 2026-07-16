part of 'receipt_photo_review_screen.dart';

extension _ReceiptPreviewActionTrayStatus on _ReceiptPreviewActionTray {
  IconData get statusIcon => photoPaths.length > 1
      ? Icons.layers_rounded
      : Icons.photo_camera_back_rounded;

  Color get statusColor => const Color(0xFF8EF6A4);

  String get statusText {
    if (photoPaths.length <= 1) {
      return 'Check that the receipt text is readable. Retake this photo, add another only if the receipt continues, or use it.';
    }
    return '${photoPaths.length} receipt photos selected. Check each photo, then continue to match them.$multiPhotoMatchStatusCopy';
  }

  String get multiPhotoMatchStatusCopy {
    if (stitchPreviewInFlight) return ' The photo match check is running.';
    final preview = stitchPreview;
    if (preview == null) return '';
    if (preview.didStitch) {
      return ' A combined receipt preview is ready.';
    }
    if (preview.usedFallback) {
      return ' The photos will remain in top-to-bottom order.';
    }
    return ' Review the photo match before using a combined image.';
  }
}
