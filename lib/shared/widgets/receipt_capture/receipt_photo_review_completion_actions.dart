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
    _completionPromptedPhotoPaths.add(photoPath);
    _recordReceiptCompletionDecision(
      photoPath,
      decision: _ReceiptContinueDecision.continueAnyway,
      coverageDecision: decision,
    );
    return _ReceiptContinueDecision.continueAnyway;
  }

  String? get _completionCheckPhotoPath {
    if (_photoPaths.isEmpty) return null;
    if (_photoPaths.length == 1) {
      return _reviewMode == _ReceiptReviewMode.preview
          ? _photoPaths.first
          : null;
    }
    if (_needsStitchReviewBeforeSave &&
        _reviewMode != _ReceiptReviewMode.stitch) {
      return null;
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
