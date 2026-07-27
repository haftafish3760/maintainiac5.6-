import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt read status announces live OCR progress accessibly', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_status_widgets.dart',
    ).readAsStringSync();

    expect(source, contains('liveRegion: reading'));
    expect(source, contains("label: '\$title. \$text. \$recoveryHint'"));
    expect(source, contains('container: true'));
  });
}
