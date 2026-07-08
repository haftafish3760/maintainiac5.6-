import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active camera planning docs point to the current viewer lane', () {
    final masterPlan = File(
      'docs/receipt_camera_ocr_master_pass_plan.md',
    ).readAsStringSync();
    final roadmap = File(
      'docs/receipt_camera_roadmap.md',
    ).readAsStringSync();

    expect(
      masterPlan,
      contains('Current active phase: Phase 3, Camera viewer.'),
    );
    expect(
      masterPlan,
      contains('Phase 2 receipt entry flow is'),
    );
    expect(
      masterPlan,
      contains('green on its targeted gate'),
    );
    expect(
      masterPlan,
      contains('the active roadmap lane has moved back'),
    );
    expect(
      masterPlan,
      contains('to viewer behavior'),
    );
    expect(
      masterPlan,
      isNot(contains('Current active phase: Phase 9, Milestone validation')),
    );

    expect(
      roadmap,
      contains('Active roadmap focus: Phase 3 camera viewer.'),
    );
    expect(
      roadmap,
      contains('Phase 2 receipt entry flow is green on its targeted gate'),
    );
    expect(
      roadmap,
      contains('Active pass lane. The Phase 3 targeted gate is green'),
    );
    expect(
      roadmap,
      isNot(
        contains(
          'Active roadmap focus: Phase 6 through Phase 9 non-UI hardening and',
        ),
      ),
    );
  });
}
