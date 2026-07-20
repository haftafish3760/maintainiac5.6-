import 'trip_tracking_session_store.dart';

/// Optional handoff boundary for reviewed trip summaries.
///
/// Trip Tracking owns only local trip truth. The application-wide durable
/// storage system may implement this port to bundle reviewed summaries with
/// other screen data, enforce account quotas, and perform remote sync. Nothing
/// in the tracking engine depends on Firebase, networking, or authentication.
abstract interface class TripTrackingBackupPort {
  Future<void> queueReview(TripTrackingReviewRecord review);

  Future<void> flushPending();

  Future<void> withdrawBackupConsent();

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

/// Temporary source-compatible aliases while callers move to the neutral
/// durable-storage terminology.
typedef TripTrackingCloudMirror = TripTrackingBackupPort;
typedef NoopTripTrackingCloudMirror = NoopTripTrackingBackupPort;
