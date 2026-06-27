part of 'receipt_photo_review_screen.dart';

class _ReceiptDataSaverPreviewCard extends StatelessWidget {
  const _ReceiptDataSaverPreviewCard({required this.preview});

  final ReceiptImageStoragePreview? preview;

  @override
  Widget build(BuildContext context) {
    final current = preview;
    if (current == null) {
      return const _DataSaverMessageCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Preparing Saved Proof Preview',
        detail: 'Building the smaller receipt image that would be kept.',
      );
    }
    final quality = current.quality;
    final mode = current.level.usesGrayscale ? 'black and white' : 'color';
    final detail = !quality.needsReview
        ? '${current.estimatedLabel} saved proof, ${current.savedLabel} saved, $mode.'
        : '${current.estimatedLabel} saved proof, $mode. ${quality.reviewGuidance}';
    return _DataSaverMessageCard(
      icon: !quality.needsReview
          ? Icons.savings_rounded
          : quality.hasCriticalIssue
          ? Icons.replay_rounded
          : Icons.fact_check_rounded,
      title: !quality.needsReview
          ? '${current.level.label} Saved Proof'
          : quality.reviewTitle,
      detail: detail,
      footer: !quality.needsReview
          ? 'The image behind this panel is the saved proof preview. OCR already uses the clear photo first. Original ${current.originalLabel}.'
          : 'OCR already uses the clear photo first. This setting only controls the smaller saved proof copy.',
      warning: quality.needsReview,
      onDetails: () => _showDataSaverDetails(context, current),
    );
  }
}

class _DataSaverMessageCard extends StatelessWidget {
  const _DataSaverMessageCard({
    required this.icon,
    required this.title,
    required this.detail,
    this.footer,
    this.warning = false,
    this.onDetails,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? footer;
  final bool warning;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFFFD166) : const Color(0xFF58D67D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .85)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                if ((footer ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    footer!,
                    style: const TextStyle(
                      color: Color(0xFFC7D0D4),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDetails != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Storage details',
              onPressed: onDetails,
              icon: const Icon(Icons.info_outline_rounded, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: color,
                minimumSize: const Size(38, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showDataSaverDetails(
  BuildContext context,
  ReceiptImageStoragePreview preview,
) async {
  final storage = await AppStorageGuard.checkForBytes(
    operationBytes: preview.estimatedBytes,
    purpose: AppStoragePurpose.receiptPhotoSave,
  );
  const cloudStatus = CloudBackupStatusSnapshot.notConnected();
  final cloud = cloudStatus.checkPendingBytes(preview.estimatedBytes);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1F2528),
        title: const Text(
          'Photo Storage Details',
          style: TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StorageDetailRow(
              label: 'Original photo',
              value: preview.originalLabel,
            ),
            _StorageDetailRow(
              label: 'Saved proof image',
              value: preview.estimatedLabel,
            ),
            _StorageDetailRow(
              label: 'Estimated savings',
              value: preview.savedLabel,
            ),
            _StorageDetailRow(
              label: 'Space saving',
              value: '${(preview.savedPercent * 100).round()}%',
            ),
            _StorageDetailRow(
              label: 'Photo mode',
              value: preview.level.usesGrayscale ? 'Black and white' : 'Color',
            ),
            _StorageDetailRow(
              label: 'Device free space',
              value: storage.availableLabel,
              warning: storage.shouldWarnLowStorage || !storage.hasEnoughSpace,
            ),
            _StorageDetailRow(
              label: 'Cloud backup',
              value:
                  '${cloudStatus.connectionState.label} (${cloud.statusLabel})',
            ),
            _StorageDetailRow(
              label: 'Cloud allowance',
              value: cloud.quotaLabel,
            ),
            _StorageDetailRow(
              label: 'Cloud note',
              value: cloud.detailLabel,
              warning: cloud.wouldExceedCloudTier,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class _StorageDetailRow extends StatelessWidget {
  const _StorageDetailRow({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final valueColor = warning
        ? const Color(0xFFFFD166)
        : const Color(0xFFE8ECEE);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
