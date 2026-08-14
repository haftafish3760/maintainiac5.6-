import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'multi-photo review pages photos instead of panning at normal size',
    () async {
      final screen = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      ).readAsString();
      final build = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
      ).readAsString();
      final pager = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_photo_pager.dart',
      ).readAsString();
      final surface = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_photo_surface.dart',
      ).readAsString();

      expect(screen, contains("part 'receipt_photo_review_photo_pager.dart';"));
      expect(build, contains('_buildPhotoReviewPager()'));
      expect(pager, contains('PageView.builder('));
      expect(pager, contains('onPageChanged: (index)'));
      expect(pager, contains('panEnabled: _zoomed'));
      expect(
        pager,
        contains('physics: _photoPreviewZoomed'),
        reason: 'Photo paging must pause while the selected photo is zoomed.',
      );
      expect(surface, contains('panEnabled: _photoPreviewZoomed'));
      expect(build, contains('onPhotoSelected: _selectPhotoForPreview'));
    },
  );

  test(
    'automatic stitch assembly uses a dedicated source-free status surface',
    () async {
      final build = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
      ).readAsString();
      final stitchSurface = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_surface.dart',
      ).readAsString();
      final working = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_widgets.dart',
      ).readAsString();
      final saveActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString();

      expect(saveActions, contains('receiptPhotoPipelineNextStep('));
      expect(saveActions, contains('_savingPhotos = true'));
      expect(
        stitchSurface,
        contains('bool get _automaticStitchAssemblyVisible'),
      );
      expect(
        stitchSurface,
        contains('return const _ReceiptStitchAssemblySurface();'),
      );
      expect(working, contains('class _ReceiptStitchAssemblySurface'));
      expect(working, contains('Checking your receipt photos…'));
      expect(working, isNot(contains('Putting your receipt together…')));
      final controls = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
      ).readAsString();
      final topBar = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
      ).readAsString();
      expect(controls, contains("return 'Checking receipt photos';"));
      expect(controls, isNot(contains('Putting receipt together')));
      expect(topBar, contains("? 'Checking receipt photos'"));
      expect(topBar, isNot(contains('Putting Receipt Together')));
      expect(
        working,
        isNot(contains('Image.file(')),
        reason:
            'The blocking assembly surface must never expose a source photo.',
      );
      expect(
        build,
        contains(
          'else if (showingLongReceiptMatch &&\n'
          '                        _automaticStitchAssemblyVisible)\n'
          '                      const SizedBox.shrink()',
        ),
        reason:
            'Source-photo stitch actions stay hidden during automatic assembly.',
      );
    },
  );

  test(
    'unsafe automatic join keeps the receipt visible and non-blocking',
    () async {
      final screen = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      ).readAsString();
      final build = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
      ).readAsString();
      final stitchActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_actions.dart',
      ).readAsString();

      expect(screen, contains('var _manualAlignmentRequested = false;'));
      expect(build, contains('? _buildPhotoReviewPager()'));
      expect(stitchActions, contains("? 'Try alignment'"));
      expect(stitchActions, contains(": 'Align two photos'"));
      expect(stitchActions, contains(": 'Continue'"));
      expect(
        build,
        contains('fallback: _stitchPreviewResult?.usedFallback == true'),
        reason: 'The action bar receives the current safe-fallback state.',
      );
    },
  );
}
