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
    final activeContext = OperationalContextScope.of(context).context;
    final reminders = ExpenseReminderScope.of(context)
        .upcomingForScope(
          workProfileId: activeContext.workProfileId,
          vehicleId: activeContext.activeVehicleId,
        )
        .take(3)
        .toList();
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
          if (reminders.isEmpty)
            const Text(
              'No upcoming expenses scheduled yet.',
              style: TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            )
          else
            for (final reminder in reminders)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${reminder.title} · ${reminder.dueLabel(DateTime.now())}',
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class ReceiptDraftsPanel extends StatefulWidget {
  const ReceiptDraftsPanel({super.key});

  @override
  State<ReceiptDraftsPanel> createState() => _ReceiptDraftsPanelState();
}

class _ReceiptDraftsPanelState extends State<ReceiptDraftsPanel> {
  late Future<List<ReceiptNativeCaptureRecoveryRecord>> _photoDrafts;

  @override
  void initState() {
    super.initState();
    _photoDrafts = _loadPhotoDrafts();
  }

  Future<List<ReceiptNativeCaptureRecoveryRecord>> _loadPhotoDrafts() {
    return const ReceiptNativeCaptureStaging().recoverableNativeCaptures();
  }

  @override
  Widget build(BuildContext context) {
    final draftsController = ExpenseDraftScope.maybeOf(context);
    final drafts = draftsController?.drafts ?? const [];
    return FutureBuilder<List<ReceiptNativeCaptureRecoveryRecord>>(
      future: _photoDrafts,
      builder: (context, snapshot) {
        final photoDrafts = snapshot.data ?? const [];
        if (drafts.isEmpty && photoDrafts.isEmpty) {
          return const SizedBox.shrink();
        }
        final count = drafts.length + photoDrafts.length;
        final latest = <DateTime>[
          ...drafts.map((draft) => draft.updatedAt),
          ...photoDrafts.map((draft) => draft.capturedAt),
        ]..sort((a, b) => b.compareTo(a));
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openDraftList(drafts, photoDrafts),
            borderRadius: BorderRadius.circular(6),
            child: _SolidSection(
              backgroundColor: _paper,
              borderColor: const Color(0xFF3E4A50),
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: _gold, size: 24),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Receipt Drafts',
                          style: TextStyle(
                            color: Color(0xFFF0F4F2),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count saved ${count == 1 ? 'draft' : 'drafts'} | Latest ${_shortDate(latest.first)}',
                          style: const TextStyle(
                            color: Color(0xFFC8D0D3),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _gold),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDraftList(
    List<ExpenseReceiptDraftRecord> drafts,
    List<ReceiptNativeCaptureRecoveryRecord> photoDrafts,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _pageBackground,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Receipt Drafts',
                style: TextStyle(
                  color: Color(0xFFF0F4F2),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Continue or delete saved receipt work.',
                style: TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              for (final draft in drafts) _DraftRow(draft: draft),
              for (final photoDraft in photoDrafts)
                _PhotoDraftRow(draft: photoDraft),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _photoDrafts = _loadPhotoDrafts());
  }
}

class _PhotoDraftRow extends StatelessWidget {
  const _PhotoDraftRow({required this.draft});

  final ReceiptNativeCaptureRecoveryRecord draft;

  @override
  Widget build(BuildContext context) {
    final count = draft.existingPhotoCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: _ink,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => _continuePhotoDraft(context, draft),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: _gold, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receipt Draft',
                        style: TextStyle(
                          color: Color(0xFFF0F4F2),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_shortDate(draft.capturedAt)} | $count photo${count == 1 ? '' : 's'} | Not yet completed',
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete receipt draft',
                  onPressed: () async {
                    await const ReceiptNativeCaptureStaging()
                        .discardRecoveryRecord(draft);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: _red,
                    size: 18,
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
                    onTap: () => ExpenseDraftScope.maybeOf(
                      context,
                    )?.deleteDraft(draft.id),
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
