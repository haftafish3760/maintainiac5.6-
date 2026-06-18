part of 'receipt_photo_review_screen.dart';

class _ReceiptPhotoSectionLabels {
  const _ReceiptPhotoSectionLabels._();

  static String label({required int index, required int total}) {
    if (total <= 1) return 'Photo';
    if (total == 2) return index == 0 ? 'Top' : 'Bottom';
    if (index == 0) return 'Top';
    if (index == total - 1) return 'Bottom';
    if (total == 3) return 'Middle';
    return 'Middle $index';
  }

  static String countLabel({required int index, required int total}) {
    return '${index + 1} of $total';
  }
}
