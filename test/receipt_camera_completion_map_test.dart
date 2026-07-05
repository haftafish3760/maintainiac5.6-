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
    expect(map, contains('2,400 to 3,100 focused camera passes'));
    expect(map, contains('2,750 focused camera passes'));
    expect(map, contains('The final 7-10% must come from real receipt/device'));
  });

  test('release blueprint points future agents to completion map', () {
    final blueprint = File(
      'docs/receipt_camera_release_one_blueprint.md',
    ).readAsStringSync();

    expect(blueprint, contains('docs/receipt_camera_completion_map.md'));
    expect(blueprint, contains('Do not estimate remaining passes'));
  });
}
