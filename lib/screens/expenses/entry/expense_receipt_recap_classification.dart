part of 'expense_receipt_entry_screen.dart';

// Kept to render drafts produced by the earlier detailed assisted-review UI.
// ignore: unused_element
class _ReceiptClassificationReviewPanel extends StatelessWidget {
  const _ReceiptClassificationReviewPanel({
    required this.classification,
    required this.parseQuality,
    required this.parseDiagnostics,
    required this.fieldConfidences,
    required this.ocrDiagnostics,
    required this.ocrWarnings,
    required this.maintenanceHints,
    required this.onApplyCategory,
    required this.ocrActionCallbacks,
  });

  final ExpenseReceiptClassification classification;
  final ExpenseReceiptParseQuality? parseQuality;
  final ExpenseReceiptParseDiagnostics? parseDiagnostics;
  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;
  final ReceiptOcrDiagnostics? ocrDiagnostics;
  final List<ReceiptOcrWarning> ocrWarnings;
  final List<ExpenseReceiptMaintenanceHint> maintenanceHints;
  final ValueChanged<String> onApplyCategory;
  final Map<String, VoidCallback> ocrActionCallbacks;

  @override
  Widget build(BuildContext context) {
    final color = classification.confidence >= .84
        ? const Color(0xFF8EF6A4)
        : classification.confidence >= .58
        ? const Color(0xFFFFD166)
        : const Color(0xFFFF8FA3);
    final category = classification.category;
    return ReceiptFormPanel(
      title: 'What Maintainiac Found',
      subtitle:
          'Review the store, date, totals, and line confidence before saving.',
      icon: Icons.fact_check_rounded,
      accentColor: color,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF11181B),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: .72)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_classificationIcon(classification.kind), color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      classification.title,
                      style: const TextStyle(
                        color: Color(0xFFE8ECEE),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${classification.confidencePercentLabel} ${classification.confidenceLabel}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                classification.detail,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
              if (category != null) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Suggested category: $category',
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => onApplyCategory(category),
                      icon: const Icon(Icons.check_circle_rounded, size: 17),
                      label: const Text('Apply'),
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Only blank categories are updated.',
                  style: TextStyle(
                    color: color.withValues(alpha: .82),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
              if (parseQuality != null ||
                  ocrDiagnostics != null ||
                  maintenanceHints.isNotEmpty) ...[
                const SizedBox(height: 9),
                _ReceiptParseReviewDetails(
                  quality: parseQuality,
                  parseDiagnostics: parseDiagnostics,
                  fieldConfidences: fieldConfidences,
                  ocrDiagnostics: ocrDiagnostics,
                  ocrWarnings: ocrWarnings,
                  maintenanceHints: maintenanceHints,
                  ocrActionCallbacks: ocrActionCallbacks,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static IconData _classificationIcon(ExpenseReceiptClassificationKind kind) {
    return switch (kind) {
      ExpenseReceiptClassificationKind.ambiguous => Icons.help_outline_rounded,
      ExpenseReceiptClassificationKind.notReceipt => Icons.receipt_long_rounded,
      ExpenseReceiptClassificationKind.unsupported =>
        Icons.warning_amber_rounded,
      ExpenseReceiptClassificationKind.fuel => Icons.local_gas_station_rounded,
      ExpenseReceiptClassificationKind.materials => Icons.inventory_2_rounded,
      ExpenseReceiptClassificationKind.maintenance ||
      ExpenseReceiptClassificationKind.repair => Icons.build_rounded,
      ExpenseReceiptClassificationKind.cellPhone => Icons.phone_android_rounded,
      ExpenseReceiptClassificationKind.jobDocument =>
        Icons.request_quote_rounded,
      ExpenseReceiptClassificationKind.otherDocument =>
        Icons.description_rounded,
      ExpenseReceiptClassificationKind.expenseReceipt =>
        Icons.receipt_long_rounded,
    };
  }
}

class _ReceiptWholeUseReviewPanel extends StatelessWidget {
  const _ReceiptWholeUseReviewPanel({
    required this.selectedUse,
    required this.onMarkBusiness,
    required this.onMarkPersonal,
    required this.onMarkMixed,
  });

  final _ExpenseLineUse selectedUse;
  final VoidCallback onMarkBusiness;
  final VoidCallback onMarkPersonal;
  final VoidCallback onMarkMixed;

  @override
  Widget build(BuildContext context) {
    return ReceiptFormPanel(
      title: 'Receipt Use',
      subtitle:
          'Choose how this receipt should count. You can change any item later.',
      icon: Icons.rule_folder_rounded,
      accentColor: const Color(0xFFFFD166),
      children: [
        Row(
          children: [
            Expanded(
              child: _ReceiptWholeUseButton(
                label: 'All Business',
                helper: 'Every parsed line counts for work.',
                icon: Icons.business_center_rounded,
                color: const Color(0xFF34A9E8),
                onPressed: onMarkBusiness,
                selected: selectedUse == _ExpenseLineUse.business,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReceiptWholeUseButton(
                label: 'All Personal',
                helper: 'Nothing on this receipt counts for work.',
                icon: Icons.person_rounded,
                color: const Color(0xFF8F9BA1),
                onPressed: onMarkPersonal,
                selected: selectedUse == _ExpenseLineUse.personal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ReceiptWholeUseButton(
          label: 'Split Receipt',
          helper: 'Choose the business portion for each item in this receipt.',
          icon: Icons.call_split_rounded,
          color: const Color(0xFF3B7C73),
          onPressed: onMarkMixed,
          selected: selectedUse == _ExpenseLineUse.split,
        ),
      ],
    );
  }
}
