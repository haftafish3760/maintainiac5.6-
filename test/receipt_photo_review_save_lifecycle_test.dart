import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('photo review save and close actions respect lifecycle state', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final saveActions = await readReceiptPhotoReviewSaveActionsSource();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    expect(saveActions, contains('bool _isStagedReceiptReviewPhoto'));
    expect(saveActions, contains('bool _isPhoneCameraBackupReviewPhoto'));
    expect(
      saveActions,
      contains(
        "diagnostics?['nativeCaptureAttachmentStorageState'] == 'staged'",
      ),
    );
    expect(
      saveActions,
      contains(
        "diagnostics?['nativeCaptureRecoveryAttachmentState'] ==\n            'staged_not_attached'",
      ),
    );
    expect(
      saveActions,
      contains("diagnostics?['phoneCameraBackupUsed'] == true"),
    );
    expect(
      saveActions,
      isNot(contains('return !widget.initialPhotoPaths.contains(photoPath)')),
    );
    expect(
      saveActions,
      contains(
        'receiptPhotoPathSetContains(widget.initialPhotoPaths, photoPath)',
      ),
    );
    expect(
      saveActions,
      contains('if (_closingReview || _confirmingReviewExit) return;'),
    );
    expect(
      saveActions,
      contains('await _deleteGeneratedEditPhotos(_photoPaths.toSet())'),
    );
    expect(saveActions, contains('final generatedPrepArtifacts = <String>{};'));
    expect(saveActions, contains('generatedPrepArtifacts'));
    expect(
      saveActions,
      contains(
        '..add(prepared.backupPath)\n          ..add(prepared.ocrSourcePath)',
      ),
    );
    expect(
      saveActions,
      contains(
        'unawaited(_cleanupFailedReceiptPrepArtifacts(generatedPrepArtifacts))',
      ),
    );
    expect(
      saveActions,
      contains(
        'Future<void> _cleanupFailedReceiptPrepArtifacts(Set<String> paths) async',
      ),
    );
    expect(
      saveActions,
      contains(
        'path.isEmpty || receiptPhotoPathSetContains(_photoPaths, path)',
      ),
    );
    expect(
      saveActions,
      contains('Best effort cleanup for app-created OCR/backup prep files.'),
    );
    expect(
      saveActions,
      isNot(contains('await _deleteGeneratedEditPhotos(const {})')),
    );
    expect(
      saveActions,
      contains('if (picked.paths.isEmpty || !_reviewWorkActive) return;'),
    );
    expect(saveActions, contains('final guidePhotoPath = _photoPaths.isEmpty'));
    expect(saveActions, contains('final guideIndex = _photoPaths.isEmpty'));
    expect(saveActions, contains('final insertPlan = guidePhotoPath == null'));
    expect(saveActions, contains('ReceiptPhotoInsertAfterOrderPlan.build('));
    expect(
      saveActions,
      contains('if (guidePhotoPath != null && insertPlan == null) return;'),
    );
    expect(
      saveActions,
      contains('final targetPhotoPath = _photoPaths[_selectedIndex];'),
    );
    expect(
      saveActions,
      contains('final retakePlan = ReceiptPhotoRetakeOrderPlan.build('),
    );
    expect(saveActions, contains('if (retakePlan == null) return;'));
    expect(saveActions, contains('_selectedIndex = retakePlan.selectedIndex;'));
    expect(
      saveActions,
      contains(
        'final firstPath = picked.paths.first;\n      _replaceCurrentPhotoPath',
      ),
    );
    expect(saveActions, contains('..addAll(retakePlan.photoPaths);'));
    expect(
      saveActions.indexOf(
        'final retakePlan = ReceiptPhotoRetakeOrderPlan.build(',
      ),
      lessThan(saveActions.indexOf('_replaceCurrentPhotoPath')),
    );
    expect(
      saveActions,
      contains('final targetPhotoNumber = _selectedIndex + 1;'),
    );
    expect(
      saveActions,
      contains('final removalPlan = ReceiptPhotoRemovalOrderPlan.build('),
    );
    expect(saveActions, contains('if (removalPlan == null) return;'));
    expect(
      saveActions,
      contains('_selectedIndex = removalPlan.selectedIndex;'),
    );
    expect(
      saveActions,
      isNot(contains('_photoPaths.indexOf(targetPhotoPath)')),
    );
    expect(
      saveActions,
      contains('final currentPathOrderMatches = _sameReceiptPhotoOrder'),
    );
    expect(saveActions, contains('currentPathOrderMatches;'));
    expect(
      saveActions,
      isNot(contains('inputPaths.length == _photoPaths.length')),
    );
    expect(
      saveActions,
      contains('final manualOverlapFractions = currentPathOrderMatches'),
    );
    final manualOverlapSetterBlock = reviewScreen.substring(
      reviewScreen.indexOf('void _setManualOverlapFraction(double value)'),
      reviewScreen.indexOf('void _clearManualOverlapFraction()'),
    );
    expect(manualOverlapSetterBlock, contains('if (!value.isFinite) return;'));
    expect(
      manualOverlapSetterBlock.indexOf('if (!value.isFinite) return;'),
      lessThan(
        manualOverlapSetterBlock.indexOf(
          '_manualOverlapFractions[_selectedStitchPairIndex]',
        ),
      ),
    );
    expect(
      saveActions,
      contains(
        'bool _sameReceiptPhotoOrder(List<String> expected, List<String> current)',
      ),
    );
    expect(
      saveActions,
      contains('static _PickedReceiptPhotos fromNativePhotoPaths'),
    );
    expect(
      saveActions,
      contains('bool _pickedReceiptPhotoPathsAreUnique(List<String> paths)'),
    );
    expect(
      saveActions,
      contains('_pickedReceiptPhotoPathsAreUnique(result.photoPaths)'),
    );
    expect(
      saveActions,
      contains('_pickedReceiptPhotoPathsAreCameraResultMembers('),
    );
    expect(
      saveActions,
      contains('final pickedPaths = _pickedReceiptPhotoUniquePaths(paths);'),
    );
    expect(saveActions, contains('paths: pickedPaths'));
    expect(saveActions, contains('_pickedReceiptDiagnosticsForPaths('));
    expect(saveActions, contains('for (final path in retakeDiagnostics.keys)'));
    expect(
      saveActions,
      isNot(
        contains(
          'if (!retakeDiagnostics.containsKey(entry.key)) entry.key: entry.value',
        ),
      ),
    );
    expect(
      saveActions,
      contains('return uniqueNormalizedReceiptPhotoPaths(paths);'),
    );
    expect(
      saveActions,
      contains('return receiptPhotoPathsAreUniqueAndNormalized(paths);'),
    );
    expect(saveActions, contains('qualityChecksByPath: const {},'));
    expect(
      saveActions,
      isNot(contains('ReceiptImageProcessor.qualityCheckFile(path)')),
    );
    expect(
      saveActions,
      contains(
        'if (_reviewWorkActive) _updateReviewState(() => _openingCamera = false);',
      ),
    );
    expect(saveActions, contains('if (!_reviewWorkActive) return false;'));
    expect(
      saveActions,
      contains(
        'if (!_reviewWorkActive) return _ReceiptContinueDecision.keepReviewing;',
      ),
    );
    expect(reviewScreen, contains('Add Bottom Section'));
    expect(reviewScreen, isNot(contains('Add Bottom First')));
    expect(reviewScreen, isNot(contains('Next If Complete')));
    expect(commonControls, contains("primary: 'Add'"));
    expect(commonControls, contains('Bottom'));
    expect(commonControls, contains("primary: 'Check'"));
    expect(commonControls, contains('Photo Match'));
    expect(saveActions, contains('decision.isMissingBottomEdgeAndTotals'));
    expect(
      saveActions,
      contains(
        'if (!_reviewWorkActive) return _ReceiptReviewExitAction.keepReviewing;',
      ),
    );
    final removeConfirmationBlock = saveActions.substring(
      saveActions.indexOf('Future<bool> _confirmRemoveCurrentPhoto'),
      saveActions.indexOf('Future<void> continueReceiptPhotoReview()'),
    );
    expect(
      removeConfirmationBlock,
      contains('if (!_reviewWorkActive) return false;'),
    );
    expect(
      removeConfirmationBlock.indexOf('if (!_reviewWorkActive) return false;'),
      lessThan(removeConfirmationBlock.indexOf('showModalBottomSheet<bool>')),
    );
    expect(
      removeConfirmationBlock.lastIndexOf(
        'if (!_reviewWorkActive) return false;',
      ),
      greaterThan(
        removeConfirmationBlock.indexOf('showModalBottomSheet<bool>'),
      ),
    );
    expect(saveActions, contains('beginReceiptReviewClose();'));
    expect(saveActions, contains('bool beginReceiptReviewClose()'));
    expect(
      saveActions,
      contains('if (!mounted || _reviewDisposed || _closingReview) {'),
    );
    expect(saveActions, contains('final navigator = Navigator.of(context);'));
    expect(saveActions, contains('if (!mounted || _closingReview) return;'));
    expect(saveActions, contains('_stitchPreviewDebounce?.cancel();'));
    expect(saveActions, contains('_previewKeysInFlight.clear();'));
    expect(saveActions, contains('_qualityCheckKeysInFlight.clear();'));
    expect(saveActions, contains('_dataSaverPreviewKeysInFlight.clear();'));
    expect(saveActions, contains('_beginClosingReviewState(() {'));
    expect(saveActions, contains('_confirmingReviewExit = true;'));
    expect(saveActions, contains('finally {'));
    expect(saveActions, contains('_confirmingReviewExit = false;'));
    expect(
      saveActions,
      isNot(
        contains(
          '_closingReview = true;\n    if (mounted) {\n      _updateReviewState',
        ),
      ),
    );
  });
}
