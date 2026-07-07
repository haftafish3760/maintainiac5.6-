import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('photo review async preview work cleans up after lifecycle changes', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final editActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
    ).readAsString();

    expect(reviewScreen, contains('var _reviewDisposed = false;'));
    expect(reviewScreen, contains('_reviewDisposed = true;'));
    expect(reviewScreen, contains('var _reviewWorkGeneration = 0;'));
    expect(reviewScreen, contains('_invalidateReviewAsyncWork();'));
    expect(
      reviewScreen,
      contains('bool _reviewWorkTokenActive(int generation'),
    );
    expect(reviewScreen, contains('generation == _reviewWorkGeneration'));
    expect(editActions, contains('_reviewMode != _ReceiptReviewMode.crop'));
    expect(
      editActions,
      contains('ReceiptImageProcessor.decodeReceiptImageBytes(bytes)'),
    );
    expect(editActions, contains('on FileSystemException'));
    expect(editActions, isNot(contains('img.decodeImage(bytes)')));
    expect(reviewScreen, contains('var _confirmingReviewExit = false;'));
    expect(
      reviewScreen,
      contains('cacheWidth: _reviewPreviewCacheWidth(context)'),
    );
    expect(reviewScreen, contains('filterQuality: FilterQuality.medium'));
    expect(reviewScreen, contains('gaplessPlayback: true'));
    expect(
      reviewScreen,
      contains('unawaited(_deferQualityCheck(photoPath, generation));'),
    );
    expect(reviewScreen, contains('_scheduleDataSaverPreviewWork(photoPath);'));
    expect(
      reviewScreen,
      contains('void _scheduleDataSaverPreviewWork(String photoPath)'),
    );
    expect(
      reviewScreen,
      contains(
        "final workKey = '\${_dataSaverPreviewKey(photoPath)}|dataSaverPreview';",
      ),
    );
    expect(
      reviewScreen,
      contains('_reviewMode != _ReceiptReviewMode.dataSaver'),
    );
    expect(
      reviewScreen,
      contains(
        'unawaited(_ensureDataSaverImagePreview(photoPath, generation));',
      ),
    );
    expect(
      reviewScreen,
      contains(
        'Future<void> _deferQualityCheck(String photoPath, int generation) async',
      ),
    );
    expect(
      reviewScreen,
      contains(
        'await Future<void>.delayed(const Duration(milliseconds: 120));',
      ),
    );
    expect(
      reviewScreen,
      isNot(contains('unawaited(_ensureQualityCheck(photoPath));')),
    );
    expect(
      reviewScreen,
      contains('_ensureQualityCheck(photoPath, generation)'),
    );
    expect(
      reviewScreen,
      contains('_ensureStoragePreview(photoPath, generation)'),
    );
    expect(
      reviewScreen,
      contains('bool _updateReviewState(VoidCallback update)'),
    );
    expect(
      reviewScreen,
      contains('bool _beginClosingReviewState(VoidCallback update)'),
    );
    expect(
      reviewScreen,
      contains(
        'if (!mounted || _reviewDisposed || _closingReview) return false;',
      ),
    );
    expect(reviewScreen, contains('_closingReview = true;'));
    expect(reviewScreen, contains('bool get _reviewWorkActive'));
    expect(
      reviewScreen,
      contains('return mounted && !_reviewDisposed && !_closingReview;'),
    );
    expect(reviewScreen, contains('bool get _reviewInteractiveControlsActive'));
    expect(reviewScreen, contains('_postFrameReviewWorkKeys.clear();'));
    expect(reviewScreen, contains('_dataSaverPreviewKeysInFlight.clear();'));
    expect(
      reviewScreen,
      contains('if (!_reviewWorkActive || _reviewDisposed) return;'),
    );
    expect(
      reviewScreen,
      isNot(
        contains('if (!_reviewWorkActive) _ensureStitchPreview(force: true);'),
      ),
    );
    expect(
      reviewScreen,
      contains('if (_reviewWorkActive) _ensureStitchPreview(force: true);'),
    );
    expect(
      reviewScreen,
      contains('void _releaseStaleStitchPreview(String key)'),
    );
    expect(reviewScreen, contains('void _selectStitchPairIndex(int index)'));
    expect(reviewScreen, contains('if (!_reviewInteractiveControlsActive) return;'));
    expect(
      reviewScreen,
      contains(
        'final selected = maxPairIndex < 0 ? 0 : index.clamp(0, maxPairIndex);',
      ),
    );
    expect(reviewScreen, contains('if (_selectedStitchPairIndex < 0)'));
    expect(
      reviewScreen,
      isNot(
        contains(
          'onStitchPairSelected: (index) =>\n          _updateReviewState(() => _selectedStitchPairIndex = index)',
        ),
      ),
    );
    expect(
      reviewScreen,
      contains('onStitchPairSelected: _selectStitchPairIndex'),
    );
    expect(
      reviewScreen,
      contains('_releaseStaleStitchPreview(key);\n        return;'),
    );
    expect(
      reviewScreen,
      contains('await _deleteStitchPreviewPath(previousPreviewPath);'),
    );
    expect(reviewScreen, contains("fallbackReasonCode: 'stitch_exception'"));
    expect(
      reviewScreen,
      contains(
        '_stitchPreviewInFlight = false;\n    });\n    _scheduleStitchPreviewRefresh();',
      ),
    );
    expect(
      reviewScreen,
      contains('if (!_reviewWorkTokenActive(generation, photoPath))'),
    );
    expect(
      reviewScreen,
      contains('!_dataSaverPreviewKeysInFlight.contains(key)'),
    );
    expect(reviewScreen, contains('!_photoPaths.contains(photoPath)'));
    expect(
      reviewScreen,
      contains(
        'await _deleteDataSaverPreviewPath(previewPath, sourcePath: photoPath)',
      ),
    );
    expect(reviewScreen, contains('keepRetained = true'));
    expect(
      reviewScreen,
      contains('await _deleteDataSaverPreviewPath(path, keepRetained: false)'),
    );
    expect(editActions, contains('if (!_reviewInteractiveControlsActive)'));
    expect(editActions, contains('await _deleteDataSaverPreviewPath(path);'));
    expect(editActions, contains('if (!_reviewWorkActive) return;'));
    expect(editActions, contains('final replacedGeneratedEdit'));
    expect(
      editActions,
      contains(
        'previousPath != path && _generatedEditPaths.contains(previousPath)',
      ),
    );
    expect(
      editActions,
      contains('unawaited(_deleteGeneratedEditPhotos(_photoPaths.toSet()))'),
    );
  });
}
