import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completion map keeps receipt camera estimates evidence based', () {
    final map = File(
      'docs/receipt_camera_completion_map.md',
    ).readAsStringSync();

    expect(map, contains('Estimating Rules'));
    expect(map, contains('Completion Evidence Table'));
    expect(map, contains('Forecast Method'));
    expect(map, contains('Do not answer "how many passes are left"'));
    expect(map, contains('400 to 550 focused receipt workflow passes'));
    expect(map, contains('450 focused receipt workflow passes'));
    expect(map, contains('Four-Phone Real-Device Proof'));
    expect(map, contains('not generic camera-app work'));
    expect(map, contains('The final 7-10% must come from real receipt/device'));
    expect(map, contains('| Milestone quality gate |'));
    expect(
      map,
      contains(
        'Phase 2 through Phase 9 targeted gates are green, the source/line-count/scope/regression gates are green, and `tool/receipt_camera_qa_gate.sh milestone` passed on 2026-07-07.',
      ),
    );
    expect(
      map,
      contains(
        'Real-device notes are still the remaining gap.',
      ),
    );
    expect(map, contains('| Partial |'));
    expect(map, isNot(contains('| Missing |')));
  });

  test('release blueprint points future agents to completion map', () {
    final blueprint = File(
      'docs/receipt_camera_release_one_blueprint.md',
    ).readAsStringSync();

    expect(blueprint, contains('docs/receipt_camera_completion_map.md'));
    expect(blueprint, contains('Do not estimate remaining passes'));
    expect(blueprint, contains('400-550 focused'));
    expect(blueprint, contains('receipt workflow passes'));
    expect(blueprint, contains('450'));
    expect(blueprint, isNot(contains('1,500-2,500')));
    expect(blueprint, isNot(contains('4,000-pass camera-app')));
  });
}
