part of 'expenses_home_screen.dart';

class _RecentLedgerPanel extends StatelessWidget {
  const _RecentLedgerPanel({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final receipts = ExpenseLedgerScope.of(context).receiptsForDay(day);
    return _SolidSection(
      backgroundColor: _paper,
      borderColor: const Color(0xFF3E4A50),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeader(
                  eyebrow: 'LEDGER',
                  title: 'Daily entries',
                  detail: 'Saved expenses for ${_longDate(day)}.',
                ),
              ),
              _SmallTextButton(
                label: 'View',
                icon: Icons.receipt_rounded,
                onTap: () => _showAllExpenseEntries(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (receipts.isEmpty)
            const _EmptyLedgerMessage()
          else
            for (final receipt in receipts)
              _LedgerRow(entry: _LedgerEntryData.fromReceipt(receipt)),
        ],
      ),
    );
  }
}

class _UpcomingExpensesPanel extends StatelessWidget {
  const _UpcomingExpensesPanel();

  @override
  Widget build(BuildContext context) {
    return _SolidSection(
      backgroundColor: _paper,
      borderColor: const Color(0xFF3E4A50),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: _SectionHeader(
                  eyebrow: 'UPCOMING',
                  title: 'Expense reminders',
                  detail:
                      'Track recurring or future expenses and get notified before they are due.',
                ),
              ),
              _SmallTextButton(
                label: 'Add',
                icon: Icons.notifications_active_rounded,
                onTap: () => _openReminder(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'No upcoming expenses scheduled yet.',
            style: TextStyle(
              color: Color(0xFFC8D0D3),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class ReceiptDraftsPanel extends StatelessWidget {
  const ReceiptDraftsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final draftsController = ExpenseDraftScope.maybeOf(context);
    if (draftsController == null) {
      return const SizedBox.shrink();
    }
    final drafts = draftsController.drafts.take(3).toList();
    if (drafts.isEmpty) {
      return const SizedBox.shrink();
    }
    return _SolidSection(
      backgroundColor: _paper,
      borderColor: const Color(0xFF3E4A50),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Receipt Draft',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFF0F4F2),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 7),
          for (final draft in drafts) _DraftRow(draft: draft),
        ],
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.draft});

  final ExpenseReceiptDraftRecord draft;

  @override
  Widget build(BuildContext context) {
    final lineText = draft.lines.length == 1
        ? '1 line'
        : '${draft.lines.length} lines';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: _ink,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _openDraft(context, draft),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: _gold, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF0F4F2),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_shortDate(draft.receiptDate)} | $lineText | ${_money(draft.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        ExpenseDraftScope.maybeOf(context)?.deleteDraft(draft.id),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: _red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
