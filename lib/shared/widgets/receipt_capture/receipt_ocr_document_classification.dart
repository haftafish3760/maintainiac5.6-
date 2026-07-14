part of '../../receipts/receipt_ocr_contract.dart';

/// A document-level reading recommendation. It carries evidence forward but
/// does not make any business, inventory, or fuel-record decision.
enum ReceiptOcrDocumentType {
  fuel,
  inventory,
  generalExpense,
  ambiguous,
  unsupported,
  notAReceipt,
}

enum ReceiptOcrDetailLevel { basic, simple, detailed, unknown }

class ReceiptOcrDocumentClassification {
  const ReceiptOcrDocumentClassification({
    required this.documentType,
    required this.detailLevel,
    required this.confidence,
    required this.evidence,
  });

  final ReceiptOcrDocumentType documentType;
  final ReceiptOcrDetailLevel detailLevel;
  final double confidence;
  final List<String> evidence;

  bool get needsReview =>
      documentType == ReceiptOcrDocumentType.ambiguous ||
      documentType == ReceiptOcrDocumentType.unsupported ||
      documentType == ReceiptOcrDocumentType.notAReceipt ||
      confidence < .85;
}

extension ReceiptOcrResultDocumentClassification on ReceiptOcrResult {
  ReceiptOcrDocumentClassification get documentClassification =>
      classifyReceiptOcrDocument(
        hasReadableText: hasText,
        handoff: parserHandoff,
      );
}

ReceiptOcrDocumentClassification classifyReceiptOcrDocument({
  required bool hasReadableText,
  required ReceiptOcrParserHandoff handoff,
}) {
  if (!hasReadableText) {
    return const ReceiptOcrDocumentClassification(
      documentType: ReceiptOcrDocumentType.notAReceipt,
      detailLevel: ReceiptOcrDetailLevel.unknown,
      confidence: 0,
      evidence: ['no_readable_text'],
    );
  }

  final hasHeader =
      handoff.vendorLines.isNotEmpty || handoff.dateLines.isNotEmpty;
  final hasSummary = handoff.summaryLines.isNotEmpty;
  final hasItems = handoff.itemLines.isNotEmpty;
  final fuelCount = handoff.fuelCandidateLineCount;
  final inventoryCount =
      handoff.inventoryPrepLineCount + handoff.materialCandidateLineCount;
  final evidence = <String>[
    if (hasHeader) 'receipt_header',
    if (hasSummary) 'receipt_summary',
    if (hasItems) 'priced_or_item_line',
    if (fuelCount > 0) 'fuel_line_evidence',
    if (inventoryCount > 0) 'inventory_line_evidence',
  ];
  final detailLevel = switch (handoff.itemLines.length) {
    >= 2 => ReceiptOcrDetailLevel.detailed,
    1 => ReceiptOcrDetailLevel.simple,
    _ when hasHeader || hasSummary => ReceiptOcrDetailLevel.basic,
    _ => ReceiptOcrDetailLevel.unknown,
  };
  if (!hasHeader && !hasSummary && !hasItems) {
    return ReceiptOcrDocumentClassification(
      documentType: ReceiptOcrDocumentType.notAReceipt,
      detailLevel: detailLevel,
      confidence: .2,
      evidence: List.unmodifiable(evidence),
    );
  }
  if (!hasSummary && !hasItems) {
    return ReceiptOcrDocumentClassification(
      documentType: ReceiptOcrDocumentType.unsupported,
      detailLevel: detailLevel,
      confidence: .45,
      evidence: List.unmodifiable(evidence),
    );
  }
  if (fuelCount > 0 && inventoryCount > 0) {
    return ReceiptOcrDocumentClassification(
      documentType: ReceiptOcrDocumentType.ambiguous,
      detailLevel: detailLevel,
      confidence: .58,
      evidence: List.unmodifiable(evidence),
    );
  }
  if (fuelCount > 0) {
    return ReceiptOcrDocumentClassification(
      documentType: ReceiptOcrDocumentType.fuel,
      detailLevel: detailLevel,
      confidence: hasSummary ? .9 : .78,
      evidence: List.unmodifiable(evidence),
    );
  }
  if (inventoryCount > 0) {
    return ReceiptOcrDocumentClassification(
      documentType: ReceiptOcrDocumentType.inventory,
      detailLevel: detailLevel,
      confidence: hasSummary ? .88 : .76,
      evidence: List.unmodifiable(evidence),
    );
  }
  return ReceiptOcrDocumentClassification(
    documentType: ReceiptOcrDocumentType.generalExpense,
    detailLevel: detailLevel,
    confidence: hasSummary ? .86 : .72,
    evidence: List.unmodifiable(evidence),
  );
}
