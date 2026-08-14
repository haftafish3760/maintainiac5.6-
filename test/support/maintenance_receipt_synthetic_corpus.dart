import 'dart:convert';
import 'dart:io';

const maintenanceReceiptSyntheticCorpusPaths = <String>[
  'test/fixtures/maintenance_receipts/synthetic_baseline_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_wheel_service_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_safety_inspection_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_drum_brake_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_system_service_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_brake_hydraulic_hardware_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_suspension_service_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_chassis_service_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_cooling_hardware_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_engine_electrical_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_ignition_service_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_drivetrain_support_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_belt_drive_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_radiator_hardware_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_fuel_pump_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_oxygen_sensor_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_emissions_air_management_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_engine_gasket_corpus.json',
  'test/fixtures/maintenance_receipts/synthetic_catalytic_converter_corpus.json',
];

List<Map<String, dynamic>> loadMaintenanceReceiptSyntheticCorpus() {
  final fixtures = <Map<String, dynamic>>[];
  final ids = <String>{};
  for (final path in maintenanceReceiptSyntheticCorpusPaths) {
    final decoded = jsonDecode(File(path).readAsStringSync());
    if (decoded is! List) {
      throw FormatException('Maintenance receipt corpus is not a list: $path');
    }
    for (final value in decoded) {
      if (value is! Map) {
        throw FormatException('Maintenance receipt fixture is invalid: $path');
      }
      final fixture = Map<String, dynamic>.from(value);
      final id = '${fixture['id'] ?? ''}'.trim();
      if (id.isEmpty || !ids.add(id)) {
        throw FormatException('Maintenance receipt fixture ID is invalid: $id');
      }
      fixtures.add(fixture);
    }
  }
  return List.unmodifiable(fixtures);
}
