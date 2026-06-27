import 'employee_activity_models.dart';
import 'employee_directory_models.dart';

enum EmployeeProfileMetric {
  hours,
  grossPay,
  invoices,
  expenses,
  jobs,
  miles,
  materials,
  receipts,
  payHistory;

  String labelFor(EmployeeDirectoryRecord record) {
    final isDelivery = _isDeliveryRecord(record);
    return switch (this) {
      EmployeeProfileMetric.hours => 'Hours',
      EmployeeProfileMetric.grossPay => 'Gross Pay',
      EmployeeProfileMetric.invoices => isDelivery ? 'Route Pay' : 'Invoices',
      EmployeeProfileMetric.expenses => 'Expenses',
      EmployeeProfileMetric.jobs => isDelivery ? 'Stops' : 'Jobs',
      EmployeeProfileMetric.miles => 'Miles',
      EmployeeProfileMetric.materials => 'Materials',
      EmployeeProfileMetric.receipts => 'Receipts',
      EmployeeProfileMetric.payHistory => 'Pay History',
    };
  }

  String valueFor(EmployeeActivitySummary activity) {
    return switch (this) {
      EmployeeProfileMetric.hours => activity.hours,
      EmployeeProfileMetric.grossPay => activity.grossPay,
      EmployeeProfileMetric.invoices => activity.moneyIn,
      EmployeeProfileMetric.expenses => activity.moneyOut,
      EmployeeProfileMetric.jobs => activity.jobs,
      EmployeeProfileMetric.miles => activity.miles,
      EmployeeProfileMetric.materials => activity.materials,
      EmployeeProfileMetric.receipts => activity.receipts,
      EmployeeProfileMetric.payHistory => '1 payment',
    };
  }

  List<EmployeeMetricDetail> detailsFor(
    EmployeeDirectoryRecord record,
    EmployeeActivitySummary activity,
  ) {
    final isDelivery = _isDeliveryRecord(record);
    return switch (this) {
      EmployeeProfileMetric.hours => _hourDetails(),
      EmployeeProfileMetric.grossPay => _grossPayDetails(record, activity),
      EmployeeProfileMetric.invoices =>
        isDelivery
            ? [
                _metric(
                  'Week',
                  'Route pay placeholder',
                  'Delivery pay records are separate from contractor invoices.',
                  activity.moneyIn,
                ),
              ]
            : _invoiceDetails(),
      EmployeeProfileMetric.expenses => _expenseDetails(),
      EmployeeProfileMetric.jobs => isDelivery ? _stopDetails() : _jobDetails(),
      EmployeeProfileMetric.miles => _mileageDetails(),
      EmployeeProfileMetric.materials => _materialDetails(),
      EmployeeProfileMetric.receipts => _receiptDetails(),
      EmployeeProfileMetric.payHistory => _payHistoryDetails(record, activity),
    };
  }
}

bool _isDeliveryRecord(EmployeeDirectoryRecord record) {
  final role = record.roleLabel.toLowerCase();
  return role.contains('delivery') || role.contains('route');
}

List<EmployeeMetricDetail> _hourDetails() {
  return [
    _metric(
      'Mon',
      'Labor recorded',
      'Water heater rough-in and material run.',
      '8.5 hr',
    ),
    _metric(
      'Tue',
      'Labor recorded',
      'Main line repair and estimate visit.',
      '9.0 hr',
    ),
    _metric(
      'Wed',
      'Labor recorded',
      'Toilet flange replacement and maintenance note.',
      '8.0 hr',
    ),
    _metric(
      'Thu',
      'Labor recorded',
      'Two service calls and supply run.',
      '9.0 hr',
    ),
    _metric('Fri', 'Labor recorded', 'Punch list and job closeout.', '8.0 hr'),
  ];
}

List<EmployeeMetricDetail> _grossPayDetails(
  EmployeeDirectoryRecord record,
  EmployeeActivitySummary activity,
) {
  return [
    _metric(
      'Base',
      'Regular hours',
      '40.0 hours from this pay week.',
      _regularPay(record),
    ),
    _metric(
      'OT',
      'Overtime hours',
      _overtimeDetail(record, activity),
      _overtimePay(record),
    ),
    _metric(
      'Total',
      'Gross pay estimate',
      'Taxes and withholdings are not calculated here.',
      activity.grossPay,
    ),
  ];
}

List<EmployeeMetricDetail> _invoiceDetails() {
  return [
    _metric(
      'Mon',
      'Progress invoice drafted',
      'Water heater rough-in.',
      r'$2,450',
    ),
    _metric(
      'Tue',
      'Estimate sent',
      'Kitchen repipe estimate sent for signature.',
      r'$1,860',
    ),
    _metric(
      'Wed',
      'Payment recorded',
      'Customer payment posted to paid invoice.',
      r'$1,225',
    ),
    _metric(
      'Thu',
      'Progress invoice sent',
      'Main line repair progress billing.',
      r'$1,740',
    ),
    _metric(
      'Fri',
      'Final invoice drafted',
      'Toilet flange and finish work.',
      r'$1,665',
    ),
  ];
}

List<EmployeeMetricDetail> _expenseDetails() {
  return [
    _metric(
      'Mon',
      "Lowe's receipt",
      'Material receipt attached to job.',
      r'$312',
    ),
    _metric(
      'Tue',
      'Home Depot receipt',
      'Inventory and receipt cost recorded.',
      r'$228',
    ),
    _metric(
      'Wed',
      'Shell fuel receipt',
      'Fuel receipt plus maintenance note.',
      r'$94',
    ),
    _metric(
      'Thu',
      'Ace Hardware receipt',
      'Fasteners and repair supplies.',
      r'$186',
    ),
    _metric(
      'Fri',
      "Miller's Hardware receipt",
      'Job closeout supplies.',
      r'$364',
    ),
  ];
}

List<EmployeeMetricDetail> _jobDetails() {
  return [
    _metric(
      'Mon',
      'Water heater rough-in',
      'Job labor and materials recorded.',
      '3.0 hr',
    ),
    _metric(
      'Tue',
      'Main line repair',
      'Field notes and photos attached.',
      '4.5 hr',
    ),
    _metric(
      'Wed',
      'Toilet flange replacement',
      'Completed with receipt proof.',
      '2.0 hr',
    ),
    _metric(
      'Thu',
      'Kitchen faucet repair',
      'Labor and materials recorded.',
      '1.5 hr',
    ),
    _metric('Thu', 'Supply run', 'Truck stock replenishment.', '1.0 hr'),
    _metric(
      'Fri',
      'Punch list closeout',
      'Photos and closeout notes attached.',
      '1.0 hr',
    ),
  ];
}

List<EmployeeMetricDetail> _stopDetails() {
  return [
    _metric('Mon', 'North route', '32 delivered, 2 rescheduled.', '34 stops'),
    _metric('Tue', 'Bulk route', '18 stops completed.', '18 stops'),
  ];
}

List<EmployeeMetricDetail> _mileageDetails() {
  return [
    _metric(
      'Trip 1',
      'Started day to first job',
      'Start odometer 10,000 / finish 10,100 / total 100 miles.',
      '100 mi',
    ),
    _metric(
      'Trip 2',
      'Job to supply house',
      'Start odometer 10,100 / finish 10,128 / total 28 miles.',
      '28 mi',
    ),
    _metric(
      'Trip 3',
      'Supply house to shop',
      'Start odometer 10,128 / finish 10,214 / total 86 miles.',
      '86 mi',
    ),
  ];
}

List<EmployeeMetricDetail> _materialDetails() {
  return [
    _metric(
      'Mon',
      'Copper fittings',
      '12 items pulled from assigned vehicle inventory.',
      '12',
    ),
    _metric(
      'Tue',
      'PVC and couplings',
      '17 items used on main line repair.',
      '17',
    ),
    _metric(
      'Wed',
      'Repair supplies',
      '8 items used on flange replacement.',
      '8',
    ),
  ];
}

List<EmployeeMetricDetail> _receiptDetails() {
  return [
    _metric(
      'Mon',
      'Supply receipt',
      'Receipt captured and attached to job.',
      '1',
    ),
    _metric('Tue', 'Material receipt', 'Receipt needs owner review.', '1'),
    _metric(
      'Wed',
      'Fuel receipt',
      'Fuel receipt assigned to active vehicle.',
      '1',
    ),
    _metric('Thu', 'Hardware receipts', 'Two receipts attached to jobs.', '2'),
    _metric('Fri', 'Closeout receipts', 'Three receipts reviewed.', '3'),
  ];
}

List<EmployeeMetricDetail> _payHistoryDetails(
  EmployeeDirectoryRecord record,
  EmployeeActivitySummary activity,
) {
  return [
    _metric(
      'Current',
      'Gross pay preview',
      record.payType == 'salary'
          ? 'Salary pay period. Taxes and withholdings are not calculated.'
          : '42.5 hours including 2.5 overtime hours. Taxes and withholdings are not calculated.',
      activity.grossPay,
    ),
    _metric(
      'Last paid',
      'Payment marked paid',
      'Preview payment history record for UI layout only.',
      activity.grossPay,
    ),
  ];
}

EmployeeMetricDetail _metric(
  String when,
  String title,
  String detail,
  String value,
) {
  return EmployeeMetricDetail(
    when: when,
    title: title,
    detail: detail,
    value: value,
  );
}

String _regularPay(EmployeeDirectoryRecord record) {
  if (record.payType == 'salary') {
    return _money(_grossPayFor(record, regularHours: 0, overtimeHours: 0));
  }
  final rate = double.tryParse(record.grossRate) ?? 0;
  return _money(rate * 40);
}

String _overtimePay(EmployeeDirectoryRecord record) {
  if (record.payType == 'salary') return r'$0.00';
  final rate = double.tryParse(record.grossRate) ?? 0;
  final overtimeRate = record.overtimePolicy == 'timeAndHalf'
      ? rate * 1.5
      : double.tryParse(record.overtimeRate) ?? rate;
  return _money(overtimeRate * 2.5);
}

String _overtimeDetail(
  EmployeeDirectoryRecord record,
  EmployeeActivitySummary activity,
) {
  if (record.payType == 'salary' || activity.hours == 'Salary') {
    return 'Salary employee: no hourly overtime in this preview.';
  }
  final rate = double.tryParse(record.grossRate) ?? 0;
  final overtimeRate = record.overtimePolicy == 'timeAndHalf'
      ? rate * 1.5
      : double.tryParse(record.overtimeRate) ?? rate;
  return '2.5 hours at ${_money(overtimeRate)} per hour.';
}

double _grossPayFor(
  EmployeeDirectoryRecord record, {
  required double regularHours,
  required double overtimeHours,
}) {
  if (record.payType == 'salary') return double.tryParse(record.grossRate) ?? 0;
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
