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

  test('Continue hides every source photo until assembly is terminal', () async {
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

    expect(saveActions, contains('_reviewMode = _ReceiptReviewMode.stitch;'));
    expect(stitchSurface, contains('bool get _automaticStitchAssemblyVisible'));
    expect(
      stitchSurface,
      contains('return const _ReceiptStitchAssemblySurface();'),
    );
    expect(working, contains('class _ReceiptStitchAssemblySurface'));
    expect(working, contains('Putting your receipt together…'));
    expect(
      working,
      isNot(contains('Image.file(')),
      reason: 'The blocking assembly surface must never expose a source photo.',
    );
    expect(
      build,
      contains(
        '_automaticStitchAssemblyVisible)\n                const SizedBox.shrink()',
      ),
      reason:
          'Source-photo stitch actions stay hidden during automatic assembly.',
    );
  });

  test('unsafe automatic join offers explicit recovery choices', () async {
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final build = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
    ).readAsString();
    final stitchSurface = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_surface.dart',
    ).readAsString();
    final widgets = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_widgets.dart',
    ).readAsString();

    expect(screen, contains('var _manualAlignmentRequested = false;'));
    expect(
      stitchSurface,
      contains('preview?.usedFallback == true && !_manualAlignmentRequested'),
    );
    expect(stitchSurface, contains('_ReceiptStitchFailureSurface('));
    expect(widgets, contains("label: const Text('Retake Photos')"));
    expect(widgets, contains("label: const Text('Align Photos Myself')"));
    expect(
      build,
      contains('_stitchPreviewResult?.usedFallback == true &&'),
      reason: 'The old stitch action bar must not duplicate recovery choices.',
    );
  });
}
