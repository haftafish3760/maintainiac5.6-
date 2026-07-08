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

    expect(
      masterPlan,
      contains('Current active phase: Phase 9, Milestone validation.'),
    );
    expect(
      masterPlan,
      contains('Phase 2 through Phase 8'),
    );
    expect(
      masterPlan,
      contains('targeted gates are green'),
    );
    expect(
      masterPlan,
      contains('active roadmap lane is final parity cleanup'),
    );
    expect(
      masterPlan,
      contains('closing milestone verification bundle'),
    );
    expect(
      masterPlan,
      isNot(contains('Current active phase: Phase 3, Camera viewer.')),
    );

    expect(
      roadmap,
      contains('Active roadmap focus: Phase 9 milestone validation.'),
    );
    expect(
      roadmap,
      contains('Phase 2 through Phase 8 targeted gates are green'),
    );
    expect(
      roadmap,
      contains('Active pass lane. Phase 2 through Phase 9 targeted gates are green.'),
    );
    expect(
      roadmap,
      isNot(
        contains(
          'Active roadmap focus: Phase 3 camera viewer.',
        ),
      ),
    );
  });
}
