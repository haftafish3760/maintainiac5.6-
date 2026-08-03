part of 'receipt_flow_route_audit.dart';

class _Evidence {
  const _Evidence(this.path, this.line, this.text);

  final String path;
  final int line;
  final String text;

  Map<String, Object?> toJson() => {'path': path, 'line': line, 'text': text};
  String get markdown => '- `$path:$line` — `${_oneLine(text)}`';
}

class _ScreenDeclaration {
  const _ScreenDeclaration(this.name, this.location, this.referenceCount);

  final String name;
  final _Evidence location;
  final int referenceCount;

  Map<String, Object?> toJson() => {
    'name': name,
    'referenceCount': referenceCount,
    'location': location.toJson(),
  };
}

class _FileSize {
  const _FileSize(this.path, this.lines);

  final String path;
  final int lines;

  Map<String, Object?> toJson() => {'path': path, 'lines': lines};
}

class _SimilarUiPair {
  const _SimilarUiPair(this.first, this.second, this.sharedLabels, this.score);

  final String first;
  final String second;
  final List<String> sharedLabels;
  final double score;

  Map<String, Object?> toJson() => {
    'first': first,
    'second': second,
    'score': score,
    'sharedLabels': sharedLabels,
  };
}

class _UnreachableFile {
  const _UnreachableFile(this.path, this.incomingReferences);

  final String path;
  final List<String> incomingReferences;

  Map<String, Object?> toJson() => {
    'path': path,
    'incomingReferences': incomingReferences,
  };
}

class _AuditReport {
  const _AuditReport({
    required this.generatedAt,
    required this.filesScanned,
    required this.routeSites,
    required this.legacyMarkers,
    required this.oversized,
    required this.exactDuplicates,
    required this.similarUi,
    required this.unreachable,
    required this.lowReferenceScreens,
  });

  final DateTime generatedAt;
  final int filesScanned;
  final List<_Evidence> routeSites;
  final List<_Evidence> legacyMarkers;
  final List<_FileSize> oversized;
  final List<List<String>> exactDuplicates;
  final List<_SimilarUiPair> similarUi;
  final List<_UnreachableFile> unreachable;
  final List<_ScreenDeclaration> lowReferenceScreens;

  Map<String, Object?> toJson() => {
    'generatedAtUtc': generatedAt.toIso8601String(),
    'scope': 'Maintainiac receipt routes and receipt UI dependencies',
    'filesScanned': filesScanned,
    'disclaimer':
        'Candidates are evidence for review, not automatic deletion approval.',
    'routeSites': routeSites.map((item) => item.toJson()).toList(),
    'legacyMarkers': legacyMarkers.map((item) => item.toJson()).toList(),
    'oversizedFiles': oversized.map((item) => item.toJson()).toList(),
    'exactDuplicateFileGroups': exactDuplicates,
    'similarUiCandidates': similarUi.map((item) => item.toJson()).toList(),
    'unreachableFromMainCandidates': unreachable
        .map((item) => item.toJson())
        .toList(),
    'lowReferenceScreenCandidates': lowReferenceScreens
        .map((item) => item.toJson())
        .toList(),
  };

  String consoleSummary() {
    return 'Receipt flow source audit: files=$filesScanned '
        'routes=${routeSites.length} legacyMarkers=${legacyMarkers.length} '
        'unreachable=${unreachable.length} '
        'lowReferenceScreens=${lowReferenceScreens.length} '
        'similarUiPairs=${similarUi.length} oversized=${oversized.length}';
  }

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Maintainiac Receipt Flow Source Audit')
      ..writeln()
      ..writeln('- Generated: ${generatedAt.toIso8601String()}')
      ..writeln('- Receipt-scope files scanned: $filesScanned')
      ..writeln(
        '- Safety: every candidate requires human verification before removal.',
      )
      ..writeln()
      ..writeln('## User-visible receipt entry and navigation sites')
      ..writeln();
    _writeEvidence(buffer, routeSites, 'None found.');
    buffer
      ..writeln()
      ..writeln('## Legacy or competing-flow markers')
      ..writeln();
    _writeEvidence(buffer, legacyMarkers, 'None found.');
    buffer
      ..writeln()
      ..writeln('## Not reachable from `lib/main.dart`')
      ..writeln();
    if (unreachable.isEmpty) {
      buffer.writeln('None found.');
    } else {
      for (final item in unreachable) {
        final incoming = item.incomingReferences.isEmpty
            ? 'no import/part references'
            : 'referenced by ${item.incomingReferences.join(', ')}';
        buffer.writeln('- `${item.path}` — $incoming');
      }
    }
    buffer
      ..writeln()
      ..writeln('## Public screen classes with declaration-only references')
      ..writeln();
    if (lowReferenceScreens.isEmpty) {
      buffer.writeln('None found.');
    } else {
      for (final item in lowReferenceScreens) {
        buffer.writeln(
          '- `${item.name}` — ${item.location.path}:${item.location.line} '
          '(references=${item.referenceCount})',
        );
      }
    }
    _writeDuplicateSections(buffer);
    return buffer.toString();
  }

  void _writeDuplicateSections(StringBuffer buffer) {
    buffer
      ..writeln()
      ..writeln('## Similar UI candidates')
      ..writeln();
    if (similarUi.isEmpty) {
      buffer.writeln('None found.');
    } else {
      for (final pair in similarUi) {
        buffer.writeln(
          '- `${pair.first}` ↔ `${pair.second}` '
          '(label similarity ${(pair.score * 100).round()}%, shared: '
          '${pair.sharedLabels.take(8).join(' | ')})',
        );
      }
    }
    buffer
      ..writeln()
      ..writeln('## Exact duplicate files')
      ..writeln();
    if (exactDuplicates.isEmpty) {
      buffer.writeln('None found.');
    } else {
      for (final group in exactDuplicates) {
        buffer.writeln('- ${group.map((path) => '`$path`').join(', ')}');
      }
    }
    buffer
      ..writeln()
      ..writeln('## Files over 500 lines')
      ..writeln();
    if (oversized.isEmpty) {
      buffer.writeln('None found.');
    } else {
      for (final item in oversized) {
        buffer.writeln('- `${item.path}` — ${item.lines} lines');
      }
    }
  }
}

String _oneLine(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();

void _writeEvidence(
  StringBuffer buffer,
  List<_Evidence> evidence,
  String emptyLabel,
) {
  if (evidence.isEmpty) {
    buffer.writeln(emptyLabel);
    return;
  }
  for (final item in evidence) {
    buffer.writeln(item.markdown);
  }
}
