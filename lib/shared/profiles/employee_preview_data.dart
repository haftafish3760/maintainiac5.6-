import 'employee_activity_models.dart';
import 'employee_directory_models.dart';
import 'user_profile_models.dart';

List<EmployeeDirectoryRecord> employeePreviewRecords() {
  final base = DateTime.utc(2026, 6, 20, 8);
  return [
    _previewRecord(
      base,
      minutes: 0,
      name: 'Alex Supervisor',
      phone: '5550101001',
      email: 'alex.supervisor@example.com',
      roleLabel: 'Supervisor',
      role: UserRole.admin,
      payType: 'salary',
      grossRate: '1450',
      assignedVehicleLabel: 'Work Truck 1',
    ),
    _previewRecord(
      base,
      minutes: 1,
      name: 'Bailey Foreman',
      phone: '5550101002',
      email: 'bailey.foreman@example.com',
      roleLabel: 'Foreman',
      role: UserRole.fieldManager,
      grossRate: '34',
      assignedVehicleLabel: 'Service Van 2',
    ),
    _previewRecord(
      base,
      minutes: 2,
      name: 'Casey Technician',
      phone: '5550101003',
      email: 'casey.tech@example.com',
      roleLabel: 'Technician',
      role: UserRole.technician,
      grossRate: '28.50',
      assignedVehicleLabel: 'Service Van 3',
    ),
    _previewRecord(
      base,
      minutes: 3,
      name: 'Drew Office',
      phone: '5550101004',
      email: 'drew.office@example.com',
      roleLabel: 'Office',
      role: UserRole.officeManager,
      grossRate: '24',
      payFrequency: 'biweekly',
      overtimePolicy: 'none',
      assignedVehicleLabel: 'Office Desk',
    ),
    _previewRecord(
      base,
      minutes: 4,
      name: 'Evan Helper',
      phone: '5550101005',
      email: 'evan.helper@example.com',
      roleLabel: 'Helper',
      role: UserRole.helper,
      grossRate: '18',
      assignedVehicleLabel: 'Crew Truck 4',
    ),
    _previewRecord(
      base,
      minutes: 5,
      name: 'Morgan Delivery Lead',
      phone: '5550101006',
      email: 'morgan.delivery@example.com',
      roleLabel: 'Delivery Lead',
      role: UserRole.driver,
      grossRate: '26',
      assignedVehicleLabel: 'Route Van 7',
    ),
    _previewRecord(
      base,
      minutes: 6,
      name: 'Riley Route Driver',
      phone: '5550101007',
      email: 'riley.route@example.com',
      roleLabel: 'Route Driver',
      role: UserRole.driver,
      grossRate: '22',
      assignedVehicleLabel: 'Box Truck 12',
    ),
    _previewRecord(
      base,
      minutes: 7,
      name: 'Frank Former',
      phone: '5550101008',
      email: 'frank.former@example.com',
      roleLabel: 'Former Driver',
      role: UserRole.driver,
      grossRate: '22',
      assignedVehicleLabel: 'No assigned vehicle',
      overtimePolicy: 'none',
    ).copyWith(status: EmployeeInviteStatus.disabled),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

List<EmployeeDirectoryRecord> combinedEmployeePreviewRecords(
  List<EmployeeDirectoryRecord> savedRecords,
) {
  if (savedRecords.isEmpty) return employeePreviewRecords();
  final savedIds = savedRecords.map((record) => record.id).toSet();
  final savedNames = savedRecords
      .map((record) => record.name.trim().toLowerCase())
      .toSet();
  final combined = [
    ...savedRecords,
    for (final preview in employeePreviewRecords())
      if (!savedIds.contains(preview.id) &&
          !savedNames.contains(preview.name.trim().toLowerCase()))
        preview,
  ];
  combined.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return combined;
}

EmployeeActivitySummary employeeActivityFor(EmployeeDirectoryRecord record) {
  if (record.roleLabel.toLowerCase().contains('delivery') ||
      record.roleLabel.toLowerCase().contains('route')) {
    return _deliveryActivity(record);
  }
  if (record.roleLabel.toLowerCase().contains('office')) {
    return _officeActivity(record);
  }
  if (!record.isActive) {
    return _inactiveActivity(record);
  }
  return _contractorActivity(record);
}

String formatEmployeePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10) return phone.trim();
  return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
}

EmployeeDirectoryRecord _previewRecord(
  DateTime base, {
  required int minutes,
  required String name,
  required String phone,
  required String email,
  required String roleLabel,
  required UserRole role,
  required String grossRate,
  required String assignedVehicleLabel,
  String payType = 'hourly',
  String payFrequency = 'weekly',
  String overtimePolicy = 'timeAndHalf',
}) {
  return EmployeeDirectoryRecord.create(
    ownerProfileId: 'preview-owner',
    name: name,
    phone: phone,
    email: email,
    roleLabel: roleLabel,
    roleName: role.name,
    customizedRole: false,
    permissions: permissionsForRole(role),
    payType: payType,
    payFrequency: payFrequency,
    grossRate: grossRate,
    payPeriodStartDay: 'monday',
    overtimePolicy: overtimePolicy,
    assignedVehicleLabel: assignedVehicleLabel,
    now: base.add(Duration(minutes: minutes)),
  ).copyWith(status: EmployeeInviteStatus.active);
}

EmployeeActivitySummary _contractorActivity(EmployeeDirectoryRecord record) {
  final grossPay = _grossPayFor(record, regularHours: 40, overtimeHours: 2.5);
  return EmployeeActivitySummary(
    hours: record.payType == 'salary' ? 'Salary' : '42.5',
    grossPay: record.payType == 'salary' ? r'$1,450' : _money(grossPay),
    moneyIn: r'$8,940',
    moneyOut: r'$1,184',
    jobs: '6',
    miles: '214',
    materials: '37',
    receipts: '9',
    days: const [],
  );
}

EmployeeActivitySummary _deliveryActivity(EmployeeDirectoryRecord record) {
  final grossPay = _grossPayFor(record, regularHours: 39, overtimeHours: 0);
  return EmployeeActivitySummary(
    hours: '39.0',
    grossPay: _money(grossPay),
    moneyIn: r'$0',
    moneyOut: r'$386',
    jobs: '82 stops',
    miles: '487',
    materials: '0',
    receipts: '6',
    days: const [],
  );
}

EmployeeActivitySummary _officeActivity(EmployeeDirectoryRecord record) {
  final grossPay = _grossPayFor(record, regularHours: 36, overtimeHours: 0);
  return EmployeeActivitySummary(
    hours: '36.0',
    grossPay: _money(grossPay),
    moneyIn: r'$6,720',
    moneyOut: r'$0',
    jobs: '14 records',
    miles: '0',
    materials: '0',
    receipts: '0',
    days: const [],
  );
}

EmployeeActivitySummary _inactiveActivity(EmployeeDirectoryRecord record) {
  return EmployeeActivitySummary(
    hours: '0.0',
    grossPay: r'$0',
    moneyIn: r'$0',
    moneyOut: r'$0',
    jobs: 'Historical',
    miles: '0',
    materials: '0',
    receipts: '0',
    days: const [],
  );
}

double _grossPayFor(
  EmployeeDirectoryRecord record, {
  required double regularHours,
  required double overtimeHours,
}) {
  if (record.payType == 'salary') {
    return double.tryParse(record.grossRate) ?? 0;
  }
  final rate = double.tryParse(record.grossRate) ?? 0;
  final overtimeRate = record.overtimePolicy == 'timeAndHalf'
      ? rate * 1.5
      : double.tryParse(record.overtimeRate) ?? rate;
  return (regularHours * rate) + (overtimeHours * overtimeRate);
}

String _money(double amount) {
  final rounded = amount.toStringAsFixed(2);
  final parts = rounded.split('.');
  final dollars = parts.first;
  final cents = parts.last;
  final buffer = StringBuffer();
  for (var i = 0; i < dollars.length; i++) {
    final remaining = dollars.length - i;
    buffer.write(dollars[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return '\$${buffer.toString()}.$cents';
}
