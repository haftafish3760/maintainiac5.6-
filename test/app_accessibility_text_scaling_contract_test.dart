import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app shell preserves the device accessibility text scale', () {
    final source = File('lib/app/maintaniac_app.dart').readAsStringSync();

    expect(source, contains('MaterialApp('));
    expect(source, isNot(contains('MediaQuery.withNoTextScaling')));
    expect(source, isNot(contains('MediaQuery.withClampedTextScaling')));
    expect(source, isNot(contains('TextScaler.noScaling')));
    expect(source, isNot(contains('textScaleFactor:')));
    expect(source, isNot(contains('textScaler:')));
  });
}
