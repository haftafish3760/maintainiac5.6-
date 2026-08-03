part of 'receipt_photo_review_screen.dart';

class _ReceiptPreviewPrimaryRow extends StatelessWidget {
  const _ReceiptPreviewPrimaryRow({
    required this.uiConfig,
    required this.current,
    required this.total,
    required this.statusIcon,
    required this.statusColor,
    required this.statusText,
    required this.compact,
    required this.coverageDecision,
    required this.savingPhotos,
    required this.continueLabel,
    required this.onRetake,
    required this.onAddPhoto,
    required this.onCrop,
    required this.onArrange,
    required this.onContinue,
  });

  final ReceiptPhotoReviewUiConfig uiConfig;
  final int current;
  final int total;
  final IconData statusIcon;
  final Color statusColor;
  final String statusText;
  final bool compact;
  final ReceiptPhotoCoverageDecision coverageDecision;
  final bool savingPhotos;
  final String continueLabel;
  final VoidCallback? onRetake;
  final VoidCallback? onAddPhoto;
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
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ReceiptPhotoCountBadge(current: current, total: total),
                const SizedBox(width: 8),
                Icon(statusIcon, color: statusColor, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    statusText,
                    maxLines: compact ? 1 : 2,
                    softWrap: true,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 12,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
            continueLabel == 'Putting receipt together'
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
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        foregroundColor: const Color(0xFFE8ECEE),
        disabledForegroundColor: const Color(0xFF758188),
        side: const BorderSide(color: Color(0xFF526168)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
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
    if (photoCount == 1) {
      return 'Choose Saved Image Size next. Then Continue opens the receipt details.';
    }
    return 'Continue combines the receipt sections, then lets you choose the saved image size.';
  }
}
