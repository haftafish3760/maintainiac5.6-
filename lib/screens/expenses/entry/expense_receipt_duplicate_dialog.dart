part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptDuplicateDialog on _ExpenseReceiptEntryScreenState {
  Future<ExpenseDuplicateSaveChoice?> _showDuplicateReceiptDialog(
    ExpenseReceiptDuplicateCheckResult result,
  ) async {
    final reasonController = TextEditingController();
    try {
      return showDialog<ExpenseDuplicateSaveChoice>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final strongest = result.candidates.first;
            return AlertDialog(
              backgroundColor: const Color(0xFF1F2528),
              title: const Text(
                'Possible duplicate receipt found.',
                style: TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${strongest.confidence.label} (${strongest.confidence.percent}%). ${strongest.reason}.',
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final candidate in result.candidates.take(3))
                      _DuplicateCandidateTile(candidate: candidate),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: const TextStyle(color: Color(0xFFE8ECEE)),
                      decoration: const InputDecoration(
                        labelText: 'Reason if saving anyway',
                        labelStyle: TextStyle(color: Color(0xFFAEB8BC)),
                        hintText: 'Optional',
                        hintStyle: TextStyle(color: Color(0xFF7E8A90)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF465158)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF8BD0FF)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    const ExpenseDuplicateSaveChoice(
                      action: ExpenseDuplicateSaveAction.viewExisting,
                    ),
                  ),
                  child: const Text('View Existing'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    const ExpenseDuplicateSaveChoice(
                      action: ExpenseDuplicateSaveAction.editCurrent,
                    ),
                  ),
                  child: const Text('Edit Current'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    const ExpenseDuplicateSaveChoice(
                      action: ExpenseDuplicateSaveAction.cancel,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(
                    ExpenseDuplicateSaveChoice(
                      action: ExpenseDuplicateSaveAction.saveAnyway,
                      overrideReason: reasonController.text,
                    ),
                  ),
                  child: const Text('Save Anyway'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _showExistingDuplicateReceipt(
    ExpenseReceiptDuplicateCandidate candidate,
  ) async {
    if (!mounted) return;
    final receipt = candidate.receipt;
    if (receipt != null) {
      await Navigator.of(context).push<void>(
        appNativeRoute(
          context,
          ExpenseReceiptEntryScreen(receiptId: receipt.id),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              candidate.merchantName.isEmpty
                  ? 'Saved receipt'
                  : candidate.merchantName,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${candidate.reason} | ${_money(candidate.total)}',
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${candidate.confidence.label} (${candidate.confidence.percent}%)',
              style: const TextStyle(color: Color(0xFFAEB8BC)),
            ),
            if (receipt != null && receipt.lines.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final line in receipt.lines.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${line.description} | ${line.category} | ${_money(line.subtotal)}',
                    style: const TextStyle(color: Color(0xFFE8ECEE)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DuplicateCandidateTile extends StatelessWidget {
  const _DuplicateCandidateTile({required this.candidate});

  final ExpenseReceiptDuplicateCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF111719),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF39454B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            candidate.merchantName.isEmpty
                ? 'Saved receipt'
                : candidate.merchantName,
            style: const TextStyle(
              color: Color(0xFFE8ECEE),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${candidate.confidence.label} | ${_money(candidate.total)}',
            style: const TextStyle(
              color: Color(0xFFC8D0D3),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            candidate.reason,
            style: const TextStyle(color: Color(0xFFAEB8BC)),
          ),
        ],
      ),
    );
  }
}
