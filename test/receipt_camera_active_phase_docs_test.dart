import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active camera planning docs point to the current validation lane', () {
    final masterPlan = File(
      'docs/receipt_camera_ocr_master_pass_plan.md',
    ).readAsStringSync();
    final roadmap = File(
      'docs/receipt_camera_roadmap.md',
    ).readAsStringSync();

    expect(masterPlan, contains('Current active phase: Phase 2, Receipt entry flow.'));
    expect(
      masterPlan,
      contains('Phase 3 camera viewer work follows'),
    );
    expect(
      masterPlan,
      contains('Existing targeted gates remain guardrails'),
    );
    expect(
      masterPlan,
      contains('compact source chooser'),
    );
    expect(
      masterPlan,
      contains('single Receipt Assist question'),
    );
    expect(
      masterPlan,
      contains('not override the current roadmap order'),
    );
    expect(
      masterPlan,
      isNot(contains('Current active phase: Phase 9, Milestone validation.')),
    );

    expect(
      roadmap,
      contains('Active roadmap focus: Phase 2 receipt entry flow.'),
    );
    expect(
      roadmap,
      contains('Current next work: finish the clean Add Receipt entry path first'),
    );
    expect(
      roadmap,
      contains('Active pass lane. Phase 2 receipt entry flow is the current bundle'),
    );
    expect(
      roadmap,
      isNot(
        contains(
          'Active roadmap focus: Phase 9 milestone validation.',
        ),
      ),
    );
  });
}
