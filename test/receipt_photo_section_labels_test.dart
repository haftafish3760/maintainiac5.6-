import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt review uses plain multi-photo wording', () async {
    final labels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final topBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final picker = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
    ).readAsString();
    final importActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();
    final attachmentList = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_list.dart',
    ).readAsString();

    expect(labels, contains("return 'Top Photo'"));
    expect(labels, contains("return 'Bottom Photo'"));
    expect(labels, contains("return 'Middle Photo \${index + 1}'"));
    expect(labels, contains('countLabel'));
    expect(labels, contains('orderHint'));
    expect(labels, contains('moveEarlierLabel'));
    expect(labels, contains('moveLaterLabel'));
    expect(topBar, contains('sectionLabel'));
    expect(topBar, contains('Add Another Photo'));
    expect(topBar, contains('Move Photo Up'));
    expect(topBar, contains('Move Photo Down'));
    expect(controls, isNot(contains('_ReceiptPageOrderActions')));
    expect(controls, contains('class _ReceiptOrderToolControls'));
    expect(controls, contains('_ReceiptPhotoSectionLabels.orderHint'));
    expect(controls, contains('_ReceiptPhotoSectionLabels.moveEarlierLabel'));
    expect(controls, contains('_ReceiptPhotoSectionLabels.moveLaterLabel'));
    expect(picker, contains('pickMultiImage'));
    expect(importActions, contains('_pickAndReviewMultiple'));
    expect(attachmentList, contains('Photos kept in receipt order'));
  });
}
