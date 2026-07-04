part 'receipt_layout_analyzer.dart';
part 'receipt_layout_patterns.dart';

enum ReceiptLayoutZone {
  header,
  transaction,
  itemBody,
  totals,
  payment,
  footer,
  unknown,
}

enum ReceiptLayoutSignal {
  merchantCandidate,
  addressCandidate,
  dateCandidate,
  timeCandidate,
  transactionCandidate,
  itemCandidate,
  priceCandidate,
  subtotalCandidate,
  taxCandidate,
  totalCandidate,
  paymentCandidate,
  barcodeCandidate,
  footerCandidate,
  personalInfoCandidate,
}

class ReceiptLayoutLine {
  const ReceiptLayoutLine({
    required this.lineNumber,
    required this.sourceIndex,
    required this.text,
    required this.zone,
    required this.signals,
  });

  final int lineNumber;
  final int sourceIndex;
  final String text;
  final ReceiptLayoutZone zone;
  final Set<ReceiptLayoutSignal> signals;

  int get safeLineNumber => lineNumber > 0
      ? lineNumber
      : sourceIndex >= 0
      ? sourceIndex + 1
      : 1;

  bool hasSignal(ReceiptLayoutSignal signal) => signals.contains(signal);

  bool get likelyMerchantName =>
      hasSignal(ReceiptLayoutSignal.merchantCandidate);
  bool get likelyAddress => hasSignal(ReceiptLayoutSignal.addressCandidate);
  bool get likelyItemLine => hasSignal(ReceiptLayoutSignal.itemCandidate);
  bool get likelyTotalLine => hasSignal(ReceiptLayoutSignal.totalCandidate);
  bool get likelySubtotalLine =>
      hasSignal(ReceiptLayoutSignal.subtotalCandidate);
  bool get likelyTaxLine => hasSignal(ReceiptLayoutSignal.taxCandidate);
  bool get likelyPaymentLine => hasSignal(ReceiptLayoutSignal.paymentCandidate);
  bool get hasPrice => hasSignal(ReceiptLayoutSignal.priceCandidate);
  bool get isFooter => zone == ReceiptLayoutZone.footer;
  bool get hasPrivateShareRisk =>
      hasSignal(ReceiptLayoutSignal.personalInfoCandidate) ||
      hasSignal(ReceiptLayoutSignal.paymentCandidate) ||
      hasSignal(ReceiptLayoutSignal.transactionCandidate);

  String get stableLineId =>
      'receipt_line_${safeLineNumber.toString().padLeft(4, '0')}';

  String get redactionAnchorCode {
    final zoneToken = zone.name;
    final roleToken = likelyMerchantName
        ? 'merchant'
        : likelyItemLine
        ? 'item'
        : likelyTotalLine
        ? 'total'
        : likelyTaxLine
        ? 'tax'
        : likelyPaymentLine
        ? 'payment'
        : hasPrivateShareRisk
        ? 'private'
        : 'context';
    return '${stableLineId}_${zoneToken}_$roleToken';
  }

  Map<String, Object?> get privacySafeSummary {
    return {
      'lineNumber': safeLineNumber,
      'safeLineNumber': safeLineNumber,
      'sourceIndex': sourceIndex,
      'zone': zone.name,
      'signals': signals.map((signal) => signal.name).toList(growable: false),
      'stableLineId': stableLineId,
      'redactionAnchorCode': redactionAnchorCode,
      'hasPrivateShareRisk': hasPrivateShareRisk,
      'hasPrice': hasPrice,
    };
  }
}

class ReceiptLineRedactionPlan {
  const ReceiptLineRedactionPlan({
    required this.visibleLineNumbers,
    required this.hiddenLineNumbers,
    required this.ignoredLineNumbers,
    required this.visibleAnchorCodes,
    required this.hiddenAnchorCodes,
    required this.protectedContentTypes,
    required this.keepsMerchantContext,
    required this.keepsTotalsContext,
  });

  final Set<int> visibleLineNumbers;
  final Set<int> hiddenLineNumbers;
  final Set<int> ignoredLineNumbers;
  final List<String> visibleAnchorCodes;
  final List<String> hiddenAnchorCodes;
  final Set<String> protectedContentTypes;
  final bool keepsMerchantContext;
  final bool keepsTotalsContext;

  bool get hidesUnselectedLines => hiddenLineNumbers.isNotEmpty;
  bool get protectsPrivateContent => protectedContentTypes.isNotEmpty;
  bool get ignoredUnknownLines => ignoredLineNumbers.isNotEmpty;

  String get summaryCode {
    final visible = visibleLineNumbers.length;
    final hidden = hiddenLineNumbers.length;
    final ignored = ignoredLineNumbers.length;
    final context = keepsMerchantContext ? 'merchant_context' : 'line_only';
    final totals = keepsTotalsContext ? 'totals_context' : 'totals_hidden';
    return 'receipt_redaction:$visible-visible:$hidden-hidden:$ignored-ignored:$context:$totals';
  }
}

class ReceiptLayoutMap {
  const ReceiptLayoutMap({
    required this.lines,
    required this.zoneCounts,
    required this.signalCounts,
    required this.structureStatus,
    required this.structureSummary,
  });

  final List<ReceiptLayoutLine> lines;
  final Map<String, int> zoneCounts;
  final Map<String, int> signalCounts;
  final String structureStatus;
  final String structureSummary;

  bool get hasLines => lines.isNotEmpty;
  bool get hasMerchantCandidate => merchantLine != null;
  bool get hasItemCandidates => itemLines.isNotEmpty;
  bool get hasTotalCandidate => totalLines.isNotEmpty;
  bool get hasTaxCandidate => taxLines.isNotEmpty;
  bool get hasPaymentCandidate => paymentLines.isNotEmpty;
  bool get isParserUseful =>
      hasMerchantCandidate && (hasItemCandidates || hasTotalCandidate);
  bool get needsManualReview =>
      structureStatus == 'no_receipt_structure' ||
      structureStatus == 'header_only' ||
      structureStatus == 'total_only';

  ReceiptLayoutLine? get merchantLine {
    for (final line in lines) {
      if (line.likelyMerchantName) return line;
    }
    return null;
  }

  List<ReceiptLayoutLine> get itemLines =>
      lines.where((line) => line.likelyItemLine).toList(growable: false);

  List<ReceiptLayoutLine> get totalLines =>
      lines.where((line) => line.likelyTotalLine).toList(growable: false);

  List<ReceiptLayoutLine> get taxLines =>
      lines.where((line) => line.likelyTaxLine).toList(growable: false);

  List<ReceiptLayoutLine> get paymentLines =>
      lines.where((line) => line.likelyPaymentLine).toList(growable: false);

  List<int> get parserLineNumbers => lines
      .where(
        (line) =>
            line.likelyMerchantName ||
            line.likelyItemLine ||
            line.likelySubtotalLine ||
            line.likelyTaxLine ||
            line.likelyTotalLine,
      )
      .map((line) => line.safeLineNumber)
      .toList(growable: false);

  List<int> get clientProofDefaultVisibleLineNumbers => lines
      .where(
        (line) =>
            line.likelyMerchantName ||
            line.likelyItemLine ||
            line.likelySubtotalLine ||
            line.likelyTaxLine ||
            line.likelyTotalLine,
      )
      .map((line) => line.safeLineNumber)
      .toList(growable: false);

  ReceiptLineRedactionPlan redactionPlanForLineNumbers(
    Set<int> selectedLineNumbers, {
    bool keepMerchantContext = true,
    bool keepTotalsContext = false,
  }) {
    final knownLineNumbers = {for (final line in lines) line.safeLineNumber};
    final requested = <int>{
      for (final lineNumber in selectedLineNumbers)
        if (lineNumber > 0) lineNumber,
    };
    final visible = <int>{
      for (final lineNumber in requested)
        if (knownLineNumbers.contains(lineNumber)) lineNumber,
    };
    final ignored = <int>{
      for (final lineNumber in requested)
        if (!knownLineNumbers.contains(lineNumber)) lineNumber,
    };
    final merchant = merchantLine;
    if (keepMerchantContext && merchant != null) {
      visible.add(merchant.safeLineNumber);
    }
    if (keepTotalsContext) {
      visible.addAll(
        lines
            .where((line) => line.likelySubtotalLine)
            .map((line) => line.safeLineNumber),
      );
      visible.addAll(totalLines.map((line) => line.safeLineNumber));
      visible.addAll(taxLines.map((line) => line.safeLineNumber));
    }

    final hidden = <int>{};
    final visibleAnchors = <String>[];
    final hiddenAnchors = <String>[];
    final protectedTypes = <String>{};
    for (final line in lines) {
      final lineNumber = line.safeLineNumber;
      if (visible.contains(lineNumber)) {
        visibleAnchors.add(line.redactionAnchorCode);
        continue;
      }
      hidden.add(lineNumber);
      hiddenAnchors.add(line.redactionAnchorCode);
      if (line.hasSignal(ReceiptLayoutSignal.personalInfoCandidate)) {
        protectedTypes.add('personal_info');
      }
      if (line.hasSignal(ReceiptLayoutSignal.paymentCandidate)) {
        protectedTypes.add('payment_info');
      }
      if (line.hasSignal(ReceiptLayoutSignal.transactionCandidate)) {
        protectedTypes.add('transaction_info');
      }
    }

    return ReceiptLineRedactionPlan(
      visibleLineNumbers: Set.unmodifiable(visible),
      hiddenLineNumbers: Set.unmodifiable(hidden),
      ignoredLineNumbers: Set.unmodifiable(ignored),
      visibleAnchorCodes: List.unmodifiable(visibleAnchors),
      hiddenAnchorCodes: List.unmodifiable(hiddenAnchors),
      protectedContentTypes: Set.unmodifiable(protectedTypes),
      keepsMerchantContext:
          merchant != null && visible.contains(merchant.safeLineNumber),
      keepsTotalsContext:
          totalLines.isNotEmpty &&
          lines
              .where((line) => line.likelySubtotalLine)
              .every((line) => visible.contains(line.safeLineNumber)) &&
          totalLines.every((line) => visible.contains(line.safeLineNumber)),
    );
  }

  Map<String, Object?> get privacySafeDiagnostics {
    return {
      'structureStatus': structureStatus,
      'structureSummary': structureSummary,
      'lineCount': lines.length,
      'zoneCounts': zoneCounts,
      'signalCounts': signalCounts,
      'merchantLineNumber': merchantLine?.safeLineNumber,
      'itemLineCount': itemLines.length,
      'totalLineCount': totalLines.length,
      'taxLineCount': taxLines.length,
      'paymentLineCount': paymentLines.length,
      'parserLineNumbers': parserLineNumbers,
      'clientProofDefaultVisibleLineNumbers':
          clientProofDefaultVisibleLineNumbers,
    };
  }
}
