import 'trip_stop_classification.dart';
import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';

enum TripStopPresentationSurface {
  none,
  quietMonitor,
  manualFallbackChip,
  reviewBanner,
  urgentReviewSheet,
}

enum TripStopPresentationReason {
  noStopEvidence,
  activeReviewAlreadyOpen,
  unsafeEvidenceSuppressed,
  trafficControlSuppressed,
  vehicleOnlyManualFallback,
  walkingReviewSuggested,
  sustainedWalkingReviewSuggested,
}

class TripStopPresentationContext {
  const TripStopPresentationContext({
    required this.profile,
    required this.classification,
    required this.stationaryDuration,
    required this.walkingEvidenceDuration,
    required this.distanceSinceLastAcceptedMeters,
    required this.activeTripInProgress,
    required this.localSessionAvailable,
    required this.stopReviewAlreadyOpen,
    required this.userEnabledStopPrompts,
  });

  final TripTrackingProfile profile;
  final TripStopClassification classification;
  final Duration stationaryDuration;
  final Duration walkingEvidenceDuration;
  final double distanceSinceLastAcceptedMeters;
  final bool activeTripInProgress;
  final bool localSessionAvailable;
  final bool stopReviewAlreadyOpen;
  final bool userEnabledStopPrompts;
}

class TripStopPresentationDecision {
  const TripStopPresentationDecision({
    required this.surface,
    required this.reason,
    required this.profile,
    required this.actionToken,
    required this.messageToken,
    required this.requiresUserReview,
    required this.canShowManualFallback,
    required this.canShowReviewPrompt,
    required this.shouldDebounceAgain,
  });

  final TripStopPresentationSurface surface;
  final TripStopPresentationReason reason;
  final TripTrackingProfile profile;
  final String actionToken;
  final String messageToken;
  final bool requiresUserReview;
  final bool canShowManualFallback;
  final bool canShowReviewPrompt;
  final bool shouldDebounceAgain;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'surface': surface.name,
    'reason': reason.name,
    'profile': profile.name,
    'actionToken': _safeAction(actionToken),
    'messageToken': _safeMessage(messageToken),
    'requiresUserReview': requiresUserReview && canShowReviewPrompt,
    'canShowManualFallback': canShowManualFallback,
    'canShowReviewPrompt': canShowReviewPrompt,
    'shouldDebounceAgain': shouldDebounceAgain,
    'reviewOnly': true,
    'advisoryOnly': true,
    'manualFallbackOnly':
        surface == TripStopPresentationSurface.manualFallbackChip,
    'activeTripRequired': true,
    'localSessionRequired': true,
    'stopReviewAlreadyOpenSuppressesDuplicate': true,
    'longTrafficLightProtected': true,
    'vehicleOnlyStopsNeedManualFallback': true,
    'walkingEvidenceCanOnlySuggestReview': true,
    'activityRecognitionCanCreateOfficialStop': false,
    'canCreateOfficialStop': false,
    'canEndTripAutomatically': false,
    'canReplaceOdometer': false,
    'officialStopSource': 'user_review',
    'officialMileageSource': 'odometer',
    'odometerIsGlobalTruth': true,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForStopPrompt': false,
    'mapboxCanShowPromptWithoutValidation': false,
    'mapboxCanCreateStop': false,
    'firebaseCanCreateStop': false,
    'remoteMirrorCanShowPromptWithoutLocalState': false,
    'employerCanForceStopPrompt': false,
    'rawLocationIncluded': false,
    'routeGeometryIncluded': false,
    'rawMotionPayloadIncluded': false,
    'tokensIncluded': false,
  };
}

class TripStopPresentationPolicy {
  const TripStopPresentationPolicy._();

  static TripStopPresentationDecision evaluate(
    TripStopPresentationContext context,
  ) {
    if (!context.activeTripInProgress || !context.localSessionAvailable) {
      return _none(
        context,
        TripStopPresentationReason.noStopEvidence,
        'no_active_local_trip',
      );
    }
    if (context.stopReviewAlreadyOpen) {
      return _none(
        context,
        TripStopPresentationReason.activeReviewAlreadyOpen,
        'stop_review_already_open',
      );
    }
    if (context.classification.signal == TripStopSignal.unsafeEvidence) {
      return _none(
        context,
        TripStopPresentationReason.unsafeEvidenceSuppressed,
        'unsafe_evidence_suppressed',
      );
    }
    if (context.classification.signal == TripStopSignal.likelyTrafficControl) {
      return _trafficControl(context);
    }
    if (context.classification.signal == TripStopSignal.reviewOnlyStop &&
        context.classification.canSuggestStop &&
        context.userEnabledStopPrompts) {
      return _walkingReview(context);
    }
    if (context.classification.signal == TripStopSignal.stopCandidate &&
        context.classification.shouldSurfaceManualStopFallback) {
      return _vehicleOnlyFallback(context);
    }
    return _quiet(context);
  }
}

TripStopPresentationDecision _walkingReview(
  TripStopPresentationContext context,
) {
  final strategy = TripTrackingProfileStrategy.forProfile(context.profile);
  final sustainedWalking =
      context.walkingEvidenceDuration >=
      strategy.walkingStopConfirmationDuration * 2;
  final urgent =
      sustainedWalking &&
      context.stationaryDuration >= const Duration(minutes: 3) &&
      !strategy.requiresStrongerStopDebounce;
  return TripStopPresentationDecision(
    surface: urgent
        ? TripStopPresentationSurface.urgentReviewSheet
        : TripStopPresentationSurface.reviewBanner,
    reason: sustainedWalking
        ? TripStopPresentationReason.sustainedWalkingReviewSuggested
        : TripStopPresentationReason.walkingReviewSuggested,
    profile: context.profile,
    actionToken: context.classification.actionToken,
    messageToken: urgent ? 'review_stop_now' : 'review_stop_when_safe',
    requiresUserReview: true,
    canShowManualFallback: true,
    canShowReviewPrompt: true,
    shouldDebounceAgain: false,
  );
}

TripStopPresentationDecision _vehicleOnlyFallback(
  TripStopPresentationContext context,
) {
  final strategy = TripTrackingProfileStrategy.forProfile(context.profile);
  final wait = strategy.requiresStrongerStopDebounce
      ? const Duration(minutes: 3)
      : const Duration(minutes: 2);
  final ready =
      context.stationaryDuration >= wait &&
      context.distanceSinceLastAcceptedMeters <= 75;
  if (!ready) {
    return TripStopPresentationDecision(
      surface: TripStopPresentationSurface.quietMonitor,
      reason: TripStopPresentationReason.vehicleOnlyManualFallback,
      profile: context.profile,
      actionToken: 'continue_monitoring',
      messageToken: 'debouncing_vehicle_only_stop',
      requiresUserReview: false,
      canShowManualFallback: false,
      canShowReviewPrompt: false,
      shouldDebounceAgain: true,
    );
  }
  return TripStopPresentationDecision(
    surface: TripStopPresentationSurface.manualFallbackChip,
    reason: TripStopPresentationReason.vehicleOnlyManualFallback,
    profile: context.profile,
    actionToken: 'add_manual_stop',
    messageToken: 'vehicle_only_stop_manual_fallback',
    requiresUserReview: false,
    canShowManualFallback: true,
    canShowReviewPrompt: false,
    shouldDebounceAgain: false,
  );
}

TripStopPresentationDecision _trafficControl(
  TripStopPresentationContext context,
) {
  final showFallback =
      context.stationaryDuration >= const Duration(minutes: 5) &&
      context.distanceSinceLastAcceptedMeters <= 50 &&
      context.classification.shouldSurfaceManualStopFallback;
  if (showFallback) {
    return TripStopPresentationDecision(
      surface: TripStopPresentationSurface.manualFallbackChip,
      reason: TripStopPresentationReason.trafficControlSuppressed,
      profile: context.profile,
      actionToken: 'add_manual_stop',
      messageToken: 'traffic_wait_manual_fallback',
      requiresUserReview: false,
      canShowManualFallback: true,
      canShowReviewPrompt: false,
      shouldDebounceAgain: false,
    );
  }
  return _none(
    context,
    TripStopPresentationReason.trafficControlSuppressed,
    'traffic_control_suppressed',
  );
}

TripStopPresentationDecision _quiet(TripStopPresentationContext context) {
  return TripStopPresentationDecision(
    surface: TripStopPresentationSurface.quietMonitor,
    reason: TripStopPresentationReason.noStopEvidence,
    profile: context.profile,
    actionToken: 'continue_monitoring',
    messageToken: 'continue_monitoring',
    requiresUserReview: false,
    canShowManualFallback: false,
    canShowReviewPrompt: false,
    shouldDebounceAgain: false,
  );
}

TripStopPresentationDecision _none(
  TripStopPresentationContext context,
  TripStopPresentationReason reason,
  String messageToken,
) {
  return TripStopPresentationDecision(
    surface: TripStopPresentationSurface.none,
    reason: reason,
    profile: context.profile,
    actionToken: 'keep_tracking',
    messageToken: messageToken,
    requiresUserReview: false,
    canShowManualFallback: false,
    canShowReviewPrompt: false,
    shouldDebounceAgain: false,
  );
}

String _safeAction(String value) {
  final clean = value.trim();
  return switch (clean) {
    'keep_tracking' ||
    'continue_monitoring' ||
    'review_delivery_stop' ||
    'review_jobsite_stop' ||
    'review_shift_stop' ||
    'review_trip_stop' ||
    'add_manual_stop' => clean,
    _ => 'keep_tracking',
  };
}

String _safeMessage(String value) {
  final clean = value.trim();
  return switch (clean) {
    'no_active_local_trip' ||
    'stop_review_already_open' ||
    'unsafe_evidence_suppressed' ||
    'traffic_control_suppressed' ||
    'traffic_wait_manual_fallback' ||
    'review_stop_now' ||
    'review_stop_when_safe' ||
    'vehicle_only_stop_manual_fallback' ||
    'debouncing_vehicle_only_stop' ||
    'continue_monitoring' => clean,
    _ => 'continue_monitoring',
  };
}
