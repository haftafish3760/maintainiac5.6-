part of 'receipt_ocr_service.dart';

_CombinedReceiptText _combinedReceiptText(Iterable<String> sections) {
  final rawSections = <String>[];
  final parserSections = <String>[];
  final parserLineSourceLocations = <ReceiptOcrParserLineLocation>[];
  var previousExactTail = const <String>[];
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
    final parserSectionLines = <String>[];
    var stillInOverlapHeader = true;
    var foundBoundarySignal = sectionIndex == 0;
    final previousExactTailSet = previousExactTail.toSet();
    final previousProbableTailSet = previousProbableTail.toSet();
    for (
      var rawLineIndex = 0;
      rawLineIndex < rawSectionLines.length;
      rawLineIndex++
    ) {
      final clean = rawSectionLines[rawLineIndex];
      final key = _receiptLineDedupeKey(clean);
      final probableKey = _receiptLineProbableOverlapKey(clean);
      if (stillInOverlapHeader &&
          key.isNotEmpty &&
          previousExactTailSet.contains(key)) {
        suppressedDuplicateLines += 1;
        foundBoundarySignal = true;
        continue;
      }
      if (stillInOverlapHeader &&
          probableKey.length >= 5 &&
          previousProbableTailSet.contains(probableKey)) {
        probableOverlapLines += 1;
        foundBoundarySignal = true;
      }
      stillInOverlapHeader = false;
      parserSectionLines.add(clean);
      parserLineSourceLocations.add(
        ReceiptOcrParserLineLocation(
          sectionNumber: sectionIndex + 1,
          sectionLineNumber: rawLineIndex + 1,
        ),
      );
    }
    if (!foundBoundarySignal && previousExactTail.isNotEmpty) {
      possibleSectionGaps += 1;
    }
    rawSections.add(rawSectionLines.join('\n'));
    if (parserSectionLines.isNotEmpty) {
      parserSections.add(parserSectionLines.join('\n'));
    }
    previousExactTail = rawSectionLines
        .map(_receiptLineDedupeKey)
        .where((key) => key.isNotEmpty)
        .toList(growable: false)
        .reversed
        .take(8)
        .toList(growable: false);
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
    rawText: rawSections.join('\n\n').trim(),
    parserText: parserSections.join('\n\n').trim(),
    parserLineSourceLocations: List.unmodifiable(parserLineSourceLocations),
    suppressedDuplicateLines: suppressedDuplicateLines,
    probableOverlapLines: probableOverlapLines,
    possibleSectionGaps: possibleSectionGaps,
  );
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
