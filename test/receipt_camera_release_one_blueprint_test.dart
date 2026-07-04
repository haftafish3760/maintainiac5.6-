import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release-one blueprint keeps camera architecture focused', () {
    final blueprint = File(
      'docs/receipt_camera_release_one_blueprint.md',
    ).readAsStringSync();
    final readme = File('README.md').readAsStringSync();
    final projectRules = File('PROJECT_RULES.md').readAsStringSync();
    final masterPlan = File(
      'docs/receipt_camera_ocr_master_pass_plan.md',
    ).readAsStringSync();

    const blueprintPath = 'docs/receipt_camera_release_one_blueprint.md';

    expect(readme, contains(blueprintPath));
    expect(projectRules, contains(blueprintPath));
    expect(masterPlan, contains(blueprintPath));
    expect(blueprint, contains('Release-One Target'));
    expect(blueprint, contains('80-90% solid release-one receipt camera'));
    expect(blueprint, contains('Native Android camera path through CameraX'));
    expect(blueprint, contains('Native iOS camera path through AVFoundation'));
    expect(blueprint, contains('Flutter Capture Orchestrator'));
    expect(blueprint, contains('Retake, Add Photo, Done/Use Receipt'));
    expect(blueprint, contains('Ghost And Overlap Guidance'));
    expect(blueprint, contains('temporary full-quality capture sources'));
    expect(blueprint, contains('compressed proof by default'));
    expect(
      blueprint,
      isNot(contains('preserves the original source captures')),
    );
    expect(blueprint, isNot(contains('original source images survive')));
    expect(blueprint, contains('Optional auto-capture'));
    expect(
      blueprint,
      contains('Android and iOS native paths share the same contract'),
    );
  });
}
