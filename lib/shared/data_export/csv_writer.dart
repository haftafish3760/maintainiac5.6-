String buildCsv(List<List<Object?>> rows) {
  return rows.map(_csvRow).join('\n');
}

String _csvRow(List<Object?> cells) {
  return cells.map(_csvCell).join(',');
}

String _csvCell(Object? value) {
  final text = _neutralizeSpreadsheetFormula(value?.toString() ?? '');
  final needsQuotes =
      text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r');
  if (!needsQuotes) return text;
  return '"${text.replaceAll('"', '""')}"';
}

String _neutralizeSpreadsheetFormula(String text) {
  if (text.isEmpty) return text;
  final trimmedLeft = text.trimLeft();
  if (trimmedLeft.isEmpty) return text;
  final first = trimmedLeft.codeUnitAt(0);
  if (first == 61 || first == 43 || first == 45 || first == 64) {
    return "'$text";
  }
  return text;
}
