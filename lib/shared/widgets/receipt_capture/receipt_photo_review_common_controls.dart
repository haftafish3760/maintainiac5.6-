part of 'receipt_photo_review_screen.dart';

class _ReceiptPersistentContinueButton extends StatelessWidget {
  const _ReceiptPersistentContinueButton({
    required this.enabled,
    required this.savingPhotos,
    required this.label,
    required this.onContinue,
  });

  final bool enabled;
  final bool savingPhotos;
  final String label;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = savingPhotos ? 'Preparing receipt details' : label;
    return Tooltip(
      message: semanticLabel,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: FilledButton.icon(
          onPressed: enabled ? onContinue : null,
          icon: savingPhotos
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.check_rounded),
          label: savingPhotos
              ? const Text('Preparing')
              : _ReceiptNextReviewLabel(label: label),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(42),
            backgroundColor: const Color(0xFF28A745),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _ReceiptNextReviewLabel extends StatelessWidget {
  const _ReceiptNextReviewLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.trim();
    if (normalized == 'Add Bottom Section') {
      return const _ReceiptStackedButtonLabel(
        primary: 'Add',
        secondary: 'Bottom Section',
      );
    }
    if (normalized == 'Check Photo Match') {
      return const _ReceiptStackedButtonLabel(
        primary: 'Check',
        secondary: 'Photo Match',
      );
    }
    return Text(normalized, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _ReceiptStackedButtonLabel extends StatelessWidget {
  const _ReceiptStackedButtonLabel({
    required this.primary,
    required this.secondary,
  });

  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        Text(
          secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.5,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ReceiptLocalPhotoLimitStrip extends StatelessWidget {
  const _ReceiptLocalPhotoLimitStrip({
    required this.photoCount,
    required this.deviceCapability,
  });

  final int photoCount;
  final ReceiptDeviceCapability deviceCapability;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF211A0C),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFFFD166)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            const Icon(
              Icons.sd_storage_rounded,
              size: 17,
              color: Color(0xFFFFD166),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$photoCount photos attached. ${deviceCapability.profileName} is tuned for ${deviceCapability.maxLocalPhotoCount} local receipt photos. Next still works, but review every line before saving.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE8ECEE),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.16,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptActionRailButton extends StatelessWidget {
  const _ReceiptActionRailButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: switch (label) {
        'Add Another Photo' =>
          'Add another receipt photo only if this receipt continues',
        'Proof' => 'Preview saved proof size',
        _ => label,
      },
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 32),
          backgroundColor: emphasized
              ? const Color(0xFFFFD166)
              : const Color(0xFF172126),
          disabledBackgroundColor: const Color(0xFF283137),
          foregroundColor: emphasized
              ? const Color(0xFF101416)
              : const Color(0xFFE8ECEE),
          disabledForegroundColor: const Color(0xFF758188),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
