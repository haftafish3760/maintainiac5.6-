part of 'maintenance_screen.dart';

int _compareMaintenancePriority(MaintenanceRecord a, MaintenanceRecord b) {
  final severity = _attentionScore(b).compareTo(_attentionScore(a));
  if (severity != 0) return severity;
  final importance = b.importance.compareTo(a.importance);
  if (importance != 0) return importance;
  return a.itemName.compareTo(b.itemName);
}

int _attentionScore(MaintenanceRecord record) {
  if (!record.setupComplete) return 5000 + record.importance;
  if (record.timeOnly) {
    if (record.monthsRemaining <= 0) return 4000 + record.importance;
    if (record.monthsRemaining <= 1) return 3000 + record.importance;
    if (record.monthsRemaining <= 3) return 2000 + record.importance;
    if (record.monthsRemaining <= 6) return 1000 + record.importance;
    return record.importance;
  }
  if (record.milesRemaining <= 0) return 4000 + record.importance;
  if (record.milesRemaining <= 300) return 3000 + record.importance;
  if (record.milesRemaining <= 600) return 2000 + record.importance;
  if (record.milesRemaining <= 900) return 1000 + record.importance;
  return record.importance;
}

Color _recordColor(MaintenanceRecord record) {
  if (!record.setupComplete) return const Color(0xFF4D5860);
  if (!record.thresholdsEnabled) return AppActionColors.primary;
  if (record.timeOnly) {
    if (record.monthsRemaining <= 1) return AppColors.red;
    if (record.monthsRemaining <= 3) return AppColors.orange;
    if (record.monthsRemaining <= 6) return AppColors.yellow;
    return AppActionColors.positive;
  }
  return thresholdColor(record.milesRemaining);
}

String _recordStatus(MaintenanceRecord record) {
  if (!record.setupComplete) {
    return 'Not set up yet - tap to add last service and intervals';
  }
  final months = record.monthsRemaining.clamp(-99, 999);
  if (record.timeOnly) {
    return '$months months remaining • time-based renewal';
  }
  return '${formatMiles(record.milesRemaining)} miles • $months months remaining';
}

String formatMiles(int value) {
  final sign = value < 0 ? '-' : '';
  final digits = value.abs().toString();
  final buffer = StringBuffer(sign);
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
