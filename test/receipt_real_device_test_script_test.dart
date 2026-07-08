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
    expect(script, contains('phase 2 receipt entry flow'));
    expect(script, contains('phase 3 camera viewer'));
    expect(script, contains('capture photo'));
    expect(script, contains('upload photos'));
    expect(script, contains('upload pdf/file'));
    expect(script, contains('paste/text'));
    expect(script, contains('receipt assist question'));
    expect(script, contains('manual entry remains available'));
    expect(script, contains('no compression, storage, or save-space setup wall'));
    expect(script, contains('camera opens immediately after the choice'));
    expect(script, contains('preview reads as full-screen'));
    expect(script, contains('settings gear'));
    expect(script, contains('torch'));
    expect(script, contains('shutter is round and centered'));
    expect(script, contains('preview tap focus stays off limits'));
  });
}
