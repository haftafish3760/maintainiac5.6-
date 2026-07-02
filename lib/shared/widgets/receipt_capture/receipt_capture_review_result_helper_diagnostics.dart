part of 'receipt_capture_models.dart';

List<String> _diagnosticStringList(Object? value) {
  if (value is Iterable) {
    return List.unmodifiable(
      value
          .map((entry) => _diagnosticToken(entry?.toString() ?? ''))
          .where((entry) => entry != 'unknown')
          .toList(),
    );
  }
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return const [];
  return List.unmodifiable(
    text
        .split(RegExp(r'[|,]'))
        .map(_diagnosticToken)
        .where((entry) => entry != 'unknown')
        .toList(),
  );
}

bool _diagnosticPositive(Object? value) {
  if (value is num) return value > 0;
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0;
}

int? _diagnosticPositiveInt(Object? value) {
  if (value is num) {
    final intValue = value.toInt();
    return intValue > 0 ? intValue : null;
  }
  final parsed = int.tryParse(value?.toString().trim() ?? '');
  return parsed != null && parsed > 0 ? parsed : null;
}

bool? _diagnosticBool(Object? value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return null;
}

String _diagnosticToken(String value) {
  final token = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return token.isEmpty ? 'unknown' : token;
}

Map<String, Map<String, Object?>> _immutableDiagnosticsMap(
  Map<String, Map<String, Object?>> values,
) {
  if (values.isEmpty) return const {};
  return Map.unmodifiable({
    for (final entry in values.entries)
      entry.key: Map<String, Object?>.unmodifiable(entry.value),
  });
}

List<String> _nonBlankPaths(List<String> paths) {
  return [
    for (final path in paths)
      if (path.trim().isNotEmpty) path.trim(),
  ];
}
