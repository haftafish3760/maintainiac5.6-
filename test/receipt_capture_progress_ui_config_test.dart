import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt read progress is staged and configurable', () async {
    final config = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_ui_config.dart',
    ).readAsString();
    final panel = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    ).readAsString();
    final status = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_status_widgets.dart',
    ).readAsString();
    final reviewRead = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
    ).readAsString();
    final ocr = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    ).readAsString();

    expect(config, contains('bool showReadProgressSteps'));
    expect(config, contains('String progressAcceptedLabel'));
    expect(config, contains('String progressReadingLabel'));
    expect(config, contains('String progressOpeningLabel'));
    expect(config, contains('ReceiptCaptureSettingsUiConfig'));
    expect(config, contains('bool showHelpAction'));
    expect(panel, contains('_ReceiptReadProgressPhase.idle'));
    expect(status, contains('class _ReceiptReadProgressSteps'));
    expect(status, contains('uiConfig.showReadProgressSteps'));
    expect(status, contains('color: index == current'));
    expect(status, contains('index < current'));
    expect(status, isNot(contains('color: index <= current')));
    expect(reviewRead, contains('_ReceiptReadProgressPhase.accepted'));
    expect(ocr, contains('_ReceiptReadProgressPhase.readingText'));
    expect(ocr, contains('_ReceiptReadProgressPhase.openingDetails'));
  });
}
