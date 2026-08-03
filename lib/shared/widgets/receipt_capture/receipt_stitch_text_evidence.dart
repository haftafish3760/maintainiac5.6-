class ReceiptStitchTextEvidence {
  const ReceiptStitchTextEvidence({required this.path, required this.lines});

  final String path;
  final List<String> lines;

  List<String> get normalizedLines => [
    for (final line in lines)
      if (_normalizeReceiptStitchLine(line).isNotEmpty)
        _normalizeReceiptStitchLine(line),
  ];
}

class ReceiptStitchTextPairEvidence {
  const ReceiptStitchTextPairEvidence({
    required this.confidence,
    required this.matchedLineCount,
    required this.previousTailOffset,
    required this.nextHeadOffset,
  });

  const ReceiptStitchTextPairEvidence.none()
    : confidence = 0,
      matchedLineCount = 0,
      previousTailOffset = 0,
      nextHeadOffset = 0;

  final double confidence;
  final int matchedLineCount;
  final int previousTailOffset;
  final int nextHeadOffset;

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
    if (evidence.length > 6 ||
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

    List<int>? bestOrder;
    var bestScore = -1.0;
    var secondScore = -1.0;
    final indexes = List<int>.generate(evidence.length, (index) => index);
    for (final candidate in _receiptStitchPermutations(indexes)) {
      var score = 0.0;
      var everyPairStrong = true;
      for (var index = 0; index < candidate.length - 1; index++) {
        final adjacent = pair(candidate[index], candidate[index + 1]);
        score += adjacent.confidence * 2;
        everyPairStrong = everyPairStrong && adjacent.isStrong;
      }
      score += _receiptHeaderHint(evidence[candidate.first]) * .20;
      score += _receiptFooterHint(evidence[candidate.last]) * .20;
      if (!everyPairStrong) score -= .45;
      if (score > bestScore) {
        secondScore = bestScore;
        bestScore = score;
        bestOrder = candidate;
      } else if (score > secondScore) {
        secondScore = score;
      }
    }

    final selected = bestOrder ?? indexes;
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
        final coverageBonus = count <= 1 ? 0.0 : (count - 1) * .035;
        final offsetPenalty = (tailOffset + headOffset) * .025;
        final confidence = (average + coverageBonus - offsetPenalty).clamp(
          0.0,
          1.0,
        );
        if (confidence > best.confidence ||
            (confidence == best.confidence && count > best.matchedLineCount)) {
          best = ReceiptStitchTextPairEvidence(
            confidence: confidence,
            matchedLineCount: count,
            previousTailOffset: tailOffset,
            nextHeadOffset: headOffset,
          );
        }
      }
    }
  }
  return best;
}

Iterable<List<int>> _receiptStitchPermutations(List<int> values) sync* {
  if (values.length <= 1) {
    yield List<int>.of(values);
    return;
  }
  for (var index = 0; index < values.length; index++) {
    final head = values[index];
    final rest = <int>[...values.take(index), ...values.skip(index + 1)];
    for (final tail in _receiptStitchPermutations(rest)) {
      yield [head, ...tail];
    }
  }
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

double _receiptStitchLineSimilarity(String left, String right) {
  if (left == right) return 1;
  if (left.isEmpty || right.isEmpty) return 0;
  final leftTokens = left.split(' ').where((token) => token.length > 1).toSet();
  final rightTokens = right
      .split(' ')
      .where((token) => token.length > 1)
      .toSet();
  if (leftTokens.isEmpty || rightTokens.isEmpty) return 0;
  final shared = leftTokens.intersection(rightTokens).length;
  final union = leftTokens.union(rightTokens).length;
  final tokenScore = union == 0 ? 0.0 : shared / union;
  final leftBigrams = _receiptStitchBigrams(left);
  final rightBigrams = _receiptStitchBigrams(right);
  final sharedBigrams = leftBigrams.intersection(rightBigrams).length;
  final bigramUnion = leftBigrams.union(rightBigrams).length;
  final bigramScore = bigramUnion == 0 ? 0.0 : sharedBigrams / bigramUnion;
  final score = (tokenScore * .62 + bigramScore * .38).clamp(0.0, 1.0);
  final leftNumbers = RegExp(
    r'\d+(?:[.,]\d+)?',
  ).allMatches(left).map((match) => match.group(0)).toSet();
  final rightNumbers = RegExp(
    r'\d+(?:[.,]\d+)?',
  ).allMatches(right).map((match) => match.group(0)).toSet();
  if (leftNumbers.isNotEmpty &&
      rightNumbers.isNotEmpty &&
      !_sameReceiptNumberTokens(leftNumbers, rightNumbers)) {
    return score.clamp(0.0, .44);
  }
  return score;
}

Set<String> _receiptStitchBigrams(String value) {
  final compact = value.replaceAll(' ', '');
  if (compact.length < 2) return {compact};
  return {
    for (var index = 0; index < compact.length - 1; index++)
      compact.substring(index, index + 2),
  };
}

bool _isDistinctiveReceiptLine(String value) {
  if (value.length < 6) return false;
  final tokens = value.split(' ').where((token) => token.length > 1).length;
  return tokens >= 2 || RegExp(r'\d').hasMatch(value);
}

bool _isUniqueReceiptOverlapLine(String value) {
  if (!_isDistinctiveReceiptLine(value) || value.length < 12) return false;
  const genericTerms = [
    'subtotal',
    'total',
    'tax',
    'balance',
    'amount due',
    'payment',
    'thank you',
  ];
  return !genericTerms.any(value.startsWith);
}

bool _sameReceiptNumberTokens(Set<String?> left, Set<String?> right) {
  if (left.length != right.length) return false;
  return left.every(right.contains);
}

String _normalizeReceiptStitchLine(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

int _minInt(int left, int right) => left < right ? left : right;
