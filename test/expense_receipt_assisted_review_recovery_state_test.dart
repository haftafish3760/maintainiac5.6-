import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test('assisted receipt review exposes recovery and no-line state', () async {
    final source = await readAssistedReviewSourceFixture();
    final entryScreen = source.entryScreen;
    final stateActions = source.stateActions;
    final attachmentPanel = source.attachmentPanel;
    final parseReview = source.parseReview;
    expect(entryScreen, contains('nativeRecoveryLastStage'));
    expect(entryScreen, contains('nativeRecoveryResumeStatusBuckets'));
    expect(entryScreen, contains('nativeRecoveryRecoveredPhotoTotal'));
    expect(entryScreen, contains('nativeRecoveryMultipleSectionCount'));
    expect(entryScreen, contains('nativeRecoveryOcrPending'));
    expect(
      entryScreen,
      contains('ExpenseTelemetryEventType.imageAttachFailure'),
    );
    expect(entryScreen, contains('nativeCaptureFailureReason'));
    expect(entryScreen, contains('bool get _hasAppAssistedReceiptReview'));
    expect(entryScreen, contains('_receiptReviewFlowStarted'));
    expect(entryScreen, contains('return _receiptReviewFlowStarted ||'));
    expect(entryScreen, contains('_rawReceiptText.trim().isNotEmpty'));
    expect(entryScreen, contains('_receiptReadAttemptedWithoutText'));
    expect(entryScreen, contains('_lastOcrDiagnostics != null'));
    expect(entryScreen, contains('_lastParseDiagnostics'));
    expect(entryScreen, contains('parseDiagnostics: _lastParseDiagnostics'));
    expect(entryScreen, contains('if (_hasAppAssistedReceiptReview)'));
    expect(
      entryScreen,
      contains('bool get _shouldShowReceiptReadHandoffPanel'),
    );
    expect(entryScreen, contains('if (_shouldShowReceiptReadHandoffPanel)'));
    expect(
      entryScreen,
      isNot(
        contains(
          'if (_scanningReceiptPhotos) ...[\n                    _ReceiptReadHandoffPanel',
        ),
      ),
    );
    expect(
      entryScreen,
      contains('final _receiptReadHandoffKey = GlobalKey();'),
    );
    expect(entryScreen, contains('key: _receiptReadHandoffKey'));
    expect(
      entryScreen,
      contains('void _scrollToReceiptReview({int attempt = 0})'),
    );
    expect(
      entryScreen,
      isNot(contains('void _scrollToReceiptReadHandoff({int attempt = 0})')),
    );
    expect(
      entryScreen,
      contains(
        'void _scrollToReceiptFlowKey(GlobalKey key, {int attempt = 0})',
      ),
    );
    expect(
      entryScreen,
      contains(
        'if (mounted) _scrollToReceiptFlowKey(key, attempt: attempt + 1);',
      ),
    );
    expect(entryScreen, contains('if (didRead)'));
    expect(entryScreen, contains('_receiptReviewFlowStarted = true;'));
    expect(entryScreen, contains('_scrollToReceiptReview();'));
    final acceptedPhotoHandler = entryScreen.substring(
      entryScreen.indexOf(
        'void _markReceiptPhotoReviewAccepted(ReceiptPhotoReviewResult result)',
      ),
      entryScreen.indexOf('void _recordReceiptPhotoPreparationTelemetry'),
    );
    expect(acceptedPhotoHandler, contains('_receiptReviewFlowStarted = true;'));
    expect(acceptedPhotoHandler, contains('_scheduleDraftSave();'));
    expect(
      acceptedPhotoHandler.indexOf('_scheduleDraftSave();'),
      lessThan(
        acceptedPhotoHandler.indexOf(
          '_recordReceiptPhotoPreparationTelemetry(result);',
        ),
      ),
    );
    expect(
      acceptedPhotoHandler.indexOf(
        '_recordReceiptPhotoPreparationTelemetry(result);',
      ),
      lessThan(acceptedPhotoHandler.indexOf('_scrollToReceiptCapture();')),
    );
    expect(acceptedPhotoHandler, isNot(contains('_scrollToReceiptReview();')));
    expect(
      acceptedPhotoHandler,
      isNot(contains('_scrollToReceiptFlowKey(_receiptReviewKey')),
    );
    expect(
      entryScreen,
      contains('_scrollToReceiptFlowKey(_receiptReadHandoffKey'),
    );
    expect(
      acceptedPhotoHandler,
      isNot(contains('_receiptReviewFlowStarted = false')),
    );
    expect(
      acceptedPhotoHandler,
      contains(
        "_receiptReadHandoffStage = 'Opening receipt details from accepted photo';",
      ),
    );
    expect(
      entryScreen,
      contains("'Opening receipt details from accepted photo'"),
    );
    expect(
      entryScreen,
      contains('String get _receiptParsedDetailsRouteResultLabel'),
    );
    expect(
      entryScreen,
      contains("'Receipt details review opened with parsed receipt fields'"),
    );
    expect(
      entryScreen,
      contains('String get _receiptManualDetailsRouteResultLabel'),
    );
    expect(
      entryScreen,
      contains(
        "'Receipt details review opened for manual receipt line review'",
      ),
    );
    expect(
      entryScreen,
      contains('String get _receiptTotalsOnlyDetailsRouteResultLabel'),
    );
    expect(
      entryScreen,
      contains(
        "'Receipt details review opened with parsed totals and no safe item lines'",
      ),
    );
    expect(
      entryScreen,
      contains('String get _receiptUnreadableDetailsRouteResultLabel'),
    );
    expect(
      entryScreen,
      contains(
        "'Receipt details review opened with saved proof and no readable text'",
      ),
    );
    expect(
      stateActions,
      contains(
        "_receiptReadHandoffStage =\n          'Reading receipt proof before filling receipt details';",
      ),
    );
    expect(
      stateActions,
      contains("'Filling receipt details from accepted proof'"),
    );
    expect(
      stateActions,
      contains('_receiptDetailsRouteResultForParsedReceipt(parsed)'),
    );
    expect(entryScreen, contains('localReceiptParserRoutingSummaryLabel'));
    expect(
      entryScreen,
      contains(
        "return '\$_receiptParsedDetailsRouteResultLabel: \$routeSummary';",
      ),
    );
    expect(
      entryScreen,
      contains(
        "return '\$_receiptTotalsOnlyDetailsRouteResultLabel: \$routeSummary';",
      ),
    );
    expect(
      entryScreen,
      contains(
        "return '\$_receiptManualDetailsRouteResultLabel: \$routeSummary';",
      ),
    );
    final importAcceptedFlow = attachmentPanel.substring(
      attachmentPanel.indexOf('Future<bool> _acceptReviewedPhotoResult'),
      attachmentPanel.indexOf('Future<void> reviewReceiptPhotos'),
    );
    expect(
      importAcceptedFlow.indexOf(
        'widget.onReceiptPhotoReviewAccepted?.call(result);',
      ),
      lessThan(
        importAcceptedFlow.indexOf('_pauseReviewedPhotoReadUntilNextSection'),
      ),
    );
    expect(
      importAcceptedFlow.indexOf('_pauseReviewedPhotoReadUntilNextSection'),
      lessThan(
        importAcceptedFlow.indexOf('_startReviewedPhotoReadStatus(result);'),
      ),
    );
    expect(
      importAcceptedFlow.indexOf('_startReviewedPhotoReadStatus(result);'),
      lessThan(
        importAcceptedFlow.indexOf('_readReviewedPhotosForReceiptForm(result)'),
      ),
    );
    final reviewedPhotoReadStatusBlock = attachmentPanel.substring(
      attachmentPanel.indexOf(
        'void _startReviewedPhotoReadStatus(ReceiptPhotoReviewResult result)',
      ),
      attachmentPanel.indexOf('String _reviewedPhotoOcrSourceQualitySummary('),
    );
    expect(
      reviewedPhotoReadStatusBlock,
      contains('widget.onReceiptReadStarted?.call();'),
    );
    expect(
      reviewedPhotoReadStatusBlock.indexOf(
        'widget.onReceiptReadStarted?.call();',
      ),
      lessThan(
        reviewedPhotoReadStatusBlock.indexOf('_readingForReview = true'),
      ),
    );
    expect(
      entryScreen,
      contains('Maintainiac could not find usable receipt text in that photo.'),
    );
    expect(entryScreen, contains('Opening Receipt Details'));
    expect(
      entryScreen,
      contains(
        'Maintainiac is checking the accepted photo now. Keep this screen open; receipt details will appear here when OCR and parsing finish.',
      ),
    );
    final handoffLayout = entryScreen.substring(
      entryScreen.indexOf('key: _receiptReadHandoffKey'),
      entryScreen.indexOf('if (_hasAppAssistedReceiptReview)'),
    );
    expect(
      handoffLayout.indexOf('_ReceiptReadHandoffPanel('),
      lessThan(handoffLayout.indexOf('if (showAttachmentBeforeReview)')),
    );
    expect(handoffLayout, isNot(contains('SharedReceiptAttachmentPanel(')));
    expect(
      entryScreen,
      isNot(contains('if (!showAttachmentBeforeReview) ...[')),
    );
    expect(parseReview, contains('Add or retake receipt photos'));
    expect(parseReview, contains('Use this only if a section is missing'));
    expect(parseReview, contains('manualReviewOnly'));
    expect(parseReview, contains('Manual receipt review stays below.'));
    expect(parseReview, contains("'Open Manual Review'"));
    expect(parseReview, contains("'Back To Review'"));
    expect(entryScreen, contains("return 'Checking photo';"));
    expect(
      entryScreen,
      contains(
        'Keep this screen open. Receipt details appear here as soon as the store, date, total, and item prices are ready.',
      ),
    );
    expect(entryScreen, contains('_receiptReadAttemptedWithoutText = true;'));
    expect(
      entryScreen.indexOf(
        '_updateReceiptState(() => _scanningReceiptPhotos = false);',
      ),
      lessThan(entryScreen.indexOf('_scrollToReceiptReview();')),
    );
    expect(entryScreen, contains('void _markReceiptReadStarted()'));
    expect(
      entryScreen,
      contains('void _markReceiptReadFinished(bool didRead)'),
    );
    expect(entryScreen, contains('String get _receiptReviewReadyStageLabel'));
    expect(
      entryScreen,
      contains(r'Receipt details ready: $lineLabel $reviewLabel'),
    );
    expect(entryScreen, contains('_lastReceiptParseCompleted'));
    expect(entryScreen, contains('_lastReceiptParseHadUsableData'));
    expect(entryScreen, contains('_lastReceiptParseHadSafeLines'));
    expect(entryScreen, contains('final parseCompleted ='));
    expect(entryScreen, contains('final parseHasUsableDetails ='));
    expect(entryScreen, contains('final parseHasSafeLines ='));
    expect(
      entryScreen,
      contains("_receiptReadHandoffDecision = 'Preparing receipt details'"),
    );
    expect(
      entryScreen,
      contains(
        "_receiptReadHandoffStage = 'Receipt details still being filled'",
      ),
    );
    expect(
      entryScreen,
      contains("_receiptReadHandoffDecision = 'Open manual receipt details'"),
    );
    expect(
      entryScreen,
      contains(
        "_receiptReadHandoffStage = 'Receipt details need manual entry'",
      ),
    );
    expect(
      entryScreen,
      contains('bool get _receiptRecoveryNeedsManualReviewOnly'),
    );
    expect(
      entryScreen,
      contains('manualReviewOnly: _receiptRecoveryNeedsManualReviewOnly'),
    );
    expect(entryScreen, contains('Review parsed store, date, tax, and totals'));
    expect(stateActions, contains('_lastReceiptParseCompleted = false;'));
    expect(stateActions, contains('_lastReceiptParseHadUsableData = true;'));
    expect(
      stateActions,
      contains('_lastReceiptParseHadSafeLines = parsed.lines.isNotEmpty;'),
    );
    expect(stateActions, contains('_lastReceiptParseHadUsableData = false;'));
    expect(
      entryScreen,
      contains('Receipt details ready: check fields and add lines if needed'),
    );
    expect(
      stateActions,
      contains('_receiptReadHandoffStage = _receiptStageLabelForParsedReceipt'),
    );
    expect(entryScreen, contains('_ReceiptAppAssistedReviewIntroPanel'));
  });
}
