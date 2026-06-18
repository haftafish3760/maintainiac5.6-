String buildCsv(List<List<Object?>> rows) {
  return rows.map(_csvRow).join('\n');
}

String _csvRow(List<Object?> cells) {
  return cells.map(_csvCell).join(',');
}

String _csvCell(Object? value) {
  final text = value?.toString() ?? '';
  final needsQuotes =
      text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r');
  if (!needsQuotes) return text;
  return '"${text.replaceAll('"', '""')}"';
}
