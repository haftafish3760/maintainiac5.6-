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
    expect(map, contains('Exact Physical and Virtual Target Proof'));
    expect(map, contains('remaining repair count cannot be known'));
    expect(map, contains('Do not manufacture a fixed pass count'));
    expect(map, isNot(contains('400 to 550 focused receipt workflow passes')));
    expect(map, isNot(contains('450 focused receipt workflow passes')));
    expect(
      map,
      contains(
        '`tool/receipt_camera_real_device_snapshot.sh` is metadata-only environment',
      ),
    );
    expect(
      map,
      contains('Do not treat that snapshot as receipt capture proof.'),
    );
    expect(
      map,
      contains('Real-device proof\nstill requires manual receipt flows'),
    );
    expect(map, contains('not generic camera-app work'));
    expect(map, contains('The final 7-10% must come from real receipt/device'));
    expect(map, contains('| Milestone quality gate |'));
    expect(
      map,
      contains('Pass 26 closed 374/374 deterministic milestone tests'),
    );
    expect(
      map,
      contains('Passes 29-31 removed first-party iOS compile warnings'),
    );
    expect(map, contains('Physical target rows remain `NOT RUN`'));
    expect(map, contains('tool/receipt_real_device_result_gate.dart'));
    expect(map, contains('docs/receipt_real_device_result_template.md'));
    expect(map, contains('tool/receipt_real_device_result_start.sh'));
    expect(map, contains('| Partial |'));
    expect(map, isNot(contains('| Missing |')));
    expect(map, contains('Deterministic host work is green through Pass 31.'));
    expect(map, contains('Galaxy S24 Ultra'));
    expect(map, contains('Galaxy S25 Ultra'));
    expect(map, contains('Galaxy S9 Plus'));
    expect(map, contains('Constrained Android emulator'));
    expect(map, contains('iPhone SE third generation'));
    expect(map, contains('Future budget Android'));
    expect(map, contains('Record unavailable rows as `NOT RUN`'));
  });

  test('release blueprint points future agents to completion map', () {
    final blueprint = File(
      'docs/receipt_camera_release_one_blueprint.md',
    ).readAsStringSync();

    expect(blueprint, contains('docs/receipt_camera_completion_map.md'));
    expect(blueprint, contains('Do not estimate remaining passes'));
    expect(blueprint, isNot(contains('400-550 focused')));
    expect(blueprint, isNot(contains('450 focused')));
    expect(blueprint, isNot(contains('1,500-2,500')));
    expect(blueprint, isNot(contains('4,000-pass camera-app')));
  });
}
