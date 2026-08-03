part of 'receipt_photo_review_screen.dart';

class _ReceiptStitchPairNavigator extends StatelessWidget {
  const _ReceiptStitchPairNavigator({
    required this.pairIndex,
    required this.pairCount,
    required this.onSelected,
  });

  final int pairIndex;
  final int pairCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = pairIndex.clamp(0, pairCount - 1).toInt();
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton.outlined(
            tooltip: 'Previous receipt join',
            onPressed: selected > 0 ? () => onSelected(selected - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              label:
                  'Receipt join ${selected + 1} of $pairCount, sections ${selected + 1} and ${selected + 2}',
              child: Text(
                'Join ${selected + 1} of $pairCount  |  Sections ${selected + 1} + ${selected + 2}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Next receipt join',
            onPressed: selected + 1 < pairCount
                ? () => onSelected(selected + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
