part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewStitchPreviewAsync
    on _ReceiptPhotoReviewScreenState {
  void _syncManualOverlapSlots() {
    final needed = (_photoPaths.length - 1).clamp(0, 1000000);
    while (_manualOverlapFractions.length < needed) {
      _manualOverlapFractions.add(null);
      _manualScaleCorrections.add(1);
      _manualRotationCorrectionsDegrees.add(0);
      _manualHorizontalOffsetFractions.add(0);
      _manualZeroOverlapPairs.add(false);
    }
    while (_manualOverlapFractions.length > needed) {
      _manualOverlapFractions.removeLast();
      _manualScaleCorrections.removeLast();
      _manualRotationCorrectionsDegrees.removeLast();
      _manualHorizontalOffsetFractions.removeLast();
      _manualZeroOverlapPairs.removeLast();
    }
    if (needed == 0) {
      _selectedStitchPairIndex = 0;
    } else if (_selectedStitchPairIndex < 0) {
      _selectedStitchPairIndex = 0;
    } else if (_selectedStitchPairIndex >= needed) {
      _selectedStitchPairIndex = needed - 1;
    }
  }

  void _selectStitchPairIndex(int index) {
    if (!_reviewInteractiveControlsActive) return;
    _syncManualOverlapSlots();
    final maxPairIndex = _manualOverlapFractions.length - 1;
    final selected = maxPairIndex < 0
        ? 0
        : index.clamp(0, maxPairIndex).toInt();
    _updateReviewState(() {
      _selectedStitchPairIndex = selected;
      // Pair navigation makes the upper section the explicit retake target.
      _selectedIndex = selected;
    });
  }

  void _selectStitchPhoto(int index) {
    if (!_reviewInteractiveControlsActive || _photoPaths.isEmpty) return;
    final selected = index.clamp(0, _photoPaths.length - 1).toInt();
    final currentPair = _selectedStitchPairIndex;
    final pairForSelected = selected == currentPair + 1
        ? currentPair
        : selected.clamp(0, _photoPaths.length - 2).toInt();
    _updateReviewState(() {
      _selectedIndex = selected;
      _selectedStitchPairIndex = pairForSelected;
    });
  }

  void _setManualOverlapFraction(double value) {
    if (!_reviewInteractiveControlsActive) return;
    if (!value.isFinite) return;
    _syncManualOverlapSlots();
    if (_manualOverlapFractions.isEmpty) return;
    _updateReviewState(() {
      _manualOverlapFractions[_selectedStitchPairIndex] = value.clamp(.08, .48);
      _manualZeroOverlapPairs[_selectedStitchPairIndex] = false;
    });
    _scheduleStitchPreviewRefresh();
  }

  void _clearManualOverlapFraction() {
    if (!_reviewInteractiveControlsActive) return;
    _syncManualOverlapSlots();
    if (_manualOverlapFractions.isEmpty) return;
    _updateReviewState(
      () => _manualOverlapFractions[_selectedStitchPairIndex] = null,
    );
    _scheduleStitchPreviewRefresh();
  }

  void _setManualZeroOverlap(bool value) {
    if (!_reviewInteractiveControlsActive) return;
    _syncManualOverlapSlots();
    if (_manualZeroOverlapPairs.isEmpty) return;
    _updateReviewState(() {
      _manualZeroOverlapPairs[_selectedStitchPairIndex] = value;
      if (value) _manualOverlapFractions[_selectedStitchPairIndex] = null;
    });
    _scheduleStitchPreviewRefresh();
  }

  void _setManualScaleCorrection(double value) {
    if (!_reviewInteractiveControlsActive || !value.isFinite) return;
    _syncManualOverlapSlots();
    if (_manualScaleCorrections.isEmpty) return;
    _updateReviewState(() {
      _manualScaleCorrections[_selectedStitchPairIndex] = value
          .clamp(.75, 1.25)
          .toDouble();
    });
    _scheduleStitchPreviewRefresh();
  }

  void _setManualRotationCorrection(double value) {
    if (!_reviewInteractiveControlsActive || !value.isFinite) return;
    _syncManualOverlapSlots();
    if (_manualRotationCorrectionsDegrees.isEmpty) return;
    _updateReviewState(() {
      _manualRotationCorrectionsDegrees[_selectedStitchPairIndex] = value
          .clamp(-8, 8)
          .toDouble();
    });
    _scheduleStitchPreviewRefresh();
  }

  void _setManualHorizontalOffsetFraction(double value) {
    if (!_reviewInteractiveControlsActive || !value.isFinite) return;
    _syncManualOverlapSlots();
    if (_manualHorizontalOffsetFractions.isEmpty) return;
    _updateReviewState(() {
      _manualHorizontalOffsetFractions[_selectedStitchPairIndex] = value
          .clamp(-.20, .20)
          .toDouble();
    });
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
    if (await _applyAutomaticStitchOrderIfConfident()) {
      if (_reviewWorkActive && _reviewMode == _ReceiptReviewMode.stitch) {
        await _ensureStitchPreview(force: true);
      }
      return;
    }
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
      final stitchFuture = ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: _photoPaths,
        textEvidence: _stitchEvidenceForPaths(_photoPaths),
        manualZeroOverlapPairs: _manualZeroOverlapPairs.any((value) => value)
            ? List<bool>.of(_manualZeroOverlapPairs)
            : null,
        manualOverlapFractions: manualOverlapFractions.any((value) => value > 0)
            ? manualOverlapFractions
            : null,
        manualScaleCorrections: List<double>.of(_manualScaleCorrections),
        manualRotationCorrectionsDegrees: List<double>.of(
          _manualRotationCorrectionsDegrees,
        ),
        manualHorizontalOffsetFractions: List<double>.of(
          _manualHorizontalOffsetFractions,
        ),
        maxOutputPixels: _stitchDeviceLimits.maxOutputPixels,
        maxOutputHeight: _stitchDeviceLimits.maxOutputHeight,
        maxTargetWidth: _stitchDeviceLimits.maxTargetWidth,
        comparisonWidth: _stitchDeviceLimits.comparisonWidth,
        retryComparisonWidth: _stitchDeviceLimits.retryComparisonWidth,
        processingTimeout: _stitchDeviceLimits.processingTimeout,
        timeoutReasonCode: 'stitch_preview_timeout',
        timeoutWarning:
            'Putting these photos together took too long. They will stay in order as separate photos so you can continue.',
      );
      final result = await stitchFuture;
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
      await _deleteStitchPreviewPath(previousPreviewPath);
      _updateReviewState(() {
        _stitchPreviewResult = ReceiptStitchResult.fallback(
          inputPaths: _photoPaths,
          warning:
              'Receipt photos could not be matched into one safe image. Receipt details will use them from top to bottom.',
          fallbackReasonCode: 'stitch_exception',
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
    final transformKey = List.generate(
      _manualScaleCorrections.length,
      (index) =>
          '${_manualScaleCorrections[index].toStringAsFixed(3)},${_manualRotationCorrectionsDegrees[index].toStringAsFixed(2)},${_manualHorizontalOffsetFractions[index].toStringAsFixed(3)}',
    ).join('|');
    final zeroOverlapKey = _manualZeroOverlapPairs
        .map((value) => value ? 'zero' : 'auto')
        .join('|');
    return '${_photoPaths.join('||')}::$overlapKey::$transformKey::$zeroOverlapKey';
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
