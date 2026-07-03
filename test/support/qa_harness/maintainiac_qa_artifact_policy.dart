enum MaintainiacQaArtifactKind {
  report,
  fixture,
  regression,
  performance,
  security,
}

class MaintainiacQaArtifact {
  const MaintainiacQaArtifact({
    required this.id,
    required this.kind,
    required this.path,
    required this.owner,
    required this.summary,
    this.redacted = true,
    this.containsRawReceiptText = false,
    this.containsPrivateData = false,
    this.tags = const {},
  });

  final String id;
  final MaintainiacQaArtifactKind kind;
  final String path;
  final String owner;
  final String summary;
  final bool redacted;
  final bool containsRawReceiptText;
  final bool containsPrivateData;
  final Set<String> tags;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('artifact missing id');
    if (path.trim().isEmpty) failures.add('$id missing path');
    if (owner.trim().isEmpty) failures.add('$id missing owner');
    if (summary.trim().isEmpty) failures.add('$id missing summary');
    if (tags.isEmpty) failures.add('$id needs searchable tags');
    if (!redacted) failures.add('$id must be redacted before it is evidence');
    if (containsRawReceiptText) {
      failures.add('$id must not store raw receipt text in QA artifacts');
    }
    if (containsPrivateData) {
      failures.add('$id must not store private data in QA artifacts');
    }
    if (!_allowedPath(path)) {
      failures.add('$id uses forbidden artifact path $path');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'path': path,
      'owner': owner,
      'summary': summary,
      'redacted': redacted,
      'containsRawReceiptText': containsRawReceiptText,
      'containsPrivateData': containsPrivateData,
      'tags': tags.toList()..sort(),
    };
  }

  static bool _allowedPath(String path) {
    final normalized = path.replaceAll('\\', '/').toLowerCase();
    if (normalized.contains('/googledrive/') ||
        normalized.contains('/google drive/') ||
        normalized.startsWith('f:/') ||
        normalized.contains('/onedrive/')) {
      return false;
    }
    return normalized.startsWith('build/qa/') ||
        normalized.startsWith('docs/qa/') ||
        normalized.startsWith('test/fixtures/');
  }
}

class MaintainiacQaArtifactPolicy {
  const MaintainiacQaArtifactPolicy(this.artifacts);

  final List<MaintainiacQaArtifact> artifacts;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    for (final artifact in artifacts) {
      if (!ids.add(artifact.id)) {
        failures.add('duplicate artifact id ${artifact.id}');
      }
      failures.addAll(artifact.validate());
    }
    if (artifacts.isEmpty) failures.add('artifact policy has no artifacts');
    return failures;
  }

  List<MaintainiacQaArtifact> byKind(MaintainiacQaArtifactKind kind) {
    return [
      for (final artifact in artifacts)
        if (artifact.kind == kind) artifact,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'artifactCount': artifacts.length,
      'artifacts': [for (final artifact in artifacts) artifact.toJson()],
    };
  }
}
