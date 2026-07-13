part of 'expense_receipt_entry_screen.dart';

class _ReceiptLineClassificationGuidance {
  const _ReceiptLineClassificationGuidance({
    required this.subtitle,
    required this.statusLabel,
    required this.actionLabel,
    required this.accentColor,
    required this.icon,
    required this.appFilledCount,
    required this.parserReviewCount,
    required this.splitCount,
    required this.splitMissingPercentCount,
  });

  final String subtitle;
  final String statusLabel;
  final String actionLabel;
  final Color accentColor;
  final IconData icon;
  final int appFilledCount;
  final int parserReviewCount;
  final int splitCount;
  final int splitMissingPercentCount;

  factory _ReceiptLineClassificationGuidance.from({
    required bool hasLines,
    required int appFilledCount,
    required int parserReviewCount,
    required int splitCount,
    required int splitMissingPercentCount,
  }) {
    if (!hasLines) {
      return const _ReceiptLineClassificationGuidance(
        subtitle:
            'Add or review receipt lines before choosing Business, Personal, or Mixed.',
        statusLabel: 'Waiting for lines',
        actionLabel: 'Add or review receipt lines first.',
        accentColor: Color(0xFFFFD166),
        icon: Icons.playlist_add_rounded,
        appFilledCount: 0,
        parserReviewCount: 0,
        splitCount: 0,
        splitMissingPercentCount: 0,
      );
    }
    if (parserReviewCount > 0) {
      return _ReceiptLineClassificationGuidance(
        subtitle:
            'Choose Business, Personal, or Mixed, then check the receipt-filled lines that need review.',
        statusLabel:
            '$parserReviewCount ${parserReviewCount == 1 ? 'line needs' : 'lines need'} review',
        actionLabel:
            'Check highlighted lines before trusting the final business/personal totals.',
        accentColor: const Color(0xFFFFD166),
        icon: Icons.manage_search_rounded,
        appFilledCount: appFilledCount,
        parserReviewCount: parserReviewCount,
        splitCount: splitCount,
        splitMissingPercentCount: splitMissingPercentCount,
      );
    }
    if (splitMissingPercentCount > 0) {
      return _ReceiptLineClassificationGuidance(
        subtitle:
            'Mixed receipt: set the business percent for every split line before saving.',
        statusLabel:
            '$splitMissingPercentCount split ${splitMissingPercentCount == 1 ? 'line needs' : 'lines need'} a percent',
        actionLabel: 'Tap each split line and choose the business share.',
        accentColor: const Color(0xFFFFD166),
        icon: Icons.percent_rounded,
        appFilledCount: appFilledCount,
        parserReviewCount: parserReviewCount,
        splitCount: splitCount,
        splitMissingPercentCount: splitMissingPercentCount,
      );
    }
    if (splitCount > 0) {
      return _ReceiptLineClassificationGuidance(
        subtitle:
            'Mixed receipt: review each line so business and personal totals are correct.',
        statusLabel:
            '$splitCount split ${splitCount == 1 ? 'line' : 'lines'} allocated',
        actionLabel: 'Review split percentages and final totals before saving.',
        accentColor: const Color(0xFF34A9E8),
        icon: Icons.call_split_rounded,
        appFilledCount: appFilledCount,
        parserReviewCount: parserReviewCount,
        splitCount: splitCount,
        splitMissingPercentCount: splitMissingPercentCount,
      );
    }
    return _ReceiptLineClassificationGuidance(
      subtitle:
          'Choose Business, Personal, or Mixed. If it is Mixed, review each line below.',
      statusLabel: appFilledCount > 0
          ? '$appFilledCount receipt-filled ${appFilledCount == 1 ? 'line' : 'lines'} ready'
          : 'Lines ready',
      actionLabel:
          'Use All Business or All Personal for one-purpose receipts, or Mixed for line-by-line classification.',
      accentColor: const Color(0xFF8EF6A4),
      icon: Icons.verified_rounded,
      appFilledCount: appFilledCount,
      parserReviewCount: parserReviewCount,
      splitCount: splitCount,
      splitMissingPercentCount: splitMissingPercentCount,
    );
  }
}

class _ReceiptLineClassificationChecklist extends StatelessWidget {
  const _ReceiptLineClassificationChecklist({required this.guidance});

  final _ReceiptLineClassificationGuidance guidance;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: guidance.accentColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: guidance.accentColor.withValues(alpha: .62)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(guidance.icon, color: guidance.accentColor, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guidance.statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: guidance.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    guidance.actionLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC8D0D3),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      height: 1.18,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
