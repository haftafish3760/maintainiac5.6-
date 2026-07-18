import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';

enum TripTrackingWorkStyle {
  generalRoad,
  rideshare,
  delivery,
  contractor,
  equipment,
}

class TripTrackingProfileStrategy {
  const TripTrackingProfileStrategy({
    required this.profile,
    required this.workStyle,
    required this.usesWalkingStopEvidence,
    required this.walkingConfirmationCount,
    required this.walkingStopConfirmationDuration,
    required this.stopReviewReasonCode,
    required this.dashboardModeToken,
    required this.dashboardWidgetTokens,
    required this.quickActionTokens,
    required this.recommendedActivityRecognition,
    required this.stopDetectionSummary,
  });

  final TripTrackingProfile profile;
  final TripTrackingWorkStyle workStyle;
  final bool usesWalkingStopEvidence;
  final int walkingConfirmationCount;
  final Duration walkingStopConfirmationDuration;
  final String stopReviewReasonCode;
  final String dashboardModeToken;
  final List<String> dashboardWidgetTokens;
  final List<String> quickActionTokens;
  final bool recommendedActivityRecognition;
  final String stopDetectionSummary;

  String get workStyleToken => switch (workStyle) {
    TripTrackingWorkStyle.generalRoad => 'general_road',
    TripTrackingWorkStyle.rideshare => 'rideshare',
    TripTrackingWorkStyle.delivery => 'delivery',
    TripTrackingWorkStyle.contractor => 'contractor',
    TripTrackingWorkStyle.equipment => 'equipment',
  };

  String get stopDetectionModeToken {
    if (!usesWalkingStopEvidence) return 'walking_ignored';
    return requiresStrongerStopDebounce
        ? 'strong_debounce'
        : 'walking_assisted';
  }

  bool get walkingMayExcludeRoadMileage => usesWalkingStopEvidence;
  bool get requiresStrongerStopDebounce =>
      walkingConfirmationCount > 3 ||
      walkingStopConfirmationDuration > const Duration(seconds: 30);
  String get driverKindToken => switch (profile) {
    TripTrackingProfile.rideshareVehicle => 'passenger_service',
    TripTrackingProfile.deliveryVehicle => 'delivery_or_route',
    TripTrackingProfile.contractorVehicle => 'contractor_or_jobsite',
    TripTrackingProfile.lowSpeedEquipment => 'equipment',
    TripTrackingProfile.roadVehicle => 'general',
  };

  String get stopEvidenceTier {
    if (!usesWalkingStopEvidence) return 'gps_only_review';
    if (requiresStrongerStopDebounce) return 'strong_debounce_review';
    return 'walking_assisted_review';
  }

  bool get phoneMayStayInVehicleDuringStops =>
      workStyle == TripTrackingWorkStyle.rideshare ||
      workStyle == TripTrackingWorkStyle.delivery;

  bool get vehicleOnlyStopsNeedManualFallback =>
      phoneMayStayInVehicleDuringStops || !usesWalkingStopEvidence;

  String get stopReviewConfidencePolicyToken => switch (workStyle) {
    TripTrackingWorkStyle.rideshare => 'strong_vehicle_only_manual_review',
    TripTrackingWorkStyle.delivery => 'walking_assist_with_manual_fallback',
    TripTrackingWorkStyle.contractor => 'walking_assist_jobsite_review',
    TripTrackingWorkStyle.equipment => 'gps_only_manual_review',
    TripTrackingWorkStyle.generalRoad => 'conservative_manual_review',
  };

  Map<String, Object?> toDashboardProfileMap() => {
    'schemaVersion': 1,
    'profile': profile.name,
    'driverKind': driverKindToken,
    'workStyle': workStyleToken,
    'dashboardMode': dashboardModeToken,
    'stopDetectionMode': stopDetectionModeToken,
    'stopEvidenceTier': stopEvidenceTier,
    'recommendedActivityRecognition': recommendedActivityRecognition,
    'usesWalkingStopEvidence': usesWalkingStopEvidence,
    'requiresStrongerStopDebounce': requiresStrongerStopDebounce,
    'phoneMayStayInVehicleDuringStops': phoneMayStayInVehicleDuringStops,
    'vehicleOnlyStopsNeedManualFallback': vehicleOnlyStopsNeedManualFallback,
    'stopReviewConfidencePolicy': stopReviewConfidencePolicyToken,
    'stopReviewReasonCode': stopReviewReasonCode,
    'dashboardWidgetTokens': List.unmodifiable(dashboardWidgetTokens),
    'quickActionTokens': List.unmodifiable(quickActionTokens),
    'walkingEvidenceCanOnlySuggestReview': true,
    'activityRecognitionRequiresOptIn': recommendedActivityRecognition,
    'gpsAssistedTrackingAvailableWithoutMaps': true,
    'mapsRequiredForTracking': false,
    'mapsCanOnlyAssistVisualization': true,
    'odometerRemainsCanonical': true,
    'locationSharingRequiresActiveOptIn': true,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'rawLocationIncluded': false,
    'rawSensorPayloadIncluded': false,
  };

  bool hasWalkingStopEvidence({
    required int walkingEvidenceCount,
    required DateTime observedAt,
    required DateTime? latestWalkingEvidenceAt,
  }) {
    if (!usesWalkingStopEvidence) return false;
    if (walkingEvidenceCount >= walkingConfirmationCount) return true;
    final latest = latestWalkingEvidenceAt;
    if (latest == null || observedAt.isBefore(latest)) return false;
    return observedAt.difference(latest) >= walkingStopConfirmationDuration;
  }

  static TripTrackingProfileStrategy forProfile(
    TripTrackingProfile profile, {
    TripTrackingPolicy policy = const TripTrackingPolicy(),
  }) {
    final baseCount = _safePositiveInt(
      policy.walkingConfirmationCount,
      fallback: 3,
    );
    final baseDuration = _safePositiveDuration(
      policy.walkingStopConfirmationDuration,
      const Duration(seconds: 20),
    );
    return switch (profile) {
      TripTrackingProfile.rideshareVehicle => TripTrackingProfileStrategy(
        profile: profile,
        workStyle: TripTrackingWorkStyle.rideshare,
        usesWalkingStopEvidence: true,
        walkingConfirmationCount: baseCount < 4 ? 4 : baseCount,
        walkingStopConfirmationDuration:
            baseDuration < const Duration(seconds: 45)
            ? const Duration(seconds: 45)
            : baseDuration,
        stopReviewReasonCode: 'rideshare_stop_requires_extra_evidence',
        dashboardModeToken: 'gig_driver',
        dashboardWidgetTokens: const [
          'start_day',
          'live_odometer',
          'pay',
          'profit',
          'miles',
          'hours',
        ],
        quickActionTokens: const ['add_pay', 'end_trip', 'review_mileage'],
        recommendedActivityRecognition: true,
        stopDetectionSummary:
            'Passenger-service trips require stronger stop evidence because the driver often stays in the vehicle.',
      ),
      TripTrackingProfile.deliveryVehicle => TripTrackingProfileStrategy(
        profile: profile,
        workStyle: TripTrackingWorkStyle.delivery,
        usesWalkingStopEvidence: true,
        walkingConfirmationCount: baseCount,
        walkingStopConfirmationDuration: baseDuration,
        stopReviewReasonCode: 'delivery_stop_walk_review',
        dashboardModeToken: 'gig_driver',
        dashboardWidgetTokens: const [
          'start_day',
          'live_odometer',
          'stops',
          'pay',
          'profit',
          'miles',
          'expenses',
        ],
        quickActionTokens: const [
          'add_pickup',
          'add_dropoff',
          'add_pay',
          'review_mileage',
        ],
        recommendedActivityRecognition: true,
        stopDetectionSummary:
            'Delivery trips can use walking evidence as a strong stop clue after vehicle movement.',
      ),
      TripTrackingProfile.contractorVehicle => TripTrackingProfileStrategy(
        profile: profile,
        workStyle: TripTrackingWorkStyle.contractor,
        usesWalkingStopEvidence: true,
        walkingConfirmationCount: baseCount,
        walkingStopConfirmationDuration: baseDuration,
        stopReviewReasonCode: 'contractor_stop_walk_review',
        dashboardModeToken: 'contractor',
        dashboardWidgetTokens: const [
          'start_day',
          'live_odometer',
          'jobs',
          'materials',
          'expenses',
          'payments',
          'miles',
        ],
        quickActionTokens: const [
          'add_stop',
          'add_job',
          'add_expense',
          'record_payment',
          'review_mileage',
        ],
        recommendedActivityRecognition: true,
        stopDetectionSummary:
            'Contractor trips can use walking evidence to identify job-site stops without changing odometer truth.',
      ),
      TripTrackingProfile.lowSpeedEquipment => TripTrackingProfileStrategy(
        profile: profile,
        workStyle: TripTrackingWorkStyle.equipment,
        usesWalkingStopEvidence: false,
        walkingConfirmationCount: baseCount,
        walkingStopConfirmationDuration: baseDuration,
        stopReviewReasonCode: 'equipment_ignores_walking_stop_evidence',
        dashboardModeToken: 'default',
        dashboardWidgetTokens: const [
          'start_day',
          'live_odometer',
          'hours',
          'maintenance',
        ],
        quickActionTokens: const ['start_trip', 'end_trip', 'maintenance_log'],
        recommendedActivityRecognition: false,
        stopDetectionSummary:
            'Low-speed equipment ignores walking-stop evidence so mower and equipment routes do not become false stops.',
      ),
      TripTrackingProfile.roadVehicle => TripTrackingProfileStrategy(
        profile: profile,
        workStyle: TripTrackingWorkStyle.generalRoad,
        usesWalkingStopEvidence: true,
        walkingConfirmationCount: baseCount,
        walkingStopConfirmationDuration: baseDuration,
        stopReviewReasonCode: 'road_vehicle_stop_walk_review',
        dashboardModeToken: 'default',
        dashboardWidgetTokens: const [
          'start_day',
          'live_odometer',
          'miles',
          'expenses',
        ],
        quickActionTokens: const ['start_trip', 'end_trip', 'review_mileage'],
        recommendedActivityRecognition: true,
        stopDetectionSummary:
            'General road trips use conservative walking evidence as review-only stop assistance.',
      ),
    };
  }
}

int _safePositiveInt(int value, {required int fallback}) =>
    value > 0 ? value : fallback;

Duration _safePositiveDuration(Duration value, Duration fallback) =>
    value > Duration.zero ? value : fallback;
