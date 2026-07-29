import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Calendar jump picker matches the supported record range', () {
    final source = File(
      'lib/shared/calendar/month_year_picker.dart',
    ).readAsStringSync();

    expect(source, contains('int get _firstYear => 1900'));
    expect(source, contains('int get _lastYear => 2100'));
  });
}
