part of '../../receipts/receipt_ocr_contract.dart';

class ReceiptOcrRow {
  const ReceiptOcrRow({
    required this.attachmentId,
    required this.pageIndex,
    required this.readingOrder,
    required this.sourceFragments,
    required this.displayText,
    required this.normalizedText,
    required this.sourceLineIndexes,
    this.bounds,
    this.confidence,
    this.optionalInterpretation,
    this.interpretationConfidence,
    this.needsReview = true,
  });

  final String attachmentId;
  final int pageIndex;
  final int readingOrder;
  final List<String> sourceFragments;
  final String displayText;
  final String normalizedText;
  final List<int> sourceLineIndexes;
  final ReceiptOcrBounds? bounds;
  final double? confidence;
  final String? optionalInterpretation;
  final double? interpretationConfidence;
  final bool needsReview;

  String get sourceText => sourceFragments.join('\t');
}

List<ReceiptOcrRow> reconstructReceiptOcrRows(ReceiptOcrDocument document) {
  final rows = <ReceiptOcrRow>[];
  var readingOrder = 0;
  for (final page in [...document.pages]..sort(_compareOcrPages)) {
    final candidates = _rowCandidates(page);
    final positioned = candidates.where((line) => line.bounds != null).toList()
      ..sort(_compareRowCandidates);
    final clusters = <_ReceiptOcrRowCluster>[];
    for (final candidate in positioned) {
      _ReceiptOcrRowCluster? best;
      var bestScore = -1.0;
      for (final cluster in clusters) {
        final score = cluster.verticalMatchScore(candidate.bounds!);
        if (score > bestScore) {
          best = cluster;
          bestScore = score;
        }
      }
      if (best != null && bestScore >= .35) {
        best.add(candidate);
      } else {
        clusters.add(_ReceiptOcrRowCluster(candidate));
      }
    }
    clusters.sort((left, right) => left.compareTo(right));
    final usedLineIndexes = <int>{};
    for (final cluster in clusters) {
      usedLineIndexes.addAll(cluster.sourceLineIndexes);
      rows.add(
        cluster.toRow(
          attachmentId: page.attachmentId,
          pageIndex: page.pageIndex,
          readingOrder: readingOrder++,
        ),
      );
    }
    for (final candidate in candidates) {
      if (usedLineIndexes.contains(candidate.sourceLineIndex)) continue;
      rows.add(
        _rowFromUnpositionedCandidate(
          page,
          candidate,
          readingOrder: readingOrder++,
        ),
      );
    }
  }
  return List.unmodifiable(rows);
}

List<_ReceiptOcrRowCandidate> _rowCandidates(ReceiptOcrPage page) {
  final candidates = <_ReceiptOcrRowCandidate>[];
  var sourceLineIndex = 0;
  for (final block in page.blocks) {
    for (final line in block.lines) {
      if (line.sourceText.trim().isNotEmpty) {
        candidates.add(
          _ReceiptOcrRowCandidate(
            sourceLineIndex: sourceLineIndex,
            text: line.sourceText,
            bounds: line.bounds,
            confidence: line.confidence,
          ),
        );
      }
      sourceLineIndex++;
    }
  }
  return candidates;
}

int _compareOcrPages(ReceiptOcrPage left, ReceiptOcrPage right) {
  final pageOrder = left.pageIndex.compareTo(right.pageIndex);
  return pageOrder != 0
      ? pageOrder
      : left.attachmentId.compareTo(right.attachmentId);
}

int _compareRowCandidates(
  _ReceiptOcrRowCandidate left,
  _ReceiptOcrRowCandidate right,
) {
  final topOrder = left.bounds!.top.compareTo(right.bounds!.top);
  return topOrder != 0
      ? topOrder
      : left.bounds!.left.compareTo(right.bounds!.left);
}

ReceiptOcrRow _rowFromUnpositionedCandidate(
  ReceiptOcrPage page,
  _ReceiptOcrRowCandidate candidate, {
  required int readingOrder,
}) {
  return ReceiptOcrRow(
    attachmentId: page.attachmentId,
    pageIndex: page.pageIndex,
    readingOrder: readingOrder,
    sourceFragments: List.unmodifiable([candidate.text]),
    displayText: candidate.text,
    normalizedText: _normalizeReceiptOcrEvidenceText(candidate.text),
    sourceLineIndexes: List.unmodifiable([candidate.sourceLineIndex]),
    confidence: candidate.confidence,
    needsReview: candidate.confidence == null,
  );
}

class _ReceiptOcrRowCandidate {
  const _ReceiptOcrRowCandidate({
    required this.sourceLineIndex,
    required this.text,
    required this.bounds,
    required this.confidence,
  });

  final int sourceLineIndex;
  final String text;
  final ReceiptOcrBounds? bounds;
  final double? confidence;
}

class _ReceiptOcrRowCluster {
  _ReceiptOcrRowCluster(_ReceiptOcrRowCandidate first)
    : lines = [first],
      bounds = first.bounds!;

  final List<_ReceiptOcrRowCandidate> lines;
  ReceiptOcrBounds bounds;

  Iterable<int> get sourceLineIndexes =>
      lines.map((line) => line.sourceLineIndex);

  double verticalMatchScore(ReceiptOcrBounds candidate) {
    final overlap =
        _minDouble(bounds.bottom, candidate.bottom) -
        _maxDouble(bounds.top, candidate.top);
    final minimumHeight = _minDouble(bounds.height, candidate.height);
    if (overlap > 0 && minimumHeight > 0) return overlap / minimumHeight;
    final center = (bounds.top + bounds.bottom) / 2;
    final candidateCenter = (candidate.top + candidate.bottom) / 2;
    final tolerance = _maxDouble(8, minimumHeight * .65);
    final distance = (center - candidateCenter).abs();
    if (distance > tolerance) return -1;
    return 1 - (distance / tolerance);
  }

  void add(_ReceiptOcrRowCandidate candidate) {
    lines.add(candidate);
    final value = candidate.bounds!;
    bounds = ReceiptOcrBounds(
      left: _minDouble(bounds.left, value.left),
      top: _minDouble(bounds.top, value.top),
      right: _maxDouble(bounds.right, value.right),
      bottom: _maxDouble(bounds.bottom, value.bottom),
    );
  }

  int compareTo(_ReceiptOcrRowCluster other) {
    final topOrder = bounds.top.compareTo(other.bounds.top);
    return topOrder != 0 ? topOrder : bounds.left.compareTo(other.bounds.left);
  }

  ReceiptOcrRow toRow({
    required String attachmentId,
    required int pageIndex,
    required int readingOrder,
  }) {
    lines.sort(
      (left, right) => left.bounds!.left.compareTo(right.bounds!.left),
    );
    final fragments = lines.map((line) => line.text).toList(growable: false);
    final displayText = fragments.join(' ');
    final confidences = lines
        .map((line) => line.confidence)
        .whereType<double>()
        .toList(growable: false);
    final confidence = confidences.isEmpty
        ? null
        : confidences.reduce((left, right) => left + right) /
              confidences.length;
    return ReceiptOcrRow(
      attachmentId: attachmentId,
      pageIndex: pageIndex,
      readingOrder: readingOrder,
      sourceFragments: List.unmodifiable(fragments),
      displayText: displayText,
      normalizedText: _normalizeReceiptOcrEvidenceText(displayText),
      sourceLineIndexes: List.unmodifiable(sourceLineIndexes),
      bounds: bounds,
      confidence: confidence,
      needsReview: confidence == null,
    );
  }
}

double _minDouble(double left, double right) => left < right ? left : right;
double _maxDouble(double left, double right) => left > right ? left : right;
