import 'trip_tracking_models.dart';

enum TripTrackingSignalQuality {
  noSamples,
  healthy,
  reduced,
  poor,
  interrupted,
  unsafe,
}

class TripTrackingSignalQualitySummary {
  const TripTrackingSignalQualitySummary({
    required this.quality,
    required this.reasonCode,
    required this.receivedSamples,
    required this.acceptedSamples,
    required this.rejectedSamples,
    required this.acceptanceRate,
    required this.requiresUserReview,
  });

  final TripTrackingSignalQuality quality;
  final String reasonCode;
  final int receivedSamples;
  final int acceptedSamples;
  final int rejectedSamples;
  final double acceptanceRate;
  final bool requiresUserReview;

  TripTrackingHealthState get healthState {
    return switch (quality) {
      TripTrackingSignalQuality.noSamples => TripTrackingHealthState.reduced,
      TripTrackingSignalQuality.healthy => TripTrackingHealthState.healthy,
      TripTrackingSignalQuality.reduced => TripTrackingHealthState.reduced,
      TripTrackingSignalQuality.poor => TripTrackingHealthState.poor,
      TripTrackingSignalQuality.interrupted =>
        TripTrackingHealthState.interrupted,
      TripTrackingSignalQuality.unsafe => TripTrackingHealthState.unavailable,
    };
  }

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'quality': quality.name,
    'reasonCode': _safeSignalReason(reasonCode),
    'receivedSamples': _safeCount(receivedSamples),
    'acceptedSamples': _safeAccepted(
      acceptedSamples,
      _safeCount(receivedSamples),
    ),
    'rejectedSamples': _safeRejected(
      rejectedSamples,
      receivedSamples: receivedSamples,
      acceptedSamples: acceptedSamples,
    ),
    'acceptanceRate': _safeRate(acceptanceRate),
    'requiresUserReview': _safeRequiresUserReview(
      quality: quality,
      reasonCode: reasonCode,
      requestedReview: requiresUserReview,
    ),
    'advisoryOnly': true,
    'diagnosticsCanOnlyRequestReview': true,
    'diagnosticsCanEndTrip': false,
    'officialMileageSource': 'odometer',
    'canReplaceOdometer': false,
    'gpsCanWriteConfirmedTripLog': false,
    'mapboxCanReplaceOdometer': false,
    'mapboxCanWriteConfirmedTripLog': false,
    'remoteTotalsCanBecomeCanonical': false,
    'externalDiagnosticsTrustedAfterValidationOnly': true,
    'firestoreDiagnosticsCanOverrideLocalTripLog': false,
    'cloudFunctionDiagnosticsCanOverrideLocalTripLog': false,
    'mapboxDiagnosticsCanOverrideLocalTripLog': false,
    'malformedDiagnosticsFailClosed': true,
    'localTripLogProtected': true,
    'canUploadRawGps': false,
    'rawSamplesIncluded': false,
    'coordinatesIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxGeometryIncluded': false,
  };

  static TripTrackingSignalQualitySummary evaluate(
    TripTrackingDiagnostics diagnostics,
  ) {
    final received = _safeCount(diagnostics.receivedSamples);
    final accepted = _safeAccepted(diagnostics.acceptedSamples, received);
    final rejected = received - accepted;
    if (received == 0) {
      return const TripTrackingSignalQualitySummary(
        quality: TripTrackingSignalQuality.noSamples,
        reasonCode: 'gps_signal_waiting_for_samples',
        receivedSamples: 0,
        acceptedSamples: 0,
        rejectedSamples: 0,
        acceptanceRate: 0,
        requiresUserReview: false,
      );
    }

    final counts = diagnostics.dispositionCounts;
    final unsafe =
        _count(counts, TripSampleDisposition.rejectedInvalid) +
        _count(counts, TripSampleDisposition.rejectedMockLocation) +
        _count(counts, TripSampleDisposition.rejectedFutureTimestamp) +
        _count(counts, TripSampleDisposition.rejectedOutOfOrder);
    final interrupted = _count(counts, TripSampleDisposition.rejectedGap);
    final poor =
        _count(counts, TripSampleDisposition.rejectedAccuracy) +
        _count(counts, TripSampleDisposition.rejectedImplausibleSpeed) +
        _count(counts, TripSampleDisposition.rejectedSpeedConflict);
    final acceptanceRate = accepted / received;
    final review = unsafe > 0 || poor >= 3 || interrupted > 0;

    if (unsafe >= 2) {
      return _summary(
        TripTrackingSignalQuality.unsafe,
        'gps_signal_unsafe_provider_evidence',
        received,
        accepted,
        rejected,
        acceptanceRate,
        true,
      );
    }
    if (interrupted > 0) {
      return _summary(
        TripTrackingSignalQuality.interrupted,
        'gps_signal_interrupted_by_gap',
        received,
        accepted,
        rejected,
        acceptanceRate,
        true,
      );
    }
    if (poor >= 3 || acceptanceRate < .45) {
      return _summary(
        TripTrackingSignalQuality.poor,
        'gps_signal_poor_measurement_quality',
        received,
        accepted,
        rejected,
        acceptanceRate,
        review,
      );
    }
    if (rejected > 0 || acceptanceRate < .8) {
      return _summary(
        TripTrackingSignalQuality.reduced,
        'gps_signal_reduced_but_usable',
        received,
        accepted,
        rejected,
        acceptanceRate,
        review,
      );
    }
    return _summary(
      TripTrackingSignalQuality.healthy,
      'gps_signal_healthy',
      received,
      accepted,
      rejected,
      acceptanceRate,
      false,
    );
  }
}

TripTrackingSignalQualitySummary _summary(
  TripTrackingSignalQuality quality,
  String reasonCode,
  int received,
  int accepted,
  int rejected,
  double acceptanceRate,
  bool requiresUserReview,
) {
  return TripTrackingSignalQualitySummary(
    quality: quality,
    reasonCode: reasonCode,
    receivedSamples: received,
    acceptedSamples: accepted,
    rejectedSamples: rejected,
    acceptanceRate: acceptanceRate.isFinite ? acceptanceRate.clamp(0, 1) : 0,
    requiresUserReview: requiresUserReview,
  );
}

int _count(
  Map<TripSampleDisposition, int> counts,
  TripSampleDisposition disposition,
) => _safeCount(counts[disposition] ?? 0);

int _safeCount(int value) => value < 0
    ? 0
    : value > 999999
    ? 999999
    : value;

int _safeAccepted(int accepted, int received) {
  final safe = _safeCount(accepted);
  return safe > received ? 0 : safe;
}

int _safeRejected(
  int rejected, {
  required int receivedSamples,
  required int acceptedSamples,
}) {
  final received = _safeCount(receivedSamples);
  final accepted = _safeAccepted(acceptedSamples, received);
  final safeRejected = _safeCount(rejected);
  return safeRejected > received - accepted
      ? received - accepted
      : safeRejected;
}

double _safeRate(double value) {
  if (!value.isFinite) return 0;
  return double.parse(value.clamp(0, 1).toStringAsFixed(3));
}

String _safeSignalReason(String value) {
  return switch (value.trim()) {
    'gps_signal_waiting_for_samples' => 'gps_signal_waiting_for_samples',
    'gps_signal_healthy' => 'gps_signal_healthy',
    'gps_signal_reduced_but_usable' => 'gps_signal_reduced_but_usable',
    'gps_signal_poor_measurement_quality' =>
      'gps_signal_poor_measurement_quality',
    'gps_signal_interrupted_by_gap' => 'gps_signal_interrupted_by_gap',
    'gps_signal_unsafe_provider_evidence' =>
      'gps_signal_unsafe_provider_evidence',
    _ => 'gps_signal_unsafe_provider_evidence',
  };
}

bool _safeRequiresUserReview({
  required TripTrackingSignalQuality quality,
  required String reasonCode,
  required bool requestedReview,
}) {
  final safeReason = _safeSignalReason(reasonCode);
  if (safeReason == 'gps_signal_unsafe_provider_evidence' ||
      safeReason == 'gps_signal_interrupted_by_gap' ||
      quality == TripTrackingSignalQuality.unsafe ||
      quality == TripTrackingSignalQuality.interrupted) {
    return true;
  }
  if (safeReason == 'gps_signal_poor_measurement_quality' ||
      quality == TripTrackingSignalQuality.poor) {
    return true;
  }
  return requestedReview && quality != TripTrackingSignalQuality.noSamples;
}
