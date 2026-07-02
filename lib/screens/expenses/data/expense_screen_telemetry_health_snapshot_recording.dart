part of 'expense_screen_telemetry.dart';

extension _ExpenseTelemetryHealthSnapshotAccumulatorRecording
    on _ExpenseTelemetryHealthSnapshotAccumulator {
  void record(ExpenseTelemetryRecord record) {
    final payload = ExpenseTelemetryPolicy.sanitizeMap(record.payload);
    if (record.isPendingUpload) {
      pendingUploadCount += 1;
    } else {
      uploadedEventCount += 1;
    }
    final event = _stringValue(payload['event']);
    _increment(eventCounts, event);
    _increment(platformCounts, _stringValue(payload['platform']));
    _increment(deviceTierCounts, _stringValue(payload['deviceTier']));
    _increment(storageModeCounts, _stringValue(payload['storageMode']));
    _increment(planStatusCounts, _stringValue(payload['planStatus']));
    _increment(
      connectionStatusCounts,
      _stringValue(payload['connectionStatus']),
    );
    switch (event) {
      case 'screenOpened':
        screenOpenCount += 1;
      case 'timeSpentOnScreen':
        timeSpentEventCount += 1;
        totalTimeSpentMs += _intValue(payload['durationMs']);
      case 'addExpenseStarted':
        addExpenseStartedCount += 1;
      case 'addExpenseCompleted':
        addExpenseCompletedCount += 1;
      case 'addExpenseAbandoned':
        addExpenseAbandonedCount += 1;
      case 'validationError':
        validationErrorCount += 1;
      case 'saveFailure':
        saveFailureCount += 1;
      case 'imageAttachSuccess':
        imageAttachSuccessCount += 1;
      case 'imageAttachFailure':
        imageAttachFailureCount += 1;
      case 'ocrStarted':
        ocrStartedCount += 1;
        final startedMetadata = _metadataValue(payload['metadata']);
        receiptReadinessSummary.recordLocalFirstReadiness(startedMetadata);
        receiptReadinessSummary.recordInstallFootprint(startedMetadata);
        receiptReadinessSummary.recordLocalOnlyAcceptance(startedMetadata);
        receiptReadinessSummary.recordNativeLocalOnlyPolicy(startedMetadata);
        receiptReadinessSummary.recordRequiredBaseFootprint(startedMetadata);
        receiptReadinessSummary.recordOcrStoragePolicy(startedMetadata);
        cameraHealthSummary.record(startedMetadata);
        exposureQualitySummary.record(startedMetadata);
        nativePreCaptureExposureAbortCount += _intValue(
          startedMetadata['preCaptureExposureAbortTotal'],
        );
        _mergeCountMap(
          nativePreCaptureExposureAbortReasonCounts,
          _metadataValue(
            startedMetadata['preCaptureExposureAbortReasonBuckets'],
          ),
        );
        manualBrightnessChangeCount += _intValue(
          startedMetadata['manualBrightnessChangeTotal'],
        );
        nativeControlsSummary.record(startedMetadata);
        nativeCameraSummary.recordIdentity(startedMetadata);
        receiptCapturePlanSummary.recordStarted(startedMetadata);
        nativeCameraSummary.recordPolicyAndRecovery(startedMetadata);
        ocrSourceSummary.record(startedMetadata);
      case 'ocrCompleted':
        ocrCompletedCount += 1;
        final completedMetadata = _metadataValue(payload['metadata']);
        receiptReadinessSummary.recordLocalFirstReadiness(completedMetadata);
        receiptReadinessSummary.recordInstallFootprint(completedMetadata);
        receiptReadinessSummary.recordLocalOnlyAcceptance(completedMetadata);
        receiptReadinessSummary.recordNativeLocalOnlyPolicy(completedMetadata);
        receiptReadinessSummary.recordOcrStoragePolicy(completedMetadata);
        ocrSourceSummary.record(completedMetadata);
        clientProofSummary.record(completedMetadata);
      case 'ocrFailed':
        ocrFailedCount += 1;
        final failedMetadata = _metadataValue(payload['metadata']);
        ocrSourceSummary.record(failedMetadata);
        clientProofSummary.record(failedMetadata);
      case 'parserStarted':
        parserStartedCount += 1;
      case 'parserCompleted':
        parserCompletedCount += 1;
        final completedMetadata = _metadataValue(payload['metadata']);
        _mergeCountMap(
          parserCategoryCounts,
          _metadataValue(completedMetadata['parsedCategoryBuckets']),
        );
        _mergeCountMap(
          parserFieldConfidenceCounts,
          _metadataValue(completedMetadata['parserFieldConfidenceBuckets']),
        );
        _mergeCountMap(
          parserCategoryHealthCounts,
          _metadataValue(completedMetadata['parserCategoryHealthCounts']),
        );
        mergeParserPackPressure(completedMetadata);
        receiptReadinessSummary.recordParserLimits(completedMetadata);
        receiptReadinessSummary.recordLocalFirstReadiness(completedMetadata);
        receiptReadinessSummary.recordLocalOnlyAcceptance(completedMetadata);
        receiptReadinessSummary.recordNativeLocalOnlyPolicy(completedMetadata);
        receiptReadinessSummary.recordRequiredBaseFootprint(completedMetadata);
        receiptReadinessSummary.recordOcrStoragePolicy(completedMetadata);
        _mergeCountMap(
          parserRequiredFieldStatusCounts,
          _metadataValue(completedMetadata['parserRequiredFieldStatusCounts']),
        );
        _increment(
          parserDownstreamReadinessStatusCounts,
          _stringValue(completedMetadata['parserDownstreamReadinessStatus']),
        );
        _mergeCountMap(
          parserDownstreamReadinessCounts,
          _metadataValue(completedMetadata['parserDownstreamReadinessCounts']),
        );
        mergeParserReviewRootCause(completedMetadata);
        mergeLocalReceiptParserRouting(completedMetadata);
        mergeLocalParserEvidence(completedMetadata);
        _mergeCountMap(
          ocrParserTaskCounts,
          _metadataValue(completedMetadata['ocrParserTaskCounts']),
        );
        _mergeCountMap(
          ocrFieldReadinessCounts,
          _metadataValue(completedMetadata['ocrFieldReadinessCounts']),
        );
        ocrSourceSummary.record(completedMetadata);
        clientProofSummary.record(completedMetadata);
      case 'parserNeedsReview':
        parserNeedsReviewCount += 1;
        final reviewMetadata = _metadataValue(payload['metadata']);
        _mergeCountMap(
          parserCategoryCounts,
          _metadataValue(reviewMetadata['parsedCategoryBuckets']),
        );
        _mergeCountMap(
          parserNeedsReviewCategoryCounts,
          _metadataValue(reviewMetadata['reviewCategoryBuckets']),
        );
        _mergeCountMap(
          parserFieldConfidenceCounts,
          _metadataValue(reviewMetadata['parserFieldConfidenceBuckets']),
        );
        _mergeCountMap(
          parserCategoryHealthCounts,
          _metadataValue(reviewMetadata['parserCategoryHealthCounts']),
        );
        mergeParserPackPressure(reviewMetadata);
        receiptReadinessSummary.recordParserLimits(reviewMetadata);
        receiptReadinessSummary.recordLocalFirstReadiness(reviewMetadata);
        receiptReadinessSummary.recordInstallFootprint(reviewMetadata);
        receiptReadinessSummary.recordLocalOnlyAcceptance(reviewMetadata);
        receiptReadinessSummary.recordNativeLocalOnlyPolicy(reviewMetadata);
        receiptReadinessSummary.recordRequiredBaseFootprint(reviewMetadata);
        receiptReadinessSummary.recordOcrStoragePolicy(reviewMetadata);
        _mergeCountMap(
          parserRequiredFieldStatusCounts,
          _metadataValue(reviewMetadata['parserRequiredFieldStatusCounts']),
        );
        _increment(
          parserDownstreamReadinessStatusCounts,
          _stringValue(reviewMetadata['parserDownstreamReadinessStatus']),
        );
        _mergeCountMap(
          parserDownstreamReadinessCounts,
          _metadataValue(reviewMetadata['parserDownstreamReadinessCounts']),
        );
        mergeParserReviewRootCause(reviewMetadata);
        mergeLocalReceiptParserRouting(reviewMetadata);
        mergeLocalParserEvidence(reviewMetadata);
        _mergeCountMap(
          ocrParserTaskCounts,
          _metadataValue(reviewMetadata['ocrParserTaskCounts']),
        );
        _mergeCountMap(
          ocrFieldReadinessCounts,
          _metadataValue(reviewMetadata['ocrFieldReadinessCounts']),
        );
        ocrSourceSummary.record(reviewMetadata);
        clientProofSummary.record(reviewMetadata);
      case 'parserFailed':
        parserFailedCount += 1;
        final failedMetadata = _metadataValue(payload['metadata']);
        _mergeCountMap(
          parserFailedCategoryCounts,
          _metadataValue(failedMetadata['parsedCategoryBuckets']),
        );
        _mergeCountMap(
          parserCategoryHealthCounts,
          _metadataValue(failedMetadata['parserCategoryHealthCounts']),
        );
        mergeParserPackPressure(failedMetadata);
        receiptReadinessSummary.recordParserLimits(failedMetadata);
        receiptReadinessSummary.recordLocalFirstReadiness(failedMetadata);
        receiptReadinessSummary.recordInstallFootprint(failedMetadata);
        receiptReadinessSummary.recordLocalOnlyAcceptance(failedMetadata);
        receiptReadinessSummary.recordNativeLocalOnlyPolicy(failedMetadata);
        receiptReadinessSummary.recordRequiredBaseFootprint(failedMetadata);
        receiptReadinessSummary.recordOcrStoragePolicy(failedMetadata);
        _mergeCountMap(
          parserRequiredFieldStatusCounts,
          _metadataValue(failedMetadata['parserRequiredFieldStatusCounts']),
        );
        _increment(
          parserDownstreamReadinessStatusCounts,
          _stringValue(failedMetadata['parserDownstreamReadinessStatus']),
        );
        _mergeCountMap(
          parserDownstreamReadinessCounts,
          _metadataValue(failedMetadata['parserDownstreamReadinessCounts']),
        );
        mergeParserReviewRootCause(failedMetadata);
        mergeLocalReceiptParserRouting(failedMetadata);
        mergeLocalParserEvidence(failedMetadata);
        _mergeCountMap(
          ocrParserTaskCounts,
          _metadataValue(failedMetadata['ocrParserTaskCounts']),
        );
        _mergeCountMap(
          ocrFieldReadinessCounts,
          _metadataValue(failedMetadata['ocrFieldReadinessCounts']),
        );
        ocrSourceSummary.record(failedMetadata);
        clientProofSummary.record(failedMetadata);
      case 'ocrCorrectionOpened':
        ocrCorrectionOpenedCount += 1;
      case 'appFilledReceiptLineConfirmed':
        appFilledReceiptLineConfirmedCount += 1;
      case 'appFilledReceiptLineCorrected':
        appFilledReceiptLineCorrectedCount += 1;
        userCorrectionCount += 1;
      case 'userCorrectedVendor':
      case 'userCorrectedDate':
      case 'userCorrectedTax':
      case 'userCorrectedTotal':
      case 'userCorrectedCategory':
        userCorrectionCount += 1;
      case 'cloudBackupSuccess':
        cloudBackupSuccessCount += 1;
      case 'cloudBackupFailure':
        cloudBackupFailureCount += 1;
      case 'syncPending':
        syncPendingCount += 1;
        final metadata = _metadataValue(payload['metadata']);
        expenseSummarySync.recordPendingSync(metadata);
      case 'synced':
        syncedCount += 1;
      case 'syncFailed':
        syncFailedCount += 1;
      case 'exportStarted':
        exportStartedCount += 1;
      case 'exportCompleted':
        exportCompletedCount += 1;
      case 'exportBlocked':
        exportBlockedCount += 1;
      case 'exportFailed':
        exportFailedCount += 1;
    }
    _recordFailureDiagnostic(failureStats, payload);
    final failureDetail = _failureDetailFor(record, payload);
    if (failureDetail != null) recentFailures.add(failureDetail);
  }
}
