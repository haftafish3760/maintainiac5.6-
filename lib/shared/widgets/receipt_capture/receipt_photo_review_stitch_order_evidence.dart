part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewStitchOrderEvidence
    on _ReceiptPhotoReviewScreenState {
  Future<void> _collectStitchOrderEvidence() {
    final existing = _stitchOrderWork;
    if (existing != null) return existing;
    final work = _evaluateStitchOrderEvidence();
    _stitchOrderWork = work;
    return work.whenComplete(() {
      if (identical(_stitchOrderWork, work)) _stitchOrderWork = null;
    });
  }

  Future<void> _evaluateStitchOrderEvidence() async {
    // Continue assembles the order the person reviewed. OCR may assess that
    // order and guide pair registration, but it must never silently replace
    // the user's source sequence—even when its alternative looks confident.
    if (_photoPaths.length <= 1) return;
    final generation = _reviewWorkGeneration;
    final paths = List<String>.of(_photoPaths);
    final key = paths.join('||');
    if (_stitchOrderEvidenceKey == key) return;

    final evidenceStopwatch = Stopwatch()..start();
    List<ReceiptStitchTextEvidence> evidence;
    try {
      evidence = await ReceiptOcrService.forDevice(_deviceCapability)
          .recognizeStitchTextEvidence(
            paths,
            totalBudget: _stitchDeviceLimits.evidenceTimeout,
          );
    } catch (_) {
      evidence = [
        for (final path in paths)
          ReceiptStitchTextEvidence(path: path, lines: const []),
      ];
    }
    evidenceStopwatch.stop();
    if (!_reviewWorkTokenActive(generation) ||
        !_sameReceiptPhotoOrder(paths, _photoPaths)) {
      return;
    }
    final plan = ReceiptStitchOrderPlan.fromEvidence(evidence);
    traceReceiptPipelineStage(
      'stitch_evidence_ready',
      traceId: _receiptStitchTraceId,
      elapsedMs: evidenceStopwatch.elapsedMilliseconds,
      sourceCount: paths.length,
      layoutLineCount: evidence.fold<int>(
        0,
        (total, item) => total + item.positionedLines.length,
      ),
      candidateLineCount: evidence
          .where((item) => item.lines.isNotEmpty)
          .length,
      deviceTier: _deviceCapability.tier.name,
      destination: plan.reasonCode,
    );
    _stitchTextEvidenceByPath
      ..removeWhere((path, _) => !paths.contains(path))
      ..addEntries(evidence.map((item) => MapEntry(item.path, item)));
    _updateReviewState(() {
      _stitchOrderEvidenceKey = key;
      for (final path in _photoPaths) {
        _captureDiagnosticsByPath[path] = {
          ...?_captureDiagnosticsByPath[path],
          'stitchOrderDecision': plan.reasonCode,
          'stitchOrderConfidence': plan.confidence,
          'stitchOrderAutomaticallyChanged': false,
          'stitchOrderRecommendationAvailable': plan.changed,
          'stitchOrderNeedsReview': plan.changed || plan.requiresReview,
          'stitchOrderUserAdjusted': _stitchOrderUserAdjusted,
          'stitchOrderAuthority': 'user_reviewed_order',
        };
      }
    });
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
        ReceiptStitchTextEvidence(
          path: targetPaths[index],
          lines: lines,
          positionedLines:
              source?.positionedLines ??
              const <ReceiptStitchTextLineEvidence>[],
        ),
      );
    }
    return hasReadableText ? evidence : null;
  }
}
