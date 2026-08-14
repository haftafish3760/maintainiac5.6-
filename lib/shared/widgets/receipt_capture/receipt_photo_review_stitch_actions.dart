part of 'receipt_photo_review_screen.dart';

class _ReceiptStitchBackButton extends StatelessWidget {
  const _ReceiptStitchBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back to receipt sections',
      child: IconButton.filledTonal(
        tooltip: 'Back to receipt sections',
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    );
  }
}

class _ReceiptStitchReviewActions extends StatelessWidget {
  const _ReceiptStitchReviewActions({
    required this.ready,
    required this.fallback,
    required this.manualAlignmentActive,
    required this.saving,
    required this.onUse,
    required this.onRedo,
    required this.onCancel,
  });

  final bool ready;
  final bool fallback;
  final bool manualAlignmentActive;
  final bool saving;
  final VoidCallback onUse;
  final VoidCallback onRedo;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final enabled = !saving;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            // Three labelled actions cannot remain readable in one row on a
            // phone. Keep the confirmation full-width and place recovery
            // actions underneath instead of crushing their labels.
            final compact = constraints.maxWidth < 480 || textScale > 1.0;
            final cancel = IconButton.outlined(
              tooltip: 'Review receipt sections',
              onPressed: enabled ? onCancel : null,
              icon: const Icon(Icons.photo_library_outlined),
            );
            final redo = OutlinedButton.icon(
              onPressed: enabled ? onRedo : null,
              icon: Icon(
                fallback ? Icons.open_with_rounded : Icons.refresh_rounded,
              ),
              label: Text(
                fallback
                    ? manualAlignmentActive
                          ? 'Try alignment'
                          : 'Align two photos'
                    : 'Review photos',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: const Color(0xFFE8ECEE),
                side: const BorderSide(color: Color(0xFF526168)),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            );
            final use = FilledButton.icon(
              onPressed: enabled && (ready || fallback) ? onUse : null,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(saving ? 'Continuing' : 'Continue'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: double.infinity, child: use),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      cancel,
                      const SizedBox(width: 8),
                      Expanded(child: redo),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                cancel,
                const SizedBox(width: 8),
                Expanded(child: redo),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: use),
              ],
            );
          },
        ),
      ),
    );
  }
}
