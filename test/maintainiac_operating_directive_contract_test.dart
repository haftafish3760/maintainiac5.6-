import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('operating directive contract matches production docs', () {
    final primary = File(
      'docs/maintainiac_operating_directive.md',
    ).readAsStringSync();
    final production = File(
      'docs/maintainiac_production_operating_directive.md',
    ).readAsStringSync();

    expect(
      maintainiacOperatingDirectiveContract.validateDocument(primary),
      isEmpty,
    );
    expect(
      maintainiacOperatingDirectiveContract.validateDocument(production),
      isEmpty,
    );
    expect(
      maintainiacOperatingDirectiveContract.toJson().toString(),
      contains('source-of-truth'),
    );
  });

  test('operating directive contract rejects missing production rules', () {
    const weakDoc = '''
Maintainiac is a nice app.
Please write tests sometimes.
''';

    final failures = maintainiacOperatingDirectiveContract
        .validateDocument(weakDoc)
        .join('\n');

    expect(failures, contains('no_build_on_failing_gate'));
    expect(failures, contains('bug_fix_requires_regression'));
    expect(failures, contains('hive_local_source_of_truth'));
    expect(failures, contains('forbidden_private_data'));
  });

  test('operating directive contract protects camera OCR lane boundaries', () {
    final primary = File(
      'docs/maintainiac_operating_directive.md',
    ).readAsStringSync();
    final production = File(
      'docs/maintainiac_production_operating_directive.md',
    ).readAsStringSync();

    expect(
      maintainiacOperatingDirectiveContract.validateDocument(primary),
      isNot(contains(contains('camera_ocr_lane_boundary'))),
    );
    expect(
      maintainiacOperatingDirectiveContract.validateDocument(production),
      isNot(contains(contains('camera_ocr_lane_boundary'))),
    );
    expect(
      maintainiacOperatingDirectiveContract.toJson().toString(),
      contains('camera_ocr_lane_boundary'),
    );
  });
}
