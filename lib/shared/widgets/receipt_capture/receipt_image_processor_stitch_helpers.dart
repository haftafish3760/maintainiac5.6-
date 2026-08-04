part of 'receipt_image_processor.dart';

_ReceiptOverlapMatch _bestScaleTolerantVerticalOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  int comparisonWidth = 400,
  int retryComparisonWidth = 320,
  bool allowUprightFastPath = false,
}) {
  final safeComparisonWidth = comparisonWidth.clamp(240, 480).toInt();
  final safeRetryComparisonWidth = retryComparisonWidth
      .clamp(200, safeComparisonWidth)
      .toInt();
  final primaryMatch = _bestScaleTolerantVerticalOverlapAtWidth(
    previous: previous,
    next: next,
    targetWidth: targetWidth,
    comparisonWidth: safeComparisonWidth,
    allowUprightFastPath: allowUprightFastPath,
  );
  if (_stitchMatchHasVisualCorroboration(previous, primaryMatch) &&
      primaryMatch.nextTopOffsetPixels <= primaryMatch.pixels) {
    return primaryMatch;
  }
  final detailRetry = _bestScaleTolerantVerticalOverlapAtWidth(
    previous: previous,
    next: next,
    targetWidth: targetWidth,
    comparisonWidth: safeRetryComparisonWidth,
    allowUprightFastPath: allowUprightFastPath,
  );
  return _strongerCorroboratedStitchMatch(
    previous: previous,
    primary: primaryMatch,
    retry: detailRetry,
  );
}

_ReceiptOverlapMatch _bestScaleTolerantVerticalOverlapAtWidth({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  required int comparisonWidth,
  required bool allowUprightFastPath,
}) {
  final sampleWidth = math.min(
    comparisonWidth,
    math.min(previous.width, next.width),
  );
  final previousSample = previous.width == sampleWidth
      ? previous
      : img.copyResize(previous, width: sampleWidth);
  final nextSample = next.width == sampleWidth
      ? next
      : img.copyResize(next, width: sampleWidth);
  final uprightFastPath = allowUprightFastPath
      ? _uprightReceiptOverlapFastPath(
          previous: previous,
          next: next,
          previousSample: previousSample,
          nextSample: nextSample,
          targetWidth: targetWidth,
          sampleWidth: sampleWidth,
        )
      : null;
  if (uprightFastPath != null) return uprightFastPath;
  final candidates = <_ReceiptStitchCandidate>[];
  for (final scale in const [1.0, .94, 1.06, .88, 1.12, .82, 1.18]) {
    final candidateImage = _transformForStitchComparison(
      nextSample,
      targetWidth: sampleWidth,
      scale: scale,
      rotationDegrees: 0,
    );
    final match = _bestVerticalOverlap(
      previous: previousSample,
      next: candidateImage,
    );
    final scalePenalty = (scale - 1).abs() * .45;
    candidates.add(
      _ReceiptStitchCandidate(
        pixels: match.pixels,
        nextSkipPixels: match.nextSkipPixels,
        nextXOffsetPixels: match.nextXOffsetPixels,
        confidence: (match.confidence - scalePenalty).clamp(0.0, 1.0),
        scaleCorrection: scale,
        sampleHeight: candidateImage.height,
        sampleWidth: candidateImage.width,
      ),
    );
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  final baseScaleCandidate = candidates.firstWhere(
    (candidate) => (candidate.scaleCorrection - 1).abs() < .001,
  );
  final bestUnrotatedCandidate = candidates.first;
  final selectedUnrotatedCandidate =
      (bestUnrotatedCandidate.scaleCorrection - 1).abs() >= .03 &&
          bestUnrotatedCandidate.confidence <
              baseScaleCandidate.confidence + .05
      ? baseScaleCandidate
      : bestUnrotatedCandidate;
  // A continuity-proven upright match already meets the same safe acceptance
  // floor used by the final proof gate. Avoid dozens of rotation/perspective
  // resamples unless base geometry cannot prove the overlap.
  if (selectedUnrotatedCandidate.confidence >= .49 &&
      _stitchCandidateHasContinuity(
        candidate: selectedUnrotatedCandidate,
        previous: previousSample,
        next: nextSample,
        targetWidth: sampleWidth,
      )) {
    return _materializeStitchCandidate(
      candidate: selectedUnrotatedCandidate,
      previousHeight: previous.height,
      next: next,
      targetWidth: targetWidth,
    );
  }

  final rotationCandidates = candidates.take(3).toList(growable: false);
  for (final base in rotationCandidates) {
    for (final rotationDegrees in const [
      -.8,
      .8,
      -1.4,
      1.4,
      -2.2,
      2.2,
      -3.0,
      3.0,
      -4.0,
      4.0,
    ]) {
      final candidateImage = _transformForStitchComparison(
        nextSample,
        targetWidth: sampleWidth,
        scale: base.scaleCorrection,
        rotationDegrees: rotationDegrees,
      );
      final match = _bestVerticalOverlap(
        previous: previousSample,
        next: candidateImage,
      );
      final scalePenalty = (base.scaleCorrection - 1).abs() * .45;
      final rotationPenalty = rotationDegrees.abs() * .025;
      candidates.add(
        _ReceiptStitchCandidate(
          pixels: match.pixels,
          nextSkipPixels: match.nextSkipPixels,
          nextXOffsetPixels: match.nextXOffsetPixels,
          confidence: (match.confidence - scalePenalty - rotationPenalty).clamp(
            0.0,
            1.0,
          ),
          scaleCorrection: base.scaleCorrection,
          rotationCorrectionDegrees: rotationDegrees,
          sampleHeight: candidateImage.height,
          sampleWidth: candidateImage.width,
        ),
      );
    }
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  final bestCandidate = candidates.first;
  // A tiny score change from resampling is not evidence that an upright
  // receipt needs rotation. Applying it can crop the derived proof and hide
  // its leading merchant/date rows. Require a material improvement before
  // accepting a rotation correction.
  var selectedCandidate =
      bestCandidate.rotationCorrectionDegrees.abs() >= .001 &&
          bestCandidate.confidence <
              selectedUnrotatedCandidate.confidence + .065
      ? selectedUnrotatedCandidate
      : bestCandidate;
  final perspectiveBaseline = selectedCandidate;
  final perspectiveBases = candidates.take(3).toList(growable: false);
  for (final base in perspectiveBases) {
    for (final correction in const [-.09, -.05, .05, .09]) {
      final candidateImage = _transformForStitchComparison(
        nextSample,
        targetWidth: sampleWidth,
        scale: base.scaleCorrection,
        rotationDegrees: base.rotationCorrectionDegrees,
        perspectiveCorrection: correction,
      );
      final match = _bestVerticalOverlap(
        previous: previousSample,
        next: candidateImage,
      );
      final scalePenalty = (base.scaleCorrection - 1).abs() * .45;
      final rotationPenalty = base.rotationCorrectionDegrees.abs() * .025;
      final perspectivePenalty = correction.abs() * .35;
      candidates.add(
        _ReceiptStitchCandidate(
          pixels: match.pixels,
          nextSkipPixels: match.nextSkipPixels,
          nextXOffsetPixels: match.nextXOffsetPixels,
          confidence:
              (match.confidence -
                      scalePenalty -
                      rotationPenalty -
                      perspectivePenalty)
                  .clamp(0.0, 1.0),
          scaleCorrection: base.scaleCorrection,
          rotationCorrectionDegrees: base.rotationCorrectionDegrees,
          perspectiveCorrection: correction,
          sampleHeight: candidateImage.height,
          sampleWidth: candidateImage.width,
        ),
      );
    }
  }
  candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
  final perspectiveCandidate = candidates.first;
  if (perspectiveCandidate.perspectiveCorrection.abs() >= .001 &&
      perspectiveCandidate.confidence >=
          perspectiveBaseline.confidence + .055) {
    selectedCandidate = perspectiveCandidate;
  }
  if ((selectedCandidate.scaleCorrection - 1).abs() >= .03 &&
      selectedCandidate.confidence < baseScaleCandidate.confidence + .05) {
    selectedCandidate = baseScaleCandidate;
  }
  selectedCandidate = _preferContinuityBackedStitchCandidate(
    candidates: candidates,
    fallback: selectedCandidate,
    previous: previousSample,
    next: nextSample,
    targetWidth: sampleWidth,
  );
  return _materializeStitchCandidate(
    candidate: selectedCandidate,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
}

bool _stitchCandidateHasContinuity({
  required _ReceiptStitchCandidate candidate,
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
}) {
  final match = _materializeStitchCandidate(
    candidate: candidate,
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
  return _receiptOverlapContinuityEvidence(
    previous: previous,
    match: match,
  ).isProven;
}

_ReceiptStitchCandidate _preferContinuityBackedStitchCandidate({
  required List<_ReceiptStitchCandidate> candidates,
  required _ReceiptStitchCandidate fallback,
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
}) {
  var selected = fallback;
  var selectedContinuityScore = -1.0;
  final minimumConfidence = math.max(.44, fallback.confidence - .14);
  final continuityCandidates = <_ReceiptStitchCandidate>{
    ...candidates.take(14),
    ...candidates.where(
      (candidate) =>
          candidate.rotationCorrectionDegrees.abs() < .001 &&
          candidate.perspectiveCorrection.abs() < .001,
    ),
  };
  for (final candidate in continuityCandidates) {
    if (candidate.confidence < minimumConfidence) continue;
    final match = _materializeStitchCandidate(
      candidate: candidate,
      previousHeight: previous.height,
      next: next,
      targetWidth: targetWidth,
    );
    final continuity = _receiptOverlapContinuityEvidence(
      previous: previous,
      match: match,
    );
    if (!continuity.isProven) continue;
    final score =
        candidate.confidence +
        continuity.correlation * .10 +
        continuity.matchingBands * .006;
    if (score > selectedContinuityScore) {
      selected = candidate;
      selectedContinuityScore = score;
    }
  }
  return selected;
}

_ReceiptOverlapMatch _fixedScaleVerticalOverlap({
  required img.Image previous,
  required img.Image next,
  required int targetWidth,
  int comparisonWidth = 400,
}) {
  final safeComparisonWidth = comparisonWidth.clamp(240, 480).toInt();
  final sampleWidth = math.min(
    safeComparisonWidth,
    math.min(previous.width, next.width),
  );
  final previousSample = previous.width == sampleWidth
      ? previous
      : img.copyResize(previous, width: sampleWidth);
  final nextSample = next.width == sampleWidth
      ? next
      : img.copyResize(next, width: sampleWidth);
  final match = _bestVerticalOverlap(
    previous: previousSample,
    next: nextSample,
  );
  return _materializeStitchCandidate(
    candidate: _ReceiptStitchCandidate(
      pixels: match.pixels,
      nextSkipPixels: match.nextSkipPixels,
      nextXOffsetPixels: match.nextXOffsetPixels,
      confidence: match.confidence,
      scaleCorrection: 1,
      sampleHeight: nextSample.height,
      sampleWidth: nextSample.width,
    ),
    previousHeight: previous.height,
    next: next,
    targetWidth: targetWidth,
  );
}

_ReceiptOverlapMatch _bestVerticalOverlap({
  required img.Image previous,
  required img.Image next,
}) {
  final maxOverlap = math.min(previous.height, next.height) * .46;
  final minOverlap = math.min(previous.height, next.height) * .08;
  final minPixels = minOverlap.round().clamp(48, 320);
  final maxPixels = maxOverlap.round().clamp(minPixels + 1, 1400);
  var bestPixels = 0;
  var bestScore = double.infinity;
  var secondBestScore = double.infinity;
  var bestHorizontalOffset = 0;
  var bestNextYOffset = 0;
  final offsetSeeds =
      <int, ({double score, int pixels, int horizontalOffset})>{};
  final geometryCandidates =
      <({double score, int pixels, int horizontalOffset, int nextYOffset})>[];
  final geometryCandidatesByOffsetBucket =
      <
        int,
        ({double score, int pixels, int horizontalOffset, int nextYOffset})
      >{};
  void trackGeometryCandidate({
    required double score,
    required int pixels,
    required int horizontalOffset,
    required int nextYOffset,
  }) {
    final candidate = (
      score: score,
      pixels: pixels,
      horizontalOffset: horizontalOffset,
      nextYOffset: nextYOffset,
    );
    geometryCandidates.add(candidate);
    geometryCandidates.sort((a, b) => a.score.compareTo(b.score));
    if (geometryCandidates.length > 10) geometryCandidates.removeLast();
    final bucket = nextYOffset ~/ 12;
    final bucketCandidate = geometryCandidatesByOffsetBucket[bucket];
    if (bucketCandidate == null || score < bucketCandidate.score) {
      geometryCandidatesByOffsetBucket[bucket] = candidate;
    }
  }

  final horizontalOffsets = _stitchHorizontalOffsets(previous.width);
  for (var pixels = minPixels; pixels <= maxPixels; pixels += 24) {
    final nextTopOffsets = _stitchNextTopOffsets(next.height, pixels);
    for (final horizontalOffset in horizontalOffsets) {
      for (final nextYOffset in nextTopOffsets) {
        final visualScore = _overlapDifference(
          previous: previous,
          next: next,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        final score =
            visualScore +
            (horizontalOffset.abs() / math.max(1, previous.width) * 80) +
            _stitchNextTopOffsetPenalty(
              height: next.height,
              overlapPixels: pixels,
              nextTopOffset: nextYOffset,
            );
        final offsetSeed = offsetSeeds[nextYOffset];
        if (offsetSeed == null || score < offsetSeed.score) {
          offsetSeeds[nextYOffset] = (
            score: score,
            pixels: pixels,
            horizontalOffset: horizontalOffset,
          );
        }
        trackGeometryCandidate(
          score: score,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  // Refine the continuation start as well as the overlap height. The coarse
  // start grid is deliberately small for device cost, but a two- or
  // three-sample miss can put narrow printed strokes out of phase and hide a
  // real overlap. Refining only each coarse offset's best local basin keeps
  // the extra work bounded instead of scanning every possible row.
  for (final entry in offsetSeeds.entries) {
    final seed = entry.value;
    for (var yDelta = -4; yDelta <= 4; yDelta += 2) {
      final nextYOffset = entry.key + yDelta;
      if (nextYOffset < 0 || nextYOffset + minPixels >= next.height) continue;
      for (
        var pixels = seed.pixels - 12;
        pixels <= seed.pixels + 12;
        pixels += 6
      ) {
        if (pixels < minPixels ||
            pixels > maxPixels ||
            nextYOffset + pixels >= next.height) {
          continue;
        }
        final visualScore = _overlapDifference(
          previous: previous,
          next: next,
          pixels: pixels,
          horizontalOffset: seed.horizontalOffset,
          nextYOffset: nextYOffset,
        );
        final score =
            visualScore +
            (seed.horizontalOffset.abs() / math.max(1, previous.width) * 80) +
            _stitchNextTopOffsetPenalty(
              height: next.height,
              overlapPixels: pixels,
              nextTopOffset: nextYOffset,
            );
        trackGeometryCandidate(
          score: score,
          pixels: pixels,
          horizontalOffset: seed.horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = seed.horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  final refinedStart = (bestPixels - 24).clamp(minPixels, maxPixels);
  final refinedEnd = (bestPixels + 24).clamp(minPixels, maxPixels);
  for (var pixels = refinedStart; pixels <= refinedEnd; pixels += 6) {
    final nextTopOffsets = _stitchNextTopOffsets(next.height, pixels);
    for (final horizontalOffset in horizontalOffsets) {
      for (final nextYOffset in nextTopOffsets) {
        final visualScore = _overlapDifference(
          previous: previous,
          next: next,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        final score =
            visualScore +
            (horizontalOffset.abs() / math.max(1, previous.width) * 80) +
            _stitchNextTopOffsetPenalty(
              height: next.height,
              overlapPixels: pixels,
              nextTopOffset: nextYOffset,
            );
        trackGeometryCandidate(
          score: score,
          pixels: pixels,
          horizontalOffset: horizontalOffset,
          nextYOffset: nextYOffset,
        );
        if (_stitchCandidateBeatsCurrent(
          score: score,
          pixels: pixels,
          bestScore: bestScore,
          bestPixels: bestPixels,
        )) {
          secondBestScore = bestScore;
          bestScore = score;
          bestPixels = pixels;
          bestHorizontalOffset = horizontalOffset;
          bestNextYOffset = nextYOffset;
        } else if ((pixels - bestPixels).abs() > 36 &&
            score < secondBestScore) {
          secondBestScore = score;
        }
      }
    }
  }
  // Repetitive receipt rows can make the lowest one-dimensional profile score
  // belong to the wrong occurrence. Re-rank only the bounded best basins with
  // two-dimensional local-ink correspondence, without widening the search.
  ({
    double score,
    int pixels,
    int horizontalOffset,
    int nextYOffset,
    double geometryScore,
  })?
  geometryChoice;
  final geometryShortlist =
      <({double score, int pixels, int horizontalOffset, int nextYOffset})>{
        ...geometryCandidates,
        ...geometryCandidatesByOffsetBucket.values,
      };
  for (final candidate in geometryShortlist) {
    if (candidate.score > bestScore + 40) continue;
    final match = _ReceiptOverlapMatch(
      pixels: candidate.pixels,
      nextSkipPixels: candidate.pixels + candidate.nextYOffset,
      nextXOffsetPixels: candidate.horizontalOffset,
      nextTopOffsetPixels: candidate.nextYOffset,
      confidence: 0,
      nextImage: next,
    );
    final geometry = _receiptOverlapGeometryEvidence(
      previous: previous,
      match: match,
    );
    if (!geometry.isProven) continue;
    final matchShare =
        geometry.matchingCells / math.max(1, geometry.detailedCells);
    final geometryScore =
        candidate.score - geometry.correlation * 16 - matchShare * 5;
    if (geometryChoice == null ||
        geometryScore < geometryChoice.geometryScore) {
      geometryChoice = (
        score: candidate.score,
        pixels: candidate.pixels,
        horizontalOffset: candidate.horizontalOffset,
        nextYOffset: candidate.nextYOffset,
        geometryScore: geometryScore,
      );
    }
  }
  if (geometryChoice != null) {
    bestScore = geometryChoice.score;
    bestPixels = geometryChoice.pixels;
    bestHorizontalOffset = geometryChoice.horizontalOffset;
    bestNextYOffset = geometryChoice.nextYOffset;
  }
  final visualConfidence = (1 - (bestScore / 64)).clamp(0.0, 1.0);
  final distinctiveness = secondBestScore.isFinite
      ? ((secondBestScore - bestScore) / 32).clamp(0.0, 1.0)
      : 1.0;
  final horizontalDriftPenalty = _overlapHorizontalDriftPenalty(
    previous: previous,
    next: next,
    pixels: bestPixels,
    horizontalOffset: bestHorizontalOffset,
    nextYOffset: bestNextYOffset,
  );
  final offsetPenalty = _stitchHorizontalOffsetPenalty(
    width: previous.width,
    offset: bestHorizontalOffset,
  );
  final texturePenalty = _overlapFlatTexturePenalty(
    previous: previous,
    next: next,
    pixels: bestPixels,
    horizontalOffset: bestHorizontalOffset,
    nextYOffset: bestNextYOffset,
  );
  final confidence =
      (visualConfidence * (.55 + (.45 * distinctiveness)) -
              horizontalDriftPenalty -
              offsetPenalty -
              texturePenalty)
          .clamp(0.0, 1.0);
  return _ReceiptOverlapMatch(
    pixels: bestPixels,
    nextSkipPixels: bestPixels + bestNextYOffset,
    nextXOffsetPixels: bestHorizontalOffset,
    nextTopOffsetPixels: bestNextYOffset,
    confidence: confidence,
    nextImage: next,
  );
}

double _stitchNextTopOffsetPenalty({
  required int height,
  required int overlapPixels,
  required int nextTopOffset,
}) {
  // In a normal long-receipt capture the shared area begins near the top of
  // the continuation. A deep start remains possible, but it must win with
  // materially better evidence rather than tying a repeated line pattern.
  final ordinaryPenalty = nextTopOffset / math.max(1, height) * 180;
  if (nextTopOffset <= overlapPixels) return ordinaryPenalty;
  final unsupportedPreRoll = nextTopOffset - overlapPixels;
  return ordinaryPenalty + 48 + (unsupportedPreRoll / math.max(1, height) * 80);
}

bool _stitchCandidateBeatsCurrent({
  required double score,
  required int pixels,
  required double bestScore,
  required int bestPixels,
}) {
  if (!bestScore.isFinite) return true;
  if (score < bestScore) return true;
  // A shorter slice is a strict subset of a real overlap and can score a
  // little cleaner simply because it excludes one faded or shadowed row.
  // Prefer the materially longer candidate when its normalized score remains
  // close, otherwise valid repeated lines are left duplicated at the join.
  final closeEnough = score <= bestScore + 6.0;
  final materiallyLonger = pixels >= bestPixels + 48;
  return closeEnough && materiallyLonger;
}

List<int> _stitchHorizontalOffsets(int width) {
  final unit = math.max(12, (width * .035).round());
  final offsets = <int>[0];
  for (final multiple in const [1, 2, 3]) {
    final offset = unit * multiple;
    offsets.addAll([-offset, offset]);
  }
  final maxOffset = math.max(unit * 2, (width * .14).round());
  offsets.addAll([-maxOffset, maxOffset]);
  return offsets.where((offset) => offset.abs() <= maxOffset).toSet().toList();
}

List<int> _stitchNextTopOffsets(int height, int pixels) {
  final maxOffset = math.min(
    320,
    math.max(0, math.min((height * .26).round(), height - pixels - 24)),
  );
  if (maxOffset <= 0) return const [0];
  final offsets = <int>{0, 12, 24, 36, 48, 72, 96, 132, 168, 220, 260, 320};
  return offsets.where((offset) => offset <= maxOffset).toList(growable: false);
}
