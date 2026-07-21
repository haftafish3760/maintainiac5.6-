// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

/// GPS-assisted calibration and review orchestration. Confirmed mileage stays
/// with the independent global odometer controller.
extension TripTrackingControllerOdometerReview on TripTrackingController {
  TripOdometerEndReviewDecision? evaluateOdometerEndReview({
    required String reviewId,
    required int endingOdometer,
    bool anomalyAlertsEnabled = true,
    bool calibrationAssistEnabled = false,
    bool userAcknowledgedReviewPrompt = false,
    bool userAcknowledgedUsageAnomaly = false,
    DateTime? nowUtc,
  }) {
    final review = _sessionStore.reviewForTrip(reviewId);
    if (review == null || review.isOdometerConfirmed) return null;
    final now = (nowUtc ?? _clockNow()).toUtc();
    final entry = TripOdometerEntryValidation.validate(
      startingOdometer: review.startingOdometer,
      endingOdometer: endingOdometer,
      previousConfirmedEndingOdometer: _previousConfirmedReviewFor(
        review,
      )?.confirmedEndingOdometer,
      gpsAssistedDistanceMeters: review.engineSnapshot.totalAcceptedMeters,
    );
    final reconciliation = TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: endingOdometer,
    );
    final usage = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: (endingOdometer - review.startingOdometer)
          .clamp(0, 999999)
          .toDouble(),
      history: _sessionStore.pendingReviews,
      vehicleId: review.vehicleId,
      nowUtc: now,
      anomalyAlertsEnabled: anomalyAlertsEnabled,
    );
    final calibrationPrompt = TripOdometerCalibrationPromptPolicy.evaluate(
      signal: odometerCalibrationSignal(
        vehicleId: review.vehicleId,
        nowUtc: now,
      ),
      userEnabledCalibrationAssist: calibrationAssistEnabled,
      userDismissedPrompt: false,
      snoozedUntilUtc: null,
      nowUtc: now,
    );
    return TripOdometerEndReviewPolicy.evaluate(
      entryValidation: entry,
      reconciliation: reconciliation,
      calibrationPrompt: calibrationPrompt,
      usageAnomaly: usage,
      userAcknowledgedReviewPrompt: userAcknowledgedReviewPrompt,
      userAcknowledgedUsageAnomaly: userAcknowledgedUsageAnomaly,
    );
  }

  void refreshGpsAssistanceCalibration({required bool enabled}) {
    final signal = odometerCalibrationSignal();
    final guard = _calibrationApplyGuard(
      signal: signal,
      userOptedIn: enabled,
      userAcceptedLatestReview: calibrationReviewAcceptedForCurrentEvidence,
    );
    final next = _calibrationState.refresh(
      enabled: enabled,
      signal: signal,
      canApplyToFutureGpsProjection: guard.canApplyToFutureGpsProjection,
    );
    if (identical(next, _calibrationState)) return;
    _calibrationState = next;
    notifyListeners();
  }

  /// Records an explicit, in-session acceptance for the exact reviewed local
  /// evidence currently shown to the driver. A later confirmed review, a
  /// vehicle change, or a process restart fails neutral and requires a fresh
  /// acceptance before GPS projections can be scaled.
  bool acceptGpsAssistanceCalibrationReview() {
    final signal = odometerCalibrationSignal();
    final guard = _calibrationApplyGuard(
      signal: signal,
      userOptedIn: true,
      userAcceptedLatestReview: true,
    );
    if (!guard.canApplyToFutureGpsProjection) return false;
    _acceptedCalibrationEvidenceSignature = _calibrationEvidenceSignature(
      signal,
    );
    refreshGpsAssistanceCalibration(enabled: true);
    return _calibrationState.multiplier != 1;
  }

  TripTrackingCalibrationApplyGuard _calibrationApplyGuard({
    required TripOdometerCalibrationSignal signal,
    required bool userOptedIn,
    required bool userAcceptedLatestReview,
  }) => TripTrackingCalibrationApplyGuard.evaluate(
    signal: signal,
    userOptedIn: userOptedIn,
    userAcceptedLatestReview: userAcceptedLatestReview,
    minimumReviewedDays: 7,
    latestReviewedAtUtc: _latestConfirmedOdometerReviewAt(),
    nowUtc: _clockNow(),
    activeVehicleId: _odometer.vehicleId,
    reviewedVehicleId: _odometer.vehicleId,
    reviewedVehicleIds: [_odometer.vehicleId],
  );

  DateTime? _latestConfirmedOdometerReviewAt() {
    DateTime? latest;
    final latestAllowed = _clockNow().toUtc().add(
      _policy.maximumFutureSampleSkew,
    );
    for (final review in _sessionStore.pendingReviews) {
      final confirmedAt = review.odometerConfirmedAt;
      if (review.vehicleId != _odometer.vehicleId || confirmedAt == null) {
        continue;
      }
      if (confirmedAt.toUtc().isAfter(latestAllowed) ||
          review.finishedAt.toUtc().isAfter(latestAllowed)) {
        continue;
      }
      if (latest == null || confirmedAt.isAfter(latest)) latest = confirmedAt;
    }
    return latest;
  }

  String _calibrationEvidenceSignature([
    TripOdometerCalibrationSignal? suppliedSignal,
  ]) {
    final signal = suppliedSignal ?? odometerCalibrationSignal();
    final latest =
        _latestConfirmedOdometerReviewAt()?.toUtc().millisecondsSinceEpoch ??
        -1;
    final ratio = signal.averageGpsToOdometerRatio;
    final stableRatio = ratio.isFinite ? ratio.toStringAsFixed(8) : 'invalid';
    return '${_odometer.vehicleId}|${signal.status.name}|${signal.eligibleSampleCount}|$stableRatio|$latest';
  }

  TripOdometerUsageAnomalySignal odometerUsageAnomalySignal({
    required double currentOdometerMiles,
    String? vehicleId,
    DateTime? nowUtc,
  }) => TripOdometerUsageAnomalySignal.evaluate(
    currentOdometerMiles: currentOdometerMiles,
    history: _sessionStore.pendingReviews,
    vehicleId: vehicleId ?? _odometer.vehicleId,
    nowUtc: nowUtc,
  );

  TripOdometerUsageAnomalySignal odometerUsageAnomalySignalForCurrentDay({
    int? startingOdometer,
    DateTime? nowUtc,
  }) {
    final baseline =
        startingOdometer ??
        _session?.startingOdometer ??
        _odometer.confirmedReading;
    final miles = (_odometer.reading - baseline).clamp(0, 999999).toDouble();
    final referenceTime = (nowUtc ?? _clockNow()).toUtc();
    // A recurring route is best compared with the same weekday. Three
    // confirmed occurrences are enough to provide a useful early warning;
    // until then, fall back to the broader seven-day baseline instead of
    // hiding a genuinely unusual odometer entry for a new user.
    final weekdaySignal = TripOdometerUsageAnomalySignal.evaluate(
      currentOdometerMiles: miles,
      history: _sessionStore.pendingReviews,
      vehicleId: _odometer.vehicleId,
      nowUtc: referenceTime,
      weekday: referenceTime.weekday,
      minimumReviewedDays: 3,
    );
    if (weekdaySignal.status !=
        TripOdometerUsageAnomalyStatus.insufficientHistory) {
      return weekdaySignal;
    }
    return odometerUsageAnomalySignal(
      currentOdometerMiles: miles,
      nowUtc: referenceTime,
    );
  }

  Future<bool> confirmOdometerReview({
    required String reviewId,
    required int confirmedEndingOdometer,
    DateTime? confirmedAt,
    bool userAcknowledgedReviewPrompt = false,
  }) => _runExclusiveSessionOperation(
    false,
    () => _confirmOdometerReview(
      reviewId: reviewId,
      confirmedEndingOdometer: confirmedEndingOdometer,
      confirmedAt: confirmedAt,
      userAcknowledgedReviewPrompt: userAcknowledgedReviewPrompt,
    ),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip is already starting or ending. Please wait for it to finish.',
  );

  Future<bool> _confirmOdometerReview({
    required String reviewId,
    required int confirmedEndingOdometer,
    DateTime? confirmedAt,
    required bool userAcknowledgedReviewPrompt,
  }) async {
    final review = _sessionStore.reviewForTrip(reviewId);
    if (review == null ||
        !review.hasValidTimeline ||
        review.id.trim().isEmpty ||
        review.vehicleId.trim().isEmpty ||
        review.isOdometerConfirmed ||
        review.vehicleId != _odometer.vehicleId ||
        review.estimatedEndingOdometer < review.startingOdometer ||
        confirmedEndingOdometer < review.startingOdometer) {
      return false;
    }
    final confirmationTime = confirmedAt ?? _clockNow();
    if (confirmationTime.isBefore(review.finishedAt)) return false;
    if (confirmationTime.toUtc().isAfter(
      _clockNow().toUtc().add(_policy.maximumFutureSampleSkew),
    )) {
      _platformStatus = 'odometer_confirmation_time_invalid';
      _platformError =
          'Trip odometer confirmation time cannot be in the future.';
      notifyListeners();
      return false;
    }
    final continuity = _continuityAgainstPreviousConfirmedReview(review);
    if (continuity.shouldBlockConfirmation) {
      _platformStatus = 'odometer_continuity_invalid';
      _platformError =
          'This trip starts below the previous confirmed odometer for this vehicle. Review the starting and ending odometer readings before confirming.';
      notifyListeners();
      return false;
    }
    final entryValidation = TripOdometerEntryValidation.validate(
      startingOdometer: review.startingOdometer,
      endingOdometer: confirmedEndingOdometer,
      previousConfirmedEndingOdometer: _previousConfirmedReviewFor(
        review,
      )?.confirmedEndingOdometer,
      gpsAssistedDistanceMeters: review.engineSnapshot.totalAcceptedMeters,
    );
    if (entryValidation.shouldBlockConfirmation) {
      _platformStatus = 'odometer_entry_invalid';
      _platformError =
          'Review the starting and ending odometer readings before confirming this trip.';
      notifyListeners();
      return false;
    }
    final reconciliation = TripOdometerReconciliation.compare(
      review: review,
      confirmedEndingOdometer: confirmedEndingOdometer,
    );
    if ((entryValidation.shouldPromptUser || reconciliation.shouldPromptUser) &&
        !userAcknowledgedReviewPrompt) {
      _platformStatus = 'odometer_review_acknowledgement_required';
      _platformError =
          'Review the GPS-assisted comparison, then explicitly confirm the physical odometer value.';
      notifyListeners();
      return false;
    }
    final odometerMileageReview = const OdometerMileageReview(
      use: OdometerMileageUse.unresolved,
    );
    final odometerPreflight = _odometer.updateFromText(
      confirmedEndingOdometer.toString(),
      enteredAt: confirmationTime,
      confirmSuspicious: true,
      commit: false,
      mileageReview: odometerMileageReview,
      sourceType: 'gps_trip_review',
      sourceId: review.id,
    );
    if (!odometerPreflight.ok) return false;

    final confirmedReview = review.copyWith(
      confirmedEndingOdometer: confirmedEndingOdometer,
      odometerConfirmedAt: confirmationTime,
    );
    final odometerCommit = _odometer.updateFromText(
      confirmedEndingOdometer.toString(),
      enteredAt: confirmationTime,
      confirmSuspicious: true,
      mileageReview: odometerPreflight.mileageReview ?? odometerMileageReview,
      sourceType: 'gps_trip_review',
      sourceId: review.id,
    );
    if (!odometerCommit.ok) return false;
    try {
      await _sessionStore.saveReview(confirmedReview);
    } catch (error) {
      // The odometer event is already source-idempotent, so a later retry can
      // safely mark the review confirmed without duplicating mileage history.
      _platformStatus = 'review_confirmation_save_failed';
      _platformError =
          'Could not save the confirmed trip review locally. Retry review confirmation.';
      notifyListeners();
      return false;
    }
    if (_platformStatus == 'review_confirmation_save_failed') {
      _platformStatus = null;
      _platformError = null;
    }
    await _saveDurableReviewedTrip(confirmedReview);
    _acceptedCalibrationEvidenceSignature = null;
    _calibrationState = _calibrationState.refreshEnabled(
      signal: odometerCalibrationSignal(),
      canApplyToFutureGpsProjection: false,
    );
    if (reconciliation.status ==
        TripOdometerReconciliationStatus.reviewRecommended) {
      _platformStatus = 'odometer_reconciliation_review';
      _platformError =
          'GPS and odometer mileage differ enough to review. The physical odometer remains the official mileage.';
    } else if (entryValidation.shouldPromptUser) {
      _platformStatus = 'odometer_entry_review';
      _platformError =
          'This odometer entry looks unusual compared with recent confirmed mileage. The physical odometer remains the official mileage.';
    } else if (_platformStatus == 'odometer_reconciliation_review') {
      _platformStatus = null;
      _platformError = null;
    } else if (_platformStatus == 'odometer_entry_review') {
      _platformStatus = null;
      _platformError = null;
    }
    try {
      await _cloudMirror.queueReview(confirmedReview);
      unawaited(_flushCloudMirror());
      _cloudMirrorError = null;
    } catch (error) {
      // Physical confirmation is durable locally even when a cloud queue is
      // unavailable. The user can retry backup without reopening the trip.
      _cloudMirrorError = 'Cloud mileage backup is pending.';
    }
    notifyListeners();
    return true;
  }

  TripOdometerContinuityCheck _continuityAgainstPreviousConfirmedReview(
    TripTrackingReviewRecord review,
  ) {
    final previous = _previousConfirmedReviewFor(review);
    if (previous == null) {
      return const TripOdometerContinuityCheck(
        status: TripOdometerContinuityStatus.insufficientData,
        odometerGapMiles: 0,
        reasonCode: 'missing_same_vehicle_confirmed_history',
      );
    }
    return TripOdometerContinuityCheck.betweenReviews(
      previous: previous,
      next: review,
    );
  }

  TripTrackingReviewRecord? _previousConfirmedReviewFor(
    TripTrackingReviewRecord review,
  ) => _sessionStore.pendingReviews
      .where(
        (candidate) =>
            candidate.id != review.id &&
            candidate.vehicleId == review.vehicleId &&
            candidate.isOdometerConfirmed &&
            candidate.finishedAt.isBefore(review.startedAt),
      )
      .firstOrNull;

  /// Retries locally durable mileage backups without touching the active trip
  /// or confirmed odometer. A successful retry clears any stale dashboard
  /// warning; failures remain visible and retryable.
}
