import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('world-class readiness stays current-state based instead of stale pass snapshots', () {
    final readiness = File(
      'docs/receipt_camera_world_class_readiness.md',
    ).readAsStringSync();

    expect(
      readiness,
      contains('not "nearly done" against the full world-class receipt'),
    );
    expect(
      readiness,
      contains('late synthetic QA, real-device receipt proof, and release-build measurement'),
    );
    expect(
      readiness,
      contains('Any source-footprint number in this lane must come from a fresh current audit'),
    );
    expect(
      readiness,
      contains('not installed app-size guarantees'),
    );
    expect(readiness, isNot(contains('As of Pass 410')));
    expect(readiness, isNot(contains('closer to the first quarter of the full scope')));
    expect(readiness, isNot(contains('at about 1.68 MB')));
  });
}
