part of 'receipt_image_processor.dart';

Future<ReceiptStitchResult> _stitchReceiptPhotosForOcr({
  required List<String> paths,
  List<List<String>>? textLinesByPath,
  List<bool>? manualZeroOverlapPairs,
  List<int>? manualOverlapPixels,
  List<double>? manualOverlapFractions,
  List<double>? manualScaleCorrections,
  List<double>? manualRotationCorrectionsDegrees,
  List<double>? manualHorizontalOffsetFractions,
  int maxOutputPixels = 16000000,
  int maxOutputHeight = 20000,
}) async {
  final inputPaths = paths
      .map((path) => path.trim())
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
  if (inputPaths.isEmpty) {
    return ReceiptStitchResult.fallback(
      inputPaths: [],
      warning: 'No receipt photos were available for stitching.',
      fallbackReasonCode: 'no_input_paths',
    );
  }
  if (inputPaths.length <= 1) {
    return ReceiptStitchResult.notNeeded(inputPaths);
  }
  if (!receiptPhotoPathsAreUniqueAndNormalized(inputPaths)) {
    final duplicateOrAlias = _stitchInputPathsHaveDuplicateAliases(inputPaths);
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos included invalid or repeated section paths. Receipt details will use the photos separately.',
      fallbackReasonCode: duplicateOrAlias
          ? 'duplicate_input_paths'
          : 'invalid_input_paths',
    );
  }
  if (!_stitchInputPathsAreUnique(inputPaths)) {
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos included the same section more than once. Receipt details will use the photos separately.',
      fallbackReasonCode: 'duplicate_input_paths',
    );
  }

  final confidences = <double>[];
  final pairResults = <ReceiptStitchPairResult>[];
  // The combined proof has a deliberate width cap. Do the private crop/frame
  // work close to that cap instead of repeatedly copying an entire 12–50 MP
  // camera image just to reduce it later. Original user photos remain intact.
  final targetWidth = _stitchTargetWidth(inputPaths.length);
  var activePairIndex = -1;
  try {
    final sourcePreparation = await _prepareReceiptStitchSources(
      inputPaths: inputPaths,
      targetWidth: targetWidth,
    );
    final preparationFailure = sourcePreparation.failure;
    if (preparationFailure != null) return preparationFailure;
    final prepared = sourcePreparation.prepared;
    final comparisonPrepared = sourcePreparation.comparisonPrepared;
    final comparisonHasReadableDetail =
        sourcePreparation.comparisonHasReadableDetail;
    final comparisonLooksLikeReceiptPhoto =
        sourcePreparation.comparisonLooksLikeReceiptPhoto;
    if (manualOverlapPixels == null && manualOverlapFractions == null) {
      final minimumAutoHeight = _minimumAutoStitchHeight(prepared);
      final minimumAutoPixels = targetWidth * minimumAutoHeight;
      if (minimumAutoHeight > maxOutputHeight ||
          minimumAutoPixels > maxOutputPixels) {
        return _oversizedStitchFallback(
          inputPaths: inputPaths,
          targetWidth: targetWidth,
          expectedHeight: minimumAutoHeight,
          maxOutputPixels: maxOutputPixels,
          maxOutputHeight: maxOutputHeight,
          confidences: const [],
          pairResults: const [],
        )!;
      }
    }
    final normalized = <img.Image>[prepared.first];
    final normalizedForComparison = <img.Image>[comparisonPrepared.first];
    var expectedHeight = normalized.first.height;
    final overlaps = <int>[];
    final horizontalOffsets = <int>[];
    ReceiptStitchResult? oversizedFallback() => _oversizedStitchFallback(
      inputPaths: inputPaths,
      targetWidth: targetWidth,
      expectedHeight: expectedHeight,
      maxOutputPixels: maxOutputPixels,
      maxOutputHeight: maxOutputHeight,
      confidences: confidences,
      pairResults: pairResults,
    );
    final initialOversizedFallback = oversizedFallback();
    if (initialOversizedFallback != null) return initialOversizedFallback;

    for (var index = 1; index < prepared.length; index++) {
      final pairIndex = index - 1;
      activePairIndex = pairIndex;
      final previous = normalized[pairIndex];
      final manualScale = _manualStitchValue(
        manualScaleCorrections,
        pairIndex,
        fallback: 1,
        minimum: .75,
        maximum: 1.25,
      );
      final manualRotation = _manualStitchValue(
        manualRotationCorrectionsDegrees,
        pairIndex,
        fallback: 0,
        minimum: -8,
        maximum: 8,
      );
      final manualHorizontalFraction = _manualStitchValue(
        manualHorizontalOffsetFractions,
        pairIndex,
        fallback: 0,
        minimum: -.20,
        maximum: .20,
      );
      final manualNext = _transformForStitchComparison(
        prepared[index],
        targetWidth: targetWidth,
        scale: manualScale,
        rotationDegrees: manualRotation,
      );
      final manualOverlap = _manualOverlapFor(
        previous: previous,
        next: manualNext,
        pairIndex: pairIndex,
        manualOverlapPixels: manualOverlapPixels,
        manualOverlapFractions: manualOverlapFractions,
      );
      final manualZeroOverlap =
          manualZeroOverlapPairs != null &&
          pairIndex < manualZeroOverlapPairs.length &&
          manualZeroOverlapPairs[pairIndex];
      if (manualZeroOverlap) {
        final manualHorizontalOffset = (targetWidth * manualHorizontalFraction)
            .round();
        overlaps.add(0);
        horizontalOffsets.add(manualHorizontalOffset);
        confidences.add(.30);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: 0,
            confidence: .30,
            usedManualAdjustment: true,
            usedZeroOverlapJoin: true,
            scaleCorrection: manualScale,
            rotationCorrectionDegrees: manualRotation,
            horizontalOffsetPixels: manualHorizontalOffset,
          ),
        );
        normalized.add(manualNext);
        normalizedForComparison.add(
          _transformForStitchComparison(
            comparisonPrepared[index],
            targetWidth: targetWidth,
            scale: manualScale,
            rotationDegrees: manualRotation,
          ),
        );
        expectedHeight += manualNext.height;
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
        continue;
      }
      if (manualOverlap != null) {
        final maxManualOverlap =
            math.min(previous.height, manualNext.height) - 24;
        if (manualOverlap < 24 || manualOverlap > maxManualOverlap) {
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning: 'Manual receipt overlap was outside the safe range.',
            fallbackReasonCode: 'manual_overlap_unsafe',
            failedPairIndex: pairIndex,
            pairs: pairResults,
          );
        }
        overlaps.add(manualOverlap);
        final manualHorizontalOffset = (targetWidth * manualHorizontalFraction)
            .round();
        horizontalOffsets.add(manualHorizontalOffset);
        confidences.add(1);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: manualOverlap,
            confidence: 1,
            usedManualAdjustment: true,
            scaleCorrection: manualScale,
            rotationCorrectionDegrees: manualRotation,
            horizontalOffsetPixels: manualHorizontalOffset,
          ),
        );
        normalized.add(manualNext);
        // Keep the matching sequence aligned with the visible sequence. A
        // following automatic join in a three-or-more-photo receipt must use
        // this manually accepted section as its previous comparison image.
        normalizedForComparison.add(
          _transformForStitchComparison(
            comparisonPrepared[index],
            targetWidth: targetWidth,
            scale: manualScale,
            rotationDegrees: manualRotation,
          ),
        );
        expectedHeight += manualNext.height - manualOverlap;
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
      } else {
        // Do not let a blank, dark, or nearly uniform photo win a visual
        // overlap score merely because it has no competing detail. It stays
        // in the ordered fallback set so the person can retake only that
        // section; it must never become part of a misleading combined proof.
        if (!comparisonHasReadableDetail[pairIndex] ||
            !comparisonHasReadableDetail[index] ||
            !comparisonLooksLikeReceiptPhoto[pairIndex] ||
            !comparisonLooksLikeReceiptPhoto[index]) {
          final failedPair = ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: 0,
            confidence: 0,
          );
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning:
                'One receipt photo does not show enough readable detail to combine safely.',
            fallbackReasonCode: 'overlap_confidence_low',
            confidence: 0,
            failedPairIndex: pairIndex,
            pairs: List.unmodifiable([...pairResults, failedPair]),
          );
        }
        var match = _bestScaleTolerantVerticalOverlap(
          previous: normalizedForComparison[pairIndex],
          next: comparisonPrepared[index],
          targetWidth: targetWidth,
        );
        var continuity = _receiptOverlapContinuityEvidence(
          previous: normalizedForComparison[pairIndex],
          match: match,
        );
        if (!continuity.isProven &&
            ((match.scaleCorrection - 1).abs() >= .03 ||
                match.rotationCorrectionDegrees.abs() >= .5 ||
                match.perspectiveCorrection.abs() >= .03)) {
          final fixedMatch = _fixedScaleVerticalOverlap(
            previous: normalizedForComparison[pairIndex],
            next: comparisonPrepared[index],
            targetWidth: targetWidth,
          );
          final fixedContinuity = _receiptOverlapContinuityEvidence(
            previous: normalizedForComparison[pairIndex],
            match: fixedMatch,
          );
          if (fixedContinuity.isProven) {
            match = fixedMatch;
            continuity = fixedContinuity;
          }
        }
        final textEvidence = _receiptStitchTextEvidenceForPair(
          inputPaths: inputPaths,
          textLinesByPath: textLinesByPath,
          pairIndex: pairIndex,
        );
        final textCorroboratesGeometry =
            textEvidence.isStrong && match.confidence >= .28;
        final continuityIsCorroborated =
            continuity.isProven ||
            textCorroboratesGeometry ||
            (match.confidence >= .35 &&
                continuity.detailedBands >= 3 &&
                continuity.matchingBands >= 3 &&
                continuity.correlation >= .30) ||
            (match.confidence >= .44 &&
                continuity.detailedBands >= 2 &&
                continuity.matchingBands == continuity.detailedBands &&
                continuity.correlation >= .55);
        final continuityConfidence = continuityIsCorroborated
            ? (.42 + continuity.correlation * .30).clamp(0.0, .72)
            : 0.0;
        final textConfidence = textCorroboratesGeometry
            ? (.46 + textEvidence.confidence * .34).clamp(0.0, .80)
            : 0.0;
        final effectiveConfidence = math.max(
          math.max(match.confidence, continuityConfidence),
          textConfidence,
        );
        final hasExceptionalContinuity =
            continuity.detailedBands >= 4 &&
            continuity.matchingBands == continuity.detailedBands &&
            continuity.correlation >= .72;
        // A combined receipt is a user-facing proof image. Do not turn a
        // merely plausible overlap into a green "combined" result: preserve
        // the original ordered photos and target the failed pair for review.
        final lowConfidenceTransformIsAggressive =
            effectiveConfidence < .70 &&
            !hasExceptionalContinuity &&
            ((match.scaleCorrection - 1).abs() >= .15 ||
                match.rotationCorrectionDegrees.abs() >= 3.5 ||
                match.perspectiveCorrection.abs() >= .085);
        // A reviewable low-confidence join may still be geometrically stable.
        // But a weak match that also needs a large scale, rotation, or offset
        // correction can erase real receipt rows when the next opaque image is
        // composited. Preserve the ordered clear sections for retake/manual
        // alignment instead of producing that destructive combined image.
        if (effectiveConfidence < .49 ||
            !continuityIsCorroborated ||
            lowConfidenceTransformIsAggressive) {
          final reportedConfidence = math.min(effectiveConfidence, .69);
          final failedPair = ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: match.pixels,
            confidence: reportedConfidence,
            scaleCorrection: match.scaleCorrection,
            rotationCorrectionDegrees: match.rotationCorrectionDegrees,
            perspectiveCorrection: match.perspectiveCorrection,
            horizontalOffsetPixels: match.nextXOffsetPixels,
            verticalOffsetPixels: match.nextTopOffsetPixels,
            textOverlapConfidence: textEvidence.confidence,
            matchedTextLineCount: textEvidence.matchedLineCount,
            continuityCorrelation: continuity.correlation,
            continuityDetailedBands: continuity.detailedBands,
            continuityMatchingBands: continuity.matchingBands,
          );
          return ReceiptStitchResult.fallback(
            inputPaths: inputPaths,
            warning:
                'Receipt photos did not match clearly enough to stitch safely.',
            fallbackReasonCode: 'overlap_confidence_low',
            confidence: reportedConfidence,
            failedPairIndex: pairIndex,
            pairs: List.unmodifiable([...pairResults, failedPair]),
          );
        }
        // This includes the actual repeated rows and any leading rows before
        // the overlap. The full continuation image is retained, so both must
        // affect its placement exactly once.
        overlaps.add(match.nextSkipPixels);
        horizontalOffsets.add(match.nextXOffsetPixels);
        confidences.add(effectiveConfidence);
        final nextImage = _materializeRawStitchImage(
          prepared[index],
          match: match,
          targetWidth: targetWidth,
        );
        normalized.add(nextImage);
        // Match every adjacent pair from its independently normalized source.
        // Reusing a transformed prior match compounds zoom/rotation across a
        // three-or-more-photo receipt and makes later pairs drift away from
        // their real neighboring pixels.
        normalizedForComparison.add(comparisonPrepared[index]);
        pairResults.add(
          ReceiptStitchPairResult(
            pairIndex: pairIndex,
            overlapPixels: match.pixels,
            confidence: effectiveConfidence,
            scaleCorrection: match.scaleCorrection,
            rotationCorrectionDegrees: match.rotationCorrectionDegrees,
            perspectiveCorrection: match.perspectiveCorrection,
            horizontalOffsetPixels: match.nextXOffsetPixels,
            verticalOffsetPixels: match.nextTopOffsetPixels,
            textOverlapConfidence: textEvidence.confidence,
            matchedTextLineCount: textEvidence.matchedLineCount,
            continuityCorrelation: continuity.correlation,
            continuityDetailedBands: continuity.detailedBands,
            continuityMatchingBands: continuity.matchingBands,
          ),
        );
        expectedHeight += nextImage.height - match.nextSkipPixels;
        final fallback = oversizedFallback();
        if (fallback != null) return fallback;
      }
    }

    activePairIndex = -1;
    final horizontalPlacements = _stitchHorizontalPlacements(horizontalOffsets);
    final minPlacementX = horizontalPlacements.reduce(math.min);
    final maxPlacementX = horizontalPlacements
        .map((x) => x + targetWidth)
        .reduce(math.max);
    final canvasWidth = maxPlacementX - minPlacementX;
    final expandedPixels = canvasWidth * expectedHeight;
    if (expectedHeight > maxOutputHeight || expandedPixels > maxOutputPixels) {
      return _oversizedStitchFallback(
        inputPaths: inputPaths,
        targetWidth: canvasWidth,
        expectedHeight: expectedHeight,
        maxOutputPixels: maxOutputPixels,
        maxOutputHeight: maxOutputHeight,
        confidences: confidences,
        pairResults: pairResults,
      )!;
    }
    final placementShiftX = -minPlacementX;
    final canvas = img.Image(
      width: canvasWidth,
      height: expectedHeight,
      numChannels: 3,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    var y = 0;
    img.compositeImage(
      canvas,
      normalized.first,
      dstX: horizontalPlacements.first + placementShiftX,
      dstY: y,
    );
    y += normalized.first.height;
    for (var index = 1; index < normalized.length; index++) {
      y -= overlaps[index - 1];
      final pair = pairResults[index - 1];
      final seamCropY = _selectReceiptStitchSeamCropY(
        previous: normalized[index - 1],
        next: normalized[index],
        overlapPixels: pair.overlapPixels,
        nextTopOffset: pair.verticalOffsetPixels,
        horizontalOffset: pair.horizontalOffsetPixels,
      );
      final continuation = seamCropY <= 0
          ? normalized[index]
          : img.copyCrop(
              normalized[index],
              x: 0,
              y: seamCropY,
              width: normalized[index].width,
              height: normalized[index].height - seamCropY,
            );
      img.compositeImage(
        canvas,
        continuation,
        dstX: horizontalPlacements[index] + placementShiftX,
        dstY: y + seamCropY,
      );
      y += normalized[index].height;
    }

    final path = await _writeJpg(canvas, prefix: 'stitched', quality: 88);
    final confidence = confidences.isEmpty ? 1.0 : confidences.reduce(math.min);
    return ReceiptStitchResult(
      status: ReceiptStitchStatus.stitched,
      inputPaths: inputPaths,
      stitchedPath: path,
      ocrSourcePaths: [path],
      confidence: confidence,
      overlapPixels: overlaps,
      pairs: pairResults,
      stitchedWidth: canvasWidth,
      stitchedHeight: expectedHeight,
      usedManualAdjustment: pairResults.any(
        (pair) => pair.usedManualAdjustment,
      ),
    );
  } catch (_) {
    return ReceiptStitchResult.fallback(
      inputPaths: inputPaths,
      warning:
          'Receipt photos could not be stitched safely. Receipt details will use them separately.',
      fallbackReasonCode: 'stitch_exception',
      confidence: confidences.isEmpty ? 0 : confidences.reduce(math.min),
      failedPairIndex: activePairIndex >= 0 ? activePairIndex : null,
      pairs: pairResults,
    );
  }
}
