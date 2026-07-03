enum MaintainiacSensitiveFieldKind {
  receiptRaw,
  customerIdentity,
  payment,
  vehicleIdentity,
  passengerPatient,
  deviceIdentity,
  secret,
}

class MaintainiacSensitiveField {
  const MaintainiacSensitiveField({
    required this.name,
    required this.kind,
    required this.reason,
  });

  final String name;
  final MaintainiacSensitiveFieldKind kind;
  final String reason;

  List<String> validate() {
    final failures = <String>[];
    if (name.trim().isEmpty) {
      failures.add('sensitive field missing name');
    }
    if (reason.trim().isEmpty) {
      failures.add('$name missing reason');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {'name': name, 'kind': kind.name, 'reason': reason};
  }
}

class MaintainiacSensitiveFieldRegistry {
  const MaintainiacSensitiveFieldRegistry(this.fields);

  final List<MaintainiacSensitiveField> fields;

  List<String> validate() {
    final failures = <String>[];
    final names = <String>{};
    final kinds = <MaintainiacSensitiveFieldKind>{};
    for (final field in fields) {
      final normalized = normalize(field.name);
      if (!names.add(normalized)) {
        failures.add('duplicate sensitive field ${field.name}');
      }
      kinds.add(field.kind);
      failures.addAll(field.validate());
    }
    for (final required in MaintainiacSensitiveFieldKind.values) {
      if (!kinds.contains(required)) {
        failures.add('sensitive field registry missing kind ${required.name}');
      }
    }
    return failures;
  }

  bool contains(String fieldName) {
    final normalized = normalize(fieldName);
    return fields.any((field) => normalize(field.name) == normalized);
  }

  Set<String> names() {
    return {for (final field in fields) field.name};
  }

  static String normalize(String fieldName) {
    return fieldName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Map<String, Object?> toJson() {
    return {
      'fieldCount': fields.length,
      'kinds': ({for (final field in fields) field.kind.name}.toList()..sort()),
      'fields': [for (final field in fields) field.toJson()],
    };
  }
}

const maintainiacSensitiveFieldRegistry = MaintainiacSensitiveFieldRegistry([
  MaintainiacSensitiveField(
    name: 'rawReceiptText',
    kind: MaintainiacSensitiveFieldKind.receiptRaw,
    reason: 'Raw receipt text can contain private purchase and location data.',
  ),
  MaintainiacSensitiveField(
    name: 'receiptImagePath',
    kind: MaintainiacSensitiveFieldKind.receiptRaw,
    reason: 'Receipt image paths can expose local files or cloud object names.',
  ),
  MaintainiacSensitiveField(
    name: 'customerName',
    kind: MaintainiacSensitiveFieldKind.customerIdentity,
    reason: 'Customer names are private business records.',
  ),
  MaintainiacSensitiveField(
    name: 'customerAddress',
    kind: MaintainiacSensitiveFieldKind.customerIdentity,
    reason: 'Customer addresses are private business records.',
  ),
  MaintainiacSensitiveField(
    name: 'customerPhone',
    kind: MaintainiacSensitiveFieldKind.customerIdentity,
    reason: 'Customer phone numbers are private contact data.',
  ),
  MaintainiacSensitiveField(
    name: 'email',
    kind: MaintainiacSensitiveFieldKind.customerIdentity,
    reason: 'Email addresses are private contact data.',
  ),
  MaintainiacSensitiveField(
    name: 'cardNumber',
    kind: MaintainiacSensitiveFieldKind.payment,
    reason: 'Card numbers must never be stored or reported.',
  ),
  MaintainiacSensitiveField(
    name: 'cardLast4',
    kind: MaintainiacSensitiveFieldKind.payment,
    reason: 'Card fragments are unnecessary for Maintainiac QA telemetry.',
  ),
  MaintainiacSensitiveField(
    name: 'vin',
    kind: MaintainiacSensitiveFieldKind.vehicleIdentity,
    reason: 'VINs must not be stored in this app.',
  ),
  MaintainiacSensitiveField(
    name: 'plate',
    kind: MaintainiacSensitiveFieldKind.vehicleIdentity,
    reason: 'License plates must not be stored in this app.',
  ),
  MaintainiacSensitiveField(
    name: 'licensePlate',
    kind: MaintainiacSensitiveFieldKind.vehicleIdentity,
    reason: 'License plates must not be stored in this app.',
  ),
  MaintainiacSensitiveField(
    name: 'patient',
    kind: MaintainiacSensitiveFieldKind.passengerPatient,
    reason: 'Patient data is outside app scope and must not be modeled.',
  ),
  MaintainiacSensitiveField(
    name: 'passenger',
    kind: MaintainiacSensitiveFieldKind.passengerPatient,
    reason: 'Passenger data is outside app scope and must not be modeled.',
  ),
  MaintainiacSensitiveField(
    name: 'deviceSerial',
    kind: MaintainiacSensitiveFieldKind.deviceIdentity,
    reason: 'Device serials are too identifying for admin health telemetry.',
  ),
  MaintainiacSensitiveField(
    name: 'apiKey',
    kind: MaintainiacSensitiveFieldKind.secret,
    reason: 'Secrets must never appear in QA fixtures or reports.',
  ),
]);

const maintainiacSensitiveFieldNames = {
  'rawReceiptText',
  'receiptImagePath',
  'customerName',
  'customerAddress',
  'customerPhone',
  'email',
  'cardNumber',
  'cardLast4',
  'vin',
  'plate',
  'licensePlate',
  'patient',
  'passenger',
  'deviceSerial',
  'apiKey',
};
