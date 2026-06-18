part of 'incoming_receipt_destination_screen.dart';

enum _IncomingDocumentFallbackAction {
  saveAsAppDocument,
  chooseExpenseCategory,
}

class _OtherDocumentChoiceSheet extends StatelessWidget {
  const _OtherDocumentChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return const _DocumentFallbackChoiceSheet(
      title: 'Other document',
      detail:
          'This does not look like a normal receipt. Save it as read-only document proof, or choose an expense category if it belongs in expenses.',
    );
  }
}

class _JobDocumentChoiceSheet extends StatelessWidget {
  const _JobDocumentChoiceSheet();

  @override
  Widget build(BuildContext context) {
    return const _DocumentFallbackChoiceSheet(
      title: 'Job / contractor document',
      detail:
          'This may belong with a job, invoice, estimate, signature, or customer record. Save it as read-only document proof, or pick an expense category if it is actually a receipt.',
    );
  }
}

class _DocumentFallbackChoiceSheet extends StatelessWidget {
  const _DocumentFallbackChoiceSheet({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: const TextStyle(
                color: Color(0xFFC8D0D3),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(_IncomingDocumentFallbackAction.saveAsAppDocument),
              icon: const Icon(Icons.description_rounded),
              label: const Text('Save As Document Proof'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pop(_IncomingDocumentFallbackAction.chooseExpenseCategory),
              icon: const Icon(Icons.category_rounded),
              label: const Text('Choose Expense Category'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCategoryChoiceSheet extends StatelessWidget {
  const _ReceiptCategoryChoiceSheet();

  @override
  Widget build(BuildContext context) {
    final categories = [...defaultExpenseCategories, ...otherExpenseCategories];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
        children: [
          const Text(
            'Choose category',
            style: TextStyle(
              color: Color(0xFFE8ECEE),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          for (final category in categories)
            ListTile(
              leading: Icon(
                _incomingIconFor(category.icon),
                color: category.gradient.first,
              ),
              title: Text(
                category.label,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () => Navigator.of(context).pop(category),
            ),
        ],
      ),
    );
  }
}
