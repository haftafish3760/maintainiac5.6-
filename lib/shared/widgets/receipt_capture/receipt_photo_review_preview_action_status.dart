part of 'receipt_photo_review_screen.dart';

extension _ReceiptPreviewActionTrayStatus on _ReceiptPreviewActionTray {
  IconData get statusIcon => photoPaths.length > 1
      ? Icons.layers_rounded
      : Icons.photo_camera_back_rounded;

  Color get statusColor => const Color(0xFF8EF6A4);

  String get statusText {
    if (photoPaths.length <= 1) {
      return 'Check this photo, then choose what to do next.';
    }
    return 'Check each section. Retake a bad one, add another if the receipt '
        'continues, then use the receipt.$multiPhotoMatchStatusCopy';
  }

  String get multiPhotoMatchStatusCopy {
    if (stitchPreviewInFlight) return ' Preparing the receipt.';
    final preview = stitchPreview;
    if (preview == null) return '';
    if (preview.didStitch) return ' A combined receipt is ready.';
    if (preview.usedFallback) {
      return ' The sections will stay in their captured order.';
    }
    return '';
  }
}
