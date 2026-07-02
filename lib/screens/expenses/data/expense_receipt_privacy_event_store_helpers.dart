part of 'expense_receipt_privacy_event_store.dart';

void _increment(Map<String, int> counts, String value) {
  if (value.isEmpty) return;
  counts[value] = (counts[value] ?? 0) + 1;
}

String _stringValue(Object? value) => value is String ? value : '';

List<String> _stringListValue(Object? value) {
  if (value is! Iterable) return const [];
  return [
    for (final item in value)
      if (item is String && item.isNotEmpty) item,
  ];
}

int _intValue(Object? value) => value is int ? value : 0;

bool _boolValue(Object? value) => value is bool && value;

Map<String, int> _mapValue(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is int)
        entry.key as String: entry.value as int,
  };
}

void _mergeCountMap(Map<String, int> target, Map<String, int> source) {
  for (final entry in source.entries) {
    if (entry.key.isEmpty || entry.value <= 0) continue;
    target[entry.key] = (target[entry.key] ?? 0) + entry.value;
  }
}
