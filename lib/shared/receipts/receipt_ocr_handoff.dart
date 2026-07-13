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
  bool get needsManualReview => !hasReadableText || ocr.warnings.isNotEmpty;
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

  Future<T> dispatch(ReceiptOcrHandoff handoff) {
    final handler = switch (handoff.destination) {
      ReceiptOcrHandoffDestination.fuel => fuel ?? expenseReview,
      ReceiptOcrHandoffDestination.inventory => inventory ?? expenseReview,
      ReceiptOcrHandoffDestination.expenseReview => expenseReview,
    };
    return Future<T>.value(handler(handoff));
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
