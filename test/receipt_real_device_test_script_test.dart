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
  });
}
