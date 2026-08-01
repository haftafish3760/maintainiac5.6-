// Read-only vehicle-use summary for Dashboard and eligible Expense consumers.
//
// Owns availability, explanation, and a safe suggested percentage derived from
// an allocation summary plus explicit consent. It does not persist evidence,
// classify mileage, edit an Expense record, or access location. Dashboard and
// Expense integrations consume this projection after their owners opt in.
// odometerIsGlobalTruth: true.

import 'trip_tracking_settings_store.dart';
import 'vehicle_mileage_allocation.dart';

enum VehicleMileageAllocationAvailability {
  optInRequired,
  noConfirmedMileage,
  reviewRequired,
  ready,
}

class VehicleMileageAllocationReadModel {
  const VehicleMileageAllocationReadModel._({
    required this.summary,
    required this.availability,
    required this.suggestedBusinessPercent,
    required this.explanation,
  });

  factory VehicleMileageAllocationReadModel.fromSummary({
    required TripTrackingSettings settings,
    required VehicleMileageAllocationSummary summary,
  }) {
    if (!settings.vehicleMileageAllocationEnabled) {
      return VehicleMileageAllocationReadModel._(
        summary: summary,
        availability: VehicleMileageAllocationAvailability.optInRequired,
        suggestedBusinessPercent: null,
        explanation:
            'Vehicle-use percentages are off. Enable this optional local feature before using confirmed mileage for a suggestion.',
      );
    }
    if (!summary.hasMileage) {
      return VehicleMileageAllocationReadModel._(
        summary: summary,
        availability: VehicleMileageAllocationAvailability.noConfirmedMileage,
        suggestedBusinessPercent: null,
        explanation: summary.expenseExplanation,
      );
    }
    if (!summary.isComplete) {
      return VehicleMileageAllocationReadModel._(
        summary: summary,
        availability: VehicleMileageAllocationAvailability.reviewRequired,
        suggestedBusinessPercent: null,
        explanation: summary.expenseExplanation,
      );
    }
    return VehicleMileageAllocationReadModel._(
      summary: summary,
      availability: VehicleMileageAllocationAvailability.ready,
      suggestedBusinessPercent: summary.expenseSuggestedBusinessPercent,
      explanation: summary.expenseExplanation,
    );
  }

  final VehicleMileageAllocationSummary summary;
  final VehicleMileageAllocationAvailability availability;

  /// Null unless all period mileage is classified and the user opted in.
  final double? suggestedBusinessPercent;
  final String explanation;

  bool get canSuggestExpenseSplit =>
      availability == VehicleMileageAllocationAvailability.ready;

  Map<String, Object?> toMap() => {
    'vehicleId': summary.vehicleId,
    'from': summary.from.toUtc().toIso8601String(),
    'until': summary.until.toUtc().toIso8601String(),
    'availability': availability.name,
    'suggestedBusinessPercent': suggestedBusinessPercent,
    'businessTenths': summary.businessTenths,
    'personalTenths': summary.personalTenths,
    'unclassifiedTenths': summary.unclassifiedTenths,
    'recordCount': summary.recordCount,
    'explanation': explanation,
    'canChangeExpense': false,
    'requiresExpenseReview': true,
  };
}
