import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_classification.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_presentation_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_stop_presentation_summary_validation.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  test('walking delivery evidence shows review banner, not official stop', () {
    final decision = TripStopPresentationPolicy.evaluate(
      context(
        profile: TripTrackingProfile.deliveryVehicle,
        classification: classification(
          signal: TripStopSignal.reviewOnlyStop,
          reasonCode: 'delivery_stop_walk_review',
          actionToken: 'review_delivery_stop',
          canSuggestStop: true,
          requiresUserReview: true,
        ),
        walkingEvidenceDuration: const Duration(seconds: 25),
        stationaryDuration: const Duration(minutes: 1),
      ),
    );
    final safe = decision.toSafeDashboardMap();

    expect(decision.surface, TripStopPresentationSurface.reviewBanner);
    expect(decision.requiresUserReview, isTrue);
    expect(safe['reviewOnly'], isTrue);
    expect(safe['canCreateOfficialStop'], isFalse);
    expect(safe['officialStopSource'], 'user_review');
    expect(safe['odometerIsGlobalTruth'], isTrue);
  });

  test('sustained contractor walking can escalate to review sheet', () {
    final decision = TripStopPresentationPolicy.evaluate(
      context(
        profile: TripTrackingProfile.contractorVehicle,
        classification: classification(
          signal: TripStopSignal.reviewOnlyStop,
          reasonCode: 'contractor_stop_walk_review',
          actionToken: 'review_jobsite_stop',
          canSuggestStop: true,
          requiresUserReview: true,
        ),
        walkingEvidenceDuration: const Duration(seconds: 50),
        stationaryDuration: const Duration(minutes: 4),
      ),
    );

    expect(decision.surface, TripStopPresentationSurface.urgentReviewSheet);
    expect(
      decision.reason,
      TripStopPresentationReason.sustainedWalkingReviewSuggested,
    );
    expect(decision.actionToken, 'review_jobsite_stop');
  });

  test('rideshare stop candidate debounces longer before manual fallback', () {
    final early = TripStopPresentationPolicy.evaluate(
      context(
        profile: TripTrackingProfile.rideshareVehicle,
        classification: classification(
          signal: TripStopSignal.stopCandidate,
          reasonCode: 'stop_candidate_waiting_for_stronger_evidence',
          manualFallback: true,
        ),
        stationaryDuration: const Duration(minutes: 2),
      ),
    );
    final ready = TripStopPresentationPolicy.evaluate(
      context(
        profile: TripTrackingProfile.rideshareVehicle,
        classification: classification(
          signal: TripStopSignal.stopCandidate,
          reasonCode: 'stop_candidate_waiting_for_stronger_evidence',
          manualFallback: true,
        ),
        stationaryDuration: const Duration(minutes: 3),
      ),
    );

    expect(early.surface, TripStopPresentationSurface.quietMonitor);
    expect(early.shouldDebounceAgain, isTrue);
    expect(ready.surface, TripStopPresentationSurface.manualFallbackChip);
    expect(ready.actionToken, 'add_manual_stop');
  });

  test(
    'long traffic control stays suppressed until manual fallback threshold',
    () {
      final suppressed = TripStopPresentationPolicy.evaluate(
        context(
          profile: TripTrackingProfile.deliveryVehicle,
          classification: classification(
            signal: TripStopSignal.likelyTrafficControl,
            reasonCode: 'traffic_control_or_stationary_jitter',
            manualFallback: true,
          ),
          stationaryDuration: const Duration(minutes: 3),
        ),
      );
      final fallback = TripStopPresentationPolicy.evaluate(
        context(
          profile: TripTrackingProfile.deliveryVehicle,
          classification: classification(
            signal: TripStopSignal.likelyTrafficControl,
            reasonCode: 'traffic_control_or_stationary_jitter',
            manualFallback: true,
          ),
          stationaryDuration: const Duration(minutes: 6),
        ),
      );

      expect(suppressed.surface, TripStopPresentationSurface.none);
      expect(
        suppressed.reason,
        TripStopPresentationReason.trafficControlSuppressed,
      );
      expect(fallback.surface, TripStopPresentationSurface.manualFallbackChip);
      expect(fallback.messageToken, 'traffic_wait_manual_fallback');
    },
  );

  test('unsafe and duplicate review states suppress prompts fail closed', () {
    final unsafe = TripStopPresentationPolicy.evaluate(
      context(
        classification: classification(
          signal: TripStopSignal.unsafeEvidence,
          reasonCode: 'unsafe_stop_evidence_rejected',
        ),
      ),
    );
    final duplicate = TripStopPresentationPolicy.evaluate(
      context(stopReviewAlreadyOpen: true),
    );

    expect(unsafe.surface, TripStopPresentationSurface.none);
    expect(unsafe.reason, TripStopPresentationReason.unsafeEvidenceSuppressed);
    expect(duplicate.surface, TripStopPresentationSurface.none);
    expect(
      duplicate.reason,
      TripStopPresentationReason.activeReviewAlreadyOpen,
    );
  });

  test('no active local trip suppresses any remote-looking stop prompt', () {
    final decision = TripStopPresentationPolicy.evaluate(
      context(
        activeTripInProgress: false,
        localSessionAvailable: false,
        classification: classification(
          signal: TripStopSignal.reviewOnlyStop,
          reasonCode: 'delivery_stop_walk_review',
          actionToken: 'review_delivery_stop',
          canSuggestStop: true,
          requiresUserReview: true,
        ),
      ),
    );

    expect(decision.surface, TripStopPresentationSurface.none);
    expect(decision.canShowReviewPrompt, isFalse);
    expect(
      decision
          .toSafeDashboardMap()['remoteMirrorCanShowPromptWithoutLocalState'],
      isFalse,
    );
  });

  test('safe summary never exposes location, routes, tokens, or authority', () {
    final safe = TripStopPresentationPolicy.evaluate(
      context(
        classification: classification(
          signal: TripStopSignal.reviewOnlyStop,
          reasonCode: 'delivery_stop_walk_review',
          actionToken: 'review_delivery_stop',
          canSuggestStop: true,
          requiresUserReview: true,
        ),
      ),
    ).toSafeDashboardMap();

    expect(safe['mapsRequiredForStopPrompt'], isFalse);
    expect(safe['mapboxCanCreateStop'], isFalse);
    expect(safe['firebaseCanCreateStop'], isFalse);
    expect(safe['odometerIsGlobalTruth'], isTrue);
    expect(safe['employerCanForceStopPrompt'], isFalse);
    expect(safe['rawLocationIncluded'], isFalse);
    expect(safe['routeGeometryIncluded'], isFalse);
    expect(safe['rawMotionPayloadIncluded'], isFalse);
    expect(safe['tokensIncluded'], isFalse);
    expect(safe.toString(), isNot(contains('pk.')));
    expect(safe.toString(), isNot(contains('sk.')));
    expect(
      TripStopPresentationSummaryValidation.fromSummary(safe).isRenderable,
      isTrue,
    );
  });

  test('presentation summary rejects forged review and remote authority', () {
    final safe = TripStopPresentationPolicy.evaluate(
      context(activeTripInProgress: false, localSessionAvailable: false),
    ).toSafeDashboardMap();
    final validation = TripStopPresentationSummaryValidation.fromSummary({
      ...safe,
      'surface': TripStopPresentationSurface.none.name,
      'canShowReviewPrompt': true,
      'requiresUserReview': true,
      'mapboxCanCreateStop': true,
      'remoteMirrorCanShowPromptWithoutLocalState': true,
      'debug': '35.123456,-80.123456 sk.secret',
    });

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('mapboxCanCreateStop_not_false'));
    expect(
      validation.reasons,
      contains('remoteMirrorCanShowPromptWithoutLocalState_not_false'),
    );
    expect(
      validation.reasons,
      contains('presentation_review_surface_mismatch'),
    );
    expect(
      validation.reasons,
      contains('presentation_contains_sensitive_text'),
    );
  });
}

TripStopPresentationContext context({
  TripTrackingProfile profile = TripTrackingProfile.deliveryVehicle,
  TripStopClassification? classification,
  Duration stationaryDuration = const Duration(seconds: 0),
  Duration walkingEvidenceDuration = const Duration(seconds: 0),
  double distanceSinceLastAcceptedMeters = 0,
  bool activeTripInProgress = true,
  bool localSessionAvailable = true,
  bool stopReviewAlreadyOpen = false,
  bool userEnabledStopPrompts = true,
}) {
  return TripStopPresentationContext(
    profile: profile,
    classification: classification ?? noStop(),
    stationaryDuration: stationaryDuration,
    walkingEvidenceDuration: walkingEvidenceDuration,
    distanceSinceLastAcceptedMeters: distanceSinceLastAcceptedMeters,
    activeTripInProgress: activeTripInProgress,
    localSessionAvailable: localSessionAvailable,
    stopReviewAlreadyOpen: stopReviewAlreadyOpen,
    userEnabledStopPrompts: userEnabledStopPrompts,
  );
}

TripStopClassification noStop() {
  return classification(
    signal: TripStopSignal.noStop,
    reasonCode: 'no_stop_review_needed',
  );
}

TripStopClassification classification({
  required TripStopSignal signal,
  required String reasonCode,
  TripStopReviewConfidence confidence = TripStopReviewConfidence.low,
  bool requiresUserReview = false,
  bool canSuggestStop = false,
  bool manualFallback = false,
  String actionToken = 'keep_tracking',
}) {
  return TripStopClassification(
    signal: signal,
    reviewConfidence: confidence,
    reasonCode: reasonCode,
    requiresUserReview: requiresUserReview,
    canSuggestStop: canSuggestStop,
    shouldSurfaceManualStopFallback: manualFallback,
    actionToken: actionToken,
    dashboardMessage: 'No stop review is needed right now.',
  );
}
