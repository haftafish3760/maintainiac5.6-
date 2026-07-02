part of '../../receipts/receipt_ocr_contract.dart';

class ReceiptOcrParserHandoff {
  const ReceiptOcrParserHandoff({
    required this.lines,
    required this.vendorLines,
    required this.dateLines,
    required this.itemLines,
    required this.summaryLines,
    required this.tenderLines,
    required this.metadataLines,
  });

  final List<ReceiptOcrParserLineSignal> lines;
  final List<ReceiptOcrParserLineSignal> vendorLines;
  final List<ReceiptOcrParserLineSignal> dateLines;
  final List<ReceiptOcrParserLineSignal> itemLines;
  final List<ReceiptOcrParserLineSignal> summaryLines;
  final List<ReceiptOcrParserLineSignal> tenderLines;
  final List<ReceiptOcrParserLineSignal> metadataLines;

  ReceiptOcrParserLineSignal? get primaryVendorLine =>
      vendorLines.isEmpty ? null : vendorLines.first;
  ReceiptOcrParserLineSignal? get primaryDateLine =>
      dateLines.isEmpty ? null : dateLines.first;
  ReceiptOcrParserLineSignal? get primarySubtotalLine {
    for (final line in summaryLines) {
      if (line.kind == ReceiptOcrParserLineKind.subtotalCandidate) return line;
    }
    return null;
  }

  ReceiptOcrParserLineSignal? get primaryTaxLine {
    for (final line in summaryLines) {
      if (line.kind == ReceiptOcrParserLineKind.taxCandidate) return line;
    }
    return null;
  }

  ReceiptOcrParserLineSignal? get primaryTotalLine {
    for (final line in summaryLines) {
      if (line.kind == ReceiptOcrParserLineKind.totalCandidate) return line;
    }
    return null;
  }

  int? get firstHeaderLineIndex {
    final headerLines = [...vendorLines, ...dateLines]
      ..sort((left, right) => left.index.compareTo(right.index));
    return headerLines.isEmpty ? null : headerLines.first.index;
  }

  int? get firstItemLineIndex =>
      itemLines.isEmpty ? null : itemLines.first.index;
  int? get lastItemLineIndex => itemLines.isEmpty ? null : itemLines.last.index;
  int? get firstSummaryLineIndex =>
      summaryLines.isEmpty ? null : summaryLines.first.index;
  int? get lastSummaryLineIndex =>
      summaryLines.isEmpty ? null : summaryLines.last.index;
  int? get firstTenderLineIndex =>
      tenderLines.isEmpty ? null : tenderLines.first.index;
  int? get firstPaymentTenderLineIndex {
    for (final line in tenderLines) {
      if (!_looksLikeReceiptReturnRefundOrCreditLine(line.text)) {
        return line.index;
      }
    }
    return null;
  }

  double? get primarySubtotalAmount => primarySubtotalLine?.primaryAmount;
  double? get primaryTaxAmount => primaryTaxLine?.primaryAmount;
  double? get primaryTotalAmount => primaryTotalLine?.primaryAmount;
  double get itemAmountSubtotal {
    final sum = itemLines.fold<double>(
      0,
      (total, line) => total + (line.primaryAmount ?? 0),
    );
    return _roundReceiptOcrMoney(sum);
  }

  bool get hasTotalOnlySummary =>
      primaryTotalAmount != null &&
      primarySubtotalAmount == null &&
      primaryTaxAmount == null &&
      itemLines.isNotEmpty;
  bool get totalOnlyLineMathReconciled {
    final total = primaryTotalAmount;
    if (!hasTotalOnlySummary || total == null) return false;
    var tolerance = total.abs() * .015;
    if (tolerance < .05) tolerance = .05;
    return (itemAmountSubtotal - total).abs() <= tolerance;
  }

  bool get totalOnlyLineMathNeedsReview =>
      hasTotalOnlySummary &&
      parserReadyLineCount > 0 &&
      !totalOnlyLineMathReconciled;

  bool get hasLineItemEvidence => itemLines.isNotEmpty;
  int get pricedLineCount => lines.where((line) => line.hasAmount).length;
  int get parserReadyLineCount =>
      itemLines.where((line) => !line.needsReview).length;
  int get highConfidenceItemLineCount =>
      itemLines.where((line) => !line.needsReview).length;
  int get reviewItemLineCount =>
      itemLines.where((line) => line.needsReview).length;
  int get quantitySignalItemLineCount =>
      itemLines.where((line) => line.hasQuantityOrUnitSignal).length;
  int get skuSignalItemLineCount =>
      itemLines.where((line) => line.hasSkuLikeSignal).length;
  int get genericItemLineCount =>
      itemLines.where((line) => line.hasGenericDescription).length;
  int get inventoryPrepLineCount =>
      itemLines.where((line) => line.isInventoryPrepCandidate).length;
  int get materialCandidateLineCount =>
      itemLines.where((line) => line.isMaterialCandidate).length;
  int get fuelCandidateLineCount =>
      itemLines.where((line) => line.isFuelCandidate).length;
  int get vehicleSupplyCandidateLineCount =>
      itemLines.where((line) => line.isVehicleSupplyCandidate).length;
  int get addressContactMetadataLineCount =>
      addressContactMetadataLineIds.length;
  int get weakHeaderCandidateLineCount => weakHeaderCandidateLineIds.length;
  int get parserReadyFieldCount =>
      lines.where((line) => line.isParserReadyField).length;
  int get parserReviewFieldCount =>
      lines.where((line) => line.isParserReviewField).length;
  Map<String, int> get lineRoleCounts {
    return Map.unmodifiable({
      'vendor': vendorLines.length,
      'date': dateLines.length,
      'item': itemLines.length,
      'summary': summaryLines.length,
      'tender': tenderLines.length,
      'metadata': metadataLines.length,
      'other': lines
          .where((line) => line.kind == ReceiptOcrParserLineKind.other)
          .length,
    });
  }

  String get dominantLineRole {
    var topRole = '';
    var topCount = 0;
    for (final entry in lineRoleCounts.entries) {
      if (entry.value > topCount) {
        topRole = entry.key;
        topCount = entry.value;
      }
    }
    return topRole;
  }
}
