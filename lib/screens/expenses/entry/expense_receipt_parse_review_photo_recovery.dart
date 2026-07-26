part of 'expense_receipt_entry_screen.dart';

class _ReceiptPhotoRecoveryPanel extends StatelessWidget {
  const _ReceiptPhotoRecoveryPanel({
    required this.child,
    required this.onReviewDetails,
    required this.missingBottomSection,
    required this.missingBottomEdgeAndTotals,
    required this.manualReviewOnly,
  });

  final Widget child;
  final VoidCallback onReviewDetails;
  final bool missingBottomSection;
  final bool missingBottomEdgeAndTotals;
  final bool manualReviewOnly;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        collapsedBackgroundColor: const Color(0xFF111719),
        backgroundColor: const Color(0xFF111719),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0x3346D6FF)),
        ),
        iconColor: const Color(0xFFFFD166),
        collapsedIconColor: const Color(0xFFFFD166),
        leading: const Icon(
          Icons.add_photo_alternate_rounded,
          color: Color(0xFFFFD166),
        ),
        title: Text(
          missingBottomEdgeAndTotals
              ? 'Add bottom receipt section'
              : missingBottomSection
              ? 'Add bottom receipt section'
              : manualReviewOnly
              ? 'Retake or add receipt photos'
              : 'Add or retake receipt photos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        subtitle: Text(
          missingBottomEdgeAndTotals
              ? 'Bottom edge and subtotal/total lines were not found together. Add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice so subtotal, total, and final lines can be matched.'
              : missingBottomSection
              ? 'Subtotal/total lines were not found. Add the lower section if the receipt continues; your filled review stays below.'
              : manualReviewOnly
              ? 'Use this only if the saved receipt is blurry, incomplete, or unreadable. Manual receipt review stays below.'
              : 'Use this only if a section is missing, blurry, or out of order. Your filled receipt review stays below.',
          style: TextStyle(
            color: Color(0xFFC8D0D3),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            height: 1.18,
            letterSpacing: 0,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReviewDetails,
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text(
                      manualReviewOnly
                          ? 'Open Manual Review'
                          : 'Back To Review',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8EF6A4),
                      side: const BorderSide(color: Color(0xFF8EF6A4)),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: child,
          ),
        ],
      ),
    );
  }
}
