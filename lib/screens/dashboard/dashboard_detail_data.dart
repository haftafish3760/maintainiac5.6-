part of 'dashboard_detail_screen.dart';

class _DetailData {
  const _DetailData({
    required this.title,
    required this.icon,
    required this.color,
    required this.period,
    required this.listTitle,
    required this.metrics,
    required this.actions,
    required this.categories,
    required this.entries,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String period;
  final String listTitle;
  final List<_MetricData> metrics;
  final List<_ActionData> actions;
  final List<_CategoryData> categories;
  final List<_EntryData> entries;

  static _DetailData forKind(DashboardDetailKind kind) {
    return switch (kind) {
      DashboardDetailKind.fuel => _fuel,
      DashboardDetailKind.pay => _pay,
      DashboardDetailKind.trips => _trips,
      DashboardDetailKind.expenses => _expenses,
      DashboardDetailKind.profit => _profit,
    };
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _ActionData {
  const _ActionData(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _CategoryData {
  const _CategoryData(this.label, this.total, this.icon, this.color);

  final String label;
  final String total;
  final IconData icon;
  final Color color;
}

class _EntryData {
  const _EntryData({
    required this.day,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.receiptLabel,
    required this.lines,
  });

  final String day;
  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final String receiptLabel;
  final List<String> lines;
}

const _green = Color(0xFF27D56B);
const _blue = Color(0xFF34A9E8);
const _red = Color(0xFFFF5750);
const _yellow = Color(0xFFFFD166);

final _expenses = _DetailData(
  title: 'Expenses',
  icon: Icons.receipt_long_rounded,
  color: _yellow,
  period: 'May 18-24',
  listTitle: 'Chronological expense entries',
  metrics: const [
    _MetricData('Total', r'$421', _red),
    _MetricData('Business', r'$386', _yellow),
    _MetricData('Personal', r'$35', _blue),
  ],
  actions: const [
    _ActionData('Add Expense', Icons.add_rounded, Color(0xFF2E6FA8)),
    _ActionData('Scan Receipt', Icons.document_scanner_rounded, _green),
    _ActionData('Misc', Icons.category_rounded, Color(0xFF59636A)),
  ],
  categories: const [
    _CategoryData('Fuel', r'$126', Icons.local_gas_station_rounded, _red),
    _CategoryData('Maintenance', r'$88', Icons.build_rounded, _yellow),
    _CategoryData('Supplies', r'$137', Icons.inventory_2_rounded, _blue),
    _CategoryData('Parking', r'$35', Icons.local_parking_rounded, _green),
  ],
  entries: _expenseEntries,
);

final _fuel = _DetailData(
  title: 'Fuel',
  icon: Icons.local_gas_station_rounded,
  color: _red,
  period: 'May 18-24',
  listTitle: 'Fuel entries by day',
  metrics: const [
    _MetricData('Spent', r'$126', _red),
    _MetricData('Gallons', '31.4', _blue),
    _MetricData('MPG', '24.8', _green),
  ],
  actions: const [
    _ActionData('Add Fuel', Icons.add_rounded, Color(0xFF2E6FA8)),
    _ActionData('Scan Receipt', Icons.document_scanner_rounded, _green),
  ],
  categories: const [],
  entries: _fuelEntries,
);

final _pay = _DetailData(
  title: 'Pay',
  icon: Icons.payments_rounded,
  color: _green,
  period: 'May 18-24',
  listTitle: 'Pay entries by day',
  metrics: const [
    _MetricData('Gross', r'$2,184', _green),
    _MetricData('Per hr', r'$44.80', _green),
    _MetricData('Per mi', r'$4.56', _green),
  ],
  actions: const [_ActionData('Add Pay', Icons.add_rounded, Color(0xFF2E6FA8))],
  categories: const [],
  entries: _payEntries,
);

final _trips = _DetailData(
  title: 'Trips',
  icon: Icons.route_rounded,
  color: _blue,
  period: 'May 18-24',
  listTitle: 'Trip entries by day',
  metrics: const [
    _MetricData('Miles', '386 mi', _blue),
    _MetricData('Hours', '48.7', _blue),
    _MetricData('Stops', '64', _yellow),
  ],
  actions: const [
    _ActionData('Add Trip', Icons.add_rounded, Color(0xFF2E6FA8)),
  ],
  categories: const [],
  entries: _tripEntries,
);

final _profit = _DetailData(
  title: 'Profit',
  icon: Icons.trending_up_rounded,
  color: _green,
  period: 'May 18-24',
  listTitle: 'Profit drivers',
  metrics: const [
    _MetricData('Net', r'$1,763', _green),
    _MetricData('Cost/mi', r'$1.09', _red),
    _MetricData('Net/mi', r'$3.47', _green),
  ],
  actions: const [],
  categories: const [],
  entries: _profitEntries,
);

const _expenseEntries = [
  _EntryData(
    day: 'Mon',
    title: 'Lowes - supplies',
    subtitle: 'Business | Supplies | 4 line items',
    amount: r'$137',
    color: _blue,
    receiptLabel: 'Receipt image preview',
    lines: [
      'Lowes',
      r'PVC fittings  $48.22',
      r'Sealant  $16.44',
      r'Total  $137.00',
    ],
  ),
  _EntryData(
    day: 'Tue',
    title: 'Shell fuel',
    subtitle: 'Business | Fuel | 14.8 gallons',
    amount: r'$59',
    color: _red,
    receiptLabel: 'Fuel receipt preview',
    lines: ['Shell', 'Regular 14.8 gal', r'Price/gal  $3.99', r'Total  $59.05'],
  ),
  _EntryData(
    day: 'Fri',
    title: 'Parking garage',
    subtitle: 'Business | Parking',
    amount: r'$35',
    color: _green,
    receiptLabel: 'Parking receipt preview',
    lines: ['City parking', r'Garage fee  $35.00', r'Total  $35.00'],
  ),
];

const _fuelEntries = [
  _EntryData(
    day: 'Tue',
    title: 'Shell',
    subtitle: '14.8 gal | 238 miles',
    amount: r'$59',
    color: _red,
    receiptLabel: 'Fuel receipt preview',
    lines: ['Shell', '14.8 gal', 'Odometer 298,150', r'Total  $59.05'],
  ),
  _EntryData(
    day: 'Fri',
    title: 'BP',
    subtitle: '16.6 gal | 148 miles',
    amount: r'$67',
    color: _red,
    receiptLabel: 'Fuel receipt preview',
    lines: ['BP', '16.6 gal', 'Odometer 298,386', r'Total  $66.95'],
  ),
];

const _payEntries = [
  _EntryData(
    day: 'Wed',
    title: 'DoorDash payout',
    subtitle: '18.3 hr | 161 mi',
    amount: r'$816',
    color: _green,
    receiptLabel: 'Pay record',
    lines: ['DoorDash', r'Base + tips  $816.00', 'Hours  18.3', 'Miles  161'],
  ),
  _EntryData(
    day: 'Sat',
    title: 'Uber payout',
    subtitle: '30.4 hr | 225 mi',
    amount: r'$1,368',
    color: _green,
    receiptLabel: 'Pay record',
    lines: ['Uber', r'Payout  $1,368.00', 'Hours  30.4', 'Miles  225'],
  ),
];

const _tripEntries = [
  _EntryData(
    day: 'Mon',
    title: 'Morning route',
    subtitle: '84 mi | 17 stops',
    amount: '84 mi',
    color: _blue,
    receiptLabel: 'Trip route snapshot',
    lines: ['Start  7:12 AM', 'End  12:44 PM', 'Miles  84', 'Stops  17'],
  ),
  _EntryData(
    day: 'Thu',
    title: 'Afternoon route',
    subtitle: '122 mi | 24 stops',
    amount: '122 mi',
    color: _blue,
    receiptLabel: 'Trip route snapshot',
    lines: ['Start  1:03 PM', 'End  7:18 PM', 'Miles  122', 'Stops  24'],
  ),
];

const _profitEntries = [
  _EntryData(
    day: 'Week',
    title: 'Gross pay',
    subtitle: 'All pay sources',
    amount: r'$2,184',
    color: _green,
    receiptLabel: 'Profit calculation',
    lines: [
      r'Gross pay  $2,184.00',
      r'Expenses  -$421.00',
      r'Net profit  $1,763.00',
    ],
  ),
  _EntryData(
    day: 'Week',
    title: 'Fuel impact',
    subtitle: 'Fuel cost per mile',
    amount: r'$0.33/mi',
    color: _red,
    receiptLabel: 'Fuel impact',
    lines: [r'Fuel  $126.00', 'Miles  386', r'Fuel cost/mi  $0.33'],
  ),
];
