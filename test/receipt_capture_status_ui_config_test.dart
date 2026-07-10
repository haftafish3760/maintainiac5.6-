import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt read status copy is configurable outside OCR logic', () async {
    final config = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_ui_config.dart',
    ).readAsString();
    final status = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_status_widgets.dart',
    ).readAsString();

    expect(config, contains('readStatusLabelResolver'));
    expect(config, contains('String readStatusLabel('));
    expect(status, contains("'defaultMessage'"));
    expect(status, contains("'\${statusKey}Title'"));
    expect(status, contains("'\${statusKey}RecoveryHint'"));
  });
}
