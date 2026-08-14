import '../../../shared/widgets/receipt_capture/receipt_capture_settings_store.dart';

/// The first destination after the shared receipt classification screen.
///
/// This is deliberately independent from Navigator so the Manual and
/// App-assisted contracts can be exercised without a platform picker.
enum ExpenseReceiptEntryDestination { manualDetails, assistedSourceChooser }

/// A navigation decision for one Back request in the receipt-entry wizard.
///
/// Keeping this independent from Navigator prevents the visible step and its
/// classification prerequisite from drifting apart.
enum ExpenseReceiptBackAction {
  popRoute,
  confirmExit,
  showStart,
  showDetails,
  showItems,
}

ExpenseReceiptBackAction expenseReceiptBackActionFor({
  required String stepToken,
  required bool hasRecoverableContent,
}) {
  return switch (stepToken.trim()) {
    'start' =>
      hasRecoverableContent
          ? ExpenseReceiptBackAction.confirmExit
          : ExpenseReceiptBackAction.popRoute,
    'details' => ExpenseReceiptBackAction.showStart,
    'items' => ExpenseReceiptBackAction.showDetails,
    'review' => ExpenseReceiptBackAction.showItems,
    // A corrupt or future token must never bypass recovery protection.
    _ =>
      hasRecoverableContent
          ? ExpenseReceiptBackAction.confirmExit
          : ExpenseReceiptBackAction.popRoute,
  };
}

/// Normalized state used when reopening a persisted receipt draft.
class ExpenseReceiptDraftResumePolicy {
  const ExpenseReceiptDraftResumePolicy({
    required this.stepToken,
    required this.useToken,
    required this.hasUseSelection,
    required this.classificationConfirmed,
  });

  final String stepToken;
  final String useToken;
  final bool hasUseSelection;
  final bool classificationConfirmed;
}

ExpenseReceiptDraftResumePolicy expenseReceiptDraftResumePolicy({
  required String storedStepToken,
  required String storedUseToken,
  required bool storedClassificationConfirmed,
  required bool hasReceiptLinesOrOcr,
  required bool hasLegacyRecoverableContent,
}) {
  final useToken = switch (storedUseToken.trim()) {
    'business' => 'business',
    'personal' => 'personal',
    'split' => 'split',
    _ => 'unclassified',
  };
  final hasUseSelection = useToken != 'unclassified';
  final rawStep = storedStepToken.trim();
  final stepToken = switch (rawStep) {
    'start' => 'start',
    'details' => 'details',
    'items' => 'items',
    'review' => 'review',
    _ when hasReceiptLinesOrOcr => 'review',
    _ when hasLegacyRecoverableContent => 'details',
    _ => 'start',
  };

  // A progressed step is durable evidence that an older build had already
  // passed the first screen. Conversely, a stored `start` token must not be
  // promoted merely because its token is nonempty.
  final classificationConfirmed =
      stepToken != 'start' &&
      (storedClassificationConfirmed ||
          rawStep == 'details' ||
          rawStep == 'items' ||
          rawStep == 'review' ||
          hasLegacyRecoverableContent);

  return ExpenseReceiptDraftResumePolicy(
    stepToken: stepToken,
    useToken: useToken,
    hasUseSelection: hasUseSelection,
    classificationConfirmed: classificationConfirmed,
  );
}

ExpenseReceiptEntryDestination expenseReceiptEntryDestinationFor(
  ExpenseReceiptAssistanceChoice choice,
) {
  return switch (choice) {
    ExpenseReceiptAssistanceChoice.manual =>
      ExpenseReceiptEntryDestination.manualDetails,
    ExpenseReceiptAssistanceChoice.onDevice ||
    ExpenseReceiptAssistanceChoice.maintainiacAi ||
    ExpenseReceiptAssistanceChoice.chatGptAccount =>
      ExpenseReceiptEntryDestination.assistedSourceChooser,
  };
}
