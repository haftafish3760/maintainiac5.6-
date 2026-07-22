import 'trip_tracking_session_store.dart';

/// Firebase-neutral handoff for locally reviewed trip summaries.
///
/// The GPS engine and local recovery store do not depend on authentication,
/// networking, or any specific backup provider.
abstract interface class TripTrackingBackupPort {
  Future<void> queueReview(TripTrackingReviewRecord review);

  Future<void> flushPending();

  /// Withdraws backup consent without touching locally stored trip reviews.
  Future<void> withdrawBackupConsent();

  /// Stops unsent organization sharing without changing private backup consent.
  Future<void> withdrawOrganizationSharingConsent();

  void dispose();
}

class NoopTripTrackingBackupPort implements TripTrackingBackupPort {
  const NoopTripTrackingBackupPort();

  @override
  Future<void> queueReview(TripTrackingReviewRecord review) async {}

  @override
  Future<void> flushPending() async {}

  @override
  Future<void> withdrawBackupConsent() async {}

  @override
  Future<void> withdrawOrganizationSharingConsent() async {}

  @override
  void dispose() {}
}

typedef TripTrackingCloudMirror = TripTrackingBackupPort;
typedef NoopTripTrackingCloudMirror = NoopTripTrackingBackupPort;
