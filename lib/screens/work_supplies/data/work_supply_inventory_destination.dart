import '../../../shared/state/app_state.dart';

const workSupplyCustomDestinationLabel = 'Custom location';
const workSupplyCompanyInventoryLabel = 'Company inventory';
const workSupplyActiveVehicleInventoryLabel = 'Active vehicle';

List<String> buildWorkSupplyInventoryDestinations({
  required AppStateController appState,
  String jobNumber = '',
}) {
  final destinations = <String>[
    workSupplyCompanyInventoryLabel,
    workSupplyActiveVehicleInventoryLabel,
    if (appState.activeVehicle != null)
      '${appState.activeVehicle!.nickname} inventory',
    for (final vehicle in appState.vehicles)
      if (vehicle != appState.activeVehicle) '${vehicle.nickname} inventory',
    if (jobNumber.isNotEmpty) 'Job staging - $jobNumber',
    workSupplyCustomDestinationLabel,
  ];
  return destinations.toSet().toList();
}

String resolveWorkSupplyInventoryDestination({
  required String selectedDestination,
  required String customDestination,
}) {
  if (selectedDestination != workSupplyCustomDestinationLabel) {
    return selectedDestination;
  }
  final trimmed = customDestination.trim();
  return trimmed.isEmpty ? 'Custom inventory location' : trimmed;
}
