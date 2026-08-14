part of 'receipt_photo_review_screen.dart';

class _ReceiptPreviewPrimaryRow extends StatelessWidget {
  const _ReceiptPreviewPrimaryRow({
    required this.uiConfig,
    required this.current,
    required this.total,
    required this.compact,
    required this.wideShortLayout,
    required this.coverageDecision,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onRetake,
    required this.onAddPhoto,
    required this.onRemove,
    required this.onCrop,
    required this.onArrange,
    required this.onContinue,
  });

  final ReceiptPhotoReviewUiConfig uiConfig;
  final int current;
  final int total;
  final bool compact;
  final bool wideShortLayout;
  final ReceiptPhotoCoverageDecision coverageDecision;
  final bool savingPhotos;
  final String continueLabel;
  final VoidCallback? onRetake;
  final VoidCallback? onAddPhoto;
  final VoidCallback? onRemove;
  final VoidCallback? onCrop;
  final VoidCallback? onArrange;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final retakeLabel = uiConfig.labelFor(
      'retake',
      _ReceiptPhotoSectionLabels.retakeLabel(index: current - 1, total: total),
    );
    final retakeSemanticLabel = _ReceiptPhotoSectionLabels.retakeSemanticLabel(
      index: current - 1,
      total: total,
    );
    final addPhotoLabel = coverageDecision.isMissingBottomEdgeAndTotals
        ? 'Add Bottom Section'
        : uiConfig.labelFor('addPhoto', uiConfig.addPhotoLabel);
    final addPhotoTooltip = coverageDecision.isMissingBottomEdgeAndTotals
        ? 'Add bottom receipt section and repeat 3-5 readable lines in the top reference strip'
        : coverageDecision.shouldPromptForMorePhotos
        ? 'Add the next receipt section with overlap from this photo'
        : 'Add another receipt photo if the receipt continues';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: uiConfig.controlsBackgroundColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: uiConfig.controlsBorderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: wideShortLayout
            ? _buildWideShortRow(
                retakeLabel: retakeLabel,
                retakeSemanticLabel: retakeSemanticLabel,
                addPhotoLabel: addPhotoLabel,
                addPhotoTooltip: addPhotoTooltip,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ReceiptPreviewSecondaryAction(
                          icon: Icons.crop_rounded,
                          label: 'Crop',
                          semanticLabel: 'Crop receipt photo',
                          onPressed: savingPhotos ? null : onCrop,
                        ),
                      ),
                      if (onRemove != null) ...[
                        const SizedBox(width: 7),
                        Expanded(
                          child: _ReceiptPreviewSecondaryAction(
                            icon: Icons.delete_outline_rounded,
                            label: 'Remove',
                            semanticLabel:
                                'Remove receipt section $current of $total',
                            onPressed: savingPhotos ? null : onRemove,
                            destructive: true,
                          ),
                        ),
                      ],
                      const SizedBox(width: 7),
                      Expanded(
                        child: _ReceiptPreviewSecondaryAction(
                          icon: Icons.camera_alt_rounded,
                          label: retakeLabel,
                          semanticLabel: retakeSemanticLabel,
                          onPressed: savingPhotos ? null : onRetake,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: _ReceiptPreviewSecondaryAction(
                          icon: Icons.add_a_photo_rounded,
                          label: addPhotoLabel,
                          semanticLabel: addPhotoTooltip,
                          onPressed: savingPhotos ? null : onAddPhoto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (compact)
                    Row(
                      children: [
                        if (onArrange != null) ...[
                          Expanded(child: _arrangeButton(compact: true)),
                          const SizedBox(width: 7),
                        ],
                        Expanded(child: _continueButton(compact: true)),
                      ],
                    )
                  else ...[
                    if (onArrange != null) ...[
                      SizedBox(width: double.infinity, child: _arrangeButton()),
                      const SizedBox(height: 7),
                    ],
                    SizedBox(width: double.infinity, child: _continueButton()),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildWideShortRow({
    required String retakeLabel,
    required String retakeSemanticLabel,
    required String addPhotoLabel,
    required String addPhotoTooltip,
  }) {
    final actions = <Widget>[
      _ReceiptPreviewSecondaryAction(
        icon: Icons.crop_rounded,
        label: 'Crop',
        semanticLabel: 'Crop receipt photo',
        onPressed: savingPhotos ? null : onCrop,
      ),
      if (onRemove != null)
        _ReceiptPreviewSecondaryAction(
          icon: Icons.delete_outline_rounded,
          label: 'Remove',
          semanticLabel: 'Remove receipt section $current of $total',
          onPressed: savingPhotos ? null : onRemove,
          destructive: true,
        ),
      _ReceiptPreviewSecondaryAction(
        icon: Icons.camera_alt_rounded,
        label: retakeLabel,
        semanticLabel: retakeSemanticLabel,
        onPressed: savingPhotos ? null : onRetake,
      ),
      _ReceiptPreviewSecondaryAction(
        icon: Icons.add_a_photo_rounded,
        label: addPhotoLabel,
        semanticLabel: addPhotoTooltip,
        onPressed: savingPhotos ? null : onAddPhoto,
      ),
      if (onArrange != null) _arrangeButton(compact: true),
    ];
    return Row(
      key: const ValueKey('receipt-review-wide-short-actions'),
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(child: actions[index]),
          const SizedBox(width: 6),
        ],
        Expanded(flex: 2, child: _continueButton(compact: true)),
      ],
    );
  }

  Widget _arrangeButton({bool compact = false}) => OutlinedButton.icon(
    onPressed: savingPhotos ? null : onArrange,
    icon: const Icon(Icons.swap_vert_rounded, size: 18),
    label: Text(compact ? 'Arrange' : 'Arrange Photos'),
    style: OutlinedButton.styleFrom(
      minimumSize: Size.fromHeight(compact ? 46 : 42),
      foregroundColor: const Color(0xFFE8ECEE),
      side: const BorderSide(color: Color(0xFF526168)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
    ),
  );

  Widget _continueButton({bool compact = false}) => FilledButton.icon(
    onPressed: savingPhotos ? null : onContinue,
    icon: savingPhotos
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Icon(
            continueLabel == 'Checking receipt photos'
                ? Icons.hourglass_top_rounded
                : Icons.arrow_forward_rounded,
          ),
    label: Text(savingPhotos ? 'Opening' : continueLabel),
    style: FilledButton.styleFrom(
      minimumSize: Size.fromHeight(compact ? 46 : 50),
      backgroundColor: uiConfig.primaryActionColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      textStyle: TextStyle(
        fontSize: compact ? 12 : 14,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _ReceiptPreviewSecondaryAction extends StatelessWidget {
  const _ReceiptPreviewSecondaryAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        foregroundColor: destructive
            ? const Color(0xFFFF9A94)
            : const Color(0xFFE8ECEE),
        disabledForegroundColor: const Color(0xFF758188),
        side: BorderSide(
          color: destructive
              ? const Color(0xFF8C3E3A)
              : const Color(0xFF526168),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, textAlign: TextAlign.center),
          ),
        ],
      ),
    ),
  );
}

class _ReceiptReviewDecisionHeader extends StatelessWidget {
  const _ReceiptReviewDecisionHeader({
    required this.photoCount,
    required this.coverageDecision,
    required this.continueLabel,
    required this.compact,
  });

  final int photoCount;
  final ReceiptPhotoCoverageDecision coverageDecision;
  final String continueLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final title = photoCount > 1
        ? 'Review $photoCount receipt sections'
        : 'Review receipt photo';
    final guidance = _guidance;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD101719),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF344047)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(9, compact ? 6 : 8, 9, compact ? 6 : 8),
        child: Row(
          children: [
            Icon(
              photoCount > 1
                  ? Icons.receipt_long_rounded
                  : Icons.photo_camera_back_rounded,
              color: const Color(0xFFFFD166),
              size: compact ? 16 : 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFFE8ECEE),
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      guidance,
                      style: const TextStyle(
                        color: Color(0xFFC8D0D3),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _guidance {
    if (coverageDecision.isMissingBottomEdgeAndTotals) {
      return 'Add the bottom section if the receipt continues. Continue only when this is complete.';
    }
    if (coverageDecision.shouldPromptForMorePhotos) {
      return 'Add another photo if more receipt lines continue below this section.';
    }
    if (photoCount > 1 && continueLabel == 'Review Photos') {
      return 'Review the photos in order, then continue to the receipt.';
    }
    return 'Choose Saved Image Size next. Then Continue opens the receipt details.';
  }
}
