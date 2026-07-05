import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project rules ban rebuilding a pro camera for receipt capture', () {
    final rules = File('PROJECT_RULES.md').readAsStringSync().toLowerCase();

    expect(rules, contains('receipt camera native-baseline rule'));
    expect(rules, contains('not a general camera app'));
    expect(rules, contains('platform-native camera stack as the baseline'));
    expect(rules, contains('maintainiac owns the receipt workflow'));
    expect(rules, contains('screen-tap focus'));
    expect(rules, contains('preview/screen tap focus remains off'));
    expect(rules, contains('limits'));
    expect(rules, isNot(contains('tap-to-focus')));
  });

  test('camera completion map keeps native baseline inside scope', () {
    final map = File(
      'docs/receipt_camera_completion_map.md',
    ).readAsStringSync().toLowerCase();

    expect(map, contains('platform-native camera stack as the baseline'));
    expect(map, contains('native camera baseline'));
    expect(map, contains('replacing samsung, google, apple'));
    expect(map, contains('manual lens-distance controls'));
  });

  test('product standard forbids pro-camera controls as normal receipt UI', () {
    final standard = File(
      'docs/receipt_camera_ocr_product_standard.md',
    ).readAsStringSync().toLowerCase();

    expect(standard, contains('not a pro camera replacement'));
    expect(standard, contains('normal autofocus'));
    expect(standard, contains('still-capture behavior'));
    expect(standard, contains('must not expose iso'));
    expect(standard, contains('manual lens-distance controls'));
  });
}
