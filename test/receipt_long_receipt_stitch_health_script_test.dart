import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('long receipt stitch health script reports focused fixture packs', () {
    final script = File('tool/receipt_long_receipt_stitch_health.sh');
    expect(script.existsSync(), isTrue);

    final source = script.readAsStringSync();
    expect(source, contains('run_pack long_receipt'));
    expect(source, contains('run_pack damaged_ocr'));
    expect(source, contains('--summary-json'));
    expect(source, contains('failedFixtures'));
    expect(source, contains('Receipt long-receipt stitch health: PASS'));
    expect(source, isNot(contains('flutter test')));
    expect(source, isNot(contains('receipt_camera_qa_gate.sh full')));
  });
}
