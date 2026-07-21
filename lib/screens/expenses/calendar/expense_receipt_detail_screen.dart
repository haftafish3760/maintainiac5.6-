part of 'expense_calendar.dart';

class ExpenseReceiptDetailScreen extends StatelessWidget {
  const ExpenseReceiptDetailScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context) {
    final receipt = ExpenseLedgerScope.of(context).receiptById(receiptId);
    if (receipt == null) {
      return const _DeletedReceiptScreen();
    }
    if (receipt.isDeleted) {
      return _DeletedReceiptScreen(receiptId: receipt.id);
    }
    final currentEntry = _CalendarExpenseData.fromReceipt(receipt);
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          children: [
            AppScreenHeader(
              title: currentEntry.title,
              actions: [
                IconButton(
                  tooltip: 'Edit receipt',
                  onPressed: () => _editFullReceipt(context, receipt),
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFFE2E8EA),
                  ),
                ),
                IconButton(
                  tooltip: 'Add receipt line',
                  onPressed: () =>
                      _editReceiptLine(context, receipt: receipt, line: null),
                  icon: const Icon(Icons.add_rounded, color: Color(0xFFE2E8EA)),
                ),
                IconButton(
                  tooltip: 'Delete receipt',
                  onPressed: () => _deleteReceipt(context, receipt),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF6B63),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const GlobalOdometerHeader(section: AppSection.expenses),
            const SizedBox(height: 8),
            _ReceiptSummaryPanel(entry: currentEntry),
            const SizedBox(height: 8),
            _ReceiptAllocationPanel(receipt: receipt),
            const SizedBox(height: 8),
            _ReceiptInfoPanel(receipt: receipt),
            if (receipt.ocrReview.hasData) ...[
              const SizedBox(height: 8),
              _ReceiptOcrReviewPanel(review: receipt.ocrReview),
            ],
            const SizedBox(height: 8),
            _ReceiptImagePreview(receipt: receipt),
            const SizedBox(height: 8),
            _ReceiptLineItemsPanel(receipt: receipt, entry: currentEntry),
          ],
        ),
      ),
    );
  }
}

class _DeletedReceiptScreen extends StatelessWidget {
  const _DeletedReceiptScreen({this.receiptId});

  final String? receiptId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2528),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppScreenHeader(
                title: 'Receipt Removed',
                actions: [
                  if (receiptId != null)
                    TextButton.icon(
                      onPressed: () async {
                        await ExpenseLedgerScope.of(
                          context,
                        ).restoreReceipt(receiptId!);
                        if (!context.mounted) return;
                        final cloudBackup = ExpenseCloudBackupScope.maybeOf(
                          context,
                        );
                        if (cloudBackup != null) {
                          unawaited(cloudBackup.queueReceipt(receiptId!));
                        }
                      },
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Restore'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const GlobalOdometerHeader(section: AppSection.expenses),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF122A34),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF295E73)),
                ),
                child: Text(
                  receiptId == null
                      ? 'This receipt is no longer available on this device.'
                      : 'This receipt is hidden from active expenses. Restore it to review or edit it again.',
                  style: const TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptSummaryPanel extends StatelessWidget {
  const _ReceiptSummaryPanel({required this.entry});

  final _CalendarExpenseData entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF122A34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF295E73)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF0F4F2),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.timeLabel} | ${entry.scope} | ${entry.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money(entry.amount),
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
