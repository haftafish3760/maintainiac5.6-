part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryHandoffRouteHelpers
    on _ExpenseReceiptEntryScreenState {
  ExpenseReceiptParseResult _selectReceiptHandoffResult(
    Map<ReceiptOcrHandoffDestination, ExpenseReceiptParseResult> results, {
    required ReceiptOcrHandoffPlan routePlan,
  }) {
    final routeRank = <ReceiptOcrHandoffDestination, int>{
      for (var index = 0; index < routePlan.destinations.length; index += 1)
        routePlan.destinations[index]: index,
      ReceiptOcrHandoffDestination.expenseReview: routePlan.destinations.length,
    };
    final orderedResults = results.entries.toList(growable: false)
      ..sort((left, right) {
        final usable = _handoffResultUsability(
          right.value,
        ).compareTo(_handoffResultUsability(left.value));
        if (usable != 0) return usable;
        final confidence = right.value.quality.confidence.compareTo(
          left.value.quality.confidence,
        );
        if (confidence != 0) return confidence;
        return (routeRank[left.key] ?? routeRank.length).compareTo(
          routeRank[right.key] ?? routeRank.length,
        );
      });
    final selected = orderedResults.first.value;
    if (!routePlan.runsBothDedicatedConsumers) return selected;
    return selected.copyWith(
      warnings: [
        ...selected.warnings,
        'More than one receipt category may apply. Review the receipt details before saving.',
      ],
    );
  }

  int _handoffResultUsability(ExpenseReceiptParseResult result) {
    return result.hasUsableData ? 1 : 0;
  }
}
