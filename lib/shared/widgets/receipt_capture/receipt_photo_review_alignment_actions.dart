part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewAlignmentActions
    on _ReceiptPhotoReviewScreenState {
  Future<bool> _showLongReceiptAlignmentGuide(
    String? previousSectionGuidePhotoPath, {
    String? nextSectionGuidePhotoPath,
    required ReceiptPhotoCoverageDecision coverageDecision,
    String? alignmentReasonCode,
    String? alignmentGuidance,
  }) async {
    if (!_reviewWorkActive) return false;
    final reasonCode = _normalizeAlignmentReasonCode(alignmentReasonCode);
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1F2528),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _alignmentGuideTitle(
                    coverageDecision,
                    reasonCode: reasonCode,
                  ),
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _alignmentGuideMessage(
                    coverageDecision,
                    reasonCode: reasonCode,
                    alignmentGuidance: alignmentGuidance,
                  ),
                  style: const TextStyle(
                    color: Color(0xFFC7D0D4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 12),
                if (previousSectionGuidePhotoPath != null)
                  _ReceiptAlignmentGuidePreview(
                    photoPath: previousSectionGuidePhotoPath,
                    label: 'Reference: bottom of previous photo',
                    alignment: Alignment.bottomCenter,
                    height: nextSectionGuidePhotoPath == null ? 208 : 132,
                  ),
                if (nextSectionGuidePhotoPath != null) ...[
                  const SizedBox(height: 8),
                  _ReceiptAlignmentGuidePreview(
                    photoPath: nextSectionGuidePhotoPath,
                    label: 'Reference: top of next photo',
                    alignment: Alignment.topCenter,
                    height: 132,
                  ),
                ],
                const SizedBox(height: 10),
                _ReceiptAlignmentGuideNote(
                  hasPreviousReference: previousSectionGuidePhotoPath != null,
                  hasNextReference: nextSectionGuidePhotoPath != null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          _alignmentGuideButtonLabel(
                            coverageDecision,
                            reasonCode: reasonCode,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  String _alignmentGuideTitle(
    ReceiptPhotoCoverageDecision coverageDecision, {
    required String reasonCode,
  }) {
    return switch (reasonCode) {
      'retake_top_with_next_context' => 'Retake Top Receipt Section',
      'retake_middle_with_previous_next_context' =>
        'Retake Middle Receipt Section',
      'retake_bottom_with_previous_context' => 'Retake Bottom Receipt Section',
      _ =>
        coverageDecision.isMissingBottomEdgeAndTotals
            ? 'Add Bottom Receipt Section'
            : coverageDecision.shouldPromptForMorePhotos
            ? 'Add Next Receipt Section'
            : 'Line Up The Next Receipt Photo',
    };
  }

  String _alignmentGuideMessage(
    ReceiptPhotoCoverageDecision coverageDecision, {
    required String reasonCode,
    String? alignmentGuidance,
  }) {
    final guidance = alignmentGuidance?.trim();
    if (guidance != null && guidance.isNotEmpty) return guidance;
    if (reasonCode == 'retake_top_with_next_context') {
      return 'Use the next receipt section as context, retake the top section, then confirm the join in photo review.';
    }
    if (reasonCode == 'retake_middle_with_previous_next_context') {
      return 'Use the previous and next receipt sections as context, then retake this middle section without changing its order.';
    }
    if (reasonCode == 'retake_bottom_with_previous_context') {
      return 'Use the previous receipt section as the top reference, then retake the bottom section in the same slot.';
    }
    if (coverageDecision.shouldPromptForMorePhotos) {
      return '${coverageDecision.completionDialogMessage} The camera will show the bottom of the last photo at the top. Start the next photo with the same 3-5 readable lines.';
    }
    return 'The camera will show the bottom of the last photo at the top. Start the next photo with the same 3-5 readable receipt lines so Maintainiac can join the sections.';
  }

  String _alignmentGuideButtonLabel(
    ReceiptPhotoCoverageDecision coverageDecision, {
    required String reasonCode,
  }) {
    if (reasonCode.startsWith('retake_')) return 'Retake Section';
    return coverageDecision.addSectionButtonLabel;
  }
}

String _normalizeAlignmentReasonCode(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return '';
  return trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
