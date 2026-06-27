import '../../../shared/receipts/receipt_line_models.dart';
import '../../../shared/receipts/receipt_processing_contract.dart';
import '../../expenses/data/expense_ledger_models.dart';
import '../../expenses/data/expense_receipt_parser.dart';
import 'work_supply_catalog.dart';
import 'work_supply_models.dart';

class WorkSupplyParsedReceiptDraft {
  const WorkSupplyParsedReceiptDraft({
    required this.lines,
    required this.inventoryRecords,
    required this.inventoryLineCount,
    required this.businessOnlyLineCount,
    required this.personalLineCount,
    required this.splitLineCount,
    required this.processingSnapshot,
  });

  final List<ReceiptLineDraft> lines;
  final List<WorkSupplyInventoryRecord> inventoryRecords;
  final int inventoryLineCount;
  final int businessOnlyLineCount;
  final int personalLineCount;
  final int splitLineCount;
  final ReceiptProcessingSnapshot processingSnapshot;

  bool get hasLines => lines.isNotEmpty;
  bool get canCommitInventory => processingSnapshot.canCommitInventory;
}

WorkSupplyParsedReceiptDraft buildWorkSupplyParsedReceiptDraft({
  required ExpenseReceiptParseResult parsed,
  required String receiptId,
  required DateTime loggedAt,
  required String storageArea,
  required String merchantName,
  int startingLineNumber = 1,
  Iterable<WorkSupplyItem> customCatalogItems = const [],
  ReceiptProcessingSource source = ReceiptProcessingSource.importedText,
}) {
  final catalogItemsById = <String, WorkSupplyItem>{
    for (final item in workSupplyCatalogItems) item.id: item,
    for (final item in customCatalogItems) item.id: item,
  };
  final inferredTaxRate = _inferredTaxRate(parsed);
  final lines = <ReceiptLineDraft>[];
  final inventoryRecords = <WorkSupplyInventoryRecord>[];
  var inventoryCount = 0;
  var businessOnlyCount = 0;
  var personalCount = 0;
  var splitCount = 0;

  for (var index = 0; index < parsed.lines.length; index++) {
    final sourceLine = parsed.lines[index];
    final review = index < parsed.lineReviews.length
        ? parsed.lineReviews[index]
        : null;
    if (sourceLine.subtotal <= 0) continue;
    final lineNumber = startingLineNumber + lines.length;
    final lineId = '$receiptId-L$lineNumber';
    final catalogItem = catalogItemsById[sourceLine.catalogItemId?.trim()];
    final businessUse = _businessUseFor(sourceLine.use);
    final shouldTrackInventory =
        catalogItem != null && sourceLine.use != ExpenseLineUse.personal;
    final draft = ReceiptLineDraft(
      kind: shouldTrackInventory
          ? ReceiptLineKind.inventory
          : ReceiptLineKind.expense,
      description: shouldTrackInventory
          ? catalogItem.name
          : sourceLine.displayDescription,
      receiptLineId: lineId,
      inventoryItemId: shouldTrackInventory ? catalogItem.id : '',
      inventoryPath: shouldTrackInventory
          ? (sourceLine.catalogItemPath ?? catalogItem.path)
          : '',
      expenseCategory: shouldTrackInventory ? 'Materials' : sourceLine.category,
      quantity: sourceLine.quantity,
      unitsPerPackage: sourceLine.unitsPerPackage,
      purchaseType: 'each',
      unit: _unitFor(sourceLine, catalogItem),
      subtotal: sourceLine.subtotal,
      taxRate: inferredTaxRate,
      storageArea: shouldTrackInventory ? storageArea : '',
      businessUse: businessUse,
      businessPercent: sourceLine.effectiveBusinessPercent,
      note: _lineNoteFor(sourceLine, catalogItem, review),
      rawReceiptText: sourceLine.receiptEvidenceText,
      catalogMatchConfidence:
          review?.catalogMatchConfidence ?? sourceLine.catalogMatchConfidence,
      catalogMatchedTerms: _catalogMatchedTermsFor(sourceLine, review),
      parserConfidence: review?.confidence ?? sourceLine.parserConfidence,
      parserReviewLabel: review?.label ?? sourceLine.parserReviewLabel,
      parserReviewReason: review?.reason ?? sourceLine.parserReviewReason,
      parserNeedsReview: review?.needsReview ?? sourceLine.parserNeedsReview,
      originalParsedDescription: shouldTrackInventory
          ? catalogItem.name
          : sourceLine.displayDescription,
      originalParsedInventoryItemId: shouldTrackInventory ? catalogItem.id : '',
      originalParsedInventoryPath: shouldTrackInventory
          ? (sourceLine.catalogItemPath ?? catalogItem.path)
          : '',
      reviewAction: 'parsed',
    );
    lines.add(draft);

    if (shouldTrackInventory) {
      inventoryCount++;
      inventoryRecords.add(
        WorkSupplyInventoryRecord(
          item: catalogItem,
          onHand: draft.totalUnits,
          threshold: 1,
          lastUnitCost: draft.unitCostWithTax,
          storageArea: storageArea,
          receiptLinked: true,
          packagesPurchased: draft.quantity,
          unitsPerPackage: draft.unitsPerPackage,
          purchaseType: draft.purchaseType,
          lineSubtotal: draft.subtotal,
          taxRate: draft.taxRate,
          businessUse: draft.businessUse,
          businessPercent: draft.businessPercent,
          loggedAt: loggedAt,
          sourceReceiptId: receiptId,
          sourceReceiptLineId: lineId,
          sourceMerchantName: merchantName,
        ),
      );
    } else if (sourceLine.use == ExpenseLineUse.personal) {
      personalCount++;
    } else if (sourceLine.use == ExpenseLineUse.split) {
      splitCount++;
    } else {
      businessOnlyCount++;
    }
  }

  return WorkSupplyParsedReceiptDraft(
    lines: List.unmodifiable(lines),
    inventoryRecords: List.unmodifiable(inventoryRecords),
    inventoryLineCount: inventoryCount,
    businessOnlyLineCount: businessOnlyCount,
    personalLineCount: personalCount,
    splitLineCount: splitCount,
    processingSnapshot: ReceiptProcessingSnapshot(
      source: source,
      stage: ReceiptProcessingStage.stagedForReview,
      destination: ReceiptSaveDestination.inventoryReview,
      lineCount: lines.length,
      needsReview: lines.any((line) => line.parserNeedsReview),
      warningCount: parsed.warnings.length,
    ),
  );
}

double _inferredTaxRate(ExpenseReceiptParseResult parsed) {
  final subtotal = parsed.enteredSubtotal;
  final tax = parsed.enteredTax;
  if (subtotal == null || tax == null || subtotal <= 0 || tax < 0) return 0;
  return tax / subtotal;
}

String _businessUseFor(ExpenseLineUse use) {
  return switch (use) {
    ExpenseLineUse.personal => 'personal',
    ExpenseLineUse.split => 'split',
    ExpenseLineUse.business => 'business',
  };
}

String _unitFor(ExpenseReceiptLineRecord line, WorkSupplyItem? catalogItem) {
  final unit = line.unit.trim();
  if (unit.isNotEmpty && unit != 'item') return unit;
  return catalogItem?.unit ?? 'each';
}

String _lineNoteFor(
  ExpenseReceiptLineRecord line,
  WorkSupplyItem? catalogItem,
  ExpenseReceiptLineReview? review,
) {
  final parts = <String>[
    if (catalogItem != null && catalogItem.variant.trim().isNotEmpty)
      catalogItem.variant.trim(),
    if (review?.reason.trim().isNotEmpty == true) review!.reason.trim(),
    if (line.parserReviewReason?.trim().isNotEmpty == true)
      line.parserReviewReason!.trim(),
  ];
  return parts.toSet().join(' | ');
}

List<String> _catalogMatchedTermsFor(
  ExpenseReceiptLineRecord line,
  ExpenseReceiptLineReview? review,
) {
  return {
    ...line.catalogMatchedTerms.map((term) => term.trim()),
    ...?review?.catalogMatchedTerms.map((term) => term.trim()),
  }.where((term) => term.isNotEmpty).toList(growable: false);
}
