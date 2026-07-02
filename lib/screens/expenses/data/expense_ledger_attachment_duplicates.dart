part of 'expense_ledger_store.dart';

extension ExpenseLedgerAttachmentDuplicateChecks on ExpenseLedgerController {
  List<ExpenseAttachmentDuplicateCandidate> duplicateAttachmentCandidatesFor({
    required String fileHashSha256,
    ExpenseDuplicateAttachmentScope scope =
        ExpenseDuplicateAttachmentScope.expenses,
    List<ReceiptAttachmentRecord> currentFormAttachments = const [],
  }) {
    final hash = fileHashSha256.trim();
    if (hash.isEmpty) return const [];
    final candidates = <ExpenseAttachmentDuplicateCandidate>[];

    void addCurrentFormCandidates() {
      for (final attachment in currentFormAttachments) {
        if (attachment.fileHash.trim() == hash) {
          candidates.add(
            ExpenseAttachmentDuplicateCandidate.fromAttachment(
              attachment: attachment,
              reason: 'Already attached to this receipt form',
            ),
          );
        }
      }
    }

    void addExpenseCandidates() {
      final seenReceiptHashes = <String>{};
      for (final receipt in storedReceipts) {
        for (final attachment in receipt.attachments) {
          if (attachment.fileHash.trim() == hash) {
            seenReceiptHashes.add('${receipt.id}:$hash');
            candidates.add(
              ExpenseAttachmentDuplicateCandidate.fromAttachment(
                attachment: attachment,
                receiptId: receipt.id,
                reason: 'Already saved on an expense receipt',
              ),
            );
          }
        }
        if (receipt.fileHashSha256.trim() == hash) {
          if (seenReceiptHashes.contains('${receipt.id}:$hash')) continue;
          candidates.add(
            ExpenseAttachmentDuplicateCandidate(
              attachmentId: '',
              receiptId: receipt.id,
              linkedModule: 'expenses',
              fileHashSha256: hash,
              originalFileName: receipt.title,
              reason: 'Already saved on an expense receipt',
            ),
          );
        }
      }
    }

    switch (scope) {
      case ExpenseDuplicateAttachmentScope.currentForm:
        addCurrentFormCandidates();
      case ExpenseDuplicateAttachmentScope.expenses:
        addExpenseCandidates();
      case ExpenseDuplicateAttachmentScope.allModulesFuture:
        addCurrentFormCandidates();
        addExpenseCandidates();
    }
    return List.unmodifiable(candidates);
  }
}
