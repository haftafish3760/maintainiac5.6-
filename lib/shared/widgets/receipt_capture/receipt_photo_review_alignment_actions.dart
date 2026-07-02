part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewAlignmentActions
    on _ReceiptPhotoReviewScreenState {
  Future<bool> _showLongReceiptAlignmentGuide(
    String photoPath, {
    required ReceiptPhotoCoverageDecision coverageDecision,
  }) async {
    if (!_reviewWorkActive) return false;
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
                  coverageDecision.isMissingBottomEdgeAndTotals
                      ? 'Add Bottom Receipt Section'
                      : coverageDecision.shouldPromptForMorePhotos
                      ? 'Add Next Receipt Section'
                      : 'Line Up The Next Receipt Photo',
                  style: const TextStyle(
                    color: Color(0xFFE8ECEE),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  coverageDecision.shouldPromptForMorePhotos
                      ? '${coverageDecision.completionDialogMessage} Use the bottom of the last photo as the top ghost-slice guide and repeat 3-5 readable lines in the next photo.'
                      : 'Use the bottom of the last photo as the top ghost-slice guide. Start the next photo by repeating 3-5 readable receipt lines so Maintainiac can match the sections.',
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
                        label: Text(coverageDecision.addSectionButtonLabel),
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
}
