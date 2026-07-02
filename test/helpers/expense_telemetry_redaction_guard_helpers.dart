import 'dart:io';

String readDartLibraryWithParts(String entryPath) {
  final entryFile = File(entryPath);
  final entrySource = entryFile.readAsStringSync();
  final sources = <String>[entrySource];
  final partPattern = RegExp(r"^part '([^']+)';", multiLine: true);
  for (final match in partPattern.allMatches(entrySource)) {
    final partPath = match.group(1);
    if (partPath == null) {
      continue;
    }
    sources.add(File('${entryFile.parent.path}/$partPath').readAsStringSync());
  }
  return sources.join('\n');
}

String serializedTelemetryValues(Object? value) {
  if (value is Map) {
    return value.values.map(serializedTelemetryValues).join(' ');
  }
  if (value is Iterable) {
    return value.map(serializedTelemetryValues).join(' ');
  }
  return value?.toString() ?? '';
}
