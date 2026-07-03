import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('sensitive field registry covers privacy forbidden data classes', () {
    const registry = maintainiacSensitiveFieldRegistry;

    expect(registry.validate(), isEmpty);
    expect(registry.contains('VIN'), isTrue);
    expect(registry.contains('plate'), isTrue);
    expect(registry.contains('license_plate'), isTrue);
    expect(registry.contains('patient'), isTrue);
    expect(registry.contains('passenger'), isTrue);
    expect(registry.contains('api_key'), isTrue);
    expect(registry.names(), maintainiacSensitiveFieldNames);
    expect(registry.toJson().toString(), contains('vehicleIdentity'));
  });

  test('sensitive field registry rejects duplicates and missing classes', () {
    const registry = MaintainiacSensitiveFieldRegistry([
      MaintainiacSensitiveField(
        name: 'vin',
        kind: MaintainiacSensitiveFieldKind.vehicleIdentity,
        reason: '',
      ),
      MaintainiacSensitiveField(
        name: 'VIN',
        kind: MaintainiacSensitiveFieldKind.vehicleIdentity,
        reason: 'duplicate after normalization',
      ),
    ]);

    final failures = registry.validate().join('\n');

    expect(failures, contains('vin missing reason'));
    expect(failures, contains('duplicate sensitive field VIN'));
    expect(
      failures,
      contains('sensitive field registry missing kind receiptRaw'),
    );
  });
}
