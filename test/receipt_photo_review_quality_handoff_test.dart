import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review does not convert image guesses into forced capture actions', () async {
    final primaryRow = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    );
    final coverageLabels = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_coverage_decision_labels.dart',
    );
    final captureActions = await _read(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    );

    expect(primaryRow, contains("uiConfig.labelFor('addPhoto'"));
    expect(primaryRow, isNot(contains('Add Bottom Section')));
    expect(
      coverageLabels,
      contains("String get addSectionButtonLabel => 'Add Another Photo'"),
    );
    expect(coverageLabels, isNot(contains('Add Bottom Section')));
    expect(
      captureActions,
      contains('ReceiptImagePicker.takeReceiptPhotoSet()'),
    );
    expect(captureActions, isNot(contains('showAlignmentGuide: false')));
  });

  test('OCR uses prepared full-quality sources before saved proof copies', () async {
    final flow =
        await _read(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
        ) +
        await _read(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_attachment_helpers.dart',
        ) +
        await _read(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
        );
    final actions =
        await _read(
          'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
        ) +
        await _read(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
        );
    expect(flow, contains('result.ocrSourcePhotoPaths[index]'));
    expect(actions, contains('result.ocrSourcePhotoPaths[index]'));
    expect(flow, contains('ocr_reads_clear_source_before_saved_proof'));
    expect(actions, contains('ocr_reads_clear_source_before_saved_proof'));
  });
}

Future<String> _read(String path) => File(path).readAsString();
