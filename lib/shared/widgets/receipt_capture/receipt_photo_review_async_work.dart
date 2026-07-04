part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewAsyncWork on _ReceiptPhotoReviewScreenState {
  bool _updateReviewState(VoidCallback update) {
    if (!_reviewWorkActive) return false;
    return _setPhotoReviewState(update);
  }

  bool get _reviewInteractiveControlsActive {
    return _reviewWorkActive &&
        _toolControlsScrollController.hasClients &&
        !_reviewDisposed;
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
      final preview = await ReceiptImageProcessor.previewPreparedBackupFile(
        path: photoPath,
        level: _dataSaverLevel,
        cleanupSettings: ReceiptImageCleanupSettings.fromDiagnostics(
          _captureDiagnosticsByPath[photoPath],
        ),
      );
      if (!_reviewWorkTokenActive(generation, photoPath) ||
          !_previewKeysInFlight.contains(key) ||
          !_photoPaths.contains(photoPath)) {
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
    final workKey = '${_previewKey(photoPath)}|quality';
    if (_postFrameReviewWorkKeys.contains(workKey)) return;
    _postFrameReviewWorkKeys.add(workKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameReviewWorkKeys.remove(workKey);
      final generation = _reviewWorkGeneration;
      if (!_reviewWorkTokenActive(generation, photoPath)) {
        return;
      }
      unawaited(_deferQualityCheck(photoPath, generation));
      unawaited(_deferStoragePreview(photoPath, generation));
    });
  }

  void _scheduleDataSaverPreviewWork(String photoPath) {
    final workKey = '${_dataSaverPreviewKey(photoPath)}|dataSaverPreview';
    if (_postFrameReviewWorkKeys.contains(workKey)) return;
    _postFrameReviewWorkKeys.add(workKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameReviewWorkKeys.remove(workKey);
      final generation = _reviewWorkGeneration;
      if (!_reviewWorkTokenActive(generation, photoPath) ||
          _reviewMode != _ReceiptReviewMode.dataSaver ||
          !_photoPaths.contains(photoPath)) {
        return;
      }
      unawaited(_ensureDataSaverImagePreview(photoPath, generation));
    });
  }

  Future<void> _deferQualityCheck(String photoPath, int generation) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!_reviewWorkTokenActive(generation, photoPath)) {
      return;
    }
    await _ensureQualityCheck(photoPath, generation);
  }

  Future<void> _deferStoragePreview(String photoPath, int generation) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!_reviewWorkTokenActive(generation, photoPath)) {
      return;
    }
    await _ensureStoragePreview(photoPath, generation);
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
      // Review must remain usable even if a background quality pass fails.
    } finally {
      _qualityCheckKeysInFlight.remove(photoPath);
    }
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
      final previewPath =
          await ReceiptImageProcessor.optimizePreparedBackupFile(
            path: photoPath,
            level: _dataSaverLevel,
            cleanupSettings: ReceiptImageCleanupSettings.fromDiagnostics(
              _captureDiagnosticsByPath[photoPath],
            ),
          );
      if (!_reviewWorkTokenActive(generation, photoPath) ||
          !_dataSaverPreviewKeysInFlight.contains(key) ||
          !_photoPaths.contains(photoPath)) {
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
