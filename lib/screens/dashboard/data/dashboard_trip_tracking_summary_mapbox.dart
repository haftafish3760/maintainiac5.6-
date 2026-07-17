part of 'dashboard_trip_tracking_summary.dart';

class _DashboardMapboxAssistSummary {
  const _DashboardMapboxAssistSummary({
    required this.state,
    required this.reason,
    required this.reviewRequired,
    required this.trustedMileageSource,
    required this.routeDistanceMiles,
    required this.routeDeltaMiles,
  });

  final String state;
  final String reason;
  final bool reviewRequired;
  final String trustedMileageSource;
  final double? routeDistanceMiles;
  final double? routeDeltaMiles;
}

_DashboardMapboxAssistSummary _dashboardMapboxAssistFor({
  required MapboxTripAssistDecision? decision,
  required String fallbackState,
  required String fallbackReason,
  required bool fallbackReviewRequired,
  required String fallbackTrustedMileageSource,
  required double? fallbackRouteDistanceMiles,
  required double? fallbackRouteDeltaMiles,
}) {
  if (decision == null) {
    return _DashboardMapboxAssistSummary(
      state: _safeMapboxAssistState(fallbackState),
      reason: _safeMapboxAssistReason(fallbackReason),
      reviewRequired: fallbackReviewRequired,
      trustedMileageSource: _safeMapboxTrustedMileageSource(
        fallbackTrustedMileageSource,
      ),
      routeDistanceMiles: _safeMapboxMiles(fallbackRouteDistanceMiles),
      routeDeltaMiles: _safeMapboxMiles(fallbackRouteDeltaMiles),
    );
  }
  return _DashboardMapboxAssistSummary(
    state: _dashboardMapboxAssistStateFor(decision.status),
    reason: _safeMapboxAssistReason(decision.safeReason),
    reviewRequired: decision.shouldPromptReview,
    trustedMileageSource: _dashboardTrustedMileageSourceFor(
      decision.trustedMileageSource,
    ),
    routeDistanceMiles: _safeMapboxMiles(decision.routeDistanceMiles),
    routeDeltaMiles: _safeMapboxMiles(decision.comparisonDeltaMiles),
  );
}

String _dashboardMapboxAssistStateFor(MapboxTripAssistStatus status) {
  return switch (status) {
    MapboxTripAssistStatus.unavailable => 'unavailable',
    MapboxTripAssistStatus.rateLimited => 'rate_limited',
    MapboxTripAssistStatus.rejected => 'rejected',
    MapboxTripAssistStatus.visualOnly => 'visual_only',
    MapboxTripAssistStatus.distanceReview => 'distance_review',
  };
}

String _dashboardTrustedMileageSourceFor(MapboxTrustedMileageSource source) {
  return switch (source) {
    MapboxTrustedMileageSource.none => 'none',
    MapboxTrustedMileageSource.odometer => 'odometer',
    MapboxTrustedMileageSource.gpsAccepted => 'gps_accepted',
  };
}
