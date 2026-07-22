import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

Future<void> main(List<String> arguments) async {
  var root = 'lib';
  String? jsonReport;
  String? markdownReport;
  for (final argument in arguments) {
    if (argument.startsWith('--root=')) {
      root = argument.substring('--root='.length);
    } else if (argument.startsWith('--json-report=')) {
      jsonReport = argument.substring('--json-report='.length);
    } else if (argument.startsWith('--markdown-report=')) {
      markdownReport = argument.substring('--markdown-report='.length);
    }
  }

  final report = await scanAccessibilityTextRisks(Directory(root));
  if (jsonReport != null) {
    final file = File(jsonReport);
    await file.parent.create(recursive: true);
    await file.writeAsString('${jsonEncode(report.toJson())}\n');
  }
  if (markdownReport != null) {
    final file = File(markdownReport);
    await file.parent.create(recursive: true);
    await file.writeAsString(report.toMarkdown());
  }
  stdout.writeln(
    'Accessibility text scan: files=${report.filesScanned}, '
    'candidateFiles=${report.filesWithRisks}, '
    'candidates=${report.occurrences.length}, '
    'globalOverrides=${report.globalOverrideCount}',
  );
}

Future<AccessibilityTextRiskReport> scanAccessibilityTextRisks(
  Directory root,
) async {
  final occurrences = <AccessibilityTextRiskOccurrence>[];
  var filesScanned = 0;
  if (!root.existsSync()) {
    return AccessibilityTextRiskReport(
      root: root.path,
      filesScanned: 0,
      occurrences: const [],
    );
  }

  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final normalized = entity.path.replaceAll('\\', '/');
    if (normalized.endsWith('.g.dart') ||
        normalized.endsWith('.freezed.dart') ||
        normalized.contains('/generated/')) {
      continue;
    }
    filesScanned += 1;
    final relative = _reportPath(root, entity);
    final lines = await entity.readAsLines();
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      for (final rule in _riskRules) {
        if (!rule.pattern.hasMatch(line)) continue;
        occurrences.add(
          AccessibilityTextRiskOccurrence(
            file: relative,
            owner: _ownerFor(relative),
            line: index + 1,
            kind: rule.kind,
          ),
        );
      }
    }
  }
  occurrences.sort((left, right) {
    final fileOrder = left.file.compareTo(right.file);
    if (fileOrder != 0) return fileOrder;
    final lineOrder = left.line.compareTo(right.line);
    if (lineOrder != 0) return lineOrder;
    return left.kind.compareTo(right.kind);
  });
  return AccessibilityTextRiskReport(
    root: root.path,
    filesScanned: filesScanned,
    occurrences: List.unmodifiable(occurrences),
  );
}

class AccessibilityTextRiskReport {
  const AccessibilityTextRiskReport({
    required this.root,
    required this.filesScanned,
    required this.occurrences,
  });

  final String root;
  final int filesScanned;
  final List<AccessibilityTextRiskOccurrence> occurrences;

  int get filesWithRisks => occurrences.map((item) => item.file).toSet().length;
  int get globalOverrideCount => occurrences
      .where((item) => item.kind.startsWith('global_text_scale_'))
      .length;

  Map<String, int> get countsByKind =>
      _countBy(occurrences.map((item) => item.kind));

  Map<String, int> get countsByOwner =>
      _countBy(occurrences.map((item) => item.owner));

  Map<String, Object?> toJson() => {
    'root': root,
    'filesScanned': filesScanned,
    'filesWithRisks': filesWithRisks,
    'candidateCount': occurrences.length,
    'globalOverrideCount': globalOverrideCount,
    'countsByKind': countsByKind,
    'countsByOwner': countsByOwner,
    'occurrences': [for (final item in occurrences) item.toJson()],
  };

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Maintainiac 5.7 accessibility text-risk inventory')
      ..writeln()
      ..writeln(
        'This is a source inventory, not a defect count. Each candidate needs '
        'screen-specific layout review at large device text sizes.',
      )
      ..writeln()
      ..writeln('- Dart production files scanned: **$filesScanned**')
      ..writeln('- Files containing candidates: **$filesWithRisks**')
      ..writeln('- Candidate occurrences: **${occurrences.length}**')
      ..writeln('- Global text-scale overrides: **$globalOverrideCount**')
      ..writeln()
      ..writeln('## Candidate kinds')
      ..writeln()
      ..writeln('| Kind | Count |')
      ..writeln('| --- | ---: |');
    for (final entry in countsByKind.entries) {
      buffer.writeln('| `${entry.key}` | ${entry.value} |');
    }
    buffer
      ..writeln()
      ..writeln('## Owners')
      ..writeln()
      ..writeln('| Owner | Candidates |')
      ..writeln('| --- | ---: |');
    for (final entry in countsByOwner.entries) {
      buffer.writeln('| `${entry.key}` | ${entry.value} |');
    }
    buffer
      ..writeln()
      ..writeln('## Machine-readable detail')
      ..writeln()
      ..writeln(
        'Exact file and line candidates are stored in '
        '`accessibility_text_risk_inventory_2026_07_22.json`.',
      );
    return buffer.toString();
  }
}

class AccessibilityTextRiskOccurrence {
  const AccessibilityTextRiskOccurrence({
    required this.file,
    required this.owner,
    required this.line,
    required this.kind,
  });

  final String file;
  final String owner;
  final int line;
  final String kind;

  Map<String, Object?> toJson() => {
    'file': file,
    'owner': owner,
    'line': line,
    'kind': kind,
  };
}

class _RiskRule {
  const _RiskRule(this.kind, this.pattern);

  final String kind;
  final RegExp pattern;
}

final _riskRules = <_RiskRule>[
  _RiskRule('single_line_limit', RegExp(r'\bmaxLines\s*:\s*1\b')),
  _RiskRule('bounded_line_limit', RegExp(r'\bmaxLines\s*:\s*[2-9]\d*\b')),
  _RiskRule('ellipsis_overflow', RegExp(r'TextOverflow\.ellipsis')),
  _RiskRule('clip_or_fade_overflow', RegExp(r'TextOverflow\.(?:clip|fade)')),
  _RiskRule('soft_wrap_disabled', RegExp(r'\bsoftWrap\s*:\s*false\b')),
  _RiskRule('fitted_box_text_risk', RegExp(r'\bFittedBox\s*\(')),
  _RiskRule(
    'global_text_scale_disabled',
    RegExp(r'MediaQuery\.withNoTextScaling|TextScaler\.noScaling'),
  ),
  _RiskRule(
    'global_text_scale_clamped',
    RegExp(r'MediaQuery\.withClampedTextScaling'),
  ),
  _RiskRule(
    'global_text_scale_override',
    RegExp(r'\btextScaleFactor\s*:|\btextScaler\s*:'),
  ),
];

Map<String, int> _countBy(Iterable<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return Map.fromEntries(
    counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

String _reportPath(Directory root, File file) {
  final parent = root.parent.path;
  return path.relative(file.path, from: parent).replaceAll('\\', '/');
}

String _ownerFor(String file) {
  final parts = file.split('/');
  if (parts.length >= 3 && parts[0] == 'lib' && parts[1] == 'screens') {
    return 'screens/${parts[2]}';
  }
  if (parts.length >= 3 && parts[0] == 'lib' && parts[1] == 'shared') {
    return 'shared/${parts[2]}';
  }
  if (parts.length >= 2 && parts[0] == 'lib') return 'lib/${parts[1]}';
  return 'other';
}
