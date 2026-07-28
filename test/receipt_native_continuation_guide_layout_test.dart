import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native continuation guide stays compact, readable, and dismissible', () {
    final source = File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraPreviousSectionGuide.kt',
    ).readAsStringSync();

    expect(source, contains('dp(84)'));
    expect(source, contains('text = "Hide"'));
    expect(source, contains('Hide receipt overlap guide'));
    expect(
      source,
      contains('setOnClickListener { previousSectionGuidePanel.visibility = View.GONE }'),
    );
    expect(source, contains('Repeat 3–5 readable lines in this guide.'));
    expect(source, contains('dp(22)'));
    expect(source, contains('coerceIn(0.0, 1.0).toFloat()'));
  });
}
