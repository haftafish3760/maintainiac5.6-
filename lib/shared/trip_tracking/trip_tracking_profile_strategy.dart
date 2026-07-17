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
  final bool recommendedActivityRecognition;
  final String stopDetectionSummary;

  bool get walkingMayExcludeRoadMileage => usesWalkingStopEvidence;

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
