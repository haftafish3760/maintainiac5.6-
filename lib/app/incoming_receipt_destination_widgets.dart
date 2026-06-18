part of 'incoming_receipt_destination_screen.dart';

class _IncomingShareMessages extends StatelessWidget {
  const _IncomingShareMessages({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return _DestinationPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFFFD166)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Shared file notes',
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final message in messages.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFC8D0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  letterSpacing: 0,
                ),
              ),
            ),
          if (messages.length > 3)
            Text(
              '${messages.length - 3} more notes will stay with this import.',
              style: const TextStyle(
                color: Color(0xFFFFD166),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _IncomingSuggestionPanel extends StatelessWidget {
  const _IncomingSuggestionPanel({
    required this.suggestion,
    required this.onTap,
  });

  final ExpenseReceiptClassification suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: _DestinationPanel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _incomingSuggestionIconFor(suggestion.kind),
                color: const Color(0xFF8EF6A4),
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested: ${suggestion.title}',
                      style: const TextStyle(
                        color: Color(0xFFF0F4F2),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      suggestion.detail,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${suggestion.confidencePercentLabel} ${suggestion.confidenceLabel}',
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingDestinationPrompt extends StatelessWidget {
  const _IncomingDestinationPrompt();

  @override
  Widget build(BuildContext context) {
    return _DestinationPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.touch_app_rounded, color: Color(0xFF8EF6A4)),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'What are you sharing to Maintainiac? Choose the destination yourself. Suggestions only help you start faster.',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptImportProofSummary extends StatelessWidget {
  const _ReceiptImportProofSummary({
    required this.attachmentCount,
    required this.hasText,
  });

  final int attachmentCount;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    final proofLabel = attachmentCount == 1
        ? '1 receipt proof attached'
        : attachmentCount == 0
        ? 'No receipt proof attached'
        : '$attachmentCount receipt proofs attached';
    return _DestinationPanel(
      child: Row(
        children: [
          const Icon(Icons.attach_file_rounded, color: Color(0xFFFFD166)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hasText ? '$proofLabel with readable text' : proofLabel,
              style: const TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDestinationCard extends StatelessWidget {
  const _ReceiptDestinationCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: _DestinationPanel(
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8FD3FF), size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF0F4F2),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFE8ECEE)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationPanel extends StatelessWidget {
  const _DestinationPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11181B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF445159)),
      ),
      child: Padding(padding: const EdgeInsets.all(10), child: child),
    );
  }
}

IconData _incomingSuggestionIconFor(ExpenseReceiptClassificationKind kind) {
  return switch (kind) {
    ExpenseReceiptClassificationKind.fuel => Icons.local_gas_station_rounded,
    ExpenseReceiptClassificationKind.materials => Icons.inventory_2_rounded,
    ExpenseReceiptClassificationKind.maintenance ||
    ExpenseReceiptClassificationKind.repair => Icons.build_rounded,
    ExpenseReceiptClassificationKind.cellPhone => Icons.phone_android_rounded,
    ExpenseReceiptClassificationKind.jobDocument => Icons.request_quote_rounded,
    ExpenseReceiptClassificationKind.otherDocument => Icons.description_rounded,
    ExpenseReceiptClassificationKind.expenseReceipt =>
      Icons.receipt_long_rounded,
  };
}

IconData _incomingIconFor(ExpenseActionIcon icon) {
  return switch (icon) {
    ExpenseActionIcon.fuel => Icons.local_gas_station_rounded,
    ExpenseActionIcon.repair => Icons.build_rounded,
    ExpenseActionIcon.insurance => Icons.verified_user_rounded,
    ExpenseActionIcon.parking => Icons.local_parking_rounded,
    ExpenseActionIcon.tolls => Icons.toll_rounded,
    ExpenseActionIcon.meals => Icons.restaurant_rounded,
    ExpenseActionIcon.tools => Icons.handyman_rounded,
    ExpenseActionIcon.supplies => Icons.inventory_2_rounded,
    ExpenseActionIcon.registration => Icons.badge_rounded,
    ExpenseActionIcon.reminder => Icons.notifications_rounded,
    ExpenseActionIcon.rentLease => Icons.payments_rounded,
    ExpenseActionIcon.utilities => Icons.power_rounded,
  };
}
