part of 'receipt_attachment_panel.dart';

class _ReceiptCaptureTargetGuidance extends StatelessWidget {
  const _ReceiptCaptureTargetGuidance({required this.hasAttachment});

  final bool hasAttachment;

  @override
  Widget build(BuildContext context) {
    final title = hasAttachment
        ? 'Need another receipt section?'
        : 'Long receipt? Scan top to bottom.';
    final detail = hasAttachment
        ? 'Use Add Another Photo if the receipt continues, a section is blurry, or the photo match needs review.'
        : 'Take readable sections with a little overlap. Keep the order top, middle, bottom so receipt details can be filled correctly.';
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1114),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFFFFD166).withValues(alpha: .5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: Color(0xFFFFD166),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFC8D0D3),
                    fontSize: 11.2,
                    fontWeight: FontWeight.w700,
                    height: 1.24,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
