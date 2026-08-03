import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_long_guidance_sources.dart';

void main() {
  test('long receipt flow uses plain, automatic combining language', () async {
    final sources = await readReceiptLongGuidanceSources();

    expect(sources.reviewPreviewControls, contains('Check Photo Order'));
    expect(
      sources.reviewPreviewControls,
      isNot(contains('strings.matchReceiptPhotos')),
    );
    expect(sources.modeControls, contains("label: 'Align Photos'"));
    expect(sources.modeControls, contains('Align Receipt Photos'));
    expect(
      sources.stitchControls,
      contains('Keep these photos separate for now'),
    );
    expect(sources.stitchControls, contains('retake only the section'));
    expect(sources.reviewControls, contains("return 'Continue';"));
    expect(
      sources.reviewControls,
      contains("return 'Putting receipt together';"),
    );
    expect(
      sources.reviewActions,
      contains('Your receipt photos are still being combined.'),
    );
    expect(sources.reviewActions, contains('_finalStitchResultForOcr'));
    expect(
      sources.reviewActions,
      contains('ReceiptImageProcessor.stitchReceiptPhotosForOcr'),
    );
  });

  test('long receipt capture retains neighbor-aware retake guides', () async {
    final sources = await readReceiptLongGuidanceSources();

    expect(sources.captureActions, contains('previousSectionGuidePhotoPath'));
    expect(sources.captureActions, contains('nextSectionGuidePhotoPath'));
    expect(
      sources.captureActions,
      contains('ReceiptPhotoRetakeAlignmentContext.build('),
    );
    expect(
      sources.nativeGhostGuide,
      contains('previousSectionGuideUsesNextContext'),
    );
    expect(
      sources.nativeGhostGuide,
      contains('next_section_top_context_ghost_at_top_repeat_3_to_5_lines'),
    );
    expect(
      sources.nativeGhostShell,
      contains('Repeat 3-5 lines in this guide'),
    );
  });
}
