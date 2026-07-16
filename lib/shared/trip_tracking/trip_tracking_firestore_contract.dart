/// The stable, coordinate-free shape shared by trip-summary builders and the
/// local upload guard. Firestore rules repeat this allowlist independently at
/// the server boundary.
abstract final class TripTrackingFirestoreContract {
  static const reviewedSummarySchema = 'trip_tracking_review_v1';

  static const reviewedSummaryFields = <String>{
    'schema',
    'tripId',
    'orgId',
    'organizationSharingConsent',
    'createdByUid',
    'updatedByUid',
    'vehicleId',
    'profile',
    'startedAt',
    'finishedAt',
    'createdAt',
    'updatedAt',
    'startingOdometer',
    'estimatedEndingOdometer',
    'acceptedMeters',
    'acceptedMiles',
    'walkingReviewSuggested',
    'motionState',
    'receivedSampleCount',
    'acceptedSampleCount',
    'locationDataIncluded',
    'visibilityScope',
  };

  static const requiredReviewedSummaryFields = <String>{
    'schema',
    'tripId',
    'createdByUid',
    'updatedByUid',
    'vehicleId',
    'profile',
    'startedAt',
    'finishedAt',
    'createdAt',
    'updatedAt',
    'startingOdometer',
    'estimatedEndingOdometer',
    'acceptedMeters',
    'acceptedMiles',
    'walkingReviewSuggested',
    'motionState',
    'receivedSampleCount',
    'acceptedSampleCount',
    'locationDataIncluded',
    'visibilityScope',
  };
}
