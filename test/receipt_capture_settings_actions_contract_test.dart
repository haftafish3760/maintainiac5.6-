import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt settings marks reset as a destructive action', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsStringSync();

    expect(source, contains('backgroundColor: Colors.redAccent'));
    expect(source, contains('foregroundColor: Colors.redAccent'));
    expect(
      source,
      contains('side: const BorderSide(color: Color(0xFFD04A42))'),
    );
    expect(source, contains("child: const Text('Reset Defaults')"));
  });
}
