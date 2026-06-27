class EmployeeActivitySummary {
  const EmployeeActivitySummary({
    required this.hours,
    required this.grossPay,
    required this.moneyIn,
    required this.moneyOut,
    required this.jobs,
    required this.miles,
    required this.materials,
    required this.receipts,
    required this.days,
  });

  final String hours;
  final String grossPay;
  final String moneyIn;
  final String moneyOut;
  final String jobs;
  final String miles;
  final String materials;
  final String receipts;
  final List<EmployeeActivityDay> days;
}

class EmployeeActivityDay {
  const EmployeeActivityDay({
    required this.label,
    required this.vehicle,
    required this.hours,
    required this.moneyIn,
    required this.moneyOut,
    required this.entries,
  });

  final String label;
  final String vehicle;
  final String hours;
  final String moneyIn;
  final String moneyOut;
  final List<EmployeeActivityEntry> entries;
}

class EmployeeActivityEntry {
  const EmployeeActivityEntry({
    required this.time,
    required this.type,
    required this.title,
    required this.detail,
    required this.amount,
  });

  final String time;
  final String type;
  final String title;
  final String detail;
  final String amount;
}

class EmployeeMetricDetail {
  const EmployeeMetricDetail({
    required this.when,
    required this.title,
    required this.detail,
    required this.value,
  });

  final String when;
  final String title;
  final String detail;
  final String value;
}
