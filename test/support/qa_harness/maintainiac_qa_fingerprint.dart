class MaintainiacQaSourceFile {
  const MaintainiacQaSourceFile({required this.path, required this.content});

  final String path;
  final String content;

  List<String> validate() {
    final failures = <String>[];
    if (path.trim().isEmpty) failures.add('source file missing path');
    if (path.contains('\\')) {
      failures.add('$path must use normalized slash paths');
    }
    return failures;
  }
}

class MaintainiacQaFingerprint {
  const MaintainiacQaFingerprint({
    required this.label,
    required this.value,
    required this.paths,
  });

  final String label;
  final String value;
  final List<String> paths;

  Map<String, Object?> toJson() {
    return {'label': label, 'value': value, 'paths': paths};
  }
}

class MaintainiacQaFingerprintBuilder {
  const MaintainiacQaFingerprintBuilder();

  MaintainiacQaFingerprint build({
    required String label,
    required Iterable<MaintainiacQaSourceFile> files,
  }) {
    final normalized = files.toList()..sort((a, b) => a.path.compareTo(b.path));
    final failures = <String>[];
    if (label.trim().isEmpty) failures.add('fingerprint missing label');
    if (normalized.isEmpty) failures.add('$label has no files');
    for (final file in normalized) {
      failures.addAll(file.validate());
    }
    if (failures.isNotEmpty) {
      throw ArgumentError(failures.join('; '));
    }

    var hash = 0xcbf29ce484222325;
    for (final file in normalized) {
      hash = _mix(hash, file.path);
      hash = _mix(hash, '\n');
      hash = _mix(hash, _normalizeContent(file.content));
      hash = _mix(hash, '\n---\n');
    }
    return MaintainiacQaFingerprint(
      label: label,
      value: hash.toRadixString(16).padLeft(16, '0'),
      paths: [for (final file in normalized) file.path],
    );
  }

  String signatureFor({
    required String label,
    required Iterable<MaintainiacQaSourceFile> files,
  }) {
    final fingerprint = build(label: label, files: files);
    return '${fingerprint.label}:${fingerprint.value}';
  }

  static String _normalizeContent(String content) {
    return content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  static int _mix(int hash, String value) {
    var current = hash;
    for (final unit in value.codeUnits) {
      current ^= unit;
      current = (current * 0x100000001b3) & 0xffffffffffffffff;
    }
    return current;
  }
}
