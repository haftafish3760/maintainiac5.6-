enum ExpenseBackupTransport {
  wifiOnly,
  wifiAndCellular;

  static ExpenseBackupTransport fromName(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'wifiandcellular' => ExpenseBackupTransport.wifiAndCellular,
      _ => ExpenseBackupTransport.wifiOnly,
    };
  }
}

/// User-selected local-clock schedule for authorized Expense backup attempts.
///
/// This contains no network behavior. Platform background work must ask the
/// user-approved transport policy before using a planned time.
class ExpenseBackupSchedule {
  const ExpenseBackupSchedule({
    required this.timesMinutesAfterMidnight,
    required this.transport,
  });

  factory ExpenseBackupSchedule.normalized({
    required Iterable<int> timesMinutesAfterMidnight,
    required ExpenseBackupTransport transport,
  }) {
    final times =
        timesMinutesAfterMidnight
            .where((time) => time >= 0 && time < 24 * 60)
            .toSet()
            .toList()
          ..sort();
    return ExpenseBackupSchedule(
      timesMinutesAfterMidnight: List.unmodifiable(times),
      transport: transport,
    );
  }

  final List<int> timesMinutesAfterMidnight;
  final ExpenseBackupTransport transport;

  bool get hasSelectedTimes => timesMinutesAfterMidnight.isNotEmpty;

  /// Returns the next explicitly selected local time. It never schedules a
  /// backup when the user has not selected at least one time.
  DateTime? nextRunAtOrAfter(DateTime now) {
    if (!hasSelectedTimes) return null;
    for (final minutes in timesMinutesAfterMidnight) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!candidate.isBefore(now)) return candidate;
    }
    final first = timesMinutesAfterMidnight.first;
    return DateTime(now.year, now.month, now.day + 1, first ~/ 60, first % 60);
  }

  DateTime? nextRunAfter(DateTime now) {
    if (!hasSelectedTimes) return null;
    for (final minutes in timesMinutesAfterMidnight) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (candidate.isAfter(now)) return candidate;
    }
    final first = timesMinutesAfterMidnight.first;
    return DateTime(now.year, now.month, now.day + 1, first ~/ 60, first % 60);
  }

  bool isDueAt(DateTime now, {DateTime? lastAttemptAt}) {
    if (lastAttemptAt == null) return false;
    final next = nextRunAfter(lastAttemptAt);
    return next != null && !next.isAfter(now);
  }
}
