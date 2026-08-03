part of 'receipt_photo_review_screen.dart';

class _ReceiptSavedImageContinueBar extends StatelessWidget {
  const _ReceiptSavedImageContinueBar({
    required this.saving,
    required this.onContinue,
  });

  final bool saving;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1316),
        border: Border(top: BorderSide(color: Color(0xFF344047))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: FilledButton.icon(
          onPressed: saving ? null : onContinue,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded),
          label: Text(
            saving ? 'Opening receipt details' : 'Use This Saved Image',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: const Color(0xFF249D62),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _ReceiptDataSaverPreviewCard extends StatelessWidget {
  const _ReceiptDataSaverPreviewCard({required this.preview});

  final ReceiptImageStoragePreview? preview;

  @override
  Widget build(BuildContext context) {
    final strings = MaintaniacLocalizations.of(context);
    final current = preview;
    if (current == null) {
      return _DataSaverMessageCard(
        icon: Icons.hourglass_top_rounded,
        title: strings.preparingSavedProofPreview,
        detail: strings.buildingSavedProofPreview,
      );
    }
    final quality = current.quality;
    final mode = current.level.usesGrayscale
        ? strings.savedProofBlackAndWhite
        : strings.savedProofColor;
    final detail = !quality.needsReview
        ? strings.savedProofDetail(
            current.estimatedLabel,
            current.savedLabel,
            mode,
          )
        : strings.savedProofNeedsReview(current.estimatedLabel, mode);
    return _DataSaverMessageCard(
      icon: !quality.needsReview
          ? Icons.savings_rounded
          : quality.hasCriticalIssue
          ? Icons.replay_rounded
          : Icons.fact_check_rounded,
      title: !quality.needsReview
          ? strings.savedProof
          : strings.checkPhotoBeforeUse,
      detail: detail,
      footer: !quality.needsReview
          ? strings.savedProofOcrSourceFirst(current.originalLabel)
          : strings.savedProofSettingOnly,
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
  if (!context.mounted) return;
  final backupEnabled =
      ReceiptCaptureSettingsScope.maybeOf(context)?.receiptPhotoBackupEnabled ??
      false;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1F2528),
        title: const Text(
          'Receipt Proof Storage',
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
              label: 'Capture source size',
              value: preview.originalLabel,
            ),
            _StorageDetailRow(
              label: 'Saved receipt image',
              value: preview.estimatedLabel,
            ),
            _StorageDetailRow(
              label: '100 MB planning estimate',
              value: preview
                  .level
                  .proofTargetSizePolicy
                  .earlyAccessProofCapacityLabel,
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
            const _StorageDetailRow(
              label: 'Receipt assistance',
              value: 'Uses clear photo first',
            ),
            _StorageDetailRow(
              label: 'Image kept after reading',
              value: '${preview.level.label} saved image',
            ),
            _StorageDetailRow(
              label: 'Device free space',
              value: storage.availableLabel,
              warning: storage.shouldWarnLowStorage || !storage.hasEnoughSpace,
            ),
            _StorageDetailRow(
              label: 'Backup preference',
              value: backupEnabled
                  ? 'On. Check backup activity after saving this receipt.'
                  : 'Off. This receipt stays on your device until you turn backup on in Receipt settings.',
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'This estimate helps compare saved image sizes. It is not a backup balance or storage promise.',
                style: TextStyle(
                  color: Color(0xFF9FB0B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
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
