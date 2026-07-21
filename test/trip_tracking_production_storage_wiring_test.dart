import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'production trip tracking hands reviewed records to durable storage',
    () {
      final mainSource = File('lib/main.dart').readAsStringSync();

      expect(mainSource, contains('TripTrackingDurableRecordBridge'));
      expect(mainSource, isNot(contains('TripTrackingFirebaseMirror')));
      expect(mainSource, isNot(contains('cloudMirror:')));
    },
  );
}
