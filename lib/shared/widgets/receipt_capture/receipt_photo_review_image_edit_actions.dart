part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewImageEditActions
    on _ReceiptPhotoReviewScreenState {
  Future<void> _ensureCropBytesLoaded(String photoPath) async {
    if (_cropSourcePath == photoPath) {
      if (_cropImageBytes != null && _cropImageSize != null) return;
      if (_cropLoadInFlightPath == photoPath) return;
    }
    _cropSourcePath = photoPath;
    _cropLoadInFlightPath = photoPath;
    _cropImageBytes = null;
    _cropImageSize = null;
    _cropRect = null;
    _cropDisplayRect = null;
    _suggestedCropNormalized = null;
    _straightenControlsVisible = false;
    _straightenAngleDegrees = 0;
    try {
      Uint8List bytes;
      try {
        bytes = await File(photoPath).readAsBytes();
      } on FileSystemException {
        bytes = Uint8List(0);
      }
      final decoded = ReceiptImageProcessor.decodeReceiptImageBytes(bytes);
      if (!_reviewWorkActive ||
          _reviewMode != _ReceiptReviewMode.crop ||
          _cropSourcePath != photoPath) {
        return;
      }
      if (decoded == null) {
        _showCameraError(
          'This receipt photo could not be loaded for cropping.',
        );
        _updateReviewState(() {
          _reviewMode = _ReceiptReviewMode.preview;
          _cropSourcePath = null;
        });
        return;
      }
      final autoCropSuggestionEnabled =
          _captureDiagnosticsByPath[photoPath]?['autoCropSuggestionEnabled'] !=
          false;
      _updateReviewState(() {
        _cropImageBytes = bytes;
        _cropImageSize = Size(
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        );
        _suggestedCropNormalized = autoCropSuggestionEnabled
            ? ReceiptImageProcessor.suggestReceiptCropNormalizedForDecodedImage(
                decoded,
              )
            : null;
      });
    } finally {
      if (_cropLoadInFlightPath == photoPath) {
        _cropLoadInFlightPath = null;
      }
    }
  }

  void _setReviewMode(_ReceiptReviewMode mode) {
    if ((mode == _ReceiptReviewMode.order ||
            mode == _ReceiptReviewMode.stitch) &&
        _photoPaths.length <= 1) {
      return;
    }
    if (_reviewMode == mode) {
      _resetToolControlsScrollPosition();
      return;
    }
    _resetPhotoPreviewZoom();
    _updateReviewState(() {
      _reviewMode = mode;
      _dataSaverOptionsVisible = mode == _ReceiptReviewMode.dataSaver;
      if (mode == _ReceiptReviewMode.stitch) {
        // Matching is automatic. Manual overlap is recovery only, after the
        // user can see the automatic result.
        _stitchPreviewRequested = true;
      } else {
        _stitchPreviewRequested = false;
        _manualAlignmentRequested = false;
      }
    });
    if (mode == _ReceiptReviewMode.stitch) {
      unawaited(_ensureStitchPreview(force: true));
    }
    _resetToolControlsScrollPosition();
  }

  void _resetToolControlsScrollPosition() {
    if (!_reviewInteractiveControlsActive ||
        !_toolControlsScrollController.hasClients) {
      return;
    }
    _toolControlsScrollController.jumpTo(
      _toolControlsScrollController.position.minScrollExtent,
    );
  }

  Future<void> _applyCrop() async {
    if (_cropProcessing) {
      return;
    }
    final bytes = _cropImageBytes;
    final displayRect = _cropDisplayRect;
    final cropRect = _cropRect;
    if (bytes == null ||
        _cropImageSize == null ||
        displayRect == null ||
        cropRect == null) {
      _showCameraError('Crop is still getting this receipt photo ready.');
      return;
    }
    final editTarget = ReceiptPhotoEditTarget.capture(
      photoPaths: _photoPaths,
      selectedIndex: _selectedIndex,
    );
    if (editTarget == null || _cropSourcePath != editTarget.photoPath) {
      _showCameraError('This crop no longer matches the selected photo.');
      return;
    }
    _updateReviewState(() => _cropProcessing = true);
    String? generatedPath;
    try {
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.savePhotos,
      );
      if (!_reviewWorkActive) return;
      if (_reviewMode != _ReceiptReviewMode.crop) {
        _updateReviewState(() => _cropProcessing = false);
        return;
      }
      if (!storage.hasEnoughSpace) {
        _updateReviewState(() => _cropProcessing = false);
        await _showStorageDialog(
          storage.blockingMessage(ReceiptStoragePurpose.savePhotos),
        );
        return;
      }
      if (!storage.canVerify) {
        _showCameraError(
          storage.unknownMessage(ReceiptStoragePurpose.savePhotos),
        );
      } else if (storage.shouldWarnLowStorage) {
        _showCameraError(storage.warningMessage());
      }
      final path = await ReceiptImageProcessor.cropFile(
        bytes: bytes,
        displayImageRect: displayRect,
        cropRect: cropRect,
      );
      generatedPath = path;
      final quality = await ReceiptImageProcessor.qualityCheckFile(path);
      if (!_reviewWorkActive ||
          !_cropProcessing ||
          _reviewMode != _ReceiptReviewMode.crop ||
          _cropSourcePath != editTarget.photoPath ||
          !editTarget.stillOwns(
            photoPaths: _photoPaths,
            selectedIndex: _selectedIndex,
          )) {
        await _deleteUnacceptedPhotoEdit(path);
        return;
      }
      _updateReviewState(() {
        _generatedEditPaths.add(path);
        _replaceCurrentPhotoPath(path, quality, editAction: 'manual_crop');
        _cropProcessing = false;
      });
      _setReviewMode(_ReceiptReviewMode.preview);
      _invalidateStitchPreview();
    } catch (_) {
      if (!_reviewWorkActive) return;
      _updateReviewState(() => _cropProcessing = false);
      _showCameraError('Could not crop this receipt photo.');
    } finally {
      if (generatedPath != null &&
          !_generatedEditPaths.contains(generatedPath)) {
        await _deleteUnacceptedPhotoEdit(generatedPath);
      }
    }
  }

  Future<void> _rotateCurrentPhoto(num degrees) async {
    if (_cropProcessing || _savingPhotos) return;
    final editTarget = ReceiptPhotoEditTarget.capture(
      photoPaths: _photoPaths,
      selectedIndex: _selectedIndex,
    );
    if (editTarget == null) return;
    _updateReviewState(() => _cropProcessing = true);
    String? generatedPath;
    try {
      final storage = await ReceiptStorageGuard.check(
        ReceiptStoragePurpose.savePhotos,
      );
      if (!_reviewWorkActive) return;
      if (!storage.hasEnoughSpace) {
        _updateReviewState(() => _cropProcessing = false);
        await _showStorageDialog(
          storage.blockingMessage(ReceiptStoragePurpose.savePhotos),
        );
        return;
      }
      if (!storage.canVerify) {
        _showCameraError(
          storage.unknownMessage(ReceiptStoragePurpose.savePhotos),
        );
      } else if (storage.shouldWarnLowStorage) {
        _showCameraError(storage.warningMessage());
      }
      if (!editTarget.stillOwns(
        photoPaths: _photoPaths,
        selectedIndex: _selectedIndex,
      )) {
        _updateReviewState(() => _cropProcessing = false);
        return;
      }
      final currentPath = editTarget.photoPath;
      final path = await ReceiptImageProcessor.rotateFile(
        path: currentPath,
        degrees: degrees,
      );
      generatedPath = path;
      final quality = await ReceiptImageProcessor.qualityCheckFile(path);
      if (!_reviewWorkActive ||
          !_cropProcessing ||
          !editTarget.stillOwns(
            photoPaths: _photoPaths,
            selectedIndex: _selectedIndex,
          )) {
        await _deleteUnacceptedPhotoEdit(path);
        return;
      }
      _updateReviewState(() {
        _generatedEditPaths.add(path);
        _replaceCurrentPhotoPath(path, quality, editAction: 'manual_rotate');
        _straightenControlsVisible = false;
        _straightenAngleDegrees = 0;
        _cropProcessing = false;
      });
      _invalidateStitchPreview();
    } catch (_) {
      if (!_reviewWorkActive) return;
      _updateReviewState(() => _cropProcessing = false);
      _showCameraError('Could not straighten this receipt photo.');
    } finally {
      if (generatedPath != null &&
          !_generatedEditPaths.contains(generatedPath)) {
        await _deleteUnacceptedPhotoEdit(generatedPath);
      }
    }
  }

  void _toggleStraightenControls() {
    if (_cropProcessing || _savingPhotos) return;
    _updateReviewState(() {
      _straightenControlsVisible = !_straightenControlsVisible;
      if (!_straightenControlsVisible) _straightenAngleDegrees = 0;
    });
  }

  void _setStraightenAngle(double degrees) {
    if (_cropProcessing || !_straightenControlsVisible) return;
    _updateReviewState(
      () => _straightenAngleDegrees = degrees.clamp(-5.0, 5.0),
    );
  }

  Future<void> _applyStraightenAdjustment() async {
    if (_cropProcessing || !_straightenControlsVisible) return;
    final degrees = _straightenAngleDegrees;
    if (degrees.abs() < .05) {
      _updateReviewState(() {
        _straightenControlsVisible = false;
        _straightenAngleDegrees = 0;
      });
      return;
    }
    await _rotateCurrentPhoto(degrees);
  }

  Future<void> _deleteUnacceptedPhotoEdit(String path) async {
    await const ReceiptTemporaryArtifactCleanup().deleteAppOwnedFiles({
      path,
    }, keptPaths: _photoPaths);
  }

  void _resetCrop() {
    final displayRect = _cropDisplayRect;
    if (displayRect == null) return;
    _updateReviewState(() => _cropRect = displayRect);
  }

  void _cancelCropReview() {
    _updateReviewState(() {
      _cropProcessing = false;
      _cropSourcePath = null;
      _cropLoadInFlightPath = null;
      _cropImageBytes = null;
      _cropImageSize = null;
      _cropRect = null;
      _cropDisplayRect = null;
      _suggestedCropNormalized = null;
      _straightenControlsVisible = false;
      _straightenAngleDegrees = 0;
    });
    _setReviewMode(_ReceiptReviewMode.preview);
  }

  void _replaceCurrentPhotoPath(
    String path,
    ReceiptPhotoQualityCheck? quality, {
    String? editAction,
  }) {
    final previousPath = _photoPaths[_selectedIndex];
    final replacedGeneratedEdit =
        previousPath != path && _generatedEditPaths.contains(previousPath);
    final previousCaptureDiagnostics = _captureDiagnosticsByPath[previousPath];
    final staleDataSaverPreviewPaths = _removePhotoReviewCachesForPath(
      previousPath,
    );
    _photoPaths[_selectedIndex] = path;
    if (quality != null) _qualityChecksByPath[path] = quality;
    if (previousCaptureDiagnostics != null) {
      final updatedDiagnostics = {...previousCaptureDiagnostics};
      if (editAction != null) {
        updatedDiagnostics['userEditedPhoto'] = true;
        updatedDiagnostics['photoEditAction'] = editAction;
        updatedDiagnostics['photoEditReplacedOriginal'] = previousPath != path;
      }
      _captureDiagnosticsByPath[path] = updatedDiagnostics;
    }
    unawaited(_deleteStaleDataSaverPreviewFiles(staleDataSaverPreviewPaths));
    if (replacedGeneratedEdit) {
      unawaited(_deleteGeneratedEditPhotos(_photoPaths.toSet()));
    }
    _cropSourcePath = null;
    _cropLoadInFlightPath = null;
    _cropImageBytes = null;
    _cropImageSize = null;
    _cropRect = null;
    _cropDisplayRect = null;
    _suggestedCropNormalized = null;
    _straightenControlsVisible = false;
    _straightenAngleDegrees = 0;
  }

  Set<String> _removePhotoReviewCachesForPath(String photoPath) {
    final staleDataSaverPreviewPaths = _dataSaverPreviewPaths.entries
        .where((entry) => entry.key.startsWith('$photoPath::'))
        .map((entry) => entry.value)
        .toSet();
    _qualityChecksByPath.remove(photoPath);
    _captureDiagnosticsByPath.remove(photoPath);
    _reviewDecisionState.evictPhotoPath(photoPath);
    _stitchTextEvidenceByPath.remove(photoPath);
    _storagePreviews.removeWhere((key, _) => key.startsWith('$photoPath|'));
    _previewKeysInFlight.removeWhere((key) => key.startsWith('$photoPath|'));
    _dataSaverPreviewPaths.removeWhere(
      (key, _) => key.startsWith('$photoPath::'),
    );
    _dataSaverPreviewKeysInFlight.removeWhere(
      (key) => key.startsWith('$photoPath::'),
    );
    return staleDataSaverPreviewPaths;
  }

  Future<void> _deleteStaleDataSaverPreviewFiles(Set<String> paths) async {
    for (final path in paths) {
      await _deleteDataSaverPreviewPath(path);
    }
  }
}
