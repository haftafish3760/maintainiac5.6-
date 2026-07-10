import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt UI configuration reaches fresh and recovered photo review', () async {
    final flowModels = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_models.dart',
    ).readAsString();
    final freshCapture = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
    ).readAsString();
    final recoveredCapture = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart',
    ).readAsString();
    final cameraActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
    ).readAsString();
    final recoveryActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_recovery_actions.dart',
    ).readAsString();

    expect(flowModels, contains('final ReceiptCaptureUiConfig? uiConfig;'));
    expect(flowModels, contains('uiConfig: options.uiConfig,'));
    expect(freshCapture, contains('options.uiConfig?.review'));
    expect(recoveredCapture, contains('options.uiConfig?.review'));
    expect(cameraActions, contains('uiConfig: widget.uiConfig,'));
    expect(recoveryActions, contains('uiConfig: widget.uiConfig,'));
  });
}
