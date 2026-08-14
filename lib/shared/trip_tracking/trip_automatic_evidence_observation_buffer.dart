// Converts opt-in live device evidence into bounded App Assistant observations.
//
// Owns only short-lived, coordinate-free observation derivation for possible
// drive review. Does not persist routes, start sessions, classify mileage, or
// confirm business records. Consumed by the trip-tracking runtime bridge
// before TripAutomaticStartDetector creates a review-only proposal.
import 'dart:math' as math;

import 'trip_automatic_start_detector.dart';
import 'trip_tracking_models.dart';

class TripAutomaticEvidenceObservationBuffer {
  /// Derived observations cannot change physical odometer truth.
  static const bool odometerIsGlobalTruth = true;

  TripAutomaticEvidenceObservationBuffer({
    this.maximumObservationWindow = const Duration(minutes: 2),
    this.maximumObservations = 12,
  }) : assert(maximumObservationWindow > Duration.zero),
       assert(maximumObservations > 0);

  final Duration maximumObservationWindow;
  final int maximumObservations;

  final List<TripAutomaticStartObservation> _observations = [];
  TripLocationSample? _previousLocation;
  TripActivityObservation? _latestActivity;
  bool _reviewCandidateEmitted = false;

  /// Safe, derived evidence only. No coordinate leaves this buffer.
  List<TripAutomaticStartObservation> get observations =>
      List.unmodifiable(_observations);

  /// Each moving evidence window may produce at most one review proposal.
  bool get canEmitReviewCandidate => !_reviewCandidateEmitted;

  void recordActivity(TripActivityObservation activity) {
    if (!activity.canSupportStopReview &&
        activity.activity == TripActivity.unknown) {
      return;
    }
    _latestActivity = activity;
  }

  /// Adds a valid live location as derived evidence. Native coordinates remain
  /// only in memory long enough to calculate the next displacement.
  TripAutomaticStartObservation? recordLocation(
    TripLocationSample sample, {
    String? bluetoothVehicleId,
  }) {
    if (!sample.hasValidCoordinate ||
        !sample.hasValidAccuracy ||
        !sample.hasValidReportedSpeed ||
        sample.mockedLocation == true) {
      return null;
    }

    final previous = _previousLocation;
    if (previous != null &&
        !sample.recordedAt.toUtc().isAfter(previous.recordedAt.toUtc())) {
      // A delayed native callback must not become the next displacement
      // anchor or move the bounded evidence window backward in time.
      return null;
    }
    final displacement = previous == null
        ? 0.0
        : _distanceMeters(previous, sample);
    final elapsedSeconds = previous == null
        ? 0.0
        : sample.recordedAt.difference(previous.recordedAt).inMilliseconds /
              1000;
    final reportedSpeed = sample.speedMetersPerSecond;
    final inferredSpeed = elapsedSeconds > 0
        ? displacement / elapsedSeconds
        : 0.0;
    final activity = _recentActivityFor(sample.recordedAt);
    final observation = TripAutomaticStartObservation(
      recordedAt: sample.recordedAt,
      speedMetersPerSecond: reportedSpeed ?? inferredSpeed,
      displacementMeters: displacement,
      horizontalAccuracyMeters: sample.horizontalAccuracyMeters,
      activity: activity?.activity ?? TripActivity.unknown,
      activityConfidence: activity?.confidence ?? 0,
      bluetoothVehicleId: _safeVehicleId(bluetoothVehicleId),
    );
    _previousLocation = sample;
    _observations.add(observation);
    _trim(sample.recordedAt);
    return observation;
  }

  /// Prevents a noisy stream from repeatedly creating the same review item.
  void markReviewCandidateEmitted() => _reviewCandidateEmitted = true;

  /// Starts a fresh evidence window after movement has ended or been reviewed.
  void reset() {
    _observations.clear();
    _previousLocation = null;
    _latestActivity = null;
    _reviewCandidateEmitted = false;
  }

  TripActivityObservation? _recentActivityFor(DateTime locationTime) {
    final activity = _latestActivity;
    if (activity == null ||
        locationTime.difference(activity.recordedAt).abs() >
            maximumObservationWindow) {
      return null;
    }
    return activity;
  }

  void _trim(DateTime latest) {
    final earliest = latest.subtract(maximumObservationWindow);
    _observations.removeWhere((item) => item.recordedAt.isBefore(earliest));
    while (_observations.length > maximumObservations) {
      _observations.removeAt(0);
    }
  }
}

String? _safeVehicleId(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty || normalized.length > 128) {
    return null;
  }
  return RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(normalized) ? normalized : null;
}

double _distanceMeters(TripLocationSample left, TripLocationSample right) {
  const radiusMeters = 6371008.8;
  final latitudeDelta = _radians(right.latitude - left.latitude);
  final longitudeDelta = _radians(right.longitude - left.longitude);
  final latitudeOne = _radians(left.latitude);
  final latitudeTwo = _radians(right.latitude);
  final a =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(latitudeOne) *
          math.cos(latitudeTwo) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final boundedA = a.clamp(0.0, 1.0).toDouble();
  return radiusMeters *
      2 *
      math.atan2(math.sqrt(boundedA), math.sqrt(1 - boundedA));
}

double _radians(double degrees) => degrees * math.pi / 180;
