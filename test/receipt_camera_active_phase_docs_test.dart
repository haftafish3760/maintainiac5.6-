import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active camera planning docs point to the late validation lane', () {
    final masterPlan = File(
      'docs/receipt_camera_ocr_master_pass_plan.md',
    ).readAsStringSync();
    final roadmap = File(
      'docs/receipt_camera_roadmap.md',
    ).readAsStringSync();

    expect(
      masterPlan,
      contains('Current active phase: Phase 9, Milestone validation'),
    );
    expect(
      masterPlan,
      contains('Phase 2 and Phase 3 source contracts already exist'),
    );
    expect(
      masterPlan,
      contains('current hardening work is proving stitch, OCR-source, storage-proof, and'),
    );
    expect(masterPlan, isNot(contains('Current active phase: Phase 3, Camera viewer.')));

    expect(
      roadmap,
      contains('Active roadmap focus: Phase 6 through Phase 9 non-UI hardening and'),
    );
    expect(
      roadmap,
      contains('Phase 2 receipt entry flow and Phase 3 camera viewer contracts remain part of'),
    );
    expect(
      roadmap,
      contains('Not the active pass lane right now; current work is finishing late non-UI'),
    );
    expect(
      roadmap,
      isNot(contains('Active roadmap focus: Phase 2 receipt entry flow verification, then Phase 3')),
    );
  });
}
