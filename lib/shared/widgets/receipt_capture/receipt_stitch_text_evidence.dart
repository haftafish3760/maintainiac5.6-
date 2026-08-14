import 'dart:math' as math;

part 'receipt_stitch_order_solver.dart';
part 'receipt_stitch_text_evidence_similarity.dart';

class ReceiptStitchTextEvidence {
  const ReceiptStitchTextEvidence({
    required this.path,
    required this.lines,
    this.positionedLines = const <ReceiptStitchTextLineEvidence>[],
  });

  final String path;
  final List<String> lines;
  final List<ReceiptStitchTextLineEvidence> positionedLines;

  bool get hasPositionedLines => positionedLines.isNotEmpty;

  List<String> get normalizedLines => [
    for (final line
        in positionedLines.isEmpty
            ? lines
            : positionedLines.map((item) => item.text))
      if (_normalizeReceiptStitchLine(line).isNotEmpty)
        _normalizeReceiptStitchLine(line),
  ];
}

class ReceiptStitchTextLineEvidence {
  const ReceiptStitchTextLineEvidence({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.angleDegrees = 0,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double angleDegrees;

  double get centerX => ((left + right) / 2).clamp(0.0, 1.0);
  double get centerY => ((top + bottom) / 2).clamp(0.0, 1.0);
  double get width => (right - left).clamp(0.0, 1.0);
  double get height => (bottom - top).clamp(0.0, 1.0);
}

class ReceiptStitchTextPairEvidence {
  const ReceiptStitchTextPairEvidence({
    required this.confidence,
    required this.matchedLineCount,
    required this.previousTailOffset,
    required this.nextHeadOffset,
    this.positionalConfidence = 0,
    this.hasPositionalEvidence = false,
    this.previousOverlapStart = 0,
    this.nextOverlapEnd = 0,
    this.nextContinuationStart = 0,
    this.nextContinuationEnd = 0,
    this.previousAnchorCenters = const <double>[],
    this.nextAnchorCenters = const <double>[],
    this.previousAnchorCentersX = const <double>[],
    this.nextAnchorCentersX = const <double>[],
    this.previousAnchorWidths = const <double>[],
    this.nextAnchorWidths = const <double>[],
    this.previousAnchorAngles = const <double>[],
    this.nextAnchorAngles = const <double>[],
    this.usesSparsePositionAnchors = false,
  });

  const ReceiptStitchTextPairEvidence.none()
    : confidence = 0,
      matchedLineCount = 0,
      previousTailOffset = 0,
      nextHeadOffset = 0,
      positionalConfidence = 0,
      hasPositionalEvidence = false,
      previousOverlapStart = 0,
      nextOverlapEnd = 0,
      nextContinuationStart = 0,
      nextContinuationEnd = 0,
      previousAnchorCenters = const <double>[],
      nextAnchorCenters = const <double>[],
      previousAnchorCentersX = const <double>[],
      nextAnchorCentersX = const <double>[],
      previousAnchorWidths = const <double>[],
      nextAnchorWidths = const <double>[],
      previousAnchorAngles = const <double>[],
      nextAnchorAngles = const <double>[],
      usesSparsePositionAnchors = false;

  final double confidence;
  final int matchedLineCount;
  final int previousTailOffset;
  final int nextHeadOffset;
  final double positionalConfidence;
  final bool hasPositionalEvidence;
  final double previousOverlapStart;
  final double nextOverlapEnd;
  final double nextContinuationStart;
  final double nextContinuationEnd;
  final List<double> previousAnchorCenters;
  final List<double> nextAnchorCenters;
  final List<double> previousAnchorCentersX;
  final List<double> nextAnchorCentersX;
  final List<double> previousAnchorWidths;
  final List<double> nextAnchorWidths;
  final List<double> previousAnchorAngles;
  final List<double> nextAnchorAngles;
  final bool usesSparsePositionAnchors;

  bool get isStrong =>
      confidence >= .66 && (matchedLineCount >= 2 || confidence >= .94);
}

class ReceiptStitchOrderPlan {
  const ReceiptStitchOrderPlan({
    required this.originalPaths,
    required this.orderedPaths,
    required this.confidence,
    required this.changed,
    required this.requiresReview,
    required this.reasonCode,
  });

  final List<String> originalPaths;
  final List<String> orderedPaths;
  final double confidence;
  final bool changed;
  final bool requiresReview;
  final String reasonCode;

  static ReceiptStitchOrderPlan fromEvidence(
    List<ReceiptStitchTextEvidence> evidence,
  ) {
    final original = [for (final item in evidence) item.path];
    if (evidence.length <= 1) {
      return ReceiptStitchOrderPlan(
        originalPaths: original,
        orderedPaths: original,
        confidence: 1,
        changed: false,
        requiresReview: false,
        reasonCode: 'single_section',
      );
    }
    if (evidence.length > 8 ||
        evidence.any((item) => item.normalizedLines.isEmpty)) {
      return ReceiptStitchOrderPlan(
        originalPaths: original,
        orderedPaths: original,
        confidence: 0,
        changed: false,
        requiresReview: true,
        reasonCode: 'insufficient_text_evidence',
      );
    }

    final pairEvidence = <String, ReceiptStitchTextPairEvidence>{};
    ReceiptStitchTextPairEvidence pair(int from, int to) {
      return pairEvidence.putIfAbsent(
        '$from:$to',
        () => matchReceiptStitchTextOverlap(evidence[from], evidence[to]),
      );
    }

    final indexes = List<int>.generate(evidence.length, (index) => index);
    final candidates = _bestReceiptStitchOrders(evidence, pair);
    final selected = candidates.isEmpty ? indexes : candidates.first.order;
    final bestScore = candidates.isEmpty ? -1.0 : candidates.first.score;
    final secondScore = candidates.length < 2 ? -1.0 : candidates[1].score;
    final pairConfidences = <double>[
      for (var index = 0; index < selected.length - 1; index++)
        pair(selected[index], selected[index + 1]).confidence,
    ];
    final weakestPair = pairConfidences.reduce(
      (current, value) => current < value ? current : value,
    );
    final margin = bestScore - secondScore;
    final isClear = weakestPair >= .66 && margin >= .18;
    final changed =
        isClear &&
        List.generate(
          selected.length,
          (index) => selected[index] != index,
        ).any((value) => value);
    final ordered = changed
        ? [for (final index in selected) evidence[index].path]
        : original;
    return ReceiptStitchOrderPlan(
      originalPaths: original,
      orderedPaths: ordered,
      confidence: weakestPair.clamp(0.0, 1.0),
      changed: changed,
      requiresReview: !isClear,
      reasonCode: changed
          ? 'ocr_overlap_order_corrected'
          : isClear
          ? 'ocr_overlap_order_confirmed'
          : 'ocr_overlap_order_ambiguous',
    );
  }
}

ReceiptStitchTextPairEvidence matchReceiptStitchTextOverlap(
  ReceiptStitchTextEvidence previous,
  ReceiptStitchTextEvidence next,
) {
  final previousLines = previous.normalizedLines;
  final nextLines = next.normalizedLines;
  if (previousLines.isEmpty || nextLines.isEmpty) {
    return const ReceiptStitchTextPairEvidence.none();
  }
  var best = const ReceiptStitchTextPairEvidence.none();
  final maximumLines = _minInt(
    8,
    _minInt(previousLines.length, nextLines.length),
  );
  final maximumTailOffset = _minInt(3, previousLines.length - 1);
  final maximumHeadOffset = _minInt(3, nextLines.length - 1);
  for (var tailOffset = 0; tailOffset <= maximumTailOffset; tailOffset++) {
    for (var headOffset = 0; headOffset <= maximumHeadOffset; headOffset++) {
      final availablePrevious = previousLines.length - tailOffset;
      final availableNext = nextLines.length - headOffset;
      final lineLimit = _minInt(
        maximumLines,
        _minInt(availablePrevious, availableNext),
      );
      for (var count = 1; count <= lineLimit; count++) {
        final previousStart = availablePrevious - count;
        var total = 0.0;
        var weakest = 1.0;
        var distinctiveMatches = 0;
        for (var line = 0; line < count; line++) {
          final left = previousLines[previousStart + line];
          final right = nextLines[headOffset + line];
          final similarity = _receiptStitchLineSimilarity(left, right);
          total += similarity;
          if (similarity < weakest) weakest = similarity;
          if (similarity >= .72 && _isDistinctiveReceiptLine(left)) {
            distinctiveMatches += 1;
          }
        }
        final average = total / count;
        final enoughEvidence = count >= 2
            ? distinctiveMatches >= 1 && weakest >= .48
            : distinctiveMatches == 1 &&
                  average >= .94 &&
                  _isUniqueReceiptOverlapLine(previousLines[previousStart]);
        if (!enoughEvidence) continue;
        final position = _receiptStitchPositionEvidence(
          previous: previous,
          next: next,
          previousStart: previousStart,
          nextStart: headOffset,
          count: count,
        );
        if (position.isContradictory) continue;
        final coverageBonus = count <= 1 ? 0.0 : (count - 1) * .035;
        final offsetPenalty = (tailOffset + headOffset) * .025;
        final positionAdjustment = position.available
            ? (position.confidence - .5) * .12
            : 0.0;
        final confidence =
            (average + coverageBonus - offsetPenalty + positionAdjustment)
                .clamp(0.0, 1.0);
        final materiallyBetterConfidence = confidence > best.confidence + .025;
        final longerComparableMatch =
            count > best.matchedLineCount &&
            confidence >= best.confidence - .08;
        if (materiallyBetterConfidence ||
            longerComparableMatch ||
            (best.matchedLineCount == 0 && confidence > best.confidence)) {
          best = ReceiptStitchTextPairEvidence(
            confidence: confidence,
            matchedLineCount: count,
            previousTailOffset: tailOffset,
            nextHeadOffset: headOffset,
            positionalConfidence: position.confidence,
            hasPositionalEvidence: position.available,
            previousOverlapStart: position.previousStart,
            nextOverlapEnd: position.nextEnd,
            nextContinuationStart: position.nextContinuationStart,
            nextContinuationEnd: position.nextContinuationEnd,
            previousAnchorCenters: position.previousCenters,
            nextAnchorCenters: position.nextCenters,
            previousAnchorCentersX: position.previousCentersX,
            nextAnchorCentersX: position.nextCentersX,
            previousAnchorWidths: position.previousWidths,
            nextAnchorWidths: position.nextWidths,
            previousAnchorAngles: position.previousAngles,
            nextAnchorAngles: position.nextAngles,
          );
        }
      }
    }
  }
  final sparsePositionMatch = _matchSparsePositionedReceiptAnchors(
    previous,
    next,
  );
  if (sparsePositionMatch != null &&
      (sparsePositionMatch.confidence > best.confidence + .025 ||
          (sparsePositionMatch.matchedLineCount > best.matchedLineCount &&
              sparsePositionMatch.confidence >= best.confidence - .10) ||
          !best.isStrong)) {
    return sparsePositionMatch;
  }
  return best;
}

ReceiptStitchTextPairEvidence? _matchSparsePositionedReceiptAnchors(
  ReceiptStitchTextEvidence previous,
  ReceiptStitchTextEvidence next,
) {
  if (!previous.hasPositionedLines || !next.hasPositionedLines) return null;
  final previousStart = previous.positionedLines.length > 72
      ? previous.positionedLines.length - 72
      : 0;
  final previousCandidates = <int>[
    for (
      var index = previousStart;
      index < previous.positionedLines.length;
      index++
    )
      if (previous.positionedLines[index].centerY >= .30) index,
  ];
  final nextCandidates = <int>[
    for (
      var index = 0;
      index < next.positionedLines.length && index < 72;
      index++
    )
      if (next.positionedLines[index].centerY <= .70) index,
  ];
  final candidates =
      <({int previousIndex, int nextIndex, double similarity})>[];
  for (final previousIndex in previousCandidates) {
    final previousText = _normalizeReceiptStitchLine(
      previous.positionedLines[previousIndex].text,
    );
    if (!_isDistinctiveReceiptLine(previousText)) continue;
    for (final nextIndex in nextCandidates) {
      final nextText = _normalizeReceiptStitchLine(
        next.positionedLines[nextIndex].text,
      );
      if (!_isDistinctiveReceiptLine(nextText)) continue;
      final similarity = _receiptStitchLineSimilarity(previousText, nextText);
      if (similarity >= .68) {
        candidates.add((
          previousIndex: previousIndex,
          nextIndex: nextIndex,
          similarity: similarity,
        ));
      }
    }
  }
  if (candidates.length < 2) return null;
  candidates.sort((left, right) {
    final previousOrder = left.previousIndex.compareTo(right.previousIndex);
    return previousOrder != 0
        ? previousOrder
        : left.nextIndex.compareTo(right.nextIndex);
  });
  final lengths = List<int>.filled(candidates.length, 1);
  final scores = [for (final candidate in candidates) candidate.similarity];
  final parents = List<int>.filled(candidates.length, -1);
  var bestIndex = 0;
  for (var index = 0; index < candidates.length; index++) {
    for (var prior = 0; prior < index; prior++) {
      if (candidates[prior].previousIndex >= candidates[index].previousIndex ||
          candidates[prior].nextIndex >= candidates[index].nextIndex) {
        continue;
      }
      final candidateLength = lengths[prior] + 1;
      final candidateScore = scores[prior] + candidates[index].similarity;
      if (candidateLength > lengths[index] ||
          (candidateLength == lengths[index] &&
              candidateScore > scores[index])) {
        lengths[index] = candidateLength;
        scores[index] = candidateScore;
        parents[index] = prior;
      }
    }
    if (lengths[index] > lengths[bestIndex] ||
        (lengths[index] == lengths[bestIndex] &&
            scores[index] > scores[bestIndex])) {
      bestIndex = index;
    }
  }
  if (lengths[bestIndex] < 2) return null;
  final selected = <({int previousIndex, int nextIndex, double similarity})>[];
  for (var index = bestIndex; index >= 0; index = parents[index]) {
    selected.add(candidates[index]);
    if (parents[index] < 0) break;
  }
  final ordered = selected.reversed.toList(growable: false);
  final previousTexts = {
    for (final candidate in ordered)
      _normalizeReceiptStitchLine(
        previous.positionedLines[candidate.previousIndex].text,
      ),
  };
  final nextTexts = {
    for (final candidate in ordered)
      _normalizeReceiptStitchLine(
        next.positionedLines[candidate.nextIndex].text,
      ),
  };
  if (previousTexts.length < 2 || nextTexts.length < 2) return null;
  final previousLines = [
    for (final candidate in ordered)
      previous.positionedLines[candidate.previousIndex],
  ];
  final nextLines = [
    for (final candidate in ordered) next.positionedLines[candidate.nextIndex],
  ];
  final nextContinuation = _nextReceiptTextBandAfter(
    next.positionedLines,
    nextLines.last.bottom,
  );
  final averageSimilarity =
      ordered.fold<double>(0, (sum, item) => sum + item.similarity) /
      ordered.length;
  final edgeProximity =
      (previousLines.last.bottom + (1 - nextLines.first.top)) / 2;
  final previousSpan = previousLines.last.bottom - previousLines.first.top;
  final nextSpan = nextLines.last.bottom - nextLines.first.top;
  final spanCompatibility = (1 - (previousSpan - nextSpan).abs()).clamp(
    0.0,
    1.0,
  );
  final positionalConfidence = (edgeProximity * .62 + spanCompatibility * .38)
      .clamp(0.0, 1.0);
  final confidence =
      (averageSimilarity +
              math.min(.18, (ordered.length - 1) * .025) +
              (positionalConfidence - .5) * .10)
          .clamp(0.0, 1.0);
  return ReceiptStitchTextPairEvidence(
    confidence: confidence,
    matchedLineCount: ordered.length,
    previousTailOffset:
        previous.positionedLines.length - 1 - ordered.last.previousIndex,
    nextHeadOffset: ordered.first.nextIndex,
    positionalConfidence: positionalConfidence,
    hasPositionalEvidence: true,
    previousOverlapStart: previousLines.first.top.clamp(0.0, 1.0),
    nextOverlapEnd: nextLines.last.bottom.clamp(0.0, 1.0),
    nextContinuationStart: nextContinuation.start,
    nextContinuationEnd: nextContinuation.end,
    previousAnchorCenters: [for (final line in previousLines) line.centerY],
    nextAnchorCenters: [for (final line in nextLines) line.centerY],
    previousAnchorCentersX: [for (final line in previousLines) line.centerX],
    nextAnchorCentersX: [for (final line in nextLines) line.centerX],
    previousAnchorWidths: [for (final line in previousLines) line.width],
    nextAnchorWidths: [for (final line in nextLines) line.width],
    previousAnchorAngles: [for (final line in previousLines) line.angleDegrees],
    nextAnchorAngles: [for (final line in nextLines) line.angleDegrees],
    usesSparsePositionAnchors: true,
  );
}

({
  bool available,
  bool isContradictory,
  double confidence,
  double previousStart,
  double nextEnd,
  double nextContinuationStart,
  double nextContinuationEnd,
  List<double> previousCenters,
  List<double> nextCenters,
  List<double> previousCentersX,
  List<double> nextCentersX,
  List<double> previousWidths,
  List<double> nextWidths,
  List<double> previousAngles,
  List<double> nextAngles,
})
_receiptStitchPositionEvidence({
  required ReceiptStitchTextEvidence previous,
  required ReceiptStitchTextEvidence next,
  required int previousStart,
  required int nextStart,
  required int count,
}) {
  if (!previous.hasPositionedLines || !next.hasPositionedLines) {
    return (
      available: false,
      isContradictory: false,
      confidence: 0.0,
      previousStart: 0.0,
      nextEnd: 0.0,
      nextContinuationStart: 0.0,
      nextContinuationEnd: 0.0,
      previousCenters: const <double>[],
      nextCenters: const <double>[],
      previousCentersX: const <double>[],
      nextCentersX: const <double>[],
      previousWidths: const <double>[],
      nextWidths: const <double>[],
      previousAngles: const <double>[],
      nextAngles: const <double>[],
    );
  }
  if (previousStart < 0 ||
      nextStart < 0 ||
      previousStart + count > previous.positionedLines.length ||
      nextStart + count > next.positionedLines.length) {
    return (
      available: false,
      isContradictory: false,
      confidence: 0.0,
      previousStart: 0.0,
      nextEnd: 0.0,
      nextContinuationStart: 0.0,
      nextContinuationEnd: 0.0,
      previousCenters: const <double>[],
      nextCenters: const <double>[],
      previousCentersX: const <double>[],
      nextCentersX: const <double>[],
      previousWidths: const <double>[],
      nextWidths: const <double>[],
      previousAngles: const <double>[],
      nextAngles: const <double>[],
    );
  }
  final previousLines = previous.positionedLines.sublist(
    previousStart,
    previousStart + count,
  );
  final nextLines = next.positionedLines.sublist(nextStart, nextStart + count);
  final previousFirst = previousLines.first;
  final previousLast = previousLines.last;
  final nextFirst = nextLines.first;
  final nextLast = nextLines.last;
  final nextContinuation = _nextReceiptTextBandAfter(
    next.positionedLines,
    nextLast.bottom,
  );
  final contradictory = previousLast.centerY < .25 && nextFirst.centerY > .75;
  final edgeProximity =
      (previousLast.bottom.clamp(0.0, 1.0) +
          (1 - nextFirst.top.clamp(0.0, 1.0))) /
      2;
  final previousSpan = (previousLast.bottom - previousFirst.top).abs();
  final nextSpan = (nextLast.bottom - nextFirst.top).abs();
  final spanCompatibility = (1 - (previousSpan - nextSpan).abs()).clamp(
    0.0,
    1.0,
  );
  var orderCompatibility = 1.0;
  for (var index = 1; index < count; index++) {
    if (previousLines[index].centerY <= previousLines[index - 1].centerY ||
        nextLines[index].centerY <= nextLines[index - 1].centerY) {
      orderCompatibility = 0;
      break;
    }
  }
  final confidence =
      (edgeProximity * .55 + spanCompatibility * .25 + orderCompatibility * .20)
          .clamp(0.0, 1.0);
  return (
    available: true,
    isContradictory: contradictory,
    confidence: confidence,
    previousStart: previousFirst.top.clamp(0.0, 1.0),
    nextEnd: nextLast.bottom.clamp(0.0, 1.0),
    nextContinuationStart: nextContinuation.start,
    nextContinuationEnd: nextContinuation.end,
    previousCenters: [for (final line in previousLines) line.centerY],
    nextCenters: [for (final line in nextLines) line.centerY],
    previousCentersX: [for (final line in previousLines) line.centerX],
    nextCentersX: [for (final line in nextLines) line.centerX],
    previousWidths: [for (final line in previousLines) line.width],
    nextWidths: [for (final line in nextLines) line.width],
    previousAngles: [for (final line in previousLines) line.angleDegrees],
    nextAngles: [for (final line in nextLines) line.angleDegrees],
  );
}

({double start, double end}) _nextReceiptTextBandAfter(
  List<ReceiptStitchTextLineEvidence> lines,
  double matchedEnd,
) {
  final following =
      lines
          .where((line) => line.centerY > matchedEnd + .002)
          .toList(growable: false)
        ..sort((left, right) => left.top.compareTo(right.top));
  if (following.isEmpty) return (start: 0.0, end: 0.0);
  final first = following.first;
  var bandEnd = first.bottom;
  for (final line in following.skip(1)) {
    if (line.top > bandEnd + .006) break;
    bandEnd = math.max(bandEnd, line.bottom);
  }
  return (start: first.top.clamp(0.0, 1.0), end: bandEnd.clamp(0.0, 1.0));
}

bool receiptStitchTextSafelyAcceleratesGeometry(
  ReceiptStitchTextEvidence previous,
  ReceiptStitchTextEvidence next,
  ReceiptStitchTextPairEvidence match,
) {
  if (!match.isStrong || match.matchedLineCount < 2) return false;
  if (match.usesSparsePositionAnchors) return true;
  final previousLines = previous.normalizedLines;
  final nextLines = next.normalizedLines;
  final previousEnd = previousLines.length - match.previousTailOffset;
  final previousStart = previousEnd - match.matchedLineCount;
  final nextStart = match.nextHeadOffset;
  final nextEnd = nextStart + match.matchedLineCount;
  if (previousStart < 0 ||
      previousEnd > previousLines.length ||
      nextStart < 0 ||
      nextEnd > nextLines.length) {
    return false;
  }
  return previousLines.sublist(previousStart, previousEnd).toSet().length >=
          2 &&
      nextLines.sublist(nextStart, nextEnd).toSet().length >= 2;
}

double _receiptHeaderHint(ReceiptStitchTextEvidence evidence) {
  final text = evidence.normalizedLines.take(6).join(' ');
  const terms = ['store', 'address', 'phone', 'tel', 'receipt', 'invoice'];
  final matches = terms.where(text.contains).length;
  return (matches / 2).clamp(0.0, 1.0);
}

double _receiptFooterHint(ReceiptStitchTextEvidence evidence) {
  final lines = evidence.normalizedLines;
  final text = lines.skip(lines.length > 8 ? lines.length - 8 : 0).join(' ');
  const terms = [
    'subtotal',
    'total',
    'amount due',
    'balance',
    'thank you',
    'importe',
    'gracias',
  ];
  final matches = terms.where(text.contains).length;
  return (matches / 2).clamp(0.0, 1.0);
}

int _minInt(int left, int right) => left < right ? left : right;
