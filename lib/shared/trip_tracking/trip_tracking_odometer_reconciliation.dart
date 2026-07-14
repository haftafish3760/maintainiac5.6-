import 'trip_tracking_session_store.dart';

enum TripOdometerReconciliationStatus { aligned, reviewRecommended, invalid }

/// Explicit comparison only: confirmed odometer mileage remains authoritative.
/// This object never writes an odometer, TripLog, or recap record.
class TripOdometerReconciliation {
  const TripOdometerReconciliation({
    required this.status,
    required this.confirmedOdometerDeltaMiles,
    required this.filteredGpsMiles,
    required this.absoluteDifferenceMiles,
    required this.differencePercent,
  });

  final TripOdometerReconciliationStatus status;
  final double confirmedOdometerDeltaMiles;
  final double filteredGpsMiles;
  final double absoluteDifferenceMiles;
  final double differencePercent;

  static TripOdometerReconciliation compare({
    required TripTrackingReviewRecord review,
    required int confirmedEndingOdometer,
    double materialDifferenceMiles = 5,
    double materialDifferencePercent = 10,
  }) {
    final odometerDelta = confirmedEndingOdometer - review.startingOdometer;
    final gpsMiles = review.engineSnapshot.totalAcceptedMeters / 1609.344;
    if (odometerDelta < 0 ||
        !gpsMiles.isFinite ||
        materialDifferenceMiles < 0 ||
        materialDifferencePercent < 0) {
      return const TripOdometerReconciliation(
        status: TripOdometerReconciliationStatus.invalid,
        confirmedOdometerDeltaMiles: 0,
        filteredGpsMiles: 0,
        absoluteDifferenceMiles: 0,
        differencePercent: 0,
      );
    }
    final difference = (odometerDelta - gpsMiles).abs();
    final denominator = odometerDelta == 0 ? 1.0 : odometerDelta.toDouble();
    final percent = (difference / denominator) * 100;
    return TripOdometerReconciliation(
      status:
          difference >= materialDifferenceMiles ||
              percent >= materialDifferencePercent
          ? TripOdometerReconciliationStatus.reviewRecommended
          : TripOdometerReconciliationStatus.aligned,
      confirmedOdometerDeltaMiles: odometerDelta.toDouble(),
      filteredGpsMiles: gpsMiles,
      absoluteDifferenceMiles: difference,
      differencePercent: percent,
    );
  }
}
