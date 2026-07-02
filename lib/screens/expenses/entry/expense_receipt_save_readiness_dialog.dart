part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptSaveReadinessDialog
    on _ExpenseReceiptEntryScreenState {
  Future<bool> _showReceiptSaveReadinessDialog(
    List<_ReceiptSaveReadinessIssue> issues,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1F2528),
        title: const Text(
          'Review receipt before saving?',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Maintainiac found something that should be checked before this receipt is saved. You can review it now or save anyway if you already verified the receipt.',
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              for (final issue in issues.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFFFD166),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              issue.title,
                              style: const TextStyle(
                                color: Color(0xFFE8ECEE),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              issue.detail,
                              style: const TextStyle(
                                color: Color(0xFFAEB9BE),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Review Receipt'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ReceiptSaveReadinessIssue {
  const _ReceiptSaveReadinessIssue({
    required this.kind,
    required this.title,
    required this.detail,
  });

  final String kind;
  final String title;
  final String detail;
}
