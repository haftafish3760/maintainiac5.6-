part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewAsyncWork on _ReceiptPhotoReviewScreenState {
  bool _updateReviewState(VoidCallback update) {
    if (!_reviewWorkActive) return false;
    return _setPhotoReviewState(update);
  }

  bool get _reviewInteractiveControlsActive {
    // Stitch controls live outside the optional scrolling edit toolbar. Tying
    // all interaction to that controller made every visible manual alignment
    // control silently inert in long-receipt mode.
    return _reviewWorkActive;
  }

  bool _beginClosingReviewState(VoidCallback update) {
    if (!mounted || _reviewDisposed || _closingReview) return false;
    return _setPhotoReviewState(() {
      _closingReview = true;
      _invalidateReviewAsyncWork();
      update();
    });
  }

  bool get _reviewWorkActive {
    return mounted && !_reviewDisposed && !_closingReview;
  }

  void _invalidateReviewAsyncWork() {
    _reviewWorkGeneration++;
  }

  bool _reviewWorkTokenActive(int generation, [String? photoPath]) {
    return _reviewWorkActive &&
        generation == _reviewWorkGeneration &&
        (photoPath == null || _photoPaths.contains(photoPath));
  }

  Future<void> _ensureStoragePreview(String photoPath, int generation) async {
    final key = _previewKey(photoPath);
    if (_storagePreviews.containsKey(key) ||
        _previewKeysInFlight.contains(key)) {
      return;
    }
    _previewKeysInFlight.add(key);
    try {
      // This screen previews the proof the person selected. Applying scanner
      // cleanup here can wash out thermal paper and make the preview look
      // unrelated to the receipt they just reviewed.
      final preview = await ReceiptImageProcessor.previewFile(
        path: photoPath,
        level: _dataSaverLevel,
      );
      if (!_reviewWorkTokenActive(generation) ||
          !_previewKeysInFlight.contains(key)) {
        return;
      }
      _updateReviewState(() => _storagePreviews[key] = preview);
    } catch (_) {
      if (!_reviewWorkActive) return;
    } finally {
      _previewKeysInFlight.remove(key);
    }
  }

  String _previewKey(String photoPath) => '$photoPath|${_dataSaverLevel.name}';

  void _schedulePostFrameReviewWork(String photoPath) {
    if (_qualityChecksByPath.containsKey(photoPath) ||
        _qualityCheckKeysInFlight.contains(photoPath)) {
      return;
    }
    final workKey = '$photoPath|quality';
    if (_postFrameReviewWorkKeys.contains(workKey)) return;
    _postFrameReviewWorkKeys.add(workKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final generation = _reviewWorkGeneration;
      if (!_reviewWorkTokenActive(generation, photoPath)) {
        _postFrameReviewWorkKeys.remove(workKey);
        return;
      }
      // Quality feedback must never hold up capture, photo review, or the
      // clear proof image. Run it after the screen is visible and ignore it if
      // the person has already moved on.
      unawaited(
        _deferQualityCheck(
          photoPath,
          generation,
        ).whenComplete(() => _postFrameReviewWorkKeys.remove(workKey)),
      );
    });
  }

  Future<void> _deferQualityCheck(String photoPath, int generation) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!_reviewWorkTokenActive(generation, photoPath)) return;
    await _ensureQualityCheck(photoPath, generation);
  }

  Future<void> _ensureQualityCheck(String photoPath, int generation) async {
    if (_qualityChecksByPath.containsKey(photoPath) ||
        _qualityCheckKeysInFlight.contains(photoPath)) {
      return;
    }
    _qualityCheckKeysInFlight.add(photoPath);
    try {
      final quality = await ReceiptImageProcessor.qualityCheckFile(photoPath);
      if (!_reviewWorkTokenActive(generation, photoPath) ||
          !_qualityCheckKeysInFlight.contains(photoPath) ||
          !_photoPaths.contains(photoPath)) {
        return;
      }
      _updateReviewState(() => _qualityChecksByPath[photoPath] = quality);
    } catch (_) {
      // Review stays usable if a background check cannot read a photo.
    } finally {
      _qualityCheckKeysInFlight.remove(photoPath);
    }
  }

  void _scheduleDataSaverPreviewWork(String photoPath) {
    final workKey = '${_dataSaverPreviewKey(photoPath)}|dataSaverPreview';
    if (_postFrameReviewWorkKeys.contains(workKey)) return;
    _postFrameReviewWorkKeys.add(workKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameReviewWorkKeys.remove(workKey);
      final generation = _reviewWorkGeneration;
      if (!_reviewWorkTokenActive(generation) ||
          _reviewMode != _ReceiptReviewMode.dataSaver) {
        return;
      }
      unawaited(_ensureStoragePreview(photoPath, generation));
      unawaited(_ensureDataSaverImagePreview(photoPath, generation));
    });
  }

  Map<String, ReceiptPhotoQualityCheck> _initialQualityChecksByPath() {
    final checks = <String, ReceiptPhotoQualityCheck>{};
    for (final entry in widget.initialQualityChecksByPath.entries) {
      final normalizedPath = normalizedReceiptPhotoPath(entry.key);
      if (normalizedPath == null ||
          !receiptPhotoPathSetContains(_initialPhotoPaths, normalizedPath) ||
          checks.containsKey(normalizedPath)) {
        continue;
      }
      checks[normalizedPath] = entry.value;
    }
    final count = _initialPhotoPaths.length < widget.initialQualityChecks.length
        ? _initialPhotoPaths.length
        : widget.initialQualityChecks.length;
    for (var index = 0; index < count; index++) {
      if (checks.containsKey(_initialPhotoPaths[index])) continue;
      checks[_initialPhotoPaths[index]] = widget.initialQualityChecks[index];
    }
    return checks;
  }

  Future<void> _ensureDataSaverImagePreview(
    String photoPath,
    int generation,
  ) async {
    final key = _dataSaverPreviewKey(photoPath);
    if (_dataSaverPreviewPaths.containsKey(key) ||
        _dataSaverPreviewKeysInFlight.contains(key)) {
      return;
    }
    _dataSaverPreviewKeysInFlight.add(key);
    try {
      final previewPath = await ReceiptImageProcessor.optimizeFile(
        path: photoPath,
        level: _dataSaverLevel,
      );
      if (!_reviewWorkTokenActive(generation) ||
          !_dataSaverPreviewKeysInFlight.contains(key)) {
        await _deleteDataSaverPreviewPath(previewPath, sourcePath: photoPath);
        return;
      }
      _updateReviewState(() => _dataSaverPreviewPaths[key] = previewPath);
    } catch (_) {
      if (_reviewWorkActive) {
        _showCameraError('Could not preview this saved proof size.');
      }
    } finally {
      _dataSaverPreviewKeysInFlight.remove(key);
    }
  }

  String _dataSaverPreviewKey(String path) => '$path::${_dataSaverLevel.name}';

  String _dataSaverPreviewSource(String selectedPhotoPath) {
    final stitched = _stitchPreviewResult;
    if (_reviewMode == _ReceiptReviewMode.dataSaver &&
        stitched?.didStitch == true &&
        stitched?.stitchedPath != null) {
      return stitched!.stitchedPath!;
    }
    return selectedPhotoPath;
  }

  Future<void> _deleteGeneratedDataSaverPreviews() async {
    for (final path in _dataSaverPreviewPaths.values.toSet()) {
      await _deleteDataSaverPreviewPath(path, keepRetained: false);
    }
  }

  Future<void> _deleteDataSaverPreviewPath(
    String path, {
    String? sourcePath,
    bool keepRetained = true,
  }) async {
    if (path.isEmpty) return;
    if (sourcePath != null && path == sourcePath) return;
    if (keepRetained &&
        (_photoPaths.contains(path) ||
            _dataSaverPreviewPaths.containsValue(path))) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort cleanup for app-created saved proof previews.
    }
  }
}
