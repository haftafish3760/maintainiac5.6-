part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrResultParserViews on ReceiptOcrResult {
  List<ReceiptOcrParserLineSignal> get parserLineSignals {
    final cached = _receiptParserLineSignalsCache[this];
    if (cached != null) return cached;
    final lines = orderedParserLines;
    return _receiptParserLineSignalsCache[this] = List.unmodifiable([
      for (var index = 0; index < lines.length; index++)
        _parserLineSignalFor(
          lines[index],
          index,
          sourceLocation: index < parserLineSourceLocations.length
              ? parserLineSourceLocations[index]
              : null,
        ),
    ]);
  }

  ReceiptOcrParserHandoff get parserHandoff {
    final cached = _receiptParserHandoffCache[this];
    if (cached != null) return cached;
    final signals = parserLineSignals;
    List<ReceiptOcrParserLineSignal> whereKind(
      bool Function(ReceiptOcrParserLineSignal signal) test,
    ) {
      return List.unmodifiable(signals.where(test));
    }

    return _receiptParserHandoffCache[this] = ReceiptOcrParserHandoff(
      lines: signals,
      vendorLines: whereKind(
        (signal) => signal.kind == ReceiptOcrParserLineKind.vendorCandidate,
      ),
      dateLines: whereKind(
        (signal) => signal.kind == ReceiptOcrParserLineKind.dateCandidate,
      ),
      itemLines: whereKind(
        (signal) => signal.kind == ReceiptOcrParserLineKind.itemCandidate,
      ),
      summaryLines: whereKind((signal) => signal.isLikelySummary),
      tenderLines: whereKind((signal) => signal.isLikelyTender),
      metadataLines: whereKind((signal) => signal.isLikelyMetadata),
    );
  }

  List<String> get vendorCandidateLines => _parserLinesWhere(
    (signal) => signal.kind == ReceiptOcrParserLineKind.vendorCandidate,
  );

  List<String> get dateCandidateLines => _parserLinesWhere(
    (signal) => signal.kind == ReceiptOcrParserLineKind.dateCandidate,
  );

  List<String> get itemCandidateLines => _parserLinesWhere(
    (signal) => signal.kind == ReceiptOcrParserLineKind.itemCandidate,
  );

  List<String> get priceCandidateLines {
    return List.unmodifiable(
      orderedParserLines.where(_hasReceiptPriceCandidate),
    );
  }

  List<String> get subtotalCandidateLines => _parserLinesWhere(
    (signal) => signal.kind == ReceiptOcrParserLineKind.subtotalCandidate,
  );

  List<String> get totalCandidateLines => _parserLinesWhere(
    (signal) => signal.kind == ReceiptOcrParserLineKind.totalCandidate,
  );

  List<String> get taxCandidateLines => _parserLinesWhere(
    (signal) => signal.kind == ReceiptOcrParserLineKind.taxCandidate,
  );

  List<String> get tenderCandidateLines => _parserLinesWhere(
    (signal) => signal.kind == ReceiptOcrParserLineKind.tenderCandidate,
  );

  List<String> get metadataCandidateLines {
    return _parserLinesWhere(
      (signal) =>
          signal.kind == ReceiptOcrParserLineKind.receiptMetadata ||
          signal.kind == ReceiptOcrParserLineKind.barcodeOrId,
    );
  }

  List<String> get timeCandidateLines {
    return _parserLinesWhere(
      (signal) => signal.traits.contains('time_present'),
    );
  }

  Map<String, int> get parserSignalCounts {
    return Map.unmodifiable({
      'orderedRawLineCount': orderedRawLines.length,
      'orderedParserLineCount': orderedParserLines.length,
      'vendorCandidateLineCount': vendorCandidateLines.length,
      'dateCandidateLineCount': dateCandidateLines.length,
      'timeCandidateLineCount': timeCandidateLines.length,
      'itemCandidateLineCount': itemCandidateLines.length,
      'priceCandidateLineCount': priceCandidateLines.length,
      'subtotalCandidateLineCount': subtotalCandidateLines.length,
      'totalCandidateLineCount': totalCandidateLines.length,
      'taxCandidateLineCount': taxCandidateLines.length,
      'tenderCandidateLineCount': tenderCandidateLines.length,
      'metadataCandidateLineCount': metadataCandidateLines.length,
      for (final entry in parserHandoff.lineRoleCounts.entries)
        '${entry.key}RoleLineCount': entry.value,
    });
  }

  List<String> get structuredParserHandoffWarnings {
    if (!hasText) return const [];
    final warnings = <String>[
      if (itemCandidateLines.isEmpty)
        'Receipt Assist found receipt text but no priced item lines. Review line items or enter them by hand.',
      if (subtotalCandidateLines.isEmpty &&
          taxCandidateLines.isEmpty &&
          totalCandidateLines.isEmpty)
        'Receipt Assist found receipt text but no subtotal, tax, or total signals. Review the receipt totals before saving.',
      if (vendorCandidateLines.isEmpty)
        'Receipt Assist found receipt text but no clear store header. Review the vendor before saving.',
    ];
    return List.unmodifiable(warnings);
  }

  List<String> _parserLinesWhere(
    bool Function(ReceiptOcrParserLineSignal signal) test,
  ) {
    return List.unmodifiable(
      parserLineSignals.where(test).map((signal) => signal.text),
    );
  }
}
