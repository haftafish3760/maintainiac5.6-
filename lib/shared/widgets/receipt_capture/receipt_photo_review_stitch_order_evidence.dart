part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewStitchOrderEvidence
    on _ReceiptPhotoReviewScreenState {
  Future<bool> _applyAutomaticStitchOrderIfConfident() {
    final existing = _stitchOrderWork;
    if (existing != null) return existing;
    final work = _evaluateAutomaticStitchOrder();
    _stitchOrderWork = work;
    return work.whenComplete(() {
      if (identical(_stitchOrderWork, work)) _stitchOrderWork = null;
    });
  }

  Future<bool> _evaluateAutomaticStitchOrder() async {
    // Photo order is a capture concern, not an assisted-fill feature.  A
    // person who chooses manual receipt entry still needs multiple photos to
    // be assembled in the right order before the proof is saved.
    if (_stitchOrderUserAdjusted || _photoPaths.length <= 1) {
      return false;
    }
    final generation = _reviewWorkGeneration;
    final paths = List<String>.of(_photoPaths);
    final key = paths.join('||');
    if (_stitchOrderEvidenceKey == key) return false;

    List<ReceiptStitchTextEvidence> evidence;
    try {
      evidence = await ReceiptOcrService.forDevice(
        _deviceCapability,
      ).recognizeStitchTextEvidence(paths).timeout(const Duration(seconds: 28));
    } catch (_) {
      evidence = [
        for (final path in paths)
          ReceiptStitchTextEvidence(path: path, lines: const []),
      ];
    }
    if (!_reviewWorkTokenActive(generation) ||
        !_sameReceiptPhotoOrder(paths, _photoPaths)) {
      return false;
    }
    final plan = ReceiptStitchOrderPlan.fromEvidence(evidence);
    _stitchTextEvidenceByPath
      ..removeWhere((path, _) => !paths.contains(path))
      ..addEntries(evidence.map((item) => MapEntry(item.path, item)));
    if (!plan.changed) {
      _updateReviewState(() {
        _stitchOrderEvidenceKey = key;
        for (final path in _photoPaths) {
          _captureDiagnosticsByPath[path] = {
            ...?_captureDiagnosticsByPath[path],
            'stitchOrderDecision': plan.reasonCode,
            'stitchOrderConfidence': plan.confidence,
            'stitchOrderAutomaticallyChanged': false,
            'stitchOrderNeedsReview': plan.requiresReview,
          };
        }
      });
      return false;
    }

    _stitchPreviewDebounce?.cancel();
    final oldPreviewPath = _stitchPreviewResult?.stitchedPath;
    _updateReviewState(() {
      _photoPaths
        ..clear()
        ..addAll(plan.orderedPaths);
      _selectedIndex = 0;
      _selectedStitchPairIndex = 0;
      _stitchOrderEvidenceKey = _photoPaths.join('||');
      _stitchPreviewKey = null;
      _stitchPreviewResult = null;
      _stitchPreviewInFlight = false;
      _manualOverlapFractions.clear();
      _manualScaleCorrections.clear();
      _manualRotationCorrectionsDegrees.clear();
      _manualHorizontalOffsetFractions.clear();
      _manualZeroOverlapPairs.clear();
      for (final path in _photoPaths) {
        _captureDiagnosticsByPath[path] = {
          ...?_captureDiagnosticsByPath[path],
          'stitchOrderDecision': plan.reasonCode,
          'stitchOrderConfidence': plan.confidence,
          'stitchOrderAutomaticallyChanged': true,
          'stitchOrderNeedsReview': false,
        };
      }
    });
    _syncManualOverlapSlots();
    unawaited(_deleteStitchPreviewPath(oldPreviewPath));
    return true;
  }

  List<ReceiptStitchTextEvidence>? _stitchEvidenceForPaths(
    List<String> targetPaths, {
    List<String>? sourcePaths,
  }) {
    final sources = sourcePaths ?? targetPaths;
    if (sources.length != targetPaths.length) return null;
    final evidence = <ReceiptStitchTextEvidence>[];
    var hasReadableText = false;
    for (var index = 0; index < targetPaths.length; index++) {
      final source = _stitchTextEvidenceByPath[sources[index]];
      final lines = source?.lines ?? const <String>[];
      hasReadableText = hasReadableText || lines.isNotEmpty;
      evidence.add(
        ReceiptStitchTextEvidence(path: targetPaths[index], lines: lines),
      );
    }
    return hasReadableText ? evidence : null;
  }
}
