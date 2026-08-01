// Regression coverage for the allocation read-only consumer contract.
//
// Owns consent and uncertainty projection tests. It does not test the Expense
// app, durable storage, GPS, or mileage classification. Dashboard and Expense
// consumers rely on this contract for non-authoritative suggestions.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation.dart';
import 'package:maintaniac/shared/trip_tracking/vehicle_mileage_allocation_read_model.dart';

void main() {
  VehicleMileageAllocationSummary summary({int unclassifiedTenths = 0}) =>
      VehicleMileageAllocationSummary(
        vehicleId: 'vehicle-1',
        from: DateTime.utc(2026, 8, 1),
        until: DateTime.utc(2026, 8, 2),
        businessTenths: 70,
        personalTenths: 30,
        unclassifiedTenths: unclassifiedTenths,
        recordCount: 2,
      );

  test('no opt-in never exposes a percentage even for complete evidence', () {
    final model = VehicleMileageAllocationReadModel.fromSummary(
      settings: const TripTrackingSettings(),
      summary: summary(),
    );

    expect(
      model.availability,
      VehicleMileageAllocationAvailability.optInRequired,
    );
    expect(model.suggestedBusinessPercent, isNull);
    expect(model.canSuggestExpenseSplit, isFalse);
  });

  test(
    'unclassified mileage requires review rather than a false percentage',
    () {
      final model = VehicleMileageAllocationReadModel.fromSummary(
        settings: const TripTrackingSettings(
          vehicleMileageAllocationEnabled: true,
        ),
        summary: summary(unclassifiedTenths: 20),
      );

      expect(
        model.availability,
        VehicleMileageAllocationAvailability.reviewRequired,
      );
      expect(model.suggestedBusinessPercent, isNull);
    },
  );

  test(
    'opted-in users still receive no percentage before confirmed mileage',
    () {
      final model = VehicleMileageAllocationReadModel.fromSummary(
        settings: const TripTrackingSettings(
          vehicleMileageAllocationEnabled: true,
        ),
        summary: VehicleMileageAllocationSummary(
          vehicleId: 'vehicle-1',
          from: DateTime.utc(2026, 8, 1),
          until: DateTime.utc(2026, 8, 2),
          businessTenths: 0,
          personalTenths: 0,
          unclassifiedTenths: 0,
          recordCount: 0,
        ),
      );

      expect(
        model.availability,
        VehicleMileageAllocationAvailability.noConfirmedMileage,
      );
      expect(model.suggestedBusinessPercent, isNull);
    },
  );

  test('complete opted-in evidence is a suggestion, never an expense edit', () {
    final model = VehicleMileageAllocationReadModel.fromSummary(
      settings: const TripTrackingSettings(
        vehicleMileageAllocationEnabled: true,
      ),
      summary: summary(),
    );

    expect(model.availability, VehicleMileageAllocationAvailability.ready);
    expect(model.suggestedBusinessPercent, .7);
    expect(model.toMap()['canChangeExpense'], isFalse);
    expect(model.toMap()['requiresExpenseReview'], isTrue);
    expect(model.toMap()['expenseBusinessNumeratorTenths'], 70);
    expect(model.toMap()['expenseClassifiedDenominatorTenths'], 100);
  });
}
