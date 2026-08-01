// Consent gate for confirmed vehicle-use allocation evidence.
//
// Owns the explicit local opt-in decision before an allocation record can
// reach the Dashboard projection or a future durable allocation bucket. It
// does not classify mileage, persist records, access GPS, or change Expense
// records. Trip/odometer review and allocation repository consumers use it.

import 'trip_tracking_settings_store.dart';
import 'vehicle_mileage_allocation.dart';
import 'vehicle_mileage_allocation_ledger.dart';

enum VehicleMileageAllocationConsentDecision { accepted, optInRequired }

class VehicleMileageAllocationConsentResult {
  const VehicleMileageAllocationConsentResult({
    required this.decision,
    required this.ledger,
    this.ingestResult,
  });

  final VehicleMileageAllocationConsentDecision decision;
  final VehicleMileageAllocationLedger ledger;
  final VehicleMileageAllocationIngestResult? ingestResult;

  bool get changed => ingestResult?.changed ?? false;
}

/// The only allocation-ingestion entry point that accepts app settings.
///
/// A disabled setting deliberately retains the supplied ledger unchanged. That
/// lets manual mileage remain fully usable without collecting an allocation
/// history or exposing a percentage to an expense consumer.
VehicleMileageAllocationConsentResult ingestVehicleMileageAllocationIfOptedIn({
  required TripTrackingSettings settings,
  required VehicleMileageAllocationLedger ledger,
  required VehicleMileageAllocationRecord record,
}) {
  if (!settings.vehicleMileageAllocationEnabled) {
    return VehicleMileageAllocationConsentResult(
      decision: VehicleMileageAllocationConsentDecision.optInRequired,
      ledger: ledger,
    );
  }
  final ingested = ledger.ingest(record);
  return VehicleMileageAllocationConsentResult(
    decision: VehicleMileageAllocationConsentDecision.accepted,
    ledger: ingested.ledger,
    ingestResult: ingested,
  );
}
