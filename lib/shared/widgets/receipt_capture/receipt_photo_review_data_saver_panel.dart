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
        title: 'Checking Photo Size',
        detail: 'Maintaniac is estimating how much space this copy will use.',
      );
    }
    final quality = current.quality;
    final grayscaleNote = current.level.usesGrayscale
        ? ' Black-and-white copy is on for this level.'
        : '';
    final detail = quality.isLikelyReadable
        ? 'Original ${current.originalLabel}. Saved copy about ${current.estimatedLabel}. Saves ${current.savedLabel}.$grayscaleNote'
        : 'This photo may be hard to read. Zoom in and check the store name, date, and totals before saving.';
    return _DataSaverMessageCard(
      icon: quality.isLikelyReadable
          ? Icons.savings_rounded
          : Icons.center_focus_weak_rounded,
      title: quality.isLikelyReadable
          ? '${current.level.label}: ${(current.savedPercent * 100).round()}% Less Storage'
          : 'Check This Photo',
      detail: detail,
      footer: quality.isLikelyReadable
          ? '${quality.resolutionLabel} | ${quality.focusLabel}'
          : 'Tip: if photos keep coming out blurry, record a short video, pause on a clear frame, screenshot it, then upload that image.',
      warning: !quality.isLikelyReadable,
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
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .85)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 11.5,
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
                if (onDetails != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline_rounded, size: 16),
                      label: const Text('Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
              label: 'Saved copy',
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
              value: '${cloudStatus.connectionState.label} (${cloud.statusLabel})',
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
