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
    final addPhotoLabel = uiConfig.labelFor('addPhoto', uiConfig.addPhotoLabel);
    const addPhotoTooltip =
        'Add another receipt photo if the receipt continues';
    final continueIcon = Icons.check_rounded;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: uiConfig.controlsBackgroundColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: uiConfig.controlsBorderColor),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, compact ? 4 : 6, 8, compact ? 4 : 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ReceiptPhotoCountBadge(current: current, total: total),
                const SizedBox(width: 8),
                Icon(statusIcon, color: statusColor, size: compact ? 15 : 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    statusText,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFE8ECEE),
                      fontSize: compact ? 10.5 : 11,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 5 : 7),
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: retakeSemanticLabel,
                    child: Semantics(
                      button: true,
                      label: retakeSemanticLabel,
                      child: OutlinedButton.icon(
                        onPressed: savingPhotos ? null : onRetake,
                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                        label: Text(
                          retakeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: const Color(0xFFE8ECEE),
                          disabledForegroundColor: const Color(0xFF758188),
                          side: const BorderSide(color: Color(0xFF526168)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Tooltip(
                    message: addPhotoTooltip,
                    child: Semantics(
                      button: true,
                      label: addPhotoTooltip,
                      child: OutlinedButton.icon(
                        onPressed: savingPhotos ? null : onAddPhoto,
                        icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                        label: Text(
                          addPhotoLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          foregroundColor: const Color(0xFFE8ECEE),
                          disabledForegroundColor: const Color(0xFF758188),
                          side: const BorderSide(color: Color(0xFF526168)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Tooltip(
                    message: savingPhotos
                        ? 'Opening receipt details'
                        : continueLabel,
                    child: Semantics(
                      button: true,
                      label: savingPhotos
                          ? 'Opening receipt details'
                          : continueLabel,
                      child: FilledButton.icon(
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
                            : Icon(continueIcon),
                        label: savingPhotos
                            ? const Text(
                                'Opening',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : _ReceiptNextReviewLabel(
                                label: uiConfig.labelFor(
                                  'continue',
                                  continueLabel == 'Use Receipt'
                                      ? uiConfig.useReceiptLabel
                                      : continueLabel,
                                ),
                              ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          backgroundColor: uiConfig.primaryActionColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
      return 'Add the bottom section if the receipt continues. Use Receipt only when this is complete.';
    }
    if (coverageDecision.shouldPromptForMorePhotos) {
      return 'Add another photo if more receipt lines continue below this section.';
    }
    if (photoCount > 1 && continueLabel == 'Continue') {
      return 'Continue when these are the receipt sections you want to use.';
    }
    return 'Use Receipt opens the details review. Add Another is only for long receipts.';
  }
}

class _ReceiptPhotoCountBadge extends StatelessWidget {
  const _ReceiptPhotoCountBadge({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final label = total <= 1 ? 'Receipt Photo' : 'Section $current of $total';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111A1F),
        border: Border.all(color: const Color(0xFF43515A)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
