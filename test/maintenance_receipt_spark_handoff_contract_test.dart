import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Spark handoff keeps the 100-pass maintenance wave on a short leash',
    () {
      final handoff = File(
        'docs/maintenance_receipt_spark_handoff.md',
      ).readAsStringSync();

      for (final requirement in [
        '/Users/rbbie/Documents/Maintainiac_5.7_Active',
        'at most 100 accepted passes',
        'Do not begin a 101st Spark pass',
        'A pass is one bounded file/work edit cycle',
        '499 lines or fewer',
        'tool/maintenance_receipt_qa_gate.sh',
        'Duplicate-line cleanup remains OCR-owned',
        'Basic is the default setup mode',
        'Advanced requires explicit selection',
        'minimum release floor is 90%',
        'Zero-tolerance safety failures',
        'Anti-drift audit every 20 Spark passes',
        'Hundred-pass return handoff',
        'Never pre-record a pass',
        'Never count an interrupted gate',
      ]) {
        expect(handoff, contains(requirement), reason: requirement);
      }
    },
  );

  test('Spark handoff forbids unrelated implementation lanes', () {
    final handoff = File(
      'docs/maintenance_receipt_spark_handoff.md',
    ).readAsStringSync();

    for (final forbiddenLane in [
      'camera capture',
      'OCR recognition',
      'device-capability work',
      'trip/GPS tracking',
      'contractor or gig-driver dashboards',
      'Firebase rules',
      'the reusable/shared QA harness',
    ]) {
      expect(handoff, contains(forbiddenLane), reason: forbiddenLane);
    }
  });
}
