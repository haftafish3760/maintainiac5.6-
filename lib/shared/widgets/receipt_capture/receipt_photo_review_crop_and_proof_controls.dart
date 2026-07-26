part of 'receipt_photo_review_screen.dart';

class _ReceiptDataSaverStrip extends StatelessWidget {
  const _ReceiptDataSaverStrip({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ReceiptDataSaverLevel selected;
  final bool enabled;
  final ValueChanged<ReceiptDataSaverLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _cameraReceiptLevels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _cameraReceiptLevels[index];
          final active = level == selected;
          return SizedBox(
            width: 126,
            child: InkWell(
              onTap: enabled ? () => onSelected(level) : null,
              borderRadius: BorderRadius.circular(6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF172126),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: active
                        ? const Color(0xFFFFE2A1)
                        : const Color(0xFF526168),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${level.label}: ${level.shortLabel}',
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF101416)
                              : const Color(0xFFE8ECEE),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        level.reviewChoiceLabel,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF263238)
                              : const Color(0xFFC7D0D4),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static const _cameraReceiptLevels = [
    ReceiptDataSaverLevel.light,
    ReceiptDataSaverLevel.balanced,
    ReceiptDataSaverLevel.strong,
    ReceiptDataSaverLevel.maximum,
  ];
}

extension _ReceiptDataSaverReviewCopy on ReceiptDataSaverLevel {
  String get backupStyleLabel {
    return switch (this) {
      ReceiptDataSaverLevel.original => 'local source',
      ReceiptDataSaverLevel.light => 'high quality proof',
      ReceiptDataSaverLevel.balanced => 'normal proof',
      ReceiptDataSaverLevel.strong => 'low-storage proof',
      ReceiptDataSaverLevel.maximum => 'tiny proof',
    };
  }

  String get reviewChoiceLabel {
    return switch (this) {
      ReceiptDataSaverLevel.original => 'Full source stays local only.',
      ReceiptDataSaverLevel.light => 'Best proof for manual review.',
      ReceiptDataSaverLevel.balanced => 'Black-and-white everyday proof.',
      ReceiptDataSaverLevel.strong => 'Stronger contrast, less space.',
      ReceiptDataSaverLevel.maximum => 'Smallest proof; review first.',
    };
  }

  String get cleanupLabel {
    return switch (this) {
      ReceiptDataSaverLevel.original =>
        'No saved-proof shrinking is applied. The full source is kept locally only when explicitly allowed.',
      ReceiptDataSaverLevel.light =>
        'Cleanup keeps color and detail for review. Use this when the receipt is faint, wrinkled, or hard to inspect.',
      ReceiptDataSaverLevel.balanced =>
        'Cleanup uses a smaller black-and-white proof copy without changing the clear original photo used to read the receipt.',
      ReceiptDataSaverLevel.strong =>
        'Cleanup uses black-and-white plus stronger contrast for low-storage users while preserving the clear original photo separately.',
      ReceiptDataSaverLevel.maximum =>
        'Cleanup makes the smallest proof copy. Use only after checking the preview is still readable.',
    };
  }
}

class _ReceiptOcrProofLaneCard extends StatelessWidget {
  const _ReceiptOcrProofLaneCard({
    required this.selected,
    required this.storagePreview,
    required this.selectedQualityCheck,
  });

  final ReceiptDataSaverLevel selected;
  final ReceiptImageStoragePreview? storagePreview;
  final ReceiptPhotoQualityCheck? selectedQualityCheck;

  @override
  Widget build(BuildContext context) {
    final quality = selectedQualityCheck ?? storagePreview?.quality;
    final sourceStatus = quality == null
        ? 'Preparing clear photo'
        : quality.hasCriticalIssue
        ? 'Clear photo needs review'
        : quality.needsReview
        ? 'Clear photo usable with review'
        : 'Clear photo looks readable';
    final backupStatus = storagePreview == null
        ? 'Checking saved proof size'
        : '${storagePreview!.estimatedLabel} ${selected.backupStyleLabel}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101719),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Receipt Details And Saved Proof',
              style: TextStyle(
                color: Color(0xFFE8ECEE),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _ReceiptLaneChip(
                    icon: Icons.document_scanner_rounded,
                    title: 'Use Clear Photo',
                    detail: sourceStatus,
                    emphasized: !(quality?.hasCriticalIssue ?? false),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _ReceiptLaneChip(
                    icon: Icons.savings_rounded,
                    title: 'Save Small Copy',
                    detail: backupStatus,
                    emphasized: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              selected.cleanupLabel,
              style: const TextStyle(
                color: Color(0xFFC7D0D4),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.14,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptLaneChip extends StatelessWidget {
  const _ReceiptLaneChip({
    required this.icon,
    required this.title,
    required this.detail,
    required this.emphasized,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized
        ? const Color(0xFF58D67D)
        : const Color(0xFFFFD166);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? const Color(0x221CB85C) : const Color(0x22FFD166),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .65)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
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
