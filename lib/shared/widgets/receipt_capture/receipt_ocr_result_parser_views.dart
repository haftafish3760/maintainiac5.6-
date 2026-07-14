part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrResultParserViews on ReceiptOcrResult {
  List<ReceiptOcrParserLineSignal> get parserLineSignals {
    final lines = orderedParserLines;
    return List.unmodifiable([
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
    final signals = parserLineSignals;
    List<ReceiptOcrParserLineSignal> whereKind(
      bool Function(ReceiptOcrParserLineSignal signal) test,
    ) {
      return List.unmodifiable(signals.where(test));
    }

    return ReceiptOcrParserHandoff(
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
        'Receipt text was found, but no priced item lines were clear. Review line items or enter them by hand.',
      if (subtotalCandidateLines.isEmpty &&
          taxCandidateLines.isEmpty &&
          totalCandidateLines.isEmpty)
        'Receipt text was found, but subtotal, tax, or total amounts were not clear. Review the receipt totals before saving.',
      if (vendorCandidateLines.isEmpty)
        'Receipt text was found, but the store name was not clear. Review the store before saving.',
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
