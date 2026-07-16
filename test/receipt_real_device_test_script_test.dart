import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real device script includes four-phone receipt workflow matrix', () {
    final script = File(
      'docs/receipt_real_device_test_script.md',
    ).readAsStringSync().toLowerCase();

    expect(script, contains('galaxy s9 plus'));
    expect(script, contains('galaxy s24/s25'));
    expect(script, contains('second available android device'));
    expect(script, contains('additional android'));
    expect(script, contains('iphone'));
    expect(script, contains('receipt flow'));
    expect(script, isNot(contains('pro camera')));
    expect(script, contains('capture photo'));
    expect(script, contains('upload photos'));
    expect(script, contains('upload pdf/file'));
    expect(script, contains('paste/text'));
    expect(script, contains('receipt assist question'));
    expect(script, contains('manual entry remains available'));
    expect(script, contains('no compression, storage, or save-space setup wall'));
    expect(script, contains("phone's system camera opens immediately after the choice"));
    expect(script, contains('system camera handoff proof'));
    expect(script, contains('returns to full-screen photo review'));
    expect(script, contains('settings gear'));
    expect(script, contains('phone owns focus, light, zoom, and shutter controls'));
    expect(script, contains('no custom maintainiac camera viewer replaces the system camera'));
    expect(script, contains('reference photo is shown before each extra capture'));
    expect(script, isNot(contains('prove pdf receipts are handled safely')));
    expect(script, isNot(contains('pdf import is bounded and proof-safe')));
  });
}
