import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('real-device receipt script covers platform and environment matrix', () {
    final script = File(
      'docs/receipt_real_device_test_script.md',
    ).readAsStringSync().toLowerCase();

    for (final requiredText in [
      'galaxy s9 plus class device',
      'galaxy s24/s25 class device',
      'pixel/motorola/oneplus class android device',
      'iphone se class device',
      'not samsung-only',
      'bright indoor light',
      'dim indoor light',
      'glare from overhead light or window',
      'shadow across the bottom totals section',
      'wrinkled or curled receipt',
      'app switch while a draft receipt is staged',
      'lock screen and resume before saving',
      'low-storage warning or storage-saver mode',
      'continuous autofocus/readability guidance',
    ]) {
      expect(script, contains(requiredText));
    }
  });
}
