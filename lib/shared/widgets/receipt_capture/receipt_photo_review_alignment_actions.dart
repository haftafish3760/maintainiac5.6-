part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewAlignmentActions
    on _ReceiptPhotoReviewScreenState {
  Future<bool> _showLongReceiptAlignmentGuide(
    String photoPath, {
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
                _ReceiptAlignmentGuidePreview(photoPath: photoPath),
                const SizedBox(height: 10),
                _ReceiptAlignmentGuideNote(
                  missingBottomAndTotals:
                      coverageDecision.isMissingBottomEdgeAndTotals,
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
            ? 'Add Another Receipt Photo'
            : coverageDecision.shouldPromptForMorePhotos
            ? 'Add Another Receipt Photo'
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
      return 'Use the reference photo below, then open your phone camera and retake the top section. You will return here to review the order.';
    }
    if (reasonCode == 'retake_middle_with_previous_next_context') {
      return 'Use the reference photo below, then open your phone camera and retake this middle section. You will return here to review the order.';
    }
    if (reasonCode == 'retake_bottom_with_previous_context') {
      return 'Use the reference photo below, then open your phone camera and retake the bottom section. You will return here to review the order.';
    }
    if (coverageDecision.shouldPromptForMorePhotos) {
      return '${coverageDecision.completionDialogMessage} Use the reference photo below. Open your phone camera, then begin the next photo with 3-5 of the same readable lines. You will return here to review it.';
    }
    return 'Use the reference photo below. Open your phone camera, then begin the next photo with 3-5 of the same readable lines. You will return here to review it.';
  }

  String _alignmentGuideButtonLabel(
    ReceiptPhotoCoverageDecision coverageDecision, {
    required String reasonCode,
  }) {
    if (reasonCode.startsWith('retake_')) return 'Open Phone Camera to Retake';
    return 'Open Phone Camera';
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
