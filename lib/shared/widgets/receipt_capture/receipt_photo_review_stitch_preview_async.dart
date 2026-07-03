part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewStitchPreviewAsync
    on _ReceiptPhotoReviewScreenState {
  void _syncManualOverlapSlots() {
    final needed = (_photoPaths.length - 1).clamp(0, 1000000);
    while (_manualOverlapFractions.length < needed) {
      _manualOverlapFractions.add(null);
    }
    while (_manualOverlapFractions.length > needed) {
      _manualOverlapFractions.removeLast();
    }
    if (needed == 0) {
      _selectedStitchPairIndex = 0;
    } else if (_selectedStitchPairIndex >= needed) {
      _selectedStitchPairIndex = needed - 1;
    }
  }

  void _setManualOverlapFraction(double value) {
    if (!value.isFinite) return;
    _syncManualOverlapSlots();
    if (_manualOverlapFractions.isEmpty) return;
    _updateReviewState(() {
      _manualOverlapFractions[_selectedStitchPairIndex] = value.clamp(.08, .48);
    });
    _scheduleStitchPreviewRefresh();
  }

  void _clearManualOverlapFraction() {
    _syncManualOverlapSlots();
    if (_manualOverlapFractions.isEmpty) return;
    _updateReviewState(
      () => _manualOverlapFractions[_selectedStitchPairIndex] = null,
    );
    _scheduleStitchPreviewRefresh();
  }

  void _invalidateStitchPreview() {
    _stitchPreviewDebounce?.cancel();
    final previousPreviewPath = _stitchPreviewResult?.stitchedPath;
    _stitchPreviewKey = null;
    _stitchPreviewResult = null;
    _stitchPreviewInFlight = false;
    unawaited(_deleteStitchPreviewPath(previousPreviewPath));
  }

  void _scheduleStitchPreviewRefresh() {
    if (_reviewMode != _ReceiptReviewMode.stitch || _photoPaths.length <= 1) {
      _invalidateStitchPreview();
      return;
    }
    _stitchPreviewDebounce?.cancel();
    _stitchPreviewDebounce = Timer(const Duration(milliseconds: 260), () {
      if (_reviewWorkActive) _ensureStitchPreview(force: true);
    });
  }

  Future<void> _ensureStitchPreview({bool force = false}) async {
    if (!_reviewWorkActive) return;
    if (_photoPaths.length <= 1 || _stitchPreviewInFlight) return;
    final generation = _reviewWorkGeneration;
    final key = _currentStitchPreviewKey();
    if (!force && _stitchPreviewKey == key && _stitchPreviewResult != null) {
      return;
    }
    _stitchPreviewDebounce?.cancel();
    final previousPreviewPath = _stitchPreviewResult?.stitchedPath;
    if (!_updateReviewState(() {
      _stitchPreviewInFlight = true;
      _stitchPreviewKey = key;
    })) {
      return;
    }
    try {
      final manualOverlapFractions = _manualOverlapFractions
          .map((value) => value ?? 0)
          .toList(growable: false);
      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: _photoPaths,
        manualOverlapFractions: manualOverlapFractions.any((value) => value > 0)
            ? manualOverlapFractions
            : null,
        maxOutputPixels: _stitchDeviceLimits.maxOutputPixels,
        maxOutputHeight: _stitchDeviceLimits.maxOutputHeight,
      );
      if (!_reviewWorkTokenActive(generation) ||
          _currentStitchPreviewKey() != key) {
        await _deleteStitchPreviewPath(result.stitchedPath);
        _releaseStaleStitchPreview(key);
        return;
      }
      await _deleteStitchPreviewPath(previousPreviewPath);
      _updateReviewState(() {
        _stitchPreviewResult = result;
        final failedPair = result.failedPairIndex;
        if (failedPair != null &&
            failedPair >= 0 &&
            failedPair < _photoPaths.length - 1) {
          _selectedStitchPairIndex = failedPair;
        }
        _stitchPreviewInFlight = false;
      });
    } catch (_) {
      if (!_reviewWorkTokenActive(generation)) {
        _releaseStaleStitchPreview(key);
        return;
      }
      _updateReviewState(() {
        _stitchPreviewResult = ReceiptStitchResult.fallback(
          inputPaths: _photoPaths,
          warning:
              'Receipt photos could not be matched into one safe image. Next will review them from top to bottom.',
        );
        _stitchPreviewInFlight = false;
      });
    }
  }

  void _releaseStaleStitchPreview(String key) {
    if (!_reviewWorkActive || !_stitchPreviewInFlight) return;
    if (_stitchPreviewKey != key) return;
    _updateReviewState(() {
      _stitchPreviewKey = null;
      _stitchPreviewResult = null;
      _stitchPreviewInFlight = false;
    });
    _scheduleStitchPreviewRefresh();
  }

  String _currentStitchPreviewKey() {
    final overlapKey = _manualOverlapFractions
        .map((value) => value == null ? 'auto' : value.toStringAsFixed(3))
        .join('|');
    return '${_photoPaths.join('||')}::$overlapKey';
  }

  Future<void> _deleteGeneratedStitchPreview() async {
    final path = _stitchPreviewResult?.stitchedPath;
    await _deleteStitchPreviewPath(path);
  }

  Future<void> _deleteStitchPreviewPath(String? path) async {
    if (path == null || _photoPaths.contains(path)) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Best effort cleanup for app-created stitch previews.
    }
  }
}
