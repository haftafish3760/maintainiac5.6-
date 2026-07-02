part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewCaptureFeedback on _ReceiptPhotoReviewScreenState {
  void _showCameraError(String message) {
    if (!_reviewWorkActive) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showScannerFallbackNotice(ReceiptNativeScanResult result) {
    if (!_reviewWorkActive ||
        result.status == ReceiptNativeScanStatus.scanned) {
      return;
    }
    final detail = result.message.trim();
    final message = detail.isEmpty
        ? 'Document scanner was not available. Maintainiac will use your phone camera as a fallback if needed.'
        : '$detail Maintainiac will use your phone camera as a fallback if needed.';
    _showCameraError(message);
  }

  String _nativeCameraOpenErrorMessage(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = error.message?.trim();
    final combined = '$code ${message ?? ''}'.toLowerCase();
    if (combined.contains('permission') ||
        combined.contains('denied') ||
        combined.contains('restricted')) {
      return 'Camera permission is blocked. Open your phone settings, allow camera access for Maintainiac, then try Add Another Photo again.';
    }
    if (combined.contains('cancel')) {
      return 'Camera was canceled. No receipt photo was added.';
    }
    if (message != null && message.isNotEmpty) {
      return '$message Try Add Another Photo again, or choose an existing receipt image.';
    }
    return 'Maintainiac receipt camera could not open. Try Add Another Photo again, or choose an existing receipt image.';
  }

  Future<void> _showStorageDialog(String message) async {
    if (!_reviewWorkActive) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2528),
          title: const Text(
            'Storage Space Needed',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFC7D0D4),
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
