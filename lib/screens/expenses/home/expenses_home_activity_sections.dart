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
                            fontSize: 13,
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
    final visibleDrafts = List<ExpenseReceiptDraftRecord>.from(drafts);
    final visiblePhotoDrafts = List<ReceiptNativeCaptureRecoveryRecord>.from(
      photoDrafts,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _pageBackground,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
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
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final draft in visibleDrafts)
                        _DraftRow(
                          draft: draft,
                          onDeleted: () => _removeVisibleDraft(
                            sheetContext: sheetContext,
                            setSheetState: setSheetState,
                            visibleDrafts: visibleDrafts,
                            visiblePhotoDrafts: visiblePhotoDrafts,
                            draftId: draft.id,
                          ),
                        ),
                      for (final photoDraft in visiblePhotoDrafts)
                        _PhotoDraftRow(
                          draft: photoDraft,
                          onDeleted: () => _removeVisiblePhotoDraft(
                            sheetContext: sheetContext,
                            setSheetState: setSheetState,
                            visibleDrafts: visibleDrafts,
                            visiblePhotoDrafts: visiblePhotoDrafts,
                            draft: photoDraft,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    final refreshedPhotoDrafts = _loadPhotoDrafts();
    setState(() {
      _photoDrafts = refreshedPhotoDrafts;
    });
  }

  void _removeVisibleDraft({
    required BuildContext sheetContext,
    required StateSetter setSheetState,
    required List<ExpenseReceiptDraftRecord> visibleDrafts,
    required List<ReceiptNativeCaptureRecoveryRecord> visiblePhotoDrafts,
    required String draftId,
  }) {
    setSheetState(
      () => visibleDrafts.removeWhere((draft) => draft.id == draftId),
    );
    _closeDraftSheetIfEmpty(sheetContext, visibleDrafts, visiblePhotoDrafts);
  }

  void _removeVisiblePhotoDraft({
    required BuildContext sheetContext,
    required StateSetter setSheetState,
    required List<ExpenseReceiptDraftRecord> visibleDrafts,
    required List<ReceiptNativeCaptureRecoveryRecord> visiblePhotoDrafts,
    required ReceiptNativeCaptureRecoveryRecord draft,
  }) {
    setSheetState(() => visiblePhotoDrafts.remove(draft));
    _closeDraftSheetIfEmpty(sheetContext, visibleDrafts, visiblePhotoDrafts);
  }

  void _closeDraftSheetIfEmpty(
    BuildContext context,
    List<ExpenseReceiptDraftRecord> drafts,
    List<ReceiptNativeCaptureRecoveryRecord> photoDrafts,
  ) {
    if (drafts.isEmpty && photoDrafts.isEmpty) Navigator.of(context).pop();
  }
}

class _PhotoDraftRow extends StatelessWidget {
  const _PhotoDraftRow({required this.draft, required this.onDeleted});

  final ReceiptNativeCaptureRecoveryRecord draft;
  final VoidCallback onDeleted;

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
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_shortDate(draft.capturedAt)} | $count photo${count == 1 ? '' : 's'} | Not yet completed',
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _DraftDeleteAction(
                  onPressed: () async {
                    if (!await _confirmDraftDeletion(context)) return;
                    await const ReceiptNativeCaptureStaging()
                        .discardRecoveryRecord(draft);
                    if (context.mounted) onDeleted();
                  },
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
  const _DraftRow({required this.draft, required this.onDeleted});

  final ExpenseReceiptDraftRecord draft;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final draftController = ExpenseDraftScope.maybeOf(context);
    final lineText = draft.lines.length == 1
        ? '1 line'
        : '${draft.lines.length} lines';
    final proofText = draft.hasReceiptAttachment
        ? '${draft.attachments.length} receipt ${draft.attachments.length == 1 ? 'photo' : 'photos'} attached'
        : 'No receipt photo attached';
    final reviewText = draft.receiptReadAttemptedWithoutText
        ? 'Needs manual review'
        : draft.rawOcrText.trim().isNotEmpty || draft.lines.isNotEmpty
        ? 'Receipt details ready to review'
        : 'Continue entering receipt details';
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note_rounded, color: _gold, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.title,
                        style: const TextStyle(
                          color: Color(0xFFF0F4F2),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_shortDate(draft.receiptDate)} | $lineText | ${_money(draft.total)}',
                        style: const TextStyle(
                          color: Color(0xFFC8D0D3),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$proofText | $reviewText',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9CB0B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                _DraftDeleteAction(
                  onPressed: () async {
                    if (!await _confirmDraftDeletion(context)) return;
                    final controller = draftController;
                    if (controller == null) return;
                    await controller.deleteDraft(draft.id);
                    if (context.mounted) onDeleted();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDraftDeletion(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete this draft?'),
      content: const Text(
        'This saved receipt draft and its attached photos will be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _red),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _DraftDeleteAction extends StatelessWidget {
  const _DraftDeleteAction({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: _red,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        minimumSize: Size.zero,
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.close_rounded, size: 16),
      label: const Text(
        'Delete',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}
