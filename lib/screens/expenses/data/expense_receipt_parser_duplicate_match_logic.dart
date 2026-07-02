part of 'expense_receipt_parser.dart';

List<_DuplicateParsedLinePair> _adjacentDuplicateParsedLinePairs(
  List<ExpenseReceiptLineRecord> lines,
) {
  if (lines.length < 2) return const [];
  final pairs = <_DuplicateParsedLinePair>[];
  for (var index = 0; index < lines.length - 1; index++) {
    final first = lines[index];
    final maxCandidateIndex = (index + 2).clamp(0, lines.length - 1);
    for (
      var candidateIndex = index + 1;
      candidateIndex <= maxCandidateIndex;
      candidateIndex++
    ) {
      final second = lines[candidateIndex];
      final matchType = _duplicateParsedLineMatchType(first, second);
      if (matchType != null) {
        pairs.add(
          _DuplicateParsedLinePair(
            first: first,
            second: second,
            lineDistance: candidateIndex - index,
            isExact: matchType == _DuplicateParsedLineMatchType.exact,
          ),
        );
        break;
      }
    }
  }
  return List.unmodifiable(pairs);
}

List<String> _adjacentDuplicateParsedLineSourceLabels(
  List<_DuplicateParsedLinePair> pairs,
) {
  final labels = <String>[];
  for (final pair in pairs) {
    final label = _duplicateParsedLineSourceLabel(pair.first, pair.second);
    if (label.isNotEmpty && !labels.contains(label)) {
      labels.add(label);
    }
  }
  return List.unmodifiable(labels);
}

List<String> _adjacentDuplicateParsedLineWindowLabels(
  List<_DuplicateParsedLinePair> pairs,
) {
  final labels = <String>[];
  for (final pair in pairs) {
    final label = pair.windowLabel;
    if (label.isNotEmpty && !labels.contains(label)) labels.add(label);
  }
  return List.unmodifiable(labels);
}

List<String> _adjacentDuplicateParsedLineConfidenceLabels(
  List<_DuplicateParsedLinePair> pairs,
) {
  final labels = <String>[];
  for (final pair in pairs) {
    final label = pair.confidenceLabel;
    if (label.isNotEmpty && !labels.contains(label)) labels.add(label);
  }
  return List.unmodifiable(labels);
}

String _duplicateParsedLineSourceLabel(
  ExpenseReceiptLineRecord first,
  ExpenseReceiptLineRecord second,
) {
  final firstLabel = first.receiptProofLineReferenceLabel.trim();
  final secondLabel = second.receiptProofLineReferenceLabel.trim();
  if (firstLabel.isEmpty && secondLabel.isEmpty) return '';
  if (firstLabel.isEmpty) return secondLabel;
  if (secondLabel.isEmpty || secondLabel == firstLabel) return firstLabel;
  return '$firstLabel -> $secondLabel';
}

_DuplicateParsedLineMatchType? _duplicateParsedLineMatchType(
  ExpenseReceiptLineRecord first,
  ExpenseReceiptLineRecord second,
) {
  final firstDescription = _parsedLineDescriptionKey(first);
  final secondDescription = _parsedLineDescriptionKey(second);
  if (firstDescription.isEmpty || secondDescription.isEmpty) return null;
  if (first.subtotal.toStringAsFixed(2) != second.subtotal.toStringAsFixed(2)) {
    return null;
  }
  if (firstDescription == secondDescription) {
    return _DuplicateParsedLineMatchType.exact;
  }
  if (_parsedLineDescriptionSimilarity(firstDescription, secondDescription) >=
      .84) {
    return _DuplicateParsedLineMatchType.near;
  }
  return null;
}

String _parsedLineDescriptionKey(ExpenseReceiptLineRecord line) {
  return line.description
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

double _parsedLineDescriptionSimilarity(String first, String second) {
  final firstCompact = first.replaceAll(' ', '');
  final secondCompact = second.replaceAll(' ', '');
  if (firstCompact.length < 6 || secondCompact.length < 6) return 0;
  final longerLength = firstCompact.length > secondCompact.length
      ? firstCompact.length
      : secondCompact.length;
  if (longerLength == 0) return 0;
  final distance = _boundedEditDistance(firstCompact, secondCompact, 3);
  if (distance > 3) return 0;
  return 1 - (distance / longerLength);
}

int _boundedEditDistance(String first, String second, int maxDistance) {
  if ((first.length - second.length).abs() > maxDistance) {
    return maxDistance + 1;
  }
  var previous = List<int>.generate(second.length + 1, (index) => index);
  for (var i = 1; i <= first.length; i++) {
    final current = List<int>.filled(second.length + 1, 0);
    current[0] = i;
    var rowMinimum = current[0];
    for (var j = 1; j <= second.length; j++) {
      final substitutionCost =
          first.codeUnitAt(i - 1) == second.codeUnitAt(j - 1) ? 0 : 1;
      final insertCost = current[j - 1] + 1;
      final deleteCost = previous[j] + 1;
      final substituteCost = previous[j - 1] + substitutionCost;
      var best = insertCost < deleteCost ? insertCost : deleteCost;
      if (substituteCost < best) best = substituteCost;
      current[j] = best;
      if (best < rowMinimum) rowMinimum = best;
    }
    if (rowMinimum > maxDistance) return maxDistance + 1;
    previous = current;
  }
  return previous.last;
}

enum _DuplicateParsedLineMatchType { exact, near }

class _DuplicateParsedLinePair {
  const _DuplicateParsedLinePair({
    required this.first,
    required this.second,
    required this.lineDistance,
    required this.isExact,
  });

  final ExpenseReceiptLineRecord first;
  final ExpenseReceiptLineRecord second;
  final int lineDistance;
  final bool isExact;

  String get windowLabel {
    if (lineDistance <= 1) return 'adjacent overlap';
    return 'one-line gap overlap';
  }

  String get confidenceLabel {
    if (isExact && lineDistance <= 1) return 'high-confidence overlap';
    if (isExact) return 'high-confidence one-line overlap';
    if (lineDistance <= 1) return 'probable OCR overlap';
    return 'review OCR overlap';
  }
}
