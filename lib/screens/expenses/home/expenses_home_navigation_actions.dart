part of 'expenses_home_screen.dart';

void _openReceipt(
  BuildContext context, {
  String? initialCategory,
  DateTime? initialDate,
  String? draftId,
  ExpenseReceiptFlowMode mode = ExpenseReceiptFlowMode.general,
  bool showInterruptedCaptureRecovery = false,
}) {
  Navigator.of(context).push(
    appNativeRoute<Object>(
      context,
      ExpenseReceiptEntryScreen(
        mode: mode,
        initialCategory: initialCategory,
        initialDate: initialDate,
        draftId: draftId,
        showInterruptedCaptureRecovery: showInterruptedCaptureRecovery,
      ),
    ),
  );
}

void _openDraft(BuildContext context, ExpenseReceiptDraftRecord draft) {
  _openReceipt(
    context,
    draftId: draft.id,
    initialDate: draft.receiptDate,
    mode: draft.sourceScreen == 'materials_expense_receipt'
        ? ExpenseReceiptFlowMode.materials
        : ExpenseReceiptFlowMode.general,
  );
}

Future<void> _continuePhotoDraft(
  BuildContext context,
  ReceiptNativeCaptureRecoveryRecord recovery,
) async {
  final drafts = ExpenseDraftScope.maybeOf(context);
  if (drafts == null) return;
  final draftId = 'RECOVERED-${recovery.sessionId}';
  await drafts.saveDraft(
    ExpenseReceiptDraftRecord(
      id: draftId,
      receiptDate: recovery.capturedAt,
      updatedAt: recovery.capturedAt,
      hasReceiptProof: recovery.attachments.isNotEmpty,
      attachments: recovery.attachments,
    ),
  );
  await const ReceiptNativeCaptureStaging().clearRecoveryRecord(recovery);
  if (!context.mounted) return;
  Navigator.of(context).pop();
  _openReceipt(context, draftId: draftId, initialDate: recovery.capturedAt);
}

void _showAllExpenseEntries(BuildContext context) {
  final entries = ExpenseLedgerScope.of(
    context,
  ).receipts.map(_LedgerEntryData.fromReceipt).toList(growable: false);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _pageBackground,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        minChildSize: .40,
        initialChildSize: .74,
        maxChildSize: .92,
        builder: (context, controller) {
          return _ExpenseLedgerSheet(
            title: 'All expense entries',
            detail: 'Newest saved receipts first.',
            entries: entries,
            scrollController: controller,
          );
        },
      );
    },
  );
}

void _showCategoryEntries(
  BuildContext context,
  ExpenseCategoryDefinition category,
  ExpenseDateRange range,
  String rangeLabel,
) {
  Navigator.of(context).push(
    appNativeRoute<Object>(
      context,
      _ExpenseCategoryEntriesScreen(
        category: category,
        range: range,
        rangeLabel: rangeLabel,
      ),
    ),
  );
}

List<_LedgerEntryData> _categoryEntriesForRange(
  BuildContext context,
  ExpenseCategoryDefinition category,
  ExpenseDateRange range,
) {
  return ExpenseLedgerScope.of(context).receipts
      .where((receipt) => range.contains(receipt.receiptDate))
      .where(
        (receipt) => receipt.lines.any(
          (line) => _sameExpenseCategory(line.category, category.category),
        ),
      )
      .map(_LedgerEntryData.fromReceipt)
      .toList(growable: false);
}

void _openMaterialReceipt(BuildContext context, {DateTime? initialDate}) {
  _openReceipt(
    context,
    initialCategory: 'Materials',
    initialDate: initialDate,
    mode: ExpenseReceiptFlowMode.materials,
  );
}

void _openReminder(BuildContext context) {
  Navigator.of(
    context,
  ).push(appNativeRoute<void>(context, const ExpenseReminderScreen()));
}

void _openCategory(
  BuildContext context,
  ExpenseCategoryDefinition category, {
  DateTime? initialDate,
}) {
  if (category.category == 'Reminder') {
    _openReminder(context);
    return;
  }
  if (category.category == 'Materials') {
    _openMaterialReceipt(context, initialDate: initialDate);
    return;
  }
  if (category.category == 'Repair' || category.category == 'Maintenance') {
    _openReceipt(
      context,
      initialCategory: category.category,
      initialDate: initialDate,
      mode: ExpenseReceiptFlowMode.maintenanceRepair,
    );
    return;
  }
  _openReceipt(
    context,
    initialCategory: category.category,
    initialDate: initialDate,
  );
}

void _showCategoryInfo(
  BuildContext context,
  ExpenseCategoryDefinition category, {
  DateTime? initialDate,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: _ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF0F4F2),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            _DialogButton(
              label: 'Start expense',
              onTap: () {
                Navigator.of(context).pop();
                _openCategory(context, category, initialDate: initialDate);
              },
            ),
            const SizedBox(height: 8),
            _DialogButton(
              label: 'Close',
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showOtherCategories(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _pageBackground,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        minChildSize: .45,
        initialChildSize: .82,
        maxChildSize: .92,
        builder: (context, controller) =>
            _OtherCategoriesSheet(scrollController: controller),
      );
    },
  );
}

void _showQuickActionSettings(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _pageBackground,
    builder: (context) {
      return const DraggableScrollableSheet(
        expand: false,
        minChildSize: .50,
        initialChildSize: .88,
        maxChildSize: .94,
        builder: _buildQuickActionSettings,
      );
    },
  );
}

Widget _buildQuickActionSettings(
  BuildContext context,
  ScrollController controller,
) {
  return _QuickActionSettingsSheet(scrollController: controller);
}

void _openMoneyStat(BuildContext context, _MoneyStatData stat) {
  final scope = stat.scope;
  if (scope != null) {
    _showExpenseScopeSheet(context, scope, stat.range, stat.detail);
    return;
  }
}

void _showExpenseScopeSheet(
  BuildContext context,
  String scope,
  ExpenseDateRange? selectedRange,
  String? selectedDetail,
) {
  final range = selectedRange ?? _weekRange(DateTime.now());
  final entries = ExpenseLedgerScope.of(context).receipts
      .where((receipt) => range.contains(receipt.receiptDate))
      .where((receipt) => _receiptHasScope(receipt, scope))
      .map(_LedgerEntryData.fromReceipt)
      .toList(growable: false);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _pageBackground,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        minChildSize: .38,
        initialChildSize: .68,
        maxChildSize: .90,
        builder: (context, controller) {
          return _ExpenseLedgerSheet(
            title: '$scope expenses',
            detail: selectedDetail ?? 'This week, active vehicle only.',
            entries: entries,
            scrollController: controller,
          );
        },
      );
    },
  );
}

void _showReceiptDetail(BuildContext context, _LedgerEntryData entry) {
  Navigator.of(context).push(
    appNativeRoute<void>(
      context,
      ExpenseReceiptDetailScreen(receiptId: entry.receiptId),
    ),
  );
}
