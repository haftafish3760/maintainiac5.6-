part of 'receipt_photo_review_screen.dart';

extension _ReceiptPhotoReviewCompletionActions
    on _ReceiptPhotoReviewScreenState {
  Future<_ReceiptContinueDecision> _confirmReceiptCompleteIfNeeded() async {
    if (!_reviewWorkActive) return _ReceiptContinueDecision.keepReviewing;
    if (widget.bestShotCandidateMode) {
      return _ReceiptContinueDecision.continueAnyway;
    }
    final photoPath = _completionCheckPhotoPath;
    if (photoPath == null) return _ReceiptContinueDecision.continueAnyway;
    if (_completionPromptedPhotoPaths.contains(photoPath)) {
      return _ReceiptContinueDecision.continueAnyway;
    }
    final decision = _coverageDecisionForPhoto(photoPath);
    if (!decision.shouldPromptForMorePhotos) {
      return _ReceiptContinueDecision.continueAnyway;
    }
    final userDecision = await showDialog<_ReceiptContinueDecision>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161D20),
        title: Text(
          decision.completionDialogTitle,
          style: const TextStyle(
            color: Color(0xFFE8ECEE),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          decision.completionDialogMessage,
          style: const TextStyle(
            color: Color(0xFFC8D0D3),
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(_ReceiptContinueDecision.keepReviewing),
            child: const Text('Keep Reviewing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(_ReceiptContinueDecision.addNextSection),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFD166),
            ),
            child: Text(decision.addSectionButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(_ReceiptContinueDecision.continueAnyway),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF28A745),
              foregroundColor: Colors.white,
            ),
            child: Text(decision.continueAnywayButtonLabel),
          ),
        ],
      ),
    );
    if (!_reviewWorkActive) return _ReceiptContinueDecision.keepReviewing;
    final confirmedDecision =
        userDecision ?? _ReceiptContinueDecision.keepReviewing;
    if (confirmedDecision == _ReceiptContinueDecision.continueAnyway) {
      // This suppresses only the second prompt between verified assembly and
      // saved-image review. It is set after an explicit choice, never merely
      // because the dialog was displayed or dismissed.
      _completionPromptedPhotoPaths.add(photoPath);
    }
    _recordReceiptCompletionDecision(
      photoPath,
      decision: confirmedDecision,
      coverageDecision: decision,
    );
    if (confirmedDecision == _ReceiptContinueDecision.addNextSection) {
      await addAnotherReceiptPhoto();
    }
    return confirmedDecision;
  }

  String? get _completionCheckPhotoPath {
    if (_photoPaths.isEmpty) return null;
    if (_photoPaths.length == 1) {
      return _reviewMode == _ReceiptReviewMode.preview
          ? _photoPaths.first
          : null;
    }
    return _photoPaths.last;
  }

  void _recordReceiptCompletionDecision(
    String photoPath, {
    required _ReceiptContinueDecision decision,
    required ReceiptPhotoCoverageDecision coverageDecision,
  }) {
    final decisionCode = switch (decision) {
      _ReceiptContinueDecision.continueAnyway => 'continue_anyway',
      _ReceiptContinueDecision.addNextSection => 'add_next_section',
      _ReceiptContinueDecision.keepReviewing => 'keep_reviewing',
    };
    final userConfirmedComplete =
        decision == _ReceiptContinueDecision.continueAnyway;
    _completionDecisionsByPath[photoPath] = {
      ReceiptCaptureDiagnosticKeys.receiptCompletionUserDecision: decisionCode,
      ReceiptCaptureDiagnosticKeys.receiptCompletionUserConfirmedComplete:
          userConfirmedComplete,
      ReceiptCaptureDiagnosticKeys.receiptCompletionPromptReasonCode:
          coverageDecision.reasonCode,
      ReceiptCaptureDiagnosticKeys.receiptCompletionPromptNeedsMorePhotos:
          coverageDecision.shouldPromptForMorePhotos,
      'receiptCompletionPromptStatus': coverageDecision.status.name,
      'receiptCompletionPromptMissingBottomAndTotals':
          coverageDecision.isMissingBottomEdgeAndTotals,
    };
    _captureDiagnosticsByPath[photoPath] = {
      ...?_captureDiagnosticsByPath[photoPath],
      ..._completionDecisionsByPath[photoPath]!,
    };
  }
}
