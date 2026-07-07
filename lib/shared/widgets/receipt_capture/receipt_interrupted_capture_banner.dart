part of 'receipt_attachment_panel.dart';

class _ReceiptInterruptedCaptureBanner extends StatelessWidget {
  const _ReceiptInterruptedCaptureBanner({
    required this.record,
    required this.total,
    required this.loading,
    required this.onResume,
    required this.onDismiss,
  });

  final ReceiptNativeCaptureRecoveryRecord record;
  final int total;
  final bool loading;
  final VoidCallback? onResume;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final countLabel = record.recoveredCountLabel;
    final engineLabel = record.engine.label;
    final freshnessLabel = record.recoveryFreshnessLabel();
    final extraLabel = total > 1 ? ' $total interrupted captures found.' : '';
    final resumeIcon = record.hasCompleteLocalRecovery
        ? Icons.play_arrow_rounded
        : Icons.photo_camera_rounded;
    final nextStepCopy = record.hasCompleteLocalRecovery
        ? 'Resume reviews the saved photos first; receipt details open from the saved proof after review. Discard only removes this interrupted recovery copy.'
        : 'Some saved photos are missing. Retake the receipt photos, or discard this interrupted recovery copy.';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF12191C),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          loading
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFFD166),
                  ),
                )
              : const Icon(
                  Icons.restore_rounded,
                  color: Color(0xFFFFD166),
                  size: 20,
                ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume Interrupted Receipt Photos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$freshnessLabel: $countLabel from $engineLabel were saved locally before review finished.$extraLabel',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      record.hasCompleteLocalRecovery
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: record.hasCompleteLocalRecovery
                          ? const Color(0xFF52D273)
                          : const Color(0xFFFFD166),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${record.recoveryResumeStatusLabel}: ${record.recoveryResumeActionDetail}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8ECEE),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  nextStepCopy,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFE2A0),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onResume,
                        icon: Icon(resumeIcon, size: 17),
                        label: Text(record.recoveryResumeActionLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Discard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE8ECEE),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: const BorderSide(color: Color(0xFF56666E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
