part of 'expense_receipt_entry_screen.dart';

extension _ExpenseReceiptEntryDiagnosticBucketHelpers on _ExpenseReceiptEntryScreenState {
  Map<String, int> _diagnosticStringCounts(
    List<Map<String, Object?>> diagnostics,
    String key,
  ) {
    final counts = <String, int>{};
    for (final diagnostic in diagnostics) {
      final value = diagnostic[key]?.toString().trim();
      if (value == null || value.isEmpty) continue;
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _diagnosticStringListCounts(
    List<Map<String, Object?>> diagnostics,
    String key,
  ) {
    final counts = <String, int>{};
    for (final diagnostic in diagnostics) {
      final value = diagnostic[key];
      if (value is Iterable) {
        for (final item in value) {
          final text = item.toString().trim();
          if (text.isEmpty) continue;
          counts[text] = (counts[text] ?? 0) + 1;
        }
        continue;
      }
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) continue;
      counts[text] = (counts[text] ?? 0) + 1;
    }
    return counts;
  }

  int _diagnosticIntSum(List<Map<String, Object?>> diagnostics, String key) {
    var total = 0;
    for (final diagnostic in diagnostics) {
      final value = diagnostic[key];
      if (value is int) {
        total += value;
      } else if (value is num) {
        total += value.round();
      } else if (value is String) {
        total += int.tryParse(value.trim()) ?? 0;
      }
    }
    return total;
  }

  int _diagnosticIntMax(List<Map<String, Object?>> diagnostics, String key) {
    var maxValue = 0;
    for (final diagnostic in diagnostics) {
      final value = diagnostic[key];
      final parsed = switch (value) {
        int() => value,
        num() => value.round(),
        String() => int.tryParse(value.trim()) ?? 0,
        _ => 0,
      };
      if (parsed > maxValue) maxValue = parsed;
    }
    return maxValue;
  }

  int _diagnosticBoolTrueCount(
    List<Map<String, Object?>> diagnostics,
    String key,
  ) {
    var total = 0;
    for (final diagnostic in diagnostics) {
      final value = diagnostic[key];
      if (value == true || value?.toString().trim().toLowerCase() == 'true') {
        total += 1;
      }
    }
    return total;
  }

  Map<String, int> _diagnosticLumaBuckets(
    List<Map<String, Object?>> diagnostics,
    String key,
  ) {
    final counts = <String, int>{};
    for (final diagnostic in diagnostics) {
      final value = _diagnosticDoubleValue(diagnostic[key]);
      if (value == null || value < 0) continue;
      final bucket = switch (value) {
        < 70 => 'bottom_too_dark',
        < 100 => 'bottom_dark',
        < 150 => 'bottom_dim',
        < 225 => 'bottom_readable',
        _ => 'bottom_glare_risk',
      };
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _diagnosticEdgeScoreBuckets(
    List<Map<String, Object?>> diagnostics,
    String key,
  ) {
    final counts = <String, int>{};
    for (final diagnostic in diagnostics) {
      final value = _diagnosticDoubleValue(diagnostic[key]);
      if (value == null || value < 0) continue;
      final bucket = switch (value) {
        < 4 => 'bottom_edge_missing',
        < 9 => 'bottom_edge_weak',
        < 16 => 'bottom_edge_usable',
        _ => 'bottom_edge_strong',
      };
      counts[bucket] = (counts[bucket] ?? 0) + 1;
    }
    return counts;
  }

  double? _diagnosticDoubleValue(Object? value) {
    return switch (value) {
      int() => value.toDouble(),
      num() => value.toDouble(),
      String() => double.tryParse(value.trim()),
      _ => null,
    };
  }

  String _ratioBucket(double value) {
    if (value <= 0) return 'none';
    if (value < .5) return 'low';
    if (value < .75) return 'medium';
    if (value < .9) return 'high';
    return 'very_high';
  }
}
