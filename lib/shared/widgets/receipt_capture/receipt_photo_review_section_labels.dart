part of 'receipt_photo_review_screen.dart';

class _ReceiptPhotoSectionLabels {
  const _ReceiptPhotoSectionLabels._();

  static String label({required int index, required int total}) {
    if (total <= 1) return 'Photo';
    if (index <= 0) return 'Top Photo';
    if (index >= total - 1) return 'Bottom Photo';
    return 'Middle Photo ${index + 1}';
  }

  static String countLabel({required int index, required int total}) {
    return '${index + 1} of $total';
  }

  static String orderHint({required int index, required int total}) {
    if (total <= 1) return 'One receipt photo';
    if (index <= 0) {
      return 'This should show the top. Retake keeps this spot.';
    }
    if (index >= total - 1) {
      return 'This should show the bottom. Add Next Photo only if the receipt continues.';
    }
    return 'This should continue downward. Retake keeps this middle spot.';
  }

  static String moveEarlierLabel({required int index}) {
    return index <= 1 ? 'Move Toward Top' : 'Move Up';
  }

  static String moveLaterLabel({required int index, required int total}) {
    return index >= total - 2 ? 'Move Toward Bottom' : 'Move Down';
  }

  static String addNextPhotoLabel({required int index, required int total}) {
    return index >= total - 1 ? 'Add Next Photo' : 'Add Missing Photo';
  }

  static String retakeLabel({required int index, required int total}) {
    if (total <= 1) return 'Retake Photo';
    if (index <= 0) return 'Retake Top';
    if (index >= total - 1) return 'Retake Bottom';
    return 'Retake Middle';
  }
}
