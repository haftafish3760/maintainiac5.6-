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
      contains('Current active phases: 2 through 6, the system-managed capture'),
    );
    expect(
      masterPlan,
      contains("phone's normal camera"),
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
      contains('first-use Receipt Assist question'),
    );
    expect(
      masterPlan,
      contains('roadmap order or real-device proof requirement'),
    );
    expect(
      masterPlan,
      isNot(contains('Current active phase: Phase 9, Milestone validation.')),
    );

    expect(
      roadmap,
      contains('Active roadmap focus: the system-managed capture through long-receipt review'),
    );
    expect(
      roadmap,
      contains("Capture uses the phone's normal rear-camera experience"),
    );
    expect(
      roadmap,
      contains('System-managed camera capture'),
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
