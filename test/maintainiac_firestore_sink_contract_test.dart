import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared Firestore sink replaces complete durable documents', () async {
    final source = await File(
      'lib/shared/firebase/maintainiac_firestore_upload_queue.dart',
    ).readAsString();

    expect(source, contains('SetOptions(merge: false)'));
    expect(source, isNot(contains('SetOptions(merge: true)')));
  });
}
