import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/entry/expense_receipt_entry_route_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('Manual Continue opens editable receipt details', () {
    expect(
      expenseReceiptEntryDestinationFor(ExpenseReceiptAssistanceChoice.manual),
      ExpenseReceiptEntryDestination.manualDetails,
    );
  });

  test('every app-assisted choice opens receipt source selection', () {
    for (final choice in const [
      ExpenseReceiptAssistanceChoice.onDevice,
      ExpenseReceiptAssistanceChoice.maintainiacAi,
      ExpenseReceiptAssistanceChoice.chatGptAccount,
    ]) {
      expect(
        expenseReceiptEntryDestinationFor(choice),
        ExpenseReceiptEntryDestination.assistedSourceChooser,
        reason: '$choice must collect a receipt source before reading it.',
      );
    }
  });

  group('manual receipt Back state machine', () {
    test('moves backward exactly one visible step', () {
      expect(
        expenseReceiptBackActionFor(
          stepToken: 'review',
          hasRecoverableContent: true,
        ),
        ExpenseReceiptBackAction.showItems,
      );
      expect(
        expenseReceiptBackActionFor(
          stepToken: 'items',
          hasRecoverableContent: true,
        ),
        ExpenseReceiptBackAction.showDetails,
      );
      expect(
        expenseReceiptBackActionFor(
          stepToken: 'details',
          hasRecoverableContent: true,
        ),
        ExpenseReceiptBackAction.showStart,
      );
    });

    test('only leaves a clean start screen without confirmation', () {
      expect(
        expenseReceiptBackActionFor(
          stepToken: 'start',
          hasRecoverableContent: false,
        ),
        ExpenseReceiptBackAction.popRoute,
      );
      expect(
        expenseReceiptBackActionFor(
          stepToken: 'start',
          hasRecoverableContent: true,
        ),
        ExpenseReceiptBackAction.confirmExit,
      );
      expect(
        expenseReceiptBackActionFor(
          stepToken: 'corrupt-future-step',
          hasRecoverableContent: true,
        ),
        ExpenseReceiptBackAction.confirmExit,
      );
    });
  });

  group('draft resume normalization', () {
    test('start and unclassified remain incomplete', () {
      final policy = expenseReceiptDraftResumePolicy(
        storedStepToken: 'start',
        storedUseToken: 'unclassified',
        storedClassificationConfirmed: false,
        hasReceiptLinesOrOcr: false,
        hasLegacyRecoverableContent: false,
      );

      expect(policy.stepToken, 'start');
      expect(policy.useToken, 'unclassified');
      expect(policy.hasUseSelection, isFalse);
      expect(policy.classificationConfirmed, isFalse);
    });

    test('each persisted progressed step reopens at that exact step', () {
      for (final step in const ['details', 'items', 'review']) {
        final policy = expenseReceiptDraftResumePolicy(
          storedStepToken: step,
          storedUseToken: 'business',
          storedClassificationConfirmed: true,
          hasReceiptLinesOrOcr: false,
          hasLegacyRecoverableContent: true,
        );

        expect(policy.stepToken, step);
        expect(policy.hasUseSelection, isTrue);
        expect(policy.classificationConfirmed, isTrue);
      }
    });

    test('legacy drafts recover safely without trusting unknown tokens', () {
      final receiptDraft = expenseReceiptDraftResumePolicy(
        storedStepToken: '',
        storedUseToken: 'unknown-value',
        storedClassificationConfirmed: false,
        hasReceiptLinesOrOcr: true,
        hasLegacyRecoverableContent: true,
      );
      final fieldDraft = expenseReceiptDraftResumePolicy(
        storedStepToken: 'future-step',
        storedUseToken: '',
        storedClassificationConfirmed: false,
        hasReceiptLinesOrOcr: false,
        hasLegacyRecoverableContent: true,
      );

      expect(receiptDraft.stepToken, 'review');
      expect(receiptDraft.useToken, 'unclassified');
      expect(receiptDraft.hasUseSelection, isFalse);
      expect(receiptDraft.classificationConfirmed, isTrue);
      expect(fieldDraft.stepToken, 'details');
      expect(fieldDraft.classificationConfirmed, isTrue);
    });
  });
}
