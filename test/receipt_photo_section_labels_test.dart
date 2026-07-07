import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('receipt review uses plain multi-photo wording', () async {
    final labels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final topBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();
    final controls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_thumbnail.dart',
        ).readAsString();
    final picker = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
    ).readAsString();
    final importActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();
    final attachmentList =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_list.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_summary.dart',
        ).readAsString();

    expect(labels, contains("return 'Top Photo'"));
    expect(labels, contains("return 'Bottom Photo'"));
    expect(labels, contains("return 'Middle Photo \${index + 1}'"));
    expect(labels, contains('countLabel'));
    expect(labels, contains('orderHint'));
    expect(labels, contains('moveEarlierLabel'));
    expect(labels, contains('moveLaterLabel'));
    expect(labels, contains("return 'Retake Section \${index + 1}'"));
    expect(topBar, contains('sectionLabel'));
    expect(topBar, contains('Add Another Photo'));
    expect(topBar, contains('Move Photo Up'));
    expect(topBar, contains('Move Photo Down'));
    expect(topBar, contains('_ReceiptPhotoSectionLabels.retakeLabel'));
    expect(topBar, isNot(contains('Retake Current Photo')));
    expect(controls, isNot(contains('_ReceiptPageOrderActions')));
    expect(controls, contains('class _ReceiptOrderToolControls'));
    expect(controls, contains('_ReceiptPhotoSectionLabels.orderHint'));
    expect(controls, contains('_ReceiptPhotoSectionLabels.moveEarlierLabel'));
    expect(controls, contains('_ReceiptPhotoSectionLabels.moveLaterLabel'));
    expect(controls, contains('_ReceiptPhotoSectionLabels.retakeLabel'));
    expect(controls, isNot(contains("label: 'Retake',")));
    expect(picker, contains('pickMultiImage'));
    expect(importActions, contains('_pickAndReviewMultiple'));
    expect(attachmentList, contains('Photos kept in receipt order'));
  });

  test('uploaded receipt image sets preserve selected screenshot order', () {
    final picked = ReceiptPickedPhotoSet.fromFiles([
      XFile(' /tmp/advance-email-top.png '),
      null,
      XFile('   '),
      XFile('/tmp/advance-email-middle.png'),
      XFile('/tmp/advance-email-bottom.png'),
    ]);

    expect(picked.isEmpty, isFalse);
    expect(picked.paths, [
      '/tmp/advance-email-top.png',
      '/tmp/advance-email-middle.png',
      '/tmp/advance-email-bottom.png',
    ]);
    expect(
      () => picked.paths.add('/tmp/advance-email-extra.png'),
      throwsUnsupportedError,
    );
  });
}
