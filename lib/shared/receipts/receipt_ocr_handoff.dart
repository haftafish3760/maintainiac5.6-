import 'dart:async';

import '../widgets/receipt_capture/receipt_ocr_service.dart';

/// The explicit boundary between generic receipt OCR and domain-specific work.
/// It carries what OCR actually observed; it does not guess products, trade,
/// inventory records, or expense classifications.
enum ReceiptOcrHandoffDestination { expenseReview, fuel, inventory }

class ReceiptOcrHandoff {
  const ReceiptOcrHandoff({
    required this.destination,
    required this.ocr,
    this.selectedCategory = '',
    this.inventoryRequested = false,
  });

  factory ReceiptOcrHandoff.forUserSelection({
    required ReceiptOcrResult ocr,
    String? selectedCategory,
    bool inventoryRequested = false,
  }) {
    final category = selectedCategory?.trim() ?? '';
    return ReceiptOcrHandoff(
      destination: receiptOcrHandoffDestinationFor(
        selectedCategory: category,
        inventoryRequested: inventoryRequested,
      ),
      ocr: ocr,
      selectedCategory: category,
      inventoryRequested: inventoryRequested,
    );
  }

  final ReceiptOcrHandoffDestination destination;
  final ReceiptOcrResult ocr;
  final String selectedCategory;
  final bool inventoryRequested;

  bool get hasReadableText => ocr.hasText;
  ReceiptOcrDocumentClassification get documentClassification =>
      ocr.documentClassification;
  ReceiptOcrHandoffPlan get routePlan => receiptOcrHandoffPlanFor(
    selectedCategory: selectedCategory,
    inventoryRequested: inventoryRequested,
    classification: documentClassification,
  );
  bool get needsManualReview => !hasReadableText || ocr.warnings.isNotEmpty;

  ReceiptOcrHandoff forDestination(ReceiptOcrHandoffDestination value) {
    return ReceiptOcrHandoff(
      destination: value,
      ocr: ocr,
      selectedCategory: selectedCategory,
      inventoryRequested: inventoryRequested,
    );
  }
}

/// A generic routing recommendation. It contains no domain interpretation and
/// never writes records; downstream owners decide what to do with the evidence.
class ReceiptOcrHandoffPlan {
  const ReceiptOcrHandoffPlan({
    required this.destinations,
    required this.needsReview,
  });

  final List<ReceiptOcrHandoffDestination> destinations;
  final bool needsReview;

  bool get runsBothDedicatedConsumers =>
      destinations.contains(ReceiptOcrHandoffDestination.fuel) &&
      destinations.contains(ReceiptOcrHandoffDestination.inventory);
}

typedef ReceiptOcrHandoffHandler<T> =
    FutureOr<T> Function(ReceiptOcrHandoff handoff);

/// Dispatches OCR only by the user's explicit route. Dedicated consumers are
/// optional while their modules are being delivered; the fallback keeps the
/// editable expense review usable without silently reclassifying the receipt.
class ReceiptOcrHandoffRouter<T> {
  const ReceiptOcrHandoffRouter({
    required this.expenseReview,
    this.fuel,
    this.inventory,
  });

  final ReceiptOcrHandoffHandler<T> expenseReview;
  final ReceiptOcrHandoffHandler<T>? fuel;
  final ReceiptOcrHandoffHandler<T>? inventory;

  bool hasDedicatedHandlerFor(ReceiptOcrHandoffDestination destination) {
    return switch (destination) {
      ReceiptOcrHandoffDestination.fuel => fuel != null,
      ReceiptOcrHandoffDestination.inventory => inventory != null,
      ReceiptOcrHandoffDestination.expenseReview => true,
    };
  }

  Future<T> dispatch(ReceiptOcrHandoff handoff) {
    final handler = switch (handoff.destination) {
      ReceiptOcrHandoffDestination.fuel => fuel ?? expenseReview,
      ReceiptOcrHandoffDestination.inventory => inventory ?? expenseReview,
      ReceiptOcrHandoffDestination.expenseReview => expenseReview,
    };
    return Future<T>.value(handler(handoff));
  }

  /// Runs every available destination in an evidence-only recommendation.
  /// Optional consumers that are unavailable are skipped. If none are
  /// available, editable expense review is the sole recovery destination.
  Future<Map<ReceiptOcrHandoffDestination, T>> dispatchPlan(
    ReceiptOcrHandoff handoff, {
    ReceiptOcrHandoffPlan? plan,
  }) async {
    final results = <ReceiptOcrHandoffDestination, T>{};
    for (final destination in (plan ?? handoff.routePlan).destinations) {
      if (destination != ReceiptOcrHandoffDestination.expenseReview &&
          !hasDedicatedHandlerFor(destination)) {
        continue;
      }
      results[destination] = await dispatch(
        handoff.forDestination(destination),
      );
    }
    if (results.isEmpty) {
      const fallback = ReceiptOcrHandoffDestination.expenseReview;
      results[fallback] = await dispatch(handoff.forDestination(fallback));
    }
    return Map.unmodifiable(results);
  }
}

ReceiptOcrHandoffDestination receiptOcrHandoffDestinationFor({
  String? selectedCategory,
  bool inventoryRequested = false,
}) {
  if (inventoryRequested) return ReceiptOcrHandoffDestination.inventory;
  final category = selectedCategory?.trim().toLowerCase() ?? '';
  return switch (category) {
    'fuel' => ReceiptOcrHandoffDestination.fuel,
    'inventory' ||
    'material' ||
    'materials' ||
    'work supplies' => ReceiptOcrHandoffDestination.inventory,
    _ => ReceiptOcrHandoffDestination.expenseReview,
  };
}

ReceiptOcrHandoffPlan receiptOcrHandoffPlanFor({
  String? selectedCategory,
  bool inventoryRequested = false,
  required ReceiptOcrDocumentClassification classification,
}) {
  final explicitCategory = selectedCategory?.trim() ?? '';
  if (explicitCategory.isNotEmpty || inventoryRequested) {
    return ReceiptOcrHandoffPlan(
      destinations: List.unmodifiable([
        receiptOcrHandoffDestinationFor(
          selectedCategory: explicitCategory,
          inventoryRequested: inventoryRequested,
        ),
      ]),
      needsReview: classification.needsReview,
    );
  }
  final destinations = switch (classification.documentType) {
    ReceiptOcrDocumentType.fuel => const [ReceiptOcrHandoffDestination.fuel],
    ReceiptOcrDocumentType.inventory => const [
      ReceiptOcrHandoffDestination.inventory,
    ],
    ReceiptOcrDocumentType.ambiguous => const [
      ReceiptOcrHandoffDestination.fuel,
      ReceiptOcrHandoffDestination.inventory,
    ],
    ReceiptOcrDocumentType.generalExpense ||
    ReceiptOcrDocumentType.unsupported ||
    ReceiptOcrDocumentType.notAReceipt => const [
      ReceiptOcrHandoffDestination.expenseReview,
    ],
  };
  return ReceiptOcrHandoffPlan(
    destinations: destinations,
    needsReview: classification.needsReview,
  );
}
