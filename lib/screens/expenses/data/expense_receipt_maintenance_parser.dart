part of 'expense_receipt_parser.dart';

List<ExpenseReceiptMaintenanceHint> _maintenanceHintsFor({
  required List<String> rows,
  required List<ExpenseReceiptLineRecord> lines,
  required _ReceiptParseContext context,
}) {
  if (!context.looksLikeAutoServiceReceipt &&
      !lines.any((line) => line.category == 'Maintenance')) {
    return const [];
  }

  final text = rows.join(' ').toLowerCase();
  final hints = <ExpenseReceiptMaintenanceHint>[];
  final odometer = _maintenanceOdometerFor(text);
  final dueOdometer = _maintenanceDueOdometerFor(text);
  final intervalMiles = _maintenanceIntervalMilesFor(
    text,
    odometer,
    dueOdometer,
  );
  final intervalMonths = _maintenanceIntervalMonthsFor(text);

  if (RegExp(
    r'\b(oil change|engine oil|motor oil|oil filter|full synthetic|synthetic blend|conventional oil)\b',
  ).hasMatch(text)) {
    final oilWeight = _oilWeightFor(text);
    final oilType = _oilTypeFor(text);
    final evidence = <String>[
      'Oil service language found.',
      if (oilWeight != null) 'Oil weight: $oilWeight.',
      if (oilType != null) 'Oil type: $oilType.',
      if (odometer != null) 'Service odometer: $odometer.',
      if (dueOdometer != null) 'Next due odometer: $dueOdometer.',
      if (intervalMiles != null) 'Mileage interval: $intervalMiles.',
      if (intervalMonths != null) 'Time interval: $intervalMonths months.',
    ];
    var confidence = .72;
    if (oilWeight != null) confidence += .08;
    if (intervalMiles != null || dueOdometer != null) confidence += .08;
    if (odometer != null) confidence += .06;
    hints.add(
      ExpenseReceiptMaintenanceHint(
        itemName: 'Engine Oil',
        serviceType: 'Oil Change',
        detail: oilType,
        oilWeight: oilWeight,
        intervalMiles: intervalMiles,
        intervalMonths: intervalMonths,
        serviceOdometer: odometer,
        dueOdometer: dueOdometer,
        confidence: confidence.clamp(0, 1).toDouble(),
        evidence: List.unmodifiable(evidence),
      ),
    );
  }

  if (RegExp(r'\b(tire rotation|rotate tires|rotation)\b').hasMatch(text)) {
    hints.add(
      ExpenseReceiptMaintenanceHint(
        itemName: 'Tire Rotation',
        serviceType: 'Tire Rotation',
        intervalMiles: intervalMiles,
        intervalMonths: intervalMonths,
        serviceOdometer: odometer,
        dueOdometer: dueOdometer,
        confidence: odometer == null ? .74 : .82,
        evidence: const ['Tire rotation language found.'],
      ),
    );
  }

  return List.unmodifiable(hints);
}

String? _oilWeightFor(String text) {
  final match = RegExp(
    r'\b(0w|5w|10w|15w|20w)\s*-?\s*(16|20|30|40|50)\b',
  ).firstMatch(text);
  if (match == null) return null;
  return '${match.group(1)!.toUpperCase()}-${match.group(2)}';
}

String? _oilTypeFor(String text) {
  if (RegExp(r'\b(full synthetic|synthetic full)\b').hasMatch(text)) {
    return 'Full Synthetic';
  }
  if (RegExp(r'\b(synthetic blend|syn blend)\b').hasMatch(text)) {
    return 'Synthetic Blend';
  }
  if (RegExp(r'\b(high mileage)\b').hasMatch(text)) return 'High Mileage';
  if (RegExp(r'\b(conventional)\b').hasMatch(text)) return 'Conventional';
  return null;
}

int? _maintenanceOdometerFor(String text) {
  final match = RegExp(
    r'\b(?:odometer|odo|mileage|miles in|current miles)\s*[:#]?\s*(\d{3,8})\b',
  ).firstMatch(text.replaceAll(',', ''));
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

int? _maintenanceDueOdometerFor(String text) {
  final normalized = text.replaceAll(',', '');
  final match = RegExp(
    r'\b(?:next service due|next due|due at|service due at|next oil change)\D{0,24}(\d{4,8})\b',
  ).firstMatch(normalized);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

int? _maintenanceIntervalMilesFor(
  String text,
  int? odometer,
  int? dueOdometer,
) {
  final normalized = text.replaceAll(',', '');
  final explicit = RegExp(
    r'\b(?:due in|interval|every|next service in)\D{0,16}(\d{3,6})\s*(?:mi|mile|miles)\b',
  ).firstMatch(normalized);
  if (explicit != null) return int.tryParse(explicit.group(1)!);
  if (odometer != null && dueOdometer != null && dueOdometer > odometer) {
    final interval = dueOdometer - odometer;
    if (interval >= 500 && interval <= 25000) return interval;
  }
  return null;
}

int? _maintenanceIntervalMonthsFor(String text) {
  final match = RegExp(
    r'\b(?:due in|interval|every|next service in)\D{0,16}(\d{1,2})\s*(?:mo|month|months)\b',
  ).firstMatch(text);
  if (match == null) return null;
  final months = int.tryParse(match.group(1)!);
  if (months == null || months <= 0 || months > 36) return null;
  return months;
}
