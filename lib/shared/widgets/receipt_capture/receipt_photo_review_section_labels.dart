part of 'receipt_photo_review_screen.dart';

class _ReceiptPhotoSectionLabels {
  const _ReceiptPhotoSectionLabels._();

  static const sectionHeader = 'Receipt Sections';

  static String label({required int index, required int total}) {
    if (total <= 1) return 'Photo';
    if (index <= 0) return 'Top Photo';
    if (index >= total - 1) return 'Bottom Photo';
    return 'Middle Photo ${index + 1}';
  }

  static String countLabel({required int index, required int total}) {
    return '${index + 1} of $total';
  }

  static String sectionNumberLabel({required int index, required int total}) {
    return 'Section ${index + 1} of $total';
  }

  static String orderedStripHint({
    required int selectedIndex,
    required int total,
  }) {
    if (total <= 1) {
      return 'If the receipt continues below this photo, add the next section.';
    }
    final selected = sectionNumberLabel(index: selectedIndex, total: total);
    return '$selected selected. Photo 1 must be the top; every next photo should continue lower with 3-5 repeated readable lines.';
  }

  static String selectedReviewGuidance({
    required int selectedIndex,
    required int total,
  }) {
    if (total <= 1) {
      return 'If the receipt continues, add another photo. Otherwise use this photo.';
    }
    final selected = sectionNumberLabel(index: selectedIndex, total: total);
    if (selectedIndex <= 0) {
      return '$selected selected. This should be the top of the receipt. Add another photo if the receipt continues, or use Order if the sections are mixed up.';
    }
    if (selectedIndex >= total - 1) {
      return '$selected selected. This should be the bottom of the receipt. Use Match Photos before using these photos so repeated lines are checked.';
    }
    return '$selected selected. This should continue downward with 3-5 repeated readable lines from the previous photo. Use Order or Match Photos if anything looks out of place.';
  }

  static String selectedReviewAction({
    required int selectedIndex,
    required int total,
  }) {
    if (total <= 1) return 'Add another photo only if the receipt continues.';
    if (selectedIndex <= 0) return 'Confirm top section, then add or order.';
    if (selectedIndex >= total - 1) {
      return 'Confirm bottom section, then match.';
    }
    return 'Confirm middle section, then match.';
  }

  static String addNextSectionLabel({required int total}) {
    return total <= 1 ? 'Add Another Photo' : 'Add Next Receipt Photo';
  }

  static String orderHint({required int index, required int total}) {
    if (total <= 1) return 'One receipt photo';
    if (index <= 0) {
      return 'This should show the top. Retake keeps this spot.';
    }
    if (index >= total - 1) {
      return 'This should show the bottom. Add Another Photo only if the receipt continues.';
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
    return index >= total - 1 ? 'Add Next Receipt Photo' : 'Add Missing Photo';
  }

  static String retakeLabel({required int index, required int total}) {
    if (total <= 1) return 'Retake Photo';
    return 'Retake Section ${index + 1}';
  }

  static String retakeSemanticLabel({required int index, required int total}) {
    final section = sectionNumberLabel(index: index, total: total);
    if (total <= 1) return 'Retake receipt photo';
    if (index <= 0) return 'Retake $section, the top receipt photo';
    if (index >= total - 1) return 'Retake $section, the bottom receipt photo';
    return 'Retake $section, a middle receipt photo';
  }
}
