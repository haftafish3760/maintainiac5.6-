part of 'receipt_ocr_service.dart';

_CombinedReceiptText _combinedReceiptText(Iterable<String> sections) {
  final rawSections = <String>[];
  final parserSections = <String>[];
  final parserLineSourceLocations = <ReceiptOcrParserLineLocation>[];
  var previousExactLines = const <String>[];
  var previousProbableTail = const <String>[];
  var suppressedDuplicateLines = 0;
  var probableOverlapLines = 0;
  var possibleSectionGaps = 0;
  var sectionIndex = 0;
  for (final section in sections) {
    final rawSectionLines = section
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    if (rawSectionLines.isEmpty) continue;
    final exactLines = rawSectionLines
        .map(_receiptLineDedupeKey)
        .toList(growable: false);
    final exactOverlapCount = _receiptExactSectionOverlapCount(
      previousExactLines,
      exactLines,
    );
    final suppressExactOverlapCount =
        _receiptOverlapCanBeSuppressed(exactLines.take(exactOverlapCount))
        ? exactOverlapCount
        : 0;
    final parserSectionLines = <String>[];
    var foundBoundarySignal = sectionIndex == 0 || exactOverlapCount > 0;
    if (exactOverlapCount > 0 && suppressExactOverlapCount == 0) {
      probableOverlapLines += exactOverlapCount;
    }
    final previousProbableTailSet = previousProbableTail.toSet();
    for (
      var rawLineIndex = 0;
      rawLineIndex < rawSectionLines.length;
      rawLineIndex++
    ) {
      final clean = rawSectionLines[rawLineIndex];
      final probableKey = _receiptLineProbableOverlapKey(clean);
      if (rawLineIndex < suppressExactOverlapCount) {
        suppressedDuplicateLines += 1;
        continue;
      }
      if (rawLineIndex == 0 &&
          exactOverlapCount == 0 &&
          probableKey.length >= 5 &&
          previousProbableTailSet.contains(probableKey)) {
        probableOverlapLines += 1;
        foundBoundarySignal = true;
      }
      parserSectionLines.add(clean);
      parserLineSourceLocations.add(
        ReceiptOcrParserLineLocation(
          sectionNumber: sectionIndex + 1,
          sectionLineNumber: rawLineIndex + 1,
        ),
      );
    }
    if (!foundBoundarySignal && previousExactLines.isNotEmpty) {
      possibleSectionGaps += 1;
    }
    // Keep the provider's section text unchanged for source evidence. The
    // parser copy above is intentionally cleaned separately.
    rawSections.add(section);
    if (parserSectionLines.isNotEmpty) {
      parserSections.add(parserSectionLines.join('\n'));
    }
    previousExactLines = exactLines;
    previousProbableTail = rawSectionLines
        .map(_receiptLineProbableOverlapKey)
        .where((key) => key.length >= 5)
        .toList(growable: false)
        .reversed
        .take(8)
        .toList(growable: false);
    sectionIndex += 1;
  }
  return _CombinedReceiptText(
    rawText: rawSections.join('\n\n'),
    parserText: parserSections.join('\n\n').trim(),
    parserLineSourceLocations: List.unmodifiable(parserLineSourceLocations),
    suppressedDuplicateLines: suppressedDuplicateLines,
    probableOverlapLines: probableOverlapLines,
    possibleSectionGaps: possibleSectionGaps,
  );
}

int _receiptExactSectionOverlapCount(
  List<String> previous,
  List<String> current,
) {
  final maximum = [8, previous.length, current.length].reduce(math.min);
  for (var count = maximum; count > 0; count--) {
    final previousStart = previous.length - count;
    var matches = true;
    for (var index = 0; index < count; index++) {
      final key = current[index];
      if (key.isEmpty || previous[previousStart + index] != key) {
        matches = false;
        break;
      }
    }
    if (matches) return count;
  }
  return 0;
}

bool _receiptOverlapCanBeSuppressed(Iterable<String> overlap) {
  final keys = overlap.where((key) => key.isNotEmpty).toSet();
  return keys.length >= 2;
}

String _receiptLineDedupeKey(String line) {
  var key = line
      .toUpperCase()
      .replaceAll(RegExp(r'(?<=\d)O(?=\d)'), '0')
      .replaceAll(RegExp(r'\bO(?=\d)'), '0')
      .replaceAll(RegExp(r'(?<=\d)O\b'), '0')
      .replaceAll(RegExp(r'^[#\-\s]+'), '')
      .replaceAll(RegExp(r'\$'), '')
      .replaceAll(RegExp(r'(?<=\d)[.,](?=\d{2}\b)'), '')
      .replaceAll(RegExp(r'(?<=\d)\s+(?=\d{2}(?:[A-Z])?$)'), '')
      .replaceAll(RegExp(r'(?<=\d)[A-Z]$'), '')
      .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (key.startsWith('LINE ')) {
    key = key.replaceFirst(RegExp(r'^LINE \d+ '), '');
  }
  return key;
}

String _receiptLineProbableOverlapKey(String line) {
  return _receiptLineDedupeKey(
    line,
  ).replaceAll(RegExp(r'[^A-Z0-9]'), '').replaceAll(RegExp(r'\d+$'), '');
}
